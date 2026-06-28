from __future__ import annotations

import base64
import json
import os
import re
from dataclasses import dataclass
from typing import Any

import httpx

from app.core.config import settings


@dataclass(slots=True)
class VisionWrittenAnswerResult:
    available: bool
    provider: str
    engine: str
    extracted_answer: str
    confidence: float
    points_earned: float | None
    needs_review: bool
    feedback: str | None
    raw_response: str | None = None
    error: str | None = None


def vision_enabled() -> bool:
    return bool(getattr(settings, "ocr_vision_enabled", False))


def vision_inline_enabled() -> bool:
    # Keep slow local vision models out of the request path unless explicitly
    # enabled. Ollama/LLaVA on CPU can easily turn a 5-question scan into a
    # 1-2 minute request.
    return vision_enabled() and bool(getattr(settings, "ocr_vision_inline", False))


def grade_written_answer_image(
    *,
    crop: Any,
    question: dict[str, Any],
    ocr_text: str,
    ocr_confidence: float,
) -> VisionWrittenAnswerResult | None:
    """Extract and grade one written-answer crop using a free local vision model.

    Currently this supports Ollama running locally (or on a private LAN server).
    It does not call any paid/cloud provider.  If Ollama is not available, this
    returns None so the existing TrOCR/Tesseract path and manual review still work.
    """
    if not vision_enabled():
        return None

    provider = str(getattr(settings, "ocr_vision_provider", "ollama") or "ollama").strip().lower()
    if provider in {"", "off", "none", "disabled", "false", "0"}:
        return None
    if provider != "ollama":
        return VisionWrittenAnswerResult(
            available=False,
            provider=provider,
            engine=provider,
            extracted_answer=str(ocr_text or "").strip(),
            confidence=float(ocr_confidence or 0),
            points_earned=None,
            needs_review=True,
            feedback=f"Unsupported OCR vision provider: {provider}",
            error=f"Unsupported provider: {provider}",
        )

    return _grade_with_ollama(crop=crop, question=question, ocr_text=ocr_text, ocr_confidence=ocr_confidence)


def _grade_with_ollama(
    *,
    crop: Any,
    question: dict[str, Any],
    ocr_text: str,
    ocr_confidence: float,
) -> VisionWrittenAnswerResult | None:
    image_b64 = _image_to_base64(crop)
    if not image_b64:
        return None

    base_url = str(getattr(settings, "ocr_vision_ollama_base_url", "http://127.0.0.1:11434") or "http://127.0.0.1:11434").rstrip("/")
    model = str(getattr(settings, "ocr_vision_ollama_model", "llava:7b") or "llava:7b")
    timeout = int(getattr(settings, "ocr_vision_timeout_seconds", 120) or 120)
    temperature = float(getattr(settings, "ocr_vision_temperature", 0) or 0)

    prompt = _build_prompt(question=question, ocr_text=ocr_text, ocr_confidence=ocr_confidence)
    payload = {
        "model": model,
        "prompt": prompt,
        "images": [image_b64],
        "stream": False,
        "options": {
            "temperature": temperature,
        },
    }

    try:
        with httpx.Client(base_url=base_url, timeout=timeout, follow_redirects=False) as client:
            response = client.post("/api/generate", json=payload)
        response.raise_for_status()
        data = response.json()
    except Exception as exc:
        _debug(f"ollama_unavailable base_url={base_url} model={model} error={exc!r}")
        return None

    raw = str(data.get("response") if isinstance(data, dict) else data or "").strip()
    parsed = _parse_model_json(raw)
    if not isinstance(parsed, dict):
        return VisionWrittenAnswerResult(
            available=True,
            provider="ollama",
            engine=f"ollama:{model}",
            extracted_answer=str(ocr_text or "").strip(),
            confidence=float(ocr_confidence or 0),
            points_earned=None,
            needs_review=True,
            feedback="Local vision model returned an unreadable grading response. Review manually.",
            raw_response=raw,
            error="invalid_json_response",
        )

    extracted = _first_text(parsed, "extracted_answer", "student_answer", "answer", "text")
    if not extracted:
        extracted = str(ocr_text or "").strip()

    confidence = _safe_float(parsed.get("confidence"))
    if confidence is None:
        confidence = _safe_float(parsed.get("ocr_confidence"))
    if confidence is None:
        confidence = float(ocr_confidence or 0)
    # Accept 0-1 confidence too.
    if 0 < confidence <= 1:
        confidence *= 100
    confidence = max(0.0, min(100.0, confidence))

    max_score = _question_max_score(question)
    points = _safe_float(parsed.get("points_earned"))
    if points is None:
        points = _safe_float(parsed.get("score"))
    if points is None:
        points = _safe_float(parsed.get("points"))
    if points is not None:
        points = max(0.0, points)
        if max_score is not None:
            points = min(points, float(max_score))
        points = round(points, 2)

    needs_review = _truthy(parsed.get("needs_review"))
    min_grade_conf = float(getattr(settings, "ocr_vision_min_confidence_to_grade", 62) or 62)
    if not extracted.strip():
        needs_review = True
    if confidence < min_grade_conf:
        needs_review = True
    if _question_has_no_grading_reference(question):
        # Use vision for extraction, but do not pretend the grade is reliable when
        # the exam question has no expected answer/rubric.
        points = None
        needs_review = True

    feedback = _first_text(parsed, "feedback", "teacher_feedback", "comment", "explanation", "reason")
    if not feedback and needs_review:
        feedback = "Local vision extracted the answer, but confidence/reference was not strong enough for automatic grading. Review manually."

    return VisionWrittenAnswerResult(
        available=True,
        provider="ollama",
        engine=f"ollama:{model}",
        extracted_answer=extracted.strip(),
        confidence=round(confidence, 2),
        points_earned=points,
        needs_review=bool(needs_review or points is None),
        feedback=feedback.strip() if isinstance(feedback, str) and feedback.strip() else None,
        raw_response=raw,
        error=None,
    )


def _build_prompt(*, question: dict[str, Any], ocr_text: str, ocr_confidence: float) -> str:
    qtext = str(question.get("question_text") or "").strip()
    expected = question.get("expected_answer")
    rubric = question.get("grading_rubric")
    max_score = _question_max_score(question)

    return f"""
You are grading a scanned handwritten exam answer from an image.

Task:
1. Read ONLY the student's handwriting inside the answer box image.
2. Extract the answer exactly as written, but fix obvious OCR letter mistakes when the handwriting is clear.
3. Grade only if the expected answer or rubric is enough to grade confidently.
4. If the handwriting is unclear or the expected answer/rubric is missing, set needs_review=true.
5. Return JSON only. Do not wrap in markdown.

Question: {qtext or "N/A"}
Expected answer: {_json_preview(expected)}
Grading rubric: {_json_preview(rubric)}
Max score: {max_score if max_score is not None else "N/A"}
Existing OCR text, may be wrong: {str(ocr_text or "").strip() or "N/A"}
Existing OCR confidence: {round(float(ocr_confidence or 0), 2)}

Return exactly this JSON shape:
{{
  "extracted_answer": "student handwriting text",
  "confidence": 0-100,
  "points_earned": number_or_null,
  "needs_review": true_or_false,
  "feedback": "short teacher-facing explanation"
}}
""".strip()


def _image_to_base64(image: Any) -> str | None:
    try:
        import cv2
    except Exception:
        return None
    if image is None or getattr(image, "size", 0) == 0:
        return None
    try:
        # JPEG is much smaller than PNG for photographed answer boxes.
        ok, encoded = cv2.imencode(".jpg", image, [int(cv2.IMWRITE_JPEG_QUALITY), 88])
        if not ok:
            return None
        return base64.b64encode(encoded.tobytes()).decode("ascii")
    except Exception:
        return None


def _parse_model_json(raw: str) -> dict[str, Any] | None:
    text = str(raw or "").strip()
    if not text:
        return None
    # Remove common markdown fences even though the prompt says JSON only.
    text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.IGNORECASE).strip()
    text = re.sub(r"\s*```$", "", text).strip()
    try:
        data = json.loads(text)
        return data if isinstance(data, dict) else None
    except json.JSONDecodeError:
        pass
    start = text.find("{")
    end = text.rfind("}")
    if start >= 0 and end > start:
        try:
            data = json.loads(text[start:end + 1])
            return data if isinstance(data, dict) else None
        except json.JSONDecodeError:
            return None
    return None


def _question_max_score(question: dict[str, Any]) -> float | None:
    for key in ("points", "max_score", "score"):
        value = _safe_float(question.get(key))
        if value is not None:
            return value
    return None


def _question_has_no_grading_reference(question: dict[str, Any]) -> bool:
    expected = question.get("expected_answer")
    rubric = question.get("grading_rubric")
    return not _json_preview(expected).strip() and not _json_preview(rubric).strip()


def _json_preview(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value.strip()
    try:
        return json.dumps(value, ensure_ascii=False)
    except Exception:
        return str(value)


def _first_text(data: dict[str, Any], *keys: str) -> str:
    for key in keys:
        value = data.get(key)
        if value is not None and str(value).strip():
            return str(value).strip()
    return ""


def _safe_float(value: Any) -> float | None:
    try:
        if value is None or value == "":
            return None
        return float(value)
    except (TypeError, ValueError):
        return None


def _truthy(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return False
    if isinstance(value, (int, float)):
        return value != 0
    return str(value).strip().lower() in {"1", "true", "yes", "y", "on", "review", "needs_review"}


def _debug(message: str) -> None:
    if str(os.getenv("OCR_VISION_DEBUG", "false")).strip().lower() in {"1", "true", "yes", "on"}:
        print(f"[OCR_VISION] {message}", flush=True)


@dataclass(slots=True)
class VisionPageWrittenAnswer:
    exam_question_id: int | None
    question_number: int
    extracted_answer: str
    confidence: float
    needs_review: bool
    feedback: str | None
    engine: str
    raw_response: str | None = None
    error: str | None = None


def written_page_vision_enabled() -> bool:
    mode = str(getattr(settings, "ocr_written_extraction_mode", "local") or "local").strip().lower()
    return vision_enabled() and mode in {"vision", "vision_page", "ai_vision", "ollama_vision", "page_vision"}


def extract_written_answers_from_pages_with_vision(
    *,
    pages: list[dict[str, Any]],
    questions: list[dict[str, Any]],
) -> dict[int, VisionPageWrittenAnswer]:
    """Extract all written answers using one local Ollama vision request.

    This is intentionally extraction-focused, not grading-focused.  It reads the
    student's handwriting from the scanned exam page and maps it to the supplied
    written questions.  Scoring can still happen through the normal grading
    contract only when expected_answer/grading_rubric exists.
    """
    if not written_page_vision_enabled():
        return {}

    provider = str(getattr(settings, "ocr_vision_provider", "ollama") or "ollama").strip().lower()
    if provider != "ollama":
        _debug(f"page_vision_unsupported_provider provider={provider}")
        return {}

    written_questions = [
        q for q in questions
        if str(q.get("type") or "").strip().lower() in {"short_answer", "essay"}
    ]
    if not written_questions:
        return {}

    candidate_pages = _select_pages_for_written_vision(pages)
    if not candidate_pages:
        return {}

    images_b64 = []
    for page in candidate_pages:
        encoded = _page_image_to_base64(page.get("image"))
        if encoded:
            images_b64.append(encoded)
    if not images_b64:
        return {}

    base_url = str(getattr(settings, "ocr_vision_ollama_base_url", "http://127.0.0.1:11434") or "http://127.0.0.1:11434").rstrip("/")
    model = str(getattr(settings, "ocr_vision_ollama_model", "llava:7b") or "llava:7b")
    timeout = int(getattr(settings, "ocr_vision_timeout_seconds", 60) or 60)
    temperature = float(getattr(settings, "ocr_vision_temperature", 0) or 0)
    prompt = _build_page_extraction_prompt(written_questions=written_questions, pages=candidate_pages)

    payload = {
        "model": model,
        "prompt": prompt,
        "images": images_b64,
        "stream": False,
        "options": {
            "temperature": temperature,
            "num_predict": 700,
        },
    }

    try:
        with httpx.Client(base_url=base_url, timeout=timeout, follow_redirects=False) as client:
            response = client.post("/api/generate", json=payload)
        response.raise_for_status()
        data = response.json()
    except Exception as exc:
        _debug(f"page_vision_ollama_failed base_url={base_url} model={model} images={len(images_b64)} error={exc!r}")
        return {}

    raw = str(data.get("response") if isinstance(data, dict) else data or "").strip()
    parsed = _parse_model_json(raw)
    if not isinstance(parsed, dict):
        _debug(f"page_vision_invalid_json raw={raw[:800]!r}")
        return {}

    rows = parsed.get("answers")
    if not isinstance(rows, list):
        # Allow a single-object response for small models that ignore the array.
        rows = [parsed]

    by_qn: dict[int, dict[str, Any]] = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        qn = _safe_int(row.get("question_number") or row.get("question") or row.get("q"))
        if qn is None:
            eqid = _safe_int(row.get("exam_question_id"))
            if eqid is not None:
                q_match = next((_q for _q in written_questions if _safe_int(_q.get("exam_question_id")) == eqid), None)
                qn = _safe_int(q_match.get("question_number")) if q_match else None
        if qn is None:
            continue
        by_qn[qn] = row

    results: dict[int, VisionPageWrittenAnswer] = {}
    for question in written_questions:
        qn = _safe_int(question.get("question_number"))
        if qn is None:
            continue
        row = by_qn.get(qn) or {}
        extracted = _first_text(row, "extracted_answer", "student_answer", "answer", "text")
        confidence = _safe_float(row.get("confidence"))
        if confidence is None:
            confidence = 0.0 if not extracted else 65.0
        if 0 < confidence <= 1:
            confidence *= 100
        confidence = max(0.0, min(100.0, float(confidence)))
        needs_review = _truthy(row.get("needs_review")) if row else True
        if not str(extracted or "").strip():
            needs_review = True
            confidence = 0.0
        feedback = _first_text(row, "feedback", "comment", "reason", "explanation")
        results[qn] = VisionPageWrittenAnswer(
            exam_question_id=_safe_int(question.get("exam_question_id")),
            question_number=qn,
            extracted_answer=str(extracted or "").strip(),
            confidence=round(confidence, 2),
            needs_review=bool(needs_review),
            feedback=str(feedback).strip() if isinstance(feedback, str) and feedback.strip() else None,
            engine=f"ollama:{model}:page_vision",
            raw_response=raw,
            error=None,
        )

    return results


def _select_pages_for_written_vision(pages: list[dict[str, Any]]) -> list[dict[str, Any]]:
    sorted_pages = sorted(pages, key=lambda p: int(p.get("page_number") or 0))
    if len(sorted_pages) <= 1:
        return sorted_pages
    non_cover = [
        page for page in sorted_pages
        if not (int(page.get("page_number") or 0) == 1 and bool(page.get("qr_detected")))
    ]
    return non_cover or sorted_pages[1:] or sorted_pages


def _build_page_extraction_prompt(*, written_questions: list[dict[str, Any]], pages: list[dict[str, Any]]) -> str:
    question_lines = []
    for question in written_questions:
        question_lines.append(
            f"- question_number={question.get('question_number')} | "
            f"exam_question_id={question.get('exam_question_id')} | "
            f"type={question.get('type')} | text={str(question.get('question_text') or '').strip()}"
        )
    page_numbers = ", ".join(str(page.get("page_number")) for page in pages)
    return f"""
You are reading scanned Learnova exam answer-sheet images.

Images included: page(s) {page_numbers}.
Extract ONLY the student's handwritten answers inside the written/essay answer boxes.
Ignore printed headers, printed question text, multiple-choice options, footer text, page numbers, watermarks, and instructions.
Do not grade. Do not guess missing answers.

Written questions to extract:
{chr(10).join(question_lines)}

Return JSON only, no markdown, exactly in this shape:
{{
  "answers": [
    {{
      "question_number": 4,
      "exam_question_id": 60,
      "extracted_answer": "student handwriting text, or empty string if blank/unreadable",
      "confidence": 0-100,
      "needs_review": true_or_false,
      "feedback": "short note about readability"
    }}
  ]
}}

Rules:
- Keep the student's meaning; fix only obvious handwriting/OCR letter mistakes.
- Preserve numbered lists such as "1. ... 2. ... 3. ...".
- If a box is blank, return extracted_answer="" and confidence=0.
- Include one answer object for every written question listed above.
""".strip()


def _page_image_to_base64(image: Any) -> str | None:
    try:
        import cv2
    except Exception:
        return None
    if image is None or getattr(image, "size", 0) == 0:
        return None
    try:
        prepared = image
        max_long = int(getattr(settings, "ocr_vision_page_max_long_side", 1400) or 1400)
        h, w = prepared.shape[:2]
        longest = max(h, w)
        if max_long > 0 and longest > max_long:
            scale = max_long / float(longest)
            prepared = cv2.resize(prepared, (max(1, int(w * scale)), max(1, int(h * scale))), interpolation=cv2.INTER_AREA)
        quality = int(getattr(settings, "ocr_vision_page_jpeg_quality", 78) or 78)
        quality = max(45, min(95, quality))
        ok, encoded = cv2.imencode(".jpg", prepared, [int(cv2.IMWRITE_JPEG_QUALITY), quality])
        if not ok:
            return None
        return base64.b64encode(encoded.tobytes()).decode("ascii")
    except Exception:
        return None
