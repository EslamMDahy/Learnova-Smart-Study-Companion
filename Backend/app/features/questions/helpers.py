from __future__ import annotations

from typing import Any


def validate_and_normalize_question_payload(payload) -> dict[str, Any]:
    question_type = (payload.type or "").strip().lower()

    if not question_type:
        return {"ok": False, "status_code": 422, "detail": "type is required"}

    handlers = {
        "multiple_choice": validate_and_normalize_multiple_choice,
    }

    handler = handlers.get(question_type)
    if not handler:
        return {
            "ok": False,
            "status_code": 422,
            "detail": f"Unsupported question type: {question_type}"
        }

    return handler(payload)


def validate_and_normalize_multiple_choice(payload) -> dict[str, Any]:
    question_text = (payload.question_text or "").strip()
    if not question_text:
        return {"ok": False, "status_code": 422, "detail": "question_text is required"}

    difficulty = (payload.difficulty or "").strip().lower()
    if not difficulty:
        return {"ok": False, "status_code": 422, "detail": "difficulty is required"}

    options = payload.options
    if not isinstance(options, list) or len(options) < 2:
        return {
            "ok": False,
            "status_code": 422,
            "detail": "multiple_choice questions must include at least 2 options"
        }

    normalized_options = []
    seen_ids = set()

    for option in options:
        option_id = (option.id or "").strip()
        option_text = (option.text or "").strip()

        if not option_id:
            return {
                "ok": False,
                "status_code": 422,
                "detail": "Each option must include a non-empty id"
            }

        if not option_text:
            return {
                "ok": False,
                "status_code": 422,
                "detail": "Each option must include non-empty text"
            }

        if option_id in seen_ids:
            return {
                "ok": False,
                "status_code": 422,
                "detail": "Option ids must be unique"
            }

        seen_ids.add(option_id)
        normalized_options.append({
            "id": option_id,
            "text": option_text,
        })

    expected_answer = (payload.expected_answer or "").strip()
    if not expected_answer:
        return {
            "ok": False,
            "status_code": 422,
            "detail": "expected_answer is required for multiple_choice questions"
        }

    if expected_answer not in seen_ids:
        return {
            "ok": False,
            "status_code": 422,
            "detail": "expected_answer must match one of the option ids"
        }

    explanation = payload.explanation
    if isinstance(explanation, str):
        explanation = explanation.strip() or None

    return {
        "ok": True,
        "data": {
            "question_text": question_text,
            "type": question_type_from_payload(payload),
            "difficulty": difficulty,
            "explanation": explanation,
            "options": normalized_options,
            "expected_answer": expected_answer,
            "grading_rubric": None,
            "max_score": 1,
            "auto_gradable": True,
            "source": "manual",
            "approval_status": "approved",
            "usage_count": 0,
            "success_rate": None,
            "average_time_seconds": None,
            "tags": None,
        }
    }


def question_type_from_payload(payload) -> str:
    return (payload.type or "").strip().lower()