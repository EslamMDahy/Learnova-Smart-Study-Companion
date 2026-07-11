from __future__ import annotations

from typing import Any, Mapping

import uuid

from sqlalchemy import text
from sqlalchemy.orm import Session

from io import BytesIO
from datetime import datetime
from openpyxl import load_workbook
from openpyxl.styles import Font
from openpyxl.drawing.image import Image as XLImage

from app.core.background_jobs.registry import register_handler
from app.core.supabase_client import supabase
from app.core.config import settings


def validate_and_normalize_question_payload(payload) -> dict[str, Any]:
    question_type = (payload.type or "").strip().lower()

    if not question_type:
        return {"ok": False, "status_code": 422, "detail": "type is required"}

    handlers = {
        "multiple_choice": validate_and_normalize_multiple_choice,
        "multi_select": validate_and_normalize_multi_select,
        "true_false": validate_and_normalize_true_false,
        "short_answer": validate_and_normalize_short_answer,
        "essay": validate_and_normalize_essay,
        "code": validate_and_normalize_code
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



def validate_and_normalize_multi_select(payload) -> dict[str, Any]:
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
            "detail": "multi_select questions must include at least 2 options"
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

    expected_answer = payload.expected_answer
    if not isinstance(expected_answer, list) or not expected_answer:
        return {
            "ok": False,
            "status_code": 422,
            "detail": "expected_answer is required for multi_select questions and must be a non-empty list"
        }

    normalized_expected_answer = []
    seen_answer_ids = set()

    for answer_id in expected_answer:
        if not isinstance(answer_id, str):
            return {
                "ok": False,
                "status_code": 422,
                "detail": "Each expected_answer item must be a string"
            }

        answer_id = answer_id.strip()
        if not answer_id:
            return {
                "ok": False,
                "status_code": 422,
                "detail": "Each expected_answer item must be non-empty"
            }

        if answer_id not in seen_ids:
            return {
                "ok": False,
                "status_code": 422,
                "detail": "Each expected_answer item must match one of the option ids"
            }

        if answer_id in seen_answer_ids:
            return {
                "ok": False,
                "status_code": 422,
                "detail": "expected_answer must not contain duplicates"
            }

        seen_answer_ids.add(answer_id)
        normalized_expected_answer.append(answer_id)

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
            "expected_answer": normalized_expected_answer,
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



def validate_and_normalize_true_false(payload) -> dict[str, Any]:
    question_text = (payload.question_text or "").strip()
    if not question_text:
        return {"ok": False, "status_code": 422, "detail": "question_text is required"}

    difficulty = (payload.difficulty or "").strip().lower()
    if not difficulty:
        return {"ok": False, "status_code": 422, "detail": "difficulty is required"}

    expected_answer = payload.expected_answer
    if not isinstance(expected_answer, str):
        return {
            "ok": False,
            "status_code": 422,
            "detail": "expected_answer is required for true_false questions and must be a string"
        }

    expected_answer = expected_answer.strip().lower()
    if expected_answer not in {"true", "false"}:
        return {
            "ok": False,
            "status_code": 422,
            "detail": "expected_answer for true_false must be either 'true' or 'false'"
        }

    explanation = payload.explanation
    if isinstance(explanation, str):
        explanation = explanation.strip() or None

    normalized_options = [
        {"id": "true", "text": "True"},
        {"id": "false", "text": "False"},
    ]

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



def validate_and_normalize_short_answer(payload) -> dict[str, Any]:
    question_text = (payload.question_text or "").strip()
    if not question_text:
        return {"ok": False, "status_code": 422, "detail": "question_text is required"}

    difficulty = (payload.difficulty or "").strip().lower()
    if not difficulty:
        return {"ok": False, "status_code": 422, "detail": "difficulty is required"}

    expected_answer = payload.expected_answer
    if not isinstance(expected_answer, str):
        return {
            "ok": False,
            "status_code": 422,
            "detail": "expected_answer is required for short_answer questions and must be a string"
        }

    expected_answer = expected_answer.strip()
    if not expected_answer:
        return {
            "ok": False,
            "status_code": 422,
            "detail": "expected_answer is required for short_answer questions"
        }

    explanation = payload.explanation
    if isinstance(explanation, str):
        explanation = explanation.strip() or None

    grading_rubric = getattr(payload, "grading_rubric", None)
    if grading_rubric is not None and not isinstance(grading_rubric, dict):
        return {
            "ok": False,
            "status_code": 422,
            "detail": "grading_rubric must be an object when provided"
        }

    return {
        "ok": True,
        "data": {
            "question_text": question_text,
            "type": question_type_from_payload(payload),
            "difficulty": difficulty,
            "explanation": explanation,
            "options": None,
            "expected_answer": expected_answer,
            "grading_rubric": grading_rubric,
            "max_score": 1,
            "auto_gradable": False,
            "source": "manual",
            "approval_status": "approved",
            "usage_count": 0,
            "success_rate": None,
            "average_time_seconds": None,
            "tags": None,
        }
    }



def validate_and_normalize_essay(payload) -> dict[str, Any]:
    question_text = (payload.question_text or "").strip()
    if not question_text:
        return {"ok": False, "status_code": 422, "detail": "question_text is required"}

    difficulty = (payload.difficulty or "").strip().lower()
    if not difficulty:
        return {"ok": False, "status_code": 422, "detail": "difficulty is required"}

    expected_answer = payload.expected_answer
    if expected_answer is not None:
        if not isinstance(expected_answer, str):
            return {
                "ok": False,
                "status_code": 422,
                "detail": "expected_answer must be a string when provided for essay questions"
            }

        expected_answer = expected_answer.strip() or None

    explanation = payload.explanation
    if isinstance(explanation, str):
        explanation = explanation.strip() or None

    grading_rubric = getattr(payload, "grading_rubric", None)
    if grading_rubric is not None and not isinstance(grading_rubric, dict):
        return {
            "ok": False,
            "status_code": 422,
            "detail": "grading_rubric must be an object when provided"
        }

    return {
        "ok": True,
        "data": {
            "question_text": question_text,
            "type": question_type_from_payload(payload),
            "difficulty": difficulty,
            "explanation": explanation,
            "options": None,
            "expected_answer": expected_answer,
            "grading_rubric": grading_rubric,
            "max_score": 1,
            "auto_gradable": False,
            "source": "manual",
            "approval_status": "approved",
            "usage_count": 0,
            "success_rate": None,
            "average_time_seconds": None,
            "tags": None,
        }
    }



def validate_and_normalize_code(payload) -> dict[str, Any]:
    question_text = (payload.question_text or "").strip()
    if not question_text:
        return {"ok": False, "status_code": 422, "detail": "question_text is required"}

    difficulty = (payload.difficulty or "").strip().lower()
    if not difficulty:
        return {"ok": False, "status_code": 422, "detail": "difficulty is required"}

    expected_answer = payload.expected_answer
    if not isinstance(expected_answer, dict):
        return {
            "ok": False,
            "status_code": 422,
            "detail": "expected_answer is required for code questions and must be an object"
        }

    code = expected_answer.get("code")
    if not isinstance(code, str) or not code.strip():
        return {
            "ok": False,
            "status_code": 422,
            "detail": "expected_answer.code is required and must be a non-empty string"
        }

    language = expected_answer.get("language")
    if language is not None:
        if not isinstance(language, str) or not language.strip():
            return {
                "ok": False,
                "status_code": 422,
                "detail": "expected_answer.language must be a non-empty string when provided"
            }
        language = language.strip().lower()

    normalized_expected_answer = {
        "code": code.strip(),
        "language": language,
    }

    explanation = payload.explanation
    if isinstance(explanation, str):
        explanation = explanation.strip() or None

    grading_rubric = getattr(payload, "grading_rubric", None)
    if grading_rubric is not None and not isinstance(grading_rubric, dict):
        return {
            "ok": False,
            "status_code": 422,
            "detail": "grading_rubric must be an object when provided"
        }

    return {
        "ok": True,
        "data": {
            "question_text": question_text,
            "type": question_type_from_payload(payload),
            "difficulty": difficulty,
            "explanation": explanation,
            "options": None,
            "expected_answer": normalized_expected_answer,
            "grading_rubric": grading_rubric,
            "max_score": 1,
            "auto_gradable": False,
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




QUESTION_BANK_EXPORT_TEMPLATE_PATH = "assets/question_bank_export_template.xlsx"
CODE_FONT = Font(name="Consolas", size=10)


def _build_option_cells(question: Mapping) -> list[str]:
    if question["type"] not in ("multiple_choice", "multi_select"):
        return ["", "", "", ""]
    options = question["options"] or []
    cells = [opt.get("text", "") for opt in options[:4]]
    while len(cells) < 4:
        cells.append("")
    return cells


def _build_expected_answer_cell(question: Mapping) -> str:
    q_type = question["type"]
    expected = question["expected_answer"]
    options = question["options"] or []
    text_by_id = {opt.get("id"): opt.get("text", "") for opt in options}

    if q_type == "multiple_choice":
        return text_by_id.get(expected, str(expected))
    if q_type == "multi_select":
        return ", ".join(text_by_id.get(i, str(i)) for i in (expected or []))
    if q_type == "true_false":
        return "True" if str(expected).lower() == "true" else "False"
    if q_type == "code" and isinstance(expected, dict):
        language = expected.get("language")
        code = expected.get("code", "")
        return f"# {language}\n{code}" if language else code
    return str(expected) if expected is not None else ""


def question_bank_xlsx_export_handler(*, db: Session, payload: dict) -> dict:
    course_id = payload["course_id"]

    # =========================
    # 1) Validate course still exists
    # =========================
    course_row = db.execute(
        text("""
            SELECT id, title, course_code
            FROM courses
            WHERE id = :course_id
            LIMIT 1
        """),
        {"course_id": course_id},
    ).mappings().first()

    if not course_row:
        raise ValueError(f"Course {course_id} not found")

    # =========================
    # 2) Fetch approved questions with topic info
    # =========================
    rows = db.execute(
        text("""
            SELECT
                q.id, q.type, q.difficulty, q.question_text, q.explanation,
                q.options, q.expected_answer, q.image_key,
                t.title AS topic_title, t.description AS topic_description
            FROM questions q
            JOIN topics t ON t.id = q.topic_id
            WHERE q.course_id = :course_id
              AND q.approval_status = 'approved'
            ORDER BY t.id, q.id
        """),
        {"course_id": course_id},
    ).mappings().all()

    # =========================
    # 3) Load template, fill metadata
    # =========================
    wb = load_workbook(QUESTION_BANK_EXPORT_TEMPLATE_PATH)
    ws = wb["Question Bank"]

    ws["D2"] = course_row["title"]
    ws["G2"] = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
    ws["D4"] = course_row["course_code"] or ""
    ws["G4"] = len(rows)

    # =========================
    # 4) Write question rows
    # =========================
    bucket = settings.supabase_private_bucket
    current_row = 8

    for q in rows:
        ws.cell(row=current_row, column=1, value=q["topic_title"])
        ws.cell(row=current_row, column=2, value=q["topic_description"])
        ws.cell(row=current_row, column=3, value=q["id"])
        ws.cell(row=current_row, column=4, value=q["type"])
        ws.cell(row=current_row, column=5, value=q["difficulty"])

        question_text_cell = ws.cell(row=current_row, column=6, value=q["question_text"])
        for i, val in enumerate(_build_option_cells(q)):
            ws.cell(row=current_row, column=7 + i, value=val)

        expected_answer_cell = ws.cell(row=current_row, column=11, value=_build_expected_answer_cell(q))
        ws.cell(row=current_row, column=12, value=q["explanation"] or "")

        # =========================
        # 5) Monospace font on any code content
        # =========================
        if q["type"] == "code":
            question_text_cell.font = CODE_FONT
            expected_answer_cell.font = CODE_FONT

        # =========================
        # 6) Inject question image if present (best-effort)
        # =========================
        if q["image_key"]:
            try:
                image_bytes = supabase.storage.from_(bucket).download(q["image_key"])
                img = XLImage(BytesIO(image_bytes))
                img.width = 120
                img.height = 120
                ws.add_image(img, f"M{current_row}")
                ws.row_dimensions[current_row].height = 90
            except Exception:
                pass

        current_row += 1

    # =========================
    # 7) Save in-memory, upload to Supabase
    # =========================
    buffer = BytesIO()
    wb.save(buffer)
    buffer.seek(0)

    storage_key = f"courses/{course_id}/exports/{uuid.uuid4()}.xlsx"
    supabase.storage.from_(bucket).upload(
        storage_key,
        buffer.getvalue(),
        {"content-type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"},
    )

    return {"storage_key": storage_key, "file_size_bytes": buffer.getbuffer().nbytes}


