from __future__ import annotations

from typing import Any

import httpx
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.ai_service_integration.ai_protocol import (
    build_ai_request_envelope,
    build_ai_request_headers,
    serialize_json_for_signing,
)
from app.core.ai_service_integration.ai_request_tracking import generate_ai_request_id
from app.core.ai_service_integration.ai_signature import create_signature_from_bytes, get_current_timestamp

_WRITTEN_TYPES = {"short_answer", "essay"}
_DEFAULT_GRADING_ENDPOINT = "/api/v1/courses/grading/evaluate"


def estimate_written_ai_preview(answer: dict[str, Any]) -> dict[str, Any]:
    """Local preview only. Real scoring is delegated to the external AI grader."""
    text = str(answer.get("answer_text") or "").strip()
    confidence = float(answer.get("confidence") or 0)
    if not text:
        return {
            "score": None,
            "confidence": 0,
            "status": "needs_review",
            "feedback": "No written text was confidently extracted.",
        }
    status = "ai_ready" if confidence >= 55 else "needs_review"
    return {
        "score": None,
        "confidence": round(confidence, 2),
        "status": status,
        "feedback": "Ready for AI grading with OCR text context.",
    }


def grade_written_answers_with_ai(
    *,
    db: Session,
    course_id: int | None,
    exam_id: int | None,
    scan_id: str,
    answers: list[dict[str, Any]],
    questions: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[str]]:
    """Try to grade OCR-written answers during the analyze step.

    The project already has an async AI callback flow for saved attempts. During
    OCR analysis there is no attempt_id yet, so this helper uses a best-effort
    synchronous grading request. If the AI service only accepts async jobs, the
    scan still returns safely with the written answers marked as AI-ready.
    """
    warnings: list[str] = []
    written = [answer for answer in answers if _is_written(answer) and str(answer.get("answer_text") or "").strip()]
    if not written:
        for answer in answers:
            if _is_written(answer):
                preview = estimate_written_ai_preview(answer)
                answer["ai_status"] = preview["status"]
                answer["ai_feedback"] = preview["feedback"]
        return answers, warnings

    if not course_id or not exam_id:
        warnings.append("Written answers were extracted but AI grading was skipped because exam/course metadata was not resolved.")
        for answer in written:
            preview = estimate_written_ai_preview(answer)
            answer["ai_status"] = preview["status"]
            answer["ai_feedback"] = preview["feedback"]
        return answers, warnings

    request_id = generate_ai_request_id("ocr_exam_grading")
    for answer in written:
        answer["ai_request_id"] = request_id
        answer["ai_status"] = "pending"

    body = {
        "scan_id": scan_id,
        "exam_id": int(exam_id),
        "questions": [_build_ai_question(answer=answer, questions=questions) for answer in written],
        "mode": "ocr_preview",
    }

    try:
        payload = _send_ai_grading_preview_request(
            request_id=request_id,
            course_id=int(course_id),
            body=body,
        )
    except Exception as exc:
        warnings.append(f"AI grading could not be completed during scan analysis: {exc}")
        for answer in written:
            preview = estimate_written_ai_preview(answer)
            answer["ai_status"] = preview["status"]
            answer["ai_feedback"] = preview["feedback"]
        return answers, warnings

    results = _extract_results(payload)
    if not results:
        warnings.append("AI grading request was accepted, but no immediate grading results were returned. Review or save the attempt to run async grading.")
        for answer in written:
            answer["ai_status"] = "sent"
            answer["ai_feedback"] = "AI grading request was sent; no immediate result was returned."
        return answers, warnings

    _apply_ai_results(answers=answers, results=results, questions=questions, request_id=request_id)
    return answers, warnings


def _send_ai_grading_preview_request(*, request_id: str, course_id: int, body: dict[str, Any]) -> dict[str, Any]:
    endpoint_path = _normalize_endpoint_path(getattr(settings, "ocr_ai_grading_endpoint_path", _DEFAULT_GRADING_ENDPOINT))
    operation_type = getattr(settings, "ocr_ai_grading_operation_type", "exam_grading")
    method = "POST"
    timestamp = get_current_timestamp()
    envelope = build_ai_request_envelope(
        request_id=request_id,
        timestamp=timestamp,
        operation_type=operation_type,
        course_id=course_id,
        body=body,
    )
    serialized = serialize_json_for_signing(envelope)
    signature = create_signature_from_bytes(
        secret=settings.ai_shared_secret,
        method=method,
        path=endpoint_path,
        request_id=request_id,
        timestamp=timestamp,
        body=serialized,
    )
    headers = build_ai_request_headers(request_id=request_id, timestamp=timestamp, signature=signature)

    timeout = int(getattr(settings, "ocr_ai_grading_timeout_seconds", min(settings.ai_request_timeout_seconds, 90)))
    with httpx.Client(base_url=settings.ai_service_base_url, timeout=timeout) as client:
        response = client.request(method=method, url=endpoint_path, content=serialized, headers=headers)

    response.raise_for_status()
    try:
        data = response.json()
    except ValueError:
        return {"status": "accepted", "raw": response.text}
    return data if isinstance(data, dict) else {"data": data}


def _apply_ai_results(
    *,
    answers: list[dict[str, Any]],
    results: list[dict[str, Any]],
    questions: list[dict[str, Any]],
    request_id: str,
) -> None:
    answers_by_exam_question_id = {
        int(answer["exam_question_id"]): answer
        for answer in answers
        if answer.get("exam_question_id") is not None
    }
    answers_by_question_number = {
        int(answer["question_number"]): answer
        for answer in answers
        if answer.get("question_number") is not None
    }

    for item in results:
        if not isinstance(item, dict):
            continue
        answer = None
        qid = _safe_int(item.get("exam_question_id"))
        if qid is not None:
            answer = answers_by_exam_question_id.get(qid)
        if answer is None:
            qn = _safe_int(item.get("question_number") or item.get("question_no") or item.get("q"))
            if qn is not None:
                answer = answers_by_question_number.get(qn)
        if answer is None:
            continue

        max_score = _question_points(answer.get("exam_question_id"), answer.get("question_number"), questions)
        points = _extract_points(item)
        if points is not None:
            points = max(0.0, points)
            if max_score is not None:
                points = min(points, float(max_score))
            answer["points_earned"] = round(points, 2)
            answer["ai_score"] = round(points, 2)
            answer["is_correct"] = points > 0
        answer["ai_status"] = "completed" if points is not None else "needs_review"
        answer["status"] = "ai_graded" if points is not None and not item.get("needs_review") else "needs_review"
        answer["ai_request_id"] = request_id
        answer["ai_feedback"] = _extract_feedback(item)
        if item.get("confidence") is not None:
            answer["confidence"] = max(float(answer.get("confidence") or 0), _safe_float(item.get("confidence")) or 0)


def _build_ai_question(*, answer: dict[str, Any], questions: list[dict[str, Any]]) -> dict[str, Any]:
    question = _find_question(answer.get("exam_question_id"), answer.get("question_number"), questions) or {}
    return {
        "exam_question_id": answer.get("exam_question_id"),
        "question_number": answer.get("question_number"),
        "question_text": question.get("question_text"),
        "type": answer.get("type") or question.get("type"),
        "expected_answer": question.get("expected_answer"),
        "grading_rubric": question.get("grading_rubric"),
        "max_score": answer.get("max_score") or question.get("points") or question.get("max_score"),
        "student_answer": answer.get("answer_text"),
        "ocr_confidence": answer.get("confidence"),
        "answer_region": answer.get("answer_region"),
    }


def _extract_results(payload: dict[str, Any]) -> list[dict[str, Any]]:
    candidates: list[Any] = []
    candidates.append(payload.get("results"))
    candidates.append(payload.get("grading_results"))
    candidates.append(payload.get("grades"))
    body = payload.get("body")
    if isinstance(body, dict):
        candidates.extend([body.get("results"), body.get("grading_results"), body.get("grades")])
    data = payload.get("data")
    if isinstance(data, dict):
        candidates.extend([data.get("results"), data.get("grading_results"), data.get("grades")])

    for candidate in candidates:
        if isinstance(candidate, list):
            return [item for item in candidate if isinstance(item, dict)]
    return []


def _extract_points(item: dict[str, Any]) -> float | None:
    for key in ("points_earned", "score", "ai_score", "points", "grade"):
        value = item.get(key)
        parsed = _safe_float(value)
        if parsed is not None:
            return parsed
    return None


def _extract_feedback(item: dict[str, Any]) -> str | None:
    for key in ("feedback", "teacher_feedback", "explanation", "rationale", "comment"):
        value = item.get(key)
        if value is not None and str(value).strip():
            return str(value).strip()
    return None


def _question_points(exam_question_id: Any, question_number: Any, questions: list[dict[str, Any]]) -> float | None:
    question = _find_question(exam_question_id, question_number, questions)
    if not question:
        return None
    return _safe_float(question.get("points") or question.get("max_score"))


def _find_question(exam_question_id: Any, question_number: Any, questions: list[dict[str, Any]]) -> dict[str, Any] | None:
    eqid = _safe_int(exam_question_id)
    qn = _safe_int(question_number)
    for question in questions:
        if eqid is not None and _safe_int(question.get("exam_question_id")) == eqid:
            return question
    for question in questions:
        if qn is not None and _safe_int(question.get("question_number")) == qn:
            return question
    return None


def _is_written(answer: dict[str, Any]) -> bool:
    return str(answer.get("type") or "").strip().lower() in _WRITTEN_TYPES


def _safe_int(value: Any) -> int | None:
    try:
        if value is None or value == "":
            return None
        return int(str(value).strip())
    except (TypeError, ValueError):
        return None


def _safe_float(value: Any) -> float | None:
    try:
        if value is None or value == "":
            return None
        return float(value)
    except (TypeError, ValueError):
        return None


def _normalize_endpoint_path(endpoint_path: str) -> str:
    endpoint_path = (endpoint_path or "").strip()
    if not endpoint_path:
        return _DEFAULT_GRADING_ENDPOINT
    if not endpoint_path.startswith("/"):
        endpoint_path = f"/{endpoint_path}"
    return endpoint_path
