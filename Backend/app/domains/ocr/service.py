from __future__ import annotations

import json
import os
import re
import time
import traceback
from dataclasses import dataclass
from io import BytesIO
from pathlib import Path
from typing import Any, Iterable, Optional

from fastapi import HTTPException, UploadFile

from app.core.config import settings


_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff", ".bmp"}
_PDF_EXTENSIONS = {".pdf"}
_ALLOWED_IMAGE_MIME_TYPES = {
    "image/png",
    "image/jpeg",
    "image/jpg",
    "image/webp",
    "image/tiff",
    "image/bmp",
    "application/octet-stream",
    "",
}
_ALLOWED_PDF_MIME_TYPES = {
    "application/pdf",
    "application/octet-stream",
    "",
}
_ALLOWED_LANGS = {"eng", "ara", "ara+eng", "eng+ara"}
_ANSWER_RE = re.compile(
    r"(?im)^\s*(?:q(?:uestion)?\s*)?(\d{1,3})\s*[\).:\-]?\s*([A-E])\b"
)
_KEY_RE = re.compile(r"(?i)^\s*(?:q(?:uestion)?\s*)?(\d{1,3})\s*[=:\-\).,\s]+\s*([A-E])\s*$")


@dataclass(slots=True)
class _PageOcr:
    text: str
    confidence: float
    word_count: int


@dataclass(slots=True)
class _LoadedDocument:
    pages: list[Any]
    warnings: list[str]


def ensure_instructor(current_user: dict) -> None:
    role = (current_user.get("system_role") or "").strip().lower()
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can use exam OCR correction")


def normalise_lang(lang: str) -> str:
    value = (lang or "eng").strip().lower().replace(" ", "")
    if value == "eng+ara":
        value = "ara+eng"
    if value not in _ALLOWED_LANGS:
        raise HTTPException(status_code=400, detail="Unsupported OCR language")
    return value


def parse_answer_key(raw: Optional[str]) -> dict[int, str]:
    if raw is None or not raw.strip():
        return {}

    try:
        decoded = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=400, detail="answer_key_json must be valid JSON") from exc

    if isinstance(decoded, dict):
        items = decoded.items()
    elif isinstance(decoded, list):
        items = []
        for item in decoded:
            if not isinstance(item, dict):
                raise HTTPException(status_code=400, detail="answer key list items must be objects")
            question = item.get("question_number") or item.get("question") or item.get("q")
            answer = item.get("answer") or item.get("expected_answer")
            items.append((question, answer))
    else:
        raise HTTPException(status_code=400, detail="answer_key_json must be an object or list")

    answer_key: dict[int, str] = {}
    for question, answer in items:
        try:
            qn = int(str(question).strip())
        except (TypeError, ValueError) as exc:
            raise HTTPException(status_code=400, detail="answer key question numbers must be integers") from exc
        ans = str(answer or "").strip().upper()
        if not re.fullmatch(r"[A-E]", ans):
            raise HTTPException(status_code=400, detail="answer key answers must be A, B, C, D or E")
        if qn <= 0:
            raise HTTPException(status_code=400, detail="answer key question numbers must be positive")
        answer_key[qn] = ans
    return answer_key


def parse_answer_key_text(raw: str) -> dict[int, str]:
    answer_key: dict[int, str] = {}
    for line in raw.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        match = _KEY_RE.match(stripped)
        if not match:
            raise HTTPException(status_code=400, detail=f"Invalid answer key line: {stripped}")
        answer_key[int(match.group(1))] = match.group(2).upper()
    return answer_key


def ocr_health() -> dict[str, Any]:
    try:
        pytesseract = _import_pytesseract()
        version = str(pytesseract.get_tesseract_version())
        try:
            langs = sorted(str(lang) for lang in pytesseract.get_languages(config=""))
        except Exception:
            langs = []
        return {
            "available": True,
            "engine": "tesseract",
            "version": version,
            "languages": langs,
            "detail": None,
        }
    except Exception as exc:
        return {
            "available": False,
            "engine": "tesseract",
            "version": None,
            "languages": [],
            "detail": str(exc),
        }


def _ocr_perf_enabled() -> bool:
    value = getattr(settings, "ocr_debug_timing", True)
    return str(value).strip().lower() not in {"0", "false", "no", "off"}


def _mark_ocr_step(label: str, start: float, **details: Any) -> float:
    now = time.perf_counter()
    if _ocr_perf_enabled():
        suffix = ""
        if details:
            rendered = ", ".join(f"{key}={value}" for key, value in details.items() if value is not None)
            suffix = f" ({rendered})" if rendered else ""
        print(f"[OCR_TIMING] {label}: {now - start:.2f}s{suffix}", flush=True)
    return now


def _env_bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return str(value).strip().lower() in {"1", "true", "yes", "on"}


def _ocr_submit_verbose_enabled() -> bool:
    # Keep this on by default while debugging the OCR submit/grading bridge.
    return _env_bool("OCR_SUBMIT_VERBOSE_LOGS", True)


def _jsonable(value: Any) -> Any:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, dict):
        return {str(key): _jsonable(val) for key, val in value.items()}
    if isinstance(value, (list, tuple, set)):
        return [_jsonable(item) for item in value]
    if hasattr(value, "items"):
        try:
            return {str(key): _jsonable(val) for key, val in value.items()}
        except Exception:
            pass
    if hasattr(value, "_mapping"):
        try:
            return {str(key): _jsonable(val) for key, val in value._mapping.items()}
        except Exception:
            pass
    return str(value)


def _debug_dump(label: str, payload: Any, *, always: bool = False, max_chars: int | None = None) -> None:
    if not always and not _ocr_submit_verbose_enabled():
        return
    try:
        text_payload = json.dumps(_jsonable(payload), ensure_ascii=False, indent=2, default=str)
    except Exception:
        text_payload = repr(payload)
    limit = max_chars
    if limit is None:
        try:
            limit = int(os.getenv("OCR_SUBMIT_VERBOSE_MAX_CHARS", "30000"))
        except Exception:
            limit = 30000
    if limit > 0 and len(text_payload) > limit:
        text_payload = text_payload[:limit] + f"\n... <truncated {len(text_payload) - limit} chars>"
    print(f"\n========== {label} ==========", flush=True)
    print(text_payload, flush=True)
    print(f"========== END {label} ==========\n", flush=True)


def correct_exam_files(
    *,
    uploaded_files: list[UploadFile],
    file_payloads: list[bytes],
    lang: str,
    answer_key: dict[int, str],
) -> dict[str, Any]:
    if not uploaded_files:
        raise HTTPException(status_code=400, detail="At least one file is required")

    max_files = int(getattr(settings, "ocr_max_files", 12))
    if len(uploaded_files) > max_files:
        raise HTTPException(status_code=400, detail=f"A maximum of {max_files} files is allowed per request")

    lang = normalise_lang(lang)
    _assert_engine_ready(lang)

    results: list[dict[str, Any]] = []
    for upload, raw in zip(uploaded_files, file_payloads, strict=True):
        results.append(_process_one_file(upload, raw, lang, answer_key))

    pages = sum(int(result["pages"]) for result in results)
    confidence_values = [float(result["confidence"]) for result in results if int(result["word_count"]) > 0]
    avg_confidence = round(sum(confidence_values) / len(confidence_values), 2) if confidence_values else 0.0
    graded = [r for r in results if r["total_questions"] > 0]
    total_questions = sum(int(result["total_questions"]) for result in results)
    correct_answers = sum(int(result["correct_answers"]) for result in results)
    unanswered = sum(int(result["unanswered_questions"]) for result in results)
    score_percent = round((correct_answers / total_questions) * 100, 2) if total_questions else None

    return {
        "language": lang,
        "answer_key_provided": bool(answer_key),
        "summary": {
            "files": len(results),
            "pages": pages,
            "graded_files": len(graded),
            "average_confidence": avg_confidence,
            "total_questions": total_questions,
            "correct_answers": correct_answers,
            "unanswered_questions": unanswered,
            "score_percent": score_percent,
        },
        "results": results,
    }


def _process_one_file(
    upload: UploadFile,
    raw: bytes,
    lang: str,
    answer_key: dict[int, str],
) -> dict[str, Any]:
    filename = (upload.filename or "scan").strip() or "scan"
    mime_type = (upload.content_type or "").strip().lower()
    max_file_bytes = int(getattr(settings, "ocr_max_file_bytes", 15 * 1024 * 1024))

    if not raw:
        raise HTTPException(status_code=400, detail=f"{filename}: empty file")
    if len(raw) > max_file_bytes:
        mb = max_file_bytes // (1024 * 1024)
        raise HTTPException(status_code=413, detail=f"{filename}: file exceeds {mb} MB limit")

    document = _load_document(raw=raw, filename=filename, mime_type=mime_type)
    if not document.pages:
        raise HTTPException(status_code=400, detail=f"{filename}: no readable pages found")

    page_results = [_ocr_page(page, lang) for page in document.pages]
    text_parts = [result.text for result in page_results if result.text.strip()]
    text = "\n\n".join(text_parts).strip()
    word_count = sum(result.word_count for result in page_results)
    confidence = _weighted_confidence(page_results)
    parsed_answers = _parse_answers(text)
    grade_items = _grade_answers(answer_key, parsed_answers)

    warnings = list(document.warnings)
    low_confidence_threshold = float(getattr(settings, "ocr_low_confidence_threshold", 55.0))
    low_confidence = confidence < low_confidence_threshold or word_count == 0
    if low_confidence:
        warnings.append("Low OCR confidence. Review the extracted text before using the grade.")
    if not text:
        warnings.append("No text was extracted. Try a sharper scan with higher contrast.")
    if answer_key and not parsed_answers:
        warnings.append("No objective answers were detected. Check scan layout or grade manually from OCR text.")

    total_questions = len(grade_items)
    correct_answers = sum(1 for item in grade_items if item["is_correct"])
    unanswered = sum(1 for item in grade_items if not item.get("detected_answer"))
    score_percent = round((correct_answers / total_questions) * 100, 2) if total_questions else None

    return {
        "filename": filename,
        "mime_type": mime_type or None,
        "pages": len(document.pages),
        "text": text,
        "confidence": confidence,
        "word_count": word_count,
        "parsed_answers": parsed_answers,
        "grade_items": grade_items,
        "total_questions": total_questions,
        "correct_answers": correct_answers,
        "unanswered_questions": unanswered,
        "score_percent": score_percent,
        "low_confidence": low_confidence,
        "warnings": warnings,
    }


def _load_document(*, raw: bytes, filename: str, mime_type: str) -> _LoadedDocument:
    suffix = Path(filename).suffix.lower()
    if suffix in _PDF_EXTENSIONS or mime_type == "application/pdf":
        if mime_type not in _ALLOWED_PDF_MIME_TYPES:
            raise HTTPException(status_code=400, detail=f"{filename}: unsupported PDF content type")
        return _load_pdf(raw)

    if suffix in _IMAGE_EXTENSIONS or mime_type.startswith("image/"):
        if mime_type not in _ALLOWED_IMAGE_MIME_TYPES and not mime_type.startswith("image/"):
            raise HTTPException(status_code=400, detail=f"{filename}: unsupported image content type")
        return _load_image(raw)

    raise HTTPException(status_code=400, detail=f"{filename}: only image and PDF files are supported")


def _load_image(raw: bytes) -> _LoadedDocument:
    cv2, np = _import_cv2_numpy()
    arr = np.frombuffer(raw, np.uint8)
    image = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if image is None:
        raise HTTPException(status_code=400, detail="Invalid image file")
    return _LoadedDocument(pages=[image], warnings=[])


def _load_pdf(raw: bytes) -> _LoadedDocument:
    try:
        import fitz  # PyMuPDF
    except Exception as exc:
        raise HTTPException(status_code=503, detail="PDF OCR requires PyMuPDF. Install pymupdf.") from exc

    cv2, np = _import_cv2_numpy()
    max_pages = int(getattr(settings, "ocr_max_pdf_pages", 8))
    # 150 DPI is enough for text OCR preview and much faster for photographed
    # PDF uploads. Increase OCR_PDF_RENDER_DPI only when scans are too blurry.
    dpi = int(getattr(settings, "ocr_pdf_render_dpi", 150))
    warnings: list[str] = []

    try:
        document = fitz.open(stream=raw, filetype="pdf")
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Invalid PDF file") from exc

    if document.page_count > max_pages:
        warnings.append(f"Only the first {max_pages} pages were processed from a {document.page_count}-page PDF.")

    pages: list[Any] = []
    zoom = max(72, dpi) / 72.0
    matrix = fitz.Matrix(zoom, zoom)
    for page_index in range(min(document.page_count, max_pages)):
        page = document.load_page(page_index)
        pixmap = page.get_pixmap(matrix=matrix, alpha=False)

        # Avoid encoding each rendered page to PNG and decoding it again with
        # OpenCV. Direct sample conversion saves seconds on multi-page scans.
        arr = np.frombuffer(pixmap.samples, dtype=np.uint8).reshape(pixmap.height, pixmap.width, pixmap.n)
        if pixmap.n == 1:
            image = cv2.cvtColor(arr, cv2.COLOR_GRAY2BGR)
        elif pixmap.n >= 3:
            image = cv2.cvtColor(arr[:, :, :3], cv2.COLOR_RGB2BGR)
        else:
            image = None
        if image is not None:
            pages.append(image.copy())

    document.close()
    return _LoadedDocument(pages=pages, warnings=warnings)

def _ocr_page(image: Any, lang: str) -> _PageOcr:
    pytesseract = _import_pytesseract()
    cv2, np = _import_cv2_numpy()
    from pytesseract import Output

    image = _normalise_orientation(image)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    gray = _resize_for_ocr(gray)

    # Fast mode is the default for exam uploads. The previous path ran OSD +
    # three full Tesseract passes for each page/answer crop, which can take
    # minutes for a photographed multi-page PDF. Set OCR_TESSERACT_MODE=accurate
    # only when you need the old multi-candidate behavior.
    mode = str(getattr(settings, "ocr_tesseract_mode", "fast") or "fast").strip().lower()
    if mode in {"accurate", "full", "slow"}:
        gray = cv2.fastNlMeansDenoising(gray, None, 10, 7, 21)
    else:
        gray = cv2.GaussianBlur(gray, (3, 3), 0)

    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    thresholded = cv2.adaptiveThreshold(
        enhanced,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        31,
        11,
    )

    if mode in {"accurate", "full", "slow"}:
        candidates = [
            (thresholded, "--oem 3 --psm 6"),
            (enhanced, "--oem 3 --psm 6"),
            (thresholded, "--oem 3 --psm 11"),
        ]
    else:
        candidates = [(thresholded, "--oem 3 --psm 6")]

    best: _PageOcr | None = None
    timeout_seconds = int(getattr(settings, "ocr_tesseract_timeout_seconds", 45))
    for candidate, config in candidates:
        try:
            kwargs = {
                "lang": lang,
                "config": config,
                "output_type": Output.DICT,
            }
            if timeout_seconds > 0:
                kwargs["timeout"] = timeout_seconds
            data = pytesseract.image_to_data(candidate, **kwargs)
        except RuntimeError as exc:
            raise HTTPException(status_code=504, detail=f"OCR engine timed out: {exc}") from exc
        except TypeError:
            # Older pytesseract versions may not support timeout=.
            try:
                data = pytesseract.image_to_data(candidate, lang=lang, config=config, output_type=Output.DICT)
            except Exception as exc:
                raise HTTPException(status_code=503, detail=f"OCR engine failed: {exc}") from exc
        except Exception as exc:
            raise HTTPException(status_code=503, detail=f"OCR engine failed: {exc}") from exc
        current = _page_from_tesseract_data(data)
        if best is None or _ocr_quality(current) > _ocr_quality(best):
            best = current

    return best or _PageOcr(text="", confidence=0.0, word_count=0)


def _normalise_orientation(image: Any) -> Any:
    enabled = str(getattr(settings, "ocr_enable_orientation_detection", False)).strip().lower() in {"1", "true", "yes", "on"}
    if not enabled:
        return image

    pytesseract = _import_pytesseract()
    cv2, _ = _import_cv2_numpy()
    try:
        osd = pytesseract.image_to_osd(image)
    except Exception:
        return image

    angle_match = re.search(r"Rotate:\s+(\d+)", osd)
    if not angle_match:
        return image

    angle = int(angle_match.group(1)) % 360
    if angle == 90:
        return cv2.rotate(image, cv2.ROTATE_90_CLOCKWISE)
    if angle == 180:
        return cv2.rotate(image, cv2.ROTATE_180)
    if angle == 270:
        return cv2.rotate(image, cv2.ROTATE_90_COUNTERCLOCKWISE)
    return image


def _resize_for_ocr(gray: Any) -> Any:
    cv2, _ = _import_cv2_numpy()
    height, width = gray.shape[:2]
    longest = max(height, width)
    if longest < 1600:
        scale = 1600 / longest
    elif longest > 2600:
        scale = 2600 / longest
    else:
        scale = 1.0
    if abs(scale - 1.0) < 0.01:
        return gray
    return cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)


def _page_from_tesseract_data(data: dict[str, list[Any]]) -> _PageOcr:
    tokens: list[str] = []
    confidences: list[float] = []
    lines: dict[tuple[int, int, int], list[str]] = {}

    text_values = data.get("text", [])
    conf_values = data.get("conf", [])
    blocks = data.get("block_num", [])
    paragraphs = data.get("par_num", [])
    line_numbers = data.get("line_num", [])

    for index, text in enumerate(text_values):
        token = str(text or "").strip()
        if not token:
            continue

        try:
            conf = float(conf_values[index])
        except (IndexError, TypeError, ValueError):
            conf = -1.0

        try:
            key = (int(blocks[index]), int(paragraphs[index]), int(line_numbers[index]))
        except (IndexError, TypeError, ValueError):
            key = (0, 0, index)

        tokens.append(token)
        lines.setdefault(key, []).append(token)
        if conf >= 0:
            confidences.append(conf)

    ordered_lines = [" ".join(lines[key]) for key in sorted(lines)]
    text = _clean_ocr_text("\n".join(ordered_lines))
    confidence_value = round(sum(confidences) / len(confidences), 2) if confidences else 0.0
    return _PageOcr(text=text, confidence=confidence_value, word_count=len(tokens))


def _clean_ocr_text(raw: str) -> str:
    text = re.sub(r"[ \t]+", " ", raw)
    text = re.sub(r"\s+([).,:;])", r"\1", text)
    text = re.sub(r"([\n\r]){3,}", "\n\n", text)
    return text.strip()


def _weighted_confidence(results: Iterable[_PageOcr]) -> float:
    weighted = 0.0
    weight = 0
    for result in results:
        page_weight = max(1, result.word_count)
        weighted += result.confidence * page_weight
        weight += page_weight
    return round(weighted / weight, 2) if weight else 0.0


def _ocr_quality(result: _PageOcr) -> float:
    return (result.confidence * 1.2) + min(result.word_count, 400) * 0.25 + len(result.text) * 0.005


def _parse_answers(text: str) -> list[dict[str, Any]]:
    answers: dict[int, dict[str, Any]] = {}
    for match in _ANSWER_RE.finditer(text or ""):
        qn = int(match.group(1))
        if qn in answers:
            continue
        answer = match.group(2).upper()
        source_start = max(0, match.start() - 20)
        source_end = min(len(text), match.end() + 40)
        answers[qn] = {
            "question_number": qn,
            "answer": answer,
            "source_text": text[source_start:source_end].strip(),
        }
    return [answers[key] for key in sorted(answers)]


def _grade_answers(
    answer_key: dict[int, str],
    parsed_answers: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    if not answer_key:
        return []
    detected = {
        int(item["question_number"]): str(item["answer"]).strip().upper()
        for item in parsed_answers
    }
    grade_items: list[dict[str, Any]] = []
    for question_number in sorted(answer_key):
        expected = answer_key[question_number]
        actual = detected.get(question_number)
        grade_items.append({
            "question_number": question_number,
            "expected_answer": expected,
            "detected_answer": actual,
            "is_correct": actual == expected,
        })
    return grade_items


def _assert_engine_ready(lang: str) -> None:
    health = ocr_health()
    if not health["available"]:
        raise HTTPException(status_code=503, detail=f"OCR engine unavailable: {health['detail']}")

    installed = set(health.get("languages") or [])
    missing = [part for part in lang.split("+") if installed and part not in installed]
    if missing:
        raise HTTPException(status_code=503, detail=f"Missing Tesseract language data: {', '.join(missing)}")


def _import_pytesseract():
    try:
        import pytesseract

        configured_path = str(getattr(settings, "tesseract_cmd", "") or "").strip()
        candidates = [configured_path] if configured_path else []
        candidates.append(r"C:\Program Files\Tesseract-OCR\tesseract.exe")
        for candidate in candidates:
            if candidate and Path(candidate).exists():
                pytesseract.pytesseract.tesseract_cmd = candidate
                break

        return pytesseract
    except Exception as exc:
        raise HTTPException(status_code=503, detail="OCR requires pytesseract and Tesseract to be installed") from exc


def _import_cv2_numpy():
    try:
        import cv2
        import numpy as np
        return cv2, np
    except Exception as exc:
        raise HTTPException(status_code=503, detail="OCR requires opencv-python and numpy") from exc

# =============================================================================
# Production scan pipeline: QR exam detection + Student-ID OMR + answer OMR/OCR
# =============================================================================


def analyze_exam_scan_files(
    *,
    uploaded_files: list[UploadFile],
    file_payloads: list[bytes],
    lang: str,
    db: Any,
    current_user: dict,
    fallback_exam_id: int | None = None,
    fallback_course_id: int | None = None,
) -> dict[str, Any]:
    """Analyze a solved Learnova OCR exam PDF.

    The endpoint returns question-level grading preview only. It reads QR
    metadata, detects objective bubbles, OCRs written answer boxes for AI
    grading, and never saves a student attempt from this analyze call.
    """
    # This endpoint is intentionally question-correction only. Do not fall back
    # to raw page OCR preview from environment flags; the instructor needs one
    # row per exam question with the detected answer and correct answer.

    import uuid
    from sqlalchemy import text

    from .alignment import align_exam_page
    from .omr import detect_bubbles, extract_objective_answers_from_pages
    from .qr import read_qr_from_image, verify_payload
    from .written_ocr import extract_written_answers_from_pages

    total_timer = time.perf_counter()
    step_timer = total_timer
    ensure_instructor(current_user)
    if not uploaded_files:
        raise HTTPException(status_code=400, detail="At least one file is required")

    max_files = int(getattr(settings, "ocr_max_files", 12))
    if len(uploaded_files) > max_files:
        raise HTTPException(status_code=400, detail=f"A maximum of {max_files} files is allowed per request")

    lang = normalise_lang(lang)
    _assert_engine_ready(lang)
    step_timer = _mark_ocr_step("engine_ready", step_timer, lang=lang)

    scan_id = f"scan_{uuid.uuid4().hex[:16]}"
    warnings: list[str] = []
    page_payloads: list[dict[str, Any]] = []
    detected_metadata: dict[str, Any] = {}
    all_objective_answers: list[dict[str, Any]] = []
    all_written_answers: list[dict[str, Any]] = []

    # Load files/pages first; detect QR before and after alignment.
    page_number = 0
    for upload, raw in zip(uploaded_files, file_payloads, strict=True):
        filename = (upload.filename or "scan").strip() or "scan"
        mime_type = (upload.content_type or "").strip().lower()
        max_file_bytes = int(getattr(settings, "ocr_max_file_bytes", 15 * 1024 * 1024))
        if not raw:
            raise HTTPException(status_code=400, detail=f"{filename}: empty file")
        if len(raw) > max_file_bytes:
            mb = max_file_bytes // (1024 * 1024)
            raise HTTPException(status_code=413, detail=f"{filename}: file exceeds {mb} MB limit")

        document = _load_document(raw=raw, filename=filename, mime_type=mime_type)
        step_timer = _mark_ocr_step("load_document", step_timer, filename=filename, pages=len(document.pages))
        for raw_page in document.pages:
            page_number += 1
            page_warnings = list(document.warnings)
            qr_payload = read_qr_from_image(raw_page)
            alignment = align_exam_page(raw_page)
            if alignment.warnings:
                page_warnings.extend(alignment.warnings)
            qr_payload = qr_payload or read_qr_from_image(alignment.image)
            qr_detected = bool(qr_payload)
            if qr_payload:
                if verify_payload(qr_payload):
                    detected_metadata.update(qr_payload)
                else:
                    page_warnings.append("QR code was detected but its signature is invalid.")

            bubbles = detect_bubbles(alignment.image)
            step_timer = _mark_ocr_step("prepare_page", step_timer, page=page_number, bubbles=len(bubbles), qr=qr_detected)
            page_payloads.append({
                "page_number": page_number,
                "filename": filename,
                "image": alignment.image,
                "alignment_status": alignment.status,
                "alignment_confidence": alignment.confidence,
                "qr_detected": qr_detected,
                "bubbles": bubbles,
                "warnings": page_warnings,
            })

    exam_id = _safe_int(detected_metadata.get("exam_id")) or fallback_exam_id
    course_id = _safe_int(detected_metadata.get("course_id")) or fallback_course_id
    template_version = str(detected_metadata.get("template_version") or "v1")

    if not exam_id:
        warnings.append("Exam QR was not detected and no fallback exam_id was provided. Objective answers will be extracted without exam-question binding.")
    if exam_id and not course_id:
        course_id = _lookup_course_id_for_exam(db=db, exam_id=exam_id)

    if course_id:
        _assert_instructor_owns_course(db=db, course_id=course_id, current_user=current_user)

    exam_payload = _load_exam_payload(db=db, exam_id=exam_id, course_id=course_id) if exam_id and course_id else {}
    questions = _load_exam_questions_for_scan(db=db, exam_id=exam_id, course_id=course_id) if exam_id and course_id else []
    step_timer = _mark_ocr_step("metadata_and_questions", step_timer, exam_id=exam_id, course_id=course_id, questions=len(questions))

    # Student ID is deliberately ignored in this flow. The instructor only needs
    # a preview of the corrected scan; no student attempt is saved or linked.
    detected_student = {
        "student_id": None,
        "user_id": None,
        "name": None,
        "source": "not_used",
        "confidence": 0,
        "digits": [],
    }
    step_timer = _mark_ocr_step("student_id_skipped", step_timer)

    # Extract objective answers with OMR once across all pages. This prevents
    # page-3 bubbles being mapped again to Q1/Q2.
    objective_results = extract_objective_answers_from_pages(
        pages=page_payloads,
        questions=questions,
    )
    for item in objective_results:
        payload = {
            "exam_question_id": item.exam_question_id,
            "question_number": item.question_number,
            "type": item.type,
            "detected_answer": item.detected_answer,
            "detected_answers": item.detected_answers,
            "selected_option_index": item.selected_option_index,
            "selected_option_indices": item.selected_option_indices,
            "answer_text": None,
            "confidence": item.confidence,
            "status": item.status,
            "regions": item.regions,
            "answer_region": None,
            "ai_grading_payload": None,
            "ai_score": None,
        }
        _apply_objective_grade(payload, questions)
        all_objective_answers.append(payload)
    step_timer = _mark_ocr_step("objective_omr", step_timer, answers=len(all_objective_answers))

    # OCR free-text boxes once across all pages in reading/question order.
    written_results = extract_written_answers_from_pages(
        pages=page_payloads,
        questions=questions,
        lang=lang,
    )
    for item in written_results:
        all_written_answers.append({
            "exam_question_id": item.exam_question_id,
            "question_number": item.question_number,
            "type": item.type,
            "detected_answer": None,
            "detected_answers": [],
            "selected_option_index": None,
            "selected_option_indices": None,
            "answer_text": item.answer_text,
            "confidence": item.confidence,
            "status": item.status,
            "is_correct": None,
            "points_earned": None,
            "max_score": _question_points(item.exam_question_id, questions),
            "regions": [],
            "answer_region": item.region,
            "ai_grading_payload": item.ai_grading_payload,
            "ai_score": None,
        })
    step_timer = _mark_ocr_step("written_ocr", step_timer, answers=len(all_written_answers))

    answers = _dedupe_answers(all_objective_answers + all_written_answers)
    answers = _ensure_answers_for_all_questions(answers=answers, questions=questions)
    _attach_question_context(answers=answers, questions=questions)

    _debug_dump("OCR_SCAN_METADATA", {
        "scan_id": scan_id,
        "exam_id": exam_id,
        "course_id": course_id,
        "template_version": template_version,
        "detected_metadata": detected_metadata,
        "pages": [
            {
                "page_number": page.get("page_number"),
                "filename": page.get("filename"),
                "qr_detected": page.get("qr_detected"),
                "bubble_count": len(page.get("bubbles") or []),
                "alignment_status": page.get("alignment_status"),
                "alignment_confidence": page.get("alignment_confidence"),
                "warnings": page.get("warnings"),
            }
            for page in page_payloads
        ],
    })
    _debug_dump("OCR_SCAN_QUESTIONS_LOADED", [
        {
            "exam_question_id": q.get("exam_question_id"),
            "question_id": q.get("question_id"),
            "question_number": q.get("question_number"),
            "order_index": q.get("order_index"),
            "type": q.get("type"),
            "points": q.get("points"),
            "max_score": q.get("max_score"),
            "has_expected_answer": bool(q.get("expected_answer")),
            "has_grading_rubric": bool(q.get("grading_rubric")),
            "question_text_preview": str(q.get("question_text") or "")[:250],
        }
        for q in questions
    ])
    _debug_dump("OCR_SCAN_EXTRACTED_ANSWERS", [
        {
            "exam_question_id": a.get("exam_question_id"),
            "question_number": a.get("question_number"),
            "type": a.get("type"),
            "status": a.get("status"),
            "selected_option_index": a.get("selected_option_index"),
            "selected_option_indices": a.get("selected_option_indices"),
            "detected_answer": a.get("detected_answer"),
            "answer_text": a.get("answer_text"),
            "confidence": a.get("confidence"),
            "is_correct": a.get("is_correct"),
            "points_earned": a.get("points_earned"),
            "max_score": a.get("max_score"),
        }
        for a in answers
    ])

    # OCR extraction stops here. From this point we use the exact same grading
    # contract as the normal student submit flow: objective answers are already
    # locally graded, and essay/short-answer rows are saved to a scan attempt so
    # the existing async AI callback can grade them by attempt_id.
    auto_submit_scan = str(
        getattr(settings, "ocr_auto_submit_scan", os.getenv("OCR_AUTO_SUBMIT_SCAN", "true"))
    ).strip().lower() in {"1", "true", "yes", "on"}

    submit_meta: dict[str, Any] = {
        "attempt_id": None,
        "attempt_status": None,
        "ai_grading_requested": False,
        "ai_request_id": None,
    }
    if auto_submit_scan and exam_id and course_id and questions:
        submit_meta = _create_scan_attempt_like_student_submit(
            db=db,
            scan_id=scan_id,
            exam_id=int(exam_id),
            course_id=int(course_id),
            answers=answers,
            questions=questions,
            exam_payload=exam_payload,
            current_user=current_user,
        )
        step_timer = _mark_ocr_step(
            "normal_submit_grading_started",
            step_timer,
            attempt_id=submit_meta.get("attempt_id"),
            ai=submit_meta.get("ai_grading_requested"),
        )
    else:
        for answer in answers:
            if str(answer.get("type") or "").strip().lower() in {"short_answer", "essay"}:
                answer["status"] = "detected" if str(answer.get("answer_text") or "").strip() else "needs_review"
                answer["ai_status"] = "not_submitted"
                answer["ai_feedback"] = None
        step_timer = _mark_ocr_step("normal_submit_grading_skipped", step_timer)

    grade_preview = _build_scan_grade_preview(answers=answers, questions=questions, exam_payload=exam_payload)
    total_elapsed = round(time.perf_counter() - total_timer, 2)
    step_timer = _mark_ocr_step("build_response", step_timer, total_seconds=total_elapsed)

    page_responses = [
        {
            "page_number": int(page["page_number"]),
            "filename": page["filename"],
            "alignment_status": page["alignment_status"],
            "alignment_confidence": float(page["alignment_confidence"]),
            "qr_detected": bool(page["qr_detected"]),
            "bubble_count": len(page["bubbles"]),
            "warnings": page["warnings"],
        }
        for page in page_payloads
    ]

    scan_status = "graded" if answers and grade_preview.get("needs_review", 0) == 0 and grade_preview.get("ai_pending", 0) == 0 else "needs_review"
    return {
        "scan_id": scan_id,
        "status": scan_status,
        "language": lang,
        "exam": {
            "exam_id": exam_id,
            "course_id": course_id,
            "title": exam_payload.get("title"),
            "exam_type": exam_payload.get("exam_type"),
            "template_version": template_version,
        },
        "student": detected_student,
        "pages": page_responses,
        "answers": answers,
        "grade_preview": grade_preview,
        "processing_time_seconds": total_elapsed,
        "attempt_id": submit_meta.get("attempt_id"),
        "attempt_status": submit_meta.get("attempt_status"),
        "ai_grading_requested": bool(submit_meta.get("ai_grading_requested")),
        "ai_request_id": submit_meta.get("ai_request_id"),
        "warnings": warnings,
    }



def _analyze_exam_scan_files_ocr_only(
    *,
    uploaded_files: list[UploadFile],
    file_payloads: list[bytes],
    lang: str,
    db: Any,
    current_user: dict,
    fallback_exam_id: int | None = None,
    fallback_course_id: int | None = None,
) -> dict[str, Any]:
    """Fast PDF OCR preview used by the Flutter OCR upload page.

    It deliberately skips page alignment, Student ID OMR, answer-bubble OMR and
    synchronous AI grading. Those steps are useful for a full answer-sheet
    submission flow, but they are the reason a 3-page photographed PDF can take
    several minutes. This endpoint now returns page-level OCR text as read-only
    preview answers and never saves an attempt.
    """
    import uuid

    from .qr import read_qr_from_image, verify_payload

    total_timer = time.perf_counter()
    step_timer = total_timer
    ensure_instructor(current_user)
    if not uploaded_files:
        raise HTTPException(status_code=400, detail="At least one file is required")

    max_files = int(getattr(settings, "ocr_max_files", 12))
    if len(uploaded_files) > max_files:
        raise HTTPException(status_code=400, detail=f"A maximum of {max_files} files is allowed per request")

    lang = normalise_lang(lang)
    _assert_engine_ready(lang)
    step_timer = _mark_ocr_step("engine_ready", step_timer, lang=lang, mode="ocr_only")

    scan_id = f"scan_{uuid.uuid4().hex[:16]}"
    warnings: list[str] = ["OCR-only mode: Student ID, answer bubbles, saving attempts, and AI grading are skipped."]
    detected_metadata: dict[str, Any] = {}
    pages: list[dict[str, Any]] = []
    answers: list[dict[str, Any]] = []

    page_number = 0
    for upload, raw in zip(uploaded_files, file_payloads, strict=True):
        filename = (upload.filename or "scan").strip() or "scan"
        mime_type = (upload.content_type or "").strip().lower()
        max_file_bytes = int(getattr(settings, "ocr_max_file_bytes", 15 * 1024 * 1024))
        if not raw:
            raise HTTPException(status_code=400, detail=f"{filename}: empty file")
        if len(raw) > max_file_bytes:
            mb = max_file_bytes // (1024 * 1024)
            raise HTTPException(status_code=413, detail=f"{filename}: file exceeds {mb} MB limit")

        document = _load_document(raw=raw, filename=filename, mime_type=mime_type)
        step_timer = _mark_ocr_step("load_document", step_timer, filename=filename, pages=len(document.pages))
        if not document.pages:
            raise HTTPException(status_code=400, detail=f"{filename}: no readable pages found")

        for raw_page in document.pages:
            page_number += 1
            page_warnings = list(document.warnings)
            qr_payload = read_qr_from_image(raw_page)
            qr_detected = bool(qr_payload)
            if qr_payload:
                if verify_payload(qr_payload):
                    detected_metadata.update(qr_payload)
                else:
                    page_warnings.append("QR code was detected but its signature is invalid.")

            ocr_result = _ocr_page(raw_page, lang)
            extracted_text = ocr_result.text.strip()
            status = "detected" if extracted_text and ocr_result.confidence >= 35 else "needs_review"
            if not extracted_text:
                page_warnings.append("No OCR text was extracted from this page.")

            pages.append({
                "page_number": page_number,
                "filename": filename,
                "alignment_status": "skipped",
                "alignment_confidence": 100.0,
                "qr_detected": qr_detected,
                "bubble_count": 0,
                "ocr_text": extracted_text,
                "ocr_confidence": round(float(ocr_result.confidence), 2),
                "word_count": int(ocr_result.word_count),
                "warnings": page_warnings,
            })

            # OCR-only mode returns page text in pages[].ocr_text.
            # Do not invent answers here; answer extraction/grading belongs to the full OMR flow.
            step_timer = _mark_ocr_step("page_ocr", step_timer, page=page_number, words=ocr_result.word_count, confidence=round(float(ocr_result.confidence), 2), qr=qr_detected)

    exam_id = _safe_int(detected_metadata.get("exam_id")) or fallback_exam_id
    course_id = _safe_int(detected_metadata.get("course_id")) or fallback_course_id
    template_version = str(detected_metadata.get("template_version") or "ocr_only")

    if exam_id and not course_id:
        course_id = _lookup_course_id_for_exam(db=db, exam_id=exam_id)
    if course_id:
        _assert_instructor_owns_course(db=db, course_id=course_id, current_user=current_user)
    exam_payload = _load_exam_payload(db=db, exam_id=exam_id, course_id=course_id) if exam_id and course_id else {}

    pages_with_text = sum(1 for item in pages if str(item.get("ocr_text") or "").strip())
    needs_review = sum(1 for item in pages if str(item.get("ocr_text") or "").strip() == "")
    grade_preview = {
        "score_so_far": 0.0,
        "total_score": 0.0,
        "auto_gradable_questions": 0,
        "detected_questions": pages_with_text,
        "written_questions": 0,
        "needs_review": needs_review,
        "ai_ready": 0,
        "ai_graded": 0,
        "ai_pending": 0,
    }

    total_elapsed = round(time.perf_counter() - total_timer, 2)
    _mark_ocr_step("build_response", step_timer, total_seconds=total_elapsed)

    return {
        "scan_id": scan_id,
        "status": "needs_review" if needs_review else "ready",
        "language": lang,
        "exam": {
            "exam_id": exam_id,
            "course_id": course_id,
            "title": exam_payload.get("title") or (f"Exam {exam_id}" if exam_id else "OCR preview"),
            "exam_type": exam_payload.get("exam_type") or "ocr_only",
            "template_version": template_version,
        },
        "student": {"student_id": None, "user_id": None, "name": None, "source": "not_required", "confidence": 0, "digits": []},
        "pages": pages,
        "answers": answers,
        "grade_preview": grade_preview,
        "processing_time_seconds": total_elapsed,
        "warnings": warnings,
    }

def submit_exam_scan(*, payload: Any, db: Any, current_user: dict) -> dict[str, Any]:
    from sqlalchemy import text

    ensure_instructor(current_user)
    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    exam_row = db.execute(
        text("""
            SELECT e.id, e.course_id, e.passing_score, e.total_score, c.created_by
            FROM exams e
            JOIN courses c ON c.id = e.course_id
            WHERE e.id = :exam_id
            LIMIT 1
        """),
        {"exam_id": payload.exam_id},
    ).mappings().first()
    if not exam_row:
        raise HTTPException(status_code=404, detail="Exam not found")
    if int(exam_row["created_by"]) != int(instructor_id):
        raise HTTPException(status_code=403, detail="You can only submit scans for your own exams")

    # Student ID bubbles are not used in the OCR flow. If the caller does not
    # pass a real student_id, create/use a hidden dummy student for this course.
    # This keeps OCR correction on the exact same DB contract as normal student
    # submit without relying on the instructor user as student_id.
    explicit_student_id = _safe_int(getattr(payload, "student_id", None))
    scan_owner_user_id = explicit_student_id or _get_or_create_ocr_dummy_student(
        db=db,
        course_id=int(exam_row["course_id"]),
        instructor_id=int(instructor_id),
    )

    answers_need_ai = [answer for answer in payload.answers if _answer_needs_ai_grading(answer)]
    has_ai_grading = bool(answers_need_ai)
    attempt_status = "submitted" if has_ai_grading else "graded"

    try:
        next_attempt = db.execute(
            text("""
                SELECT COALESCE(MAX(attempt_number), 0) + 1 AS attempt_number
                FROM student_exam_attempts
                WHERE student_id = :student_id AND exam_id = :exam_id
            """),
            {"student_id": scan_owner_user_id, "exam_id": payload.exam_id},
        ).mappings().first()
        attempt_number = int(next_attempt["attempt_number"] if next_attempt else 1)

        total_score = float(payload.total_score or 0)
        percentage_score = payload.percentage_score
        max_total = float(exam_row["total_score"] or 0)
        if percentage_score is None:
            percentage_score = round((total_score / max_total) * 100, 2) if max_total else None

        is_passed = None
        if not has_ai_grading and percentage_score is not None and exam_row.get("passing_score") is not None:
            is_passed = float(percentage_score) >= float(exam_row["passing_score"])

        correct_count = sum(1 for answer in payload.answers if answer.is_correct is True)
        incorrect_count = sum(1 for answer in payload.answers if answer.is_correct is False)
        unanswered_count = sum(1 for answer in payload.answers if answer.is_correct is None)

        attempt = db.execute(
            text("""
                INSERT INTO student_exam_attempts (
                    student_id, exam_id, attempt_number, status,
                    started_at, submitted_at, graded_at,
                    total_score, percentage_score, is_passed,
                    correct_count, incorrect_count, unanswered_count,
                    teacher_feedback, teacher_reviewed_at, session_data
                ) VALUES (
                    :student_id, :exam_id, :attempt_number, CAST(:status AS exam_attempt_status_enum),
                    NOW(), NOW(), CASE WHEN :is_graded THEN NOW() ELSE NULL END,
                    :total_score, :percentage_score, :is_passed,
                    :correct_count, :incorrect_count, :unanswered_count,
                    :teacher_feedback, CASE WHEN :is_graded THEN NOW() ELSE NULL END,
                    CAST(:session_data AS JSONB)
                ) RETURNING id
            """),
            {
                "student_id": scan_owner_user_id,
                "exam_id": payload.exam_id,
                "attempt_number": attempt_number,
                "status": attempt_status,
                "is_graded": attempt_status == "graded",
                "total_score": total_score,
                "percentage_score": percentage_score,
                "is_passed": is_passed,
                "correct_count": correct_count,
                "incorrect_count": incorrect_count,
                "unanswered_count": unanswered_count,
                "teacher_feedback": payload.teacher_feedback,
                "session_data": json.dumps({
                    "source": "learnova_ocr_scan",
                    "scan_id": payload.scan_id,
                    "uploaded_by_instructor_id": instructor_id,
                    "student_id_from_paper_used": False,
                    "ocr_dummy_student_id": scan_owner_user_id,
                    "ai_grading_required": has_ai_grading,
                }),
            },
        ).mappings().first()
        attempt_id = int(attempt["id"])

        for answer in payload.answers:
            db.execute(
                text("""
                    INSERT INTO student_answers (
                        attempt_id, exam_question_id, selected_option_index,
                        selected_option_indices, answer_text, is_correct,
                        points_earned, auto_graded, teacher_feedback,
                        teacher_reviewed_at, created_at, updated_at
                    ) VALUES (
                        :attempt_id, :exam_question_id, :selected_option_index,
                        CAST(:selected_option_indices AS JSON), :answer_text, :is_correct,
                        :points_earned, :auto_graded, :teacher_feedback,
                        CASE WHEN :teacher_reviewed THEN NOW() ELSE NULL END, NOW(), NOW()
                    )
                """),
                {
                    "attempt_id": attempt_id,
                    "exam_question_id": answer.exam_question_id,
                    "selected_option_index": answer.selected_option_index,
                    "selected_option_indices": json.dumps(answer.selected_option_indices) if answer.selected_option_indices is not None else None,
                    "answer_text": answer.answer_text,
                    "is_correct": answer.is_correct,
                    "points_earned": answer.points_earned,
                    "auto_graded": bool(answer.auto_graded),
                    "teacher_feedback": answer.teacher_feedback,
                    "teacher_reviewed": bool(answer.teacher_feedback or answer.is_correct is not None),
                },
            )
            saved_answer_debug.append({
                "exam_question_id": int(answer["exam_question_id"]),
                "resolved_type": _answer_question_type(answer),
                "selected_option_index": answer.get("selected_option_index"),
                "selected_option_indices": selected_many,
                "answer_text": answer.get("answer_text") or answer.get("detected_answer"),
                "is_correct": answer.get("is_correct"),
                "points_earned": answer.get("points_earned"),
                "auto_graded": False if _answer_question_type(answer) in {"essay", "short_answer"} else bool(answer.get("auto_graded", answer.get("is_correct") is not None)),
            })

        _debug_dump("OCR_SUBMIT_STUDENT_ANSWERS_SAVED", saved_answer_debug)
        db.commit()

        ai_request_id: str | None = None
        ai_error: str | None = None
        response_status = "graded"

        if has_ai_grading:
            try:
                ai_request_id = _send_ocr_submit_ai_grading_request(
                    db=db,
                    attempt_id=attempt_id,
                    exam_id=int(payload.exam_id),
                    course_id=int(exam_row["course_id"]),
                )
                db.commit()
                response_status = "ai_grading_requested"
            except Exception as exc:
                db.rollback()
                ai_error = str(exc)
                response_status = "ai_grading_failed"

        return {
            "attempt_id": attempt_id,
            "exam_id": int(payload.exam_id),
            "student_id": scan_owner_user_id,
            "answer_count": len(payload.answers),
            "status": response_status,
            "ai_grading_requested": ai_request_id is not None,
            "ai_request_id": ai_request_id,
            "ai_error": ai_error,
        }
    except HTTPException:
        db.rollback()
        raise
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to submit scan correction") from exc



def _get_or_create_ocr_dummy_student(*, db: Any, course_id: int, instructor_id: int) -> int:
    """Return a hidden student user used only for instructor OCR scan attempts.

    The normal grading/callback flow is built around student_exam_attempts, where
    student_id is a NOT NULL FK to users.id. Instructor OCR scans do not use the
    printed Student ID, so we create one deterministic dummy student per course
    and enroll it in that course. This allows OCR scans to be saved and graded by
    the same code path as normal student submissions without mixing them with a
    real student account.
    """
    from sqlalchemy import text

    if not course_id or course_id <= 0:
        raise HTTPException(status_code=422, detail="Invalid course_id for OCR scan student")

    # Deterministic and unique enough for one DB. Keep it stable so repeated
    # scans for the same course reuse the same hidden student.
    email = f"ocr.scan.course.{course_id}@learnova.local"
    student_code = f"OCR-SCAN-C{int(course_id):06d}"
    full_name = f"OCR Scan Student C{int(course_id)}"

    row = db.execute(
        text("""
            SELECT id
            FROM users
            WHERE email = :email
               OR student_id = :student_code
            ORDER BY id ASC
            LIMIT 1
        """),
        {"email": email, "student_code": student_code},
    ).mappings().first()

    if row:
        student_user_id = int(row["id"])
        # Make sure an old row is still usable as the OCR scan student.
        db.execute(
            text("""
                UPDATE users
                SET system_role = CAST('student' AS system_role_enum),
                    account_status = CAST('active' AS account_status_enum),
                    is_email_verified = TRUE,
                    student_id = COALESCE(student_id, :student_code),
                    updated_at = NOW()
                WHERE id = :user_id
            """),
            {"user_id": student_user_id, "student_code": student_code},
        )
    else:
        inserted = db.execute(
            text("""
                INSERT INTO users (
                    full_name, email, hashed_password, student_id,
                    system_role, language_preference, account_status,
                    is_email_verified, email_verified_at, created_at, updated_at
                ) VALUES (
                    :full_name, :email, NULL, :student_code,
                    CAST('student' AS system_role_enum), 'en', CAST('active' AS account_status_enum),
                    TRUE, NOW(), NOW(), NOW()
                )
                RETURNING id
            """),
            {
                "full_name": full_name,
                "email": email,
                "student_code": student_code,
            },
        ).mappings().first()
        if not inserted:
            raise HTTPException(status_code=500, detail="Failed to create OCR dummy student")
        student_user_id = int(inserted["id"])

    # Enroll the dummy student so any course/exam joins that expect enrollment
    # continue to behave like the normal student flow.
    db.execute(
        text("""
            INSERT INTO course_enrollments (
                student_id, course_id, status, enrollment_type, enrolled_at
            ) VALUES (
                :student_id, :course_id,
                CAST('active' AS course_enrollment_status_enum),
                CAST('invited' AS course_enrollment_type_enum),
                NOW()
            )
            ON CONFLICT (student_id, course_id)
            DO UPDATE SET
                status = CAST('active' AS course_enrollment_status_enum),
                enrollment_type = CAST('invited' AS course_enrollment_type_enum)
        """),
        {"student_id": student_user_id, "course_id": int(course_id)},
    )

    print(
        f"[OCR_SUBMIT] using dummy student user_id={student_user_id} "
        f"student_code={student_code} course_id={course_id} instructor_id={instructor_id}",
        flush=True,
    )
    return student_user_id


def _create_scan_attempt_like_student_submit(
    *,
    db: Any,
    scan_id: str,
    exam_id: int,
    course_id: int,
    answers: list[dict[str, Any]],
    questions: list[dict[str, Any]],
    exam_payload: dict[str, Any],
    current_user: dict,
) -> dict[str, Any]:
    """Persist OCR answers in the same tables used by normal student submit.

    The existing AI callback stores grading results by attempt_id, so OCR grading
    must create an attempt before sending essay/short-answer answers to AI. We do
    not read or require the printed Student ID; instead we create/reuse a hidden
    dummy student for the scanned course and save the attempt against that user.
    The attempt is clearly marked in session_data as source=learnova_ocr_scan.
    """
    from sqlalchemy import text

    instructor_id = _safe_int(current_user.get("id"))
    if instructor_id is None:
        raise HTTPException(status_code=401, detail="Unauthorized")

    exam_row = db.execute(
        text("""
            SELECT e.id, e.course_id, e.passing_score, e.total_score, c.created_by
            FROM exams e
            JOIN courses c ON c.id = e.course_id
            WHERE e.id = :exam_id AND e.course_id = :course_id
            LIMIT 1
        """),
        {"exam_id": exam_id, "course_id": course_id},
    ).mappings().first()
    if not exam_row:
        raise HTTPException(status_code=404, detail="Exam not found")
    if int(exam_row["created_by"]) != int(instructor_id):
        raise HTTPException(status_code=403, detail="You can only scan exams for your own courses")

    owner_user_id = _get_or_create_ocr_dummy_student(
        db=db,
        course_id=course_id,
        instructor_id=instructor_id,
    )

    _debug_dump("OCR_SUBMIT_CONTEXT", {
        "scan_id": scan_id,
        "course_id": course_id,
        "exam_id": exam_id,
        "instructor_id": instructor_id,
        "dummy_student_user_id": owner_user_id,
        "exam_row": dict(exam_row),
        "env": {
            "OCR_AUTO_SUBMIT_SCAN": os.getenv("OCR_AUTO_SUBMIT_SCAN"),
            "OCR_ANALYZE_AI_GRADING": os.getenv("OCR_ANALYZE_AI_GRADING"),
            "OCR_SUBMIT_VERBOSE_LOGS": os.getenv("OCR_SUBMIT_VERBOSE_LOGS"),
            "OCR_HANDWRITING_ENGINE": os.getenv("OCR_HANDWRITING_ENGINE"),
            "OCR_TROCR_MODEL": os.getenv("OCR_TROCR_MODEL"),
        },
    })

    answer_rows = [answer for answer in answers if _safe_int(answer.get("exam_question_id")) is not None]

    question_type_by_exam_question_id = {
        _safe_int(question.get("exam_question_id")): str(question.get("type") or "").strip().lower()
        for question in questions
        if _safe_int(question.get("exam_question_id")) is not None
    }

    def _answer_question_type(answer: dict[str, Any]) -> str:
        explicit_type = str(answer.get("type") or "").strip().lower()
        if explicit_type:
            return explicit_type
        exam_question_id = _safe_int(answer.get("exam_question_id"))
        return question_type_by_exam_question_id.get(exam_question_id, "")

    def _scan_answer_needs_ai(answer: dict[str, Any]) -> bool:
        qtype = _answer_question_type(answer)
        if qtype in {"essay", "short_answer"}:
            return bool(str(answer.get("answer_text") or "").strip())
        return False

    written_with_text = [answer for answer in answer_rows if _scan_answer_needs_ai(answer)]
    has_ai_grading = bool(written_with_text)
    attempt_status = "submitted" if has_ai_grading else "graded"

    print(
        f"[OCR_SUBMIT] answers={len(answer_rows)} written_with_text={len(written_with_text)} "
        f"has_ai_grading={has_ai_grading} qtypes={[ _answer_question_type(a) for a in answer_rows ]}",
        flush=True,
    )
    _debug_dump("OCR_SUBMIT_ANSWER_ROWS_BEFORE_SAVE", [
        {
            "exam_question_id": a.get("exam_question_id"),
            "question_number": a.get("question_number"),
            "type_from_answer": a.get("type"),
            "resolved_type": _answer_question_type(a),
            "answer_text": a.get("answer_text"),
            "selected_option_index": a.get("selected_option_index"),
            "selected_option_indices": a.get("selected_option_indices"),
            "detected_answer": a.get("detected_answer"),
            "is_correct": a.get("is_correct"),
            "points_earned": a.get("points_earned"),
            "auto_graded": a.get("auto_graded"),
            "status": a.get("status"),
        }
        for a in answer_rows
    ])

    total_score = 0.0
    correct_count = 0
    incorrect_count = 0
    unanswered_count = 0
    for answer in answer_rows:
        qtype = _answer_question_type(answer)
        answer["type"] = qtype or answer.get("type")
        if qtype in {"essay", "short_answer"}:
            if not str(answer.get("answer_text") or "").strip():
                unanswered_count += 1
            # normal submit does not count written questions until AI callback
            answer["is_correct"] = None
            answer["points_earned"] = None
            answer["auto_graded"] = False
            answer["status"] = "ai_pending" if str(answer.get("answer_text") or "").strip() else "needs_review"
            answer["ai_status"] = "pending" if str(answer.get("answer_text") or "").strip() else "needs_review"
            continue

        if answer.get("is_correct") is True:
            correct_count += 1
            total_score += float(answer.get("points_earned") or 0)
        elif answer.get("is_correct") is False:
            incorrect_count += 1
        else:
            unanswered_count += 1

    exam_total_score = float(exam_row["total_score"] or exam_payload.get("total_score") or 0)
    percentage_score = round((total_score / exam_total_score) * 100, 2) if exam_total_score else None
    is_passed = None
    if not has_ai_grading and percentage_score is not None and exam_row.get("passing_score") is not None:
        is_passed = percentage_score >= float(exam_row["passing_score"])

    _debug_dump("OCR_SUBMIT_SCORE_PREVIEW", {
        "has_ai_grading": has_ai_grading,
        "attempt_status": attempt_status,
        "total_score_before_ai": total_score,
        "exam_total_score": exam_total_score,
        "percentage_score_before_ai": percentage_score,
        "is_passed_before_ai": is_passed,
        "correct_count_before_ai": correct_count,
        "incorrect_count_before_ai": incorrect_count,
        "unanswered_count_before_ai": unanswered_count,
    })

    try:
        next_attempt = db.execute(
            text("""
                SELECT COALESCE(MAX(attempt_number), 0) + 1 AS attempt_number
                FROM student_exam_attempts
                WHERE student_id = :student_id AND exam_id = :exam_id
            """),
            {"student_id": owner_user_id, "exam_id": exam_id},
        ).mappings().first()
        attempt_number = int(next_attempt["attempt_number"] if next_attempt else 1)

        attempt = db.execute(
            text("""
                INSERT INTO student_exam_attempts (
                    student_id, exam_id, attempt_number, status,
                    started_at, submitted_at, graded_at, time_spent_seconds,
                    total_score, percentage_score, is_passed,
                    correct_count, incorrect_count, unanswered_count,
                    session_data
                ) VALUES (
                    :student_id, :exam_id, :attempt_number, CAST(:status AS exam_attempt_status_enum),
                    NOW(), NOW(), CASE WHEN :is_graded THEN NOW() ELSE NULL END, 0,
                    :total_score, :percentage_score, :is_passed,
                    :correct_count, :incorrect_count, :unanswered_count,
                    CAST(:session_data AS JSONB)
                ) RETURNING id
            """),
            {
                "student_id": owner_user_id,
                "exam_id": exam_id,
                "attempt_number": attempt_number,
                "status": attempt_status,
                "is_graded": attempt_status == "graded",
                "total_score": total_score,
                "percentage_score": percentage_score,
                "is_passed": is_passed,
                "correct_count": correct_count,
                "incorrect_count": incorrect_count,
                "unanswered_count": unanswered_count,
                "session_data": json.dumps({
                    "source": "learnova_ocr_scan",
                    "scan_id": scan_id,
                    "uploaded_by_instructor_id": instructor_id,
                    "student_id_from_paper_used": False,
                    "ocr_dummy_student_id": owner_user_id,
                    "ai_grading_required": has_ai_grading,
                }),
            },
        ).mappings().first()
        attempt_id = int(attempt["id"])
        print(f"[OCR_SUBMIT] attempt_created attempt_id={attempt_id} attempt_number={attempt_number} status={attempt_status}", flush=True)
        _debug_dump("OCR_SUBMIT_ATTEMPT_INSERTED", {
            "attempt_id": attempt_id,
            "student_id": owner_user_id,
            "exam_id": exam_id,
            "attempt_number": attempt_number,
            "status": attempt_status,
            "session_source": "learnova_ocr_scan",
        })

        saved_answer_debug: list[dict[str, Any]] = []
        for answer in answer_rows:
            selected_many = answer.get("selected_option_indices")
            db.execute(
                text("""
                    INSERT INTO student_answers (
                        attempt_id, exam_question_id,
                        selected_option_index, selected_option_indices,
                        answer_text, time_taken_seconds,
                        is_correct, points_earned, auto_graded,
                        created_at, updated_at
                    ) VALUES (
                        :attempt_id, :exam_question_id,
                        :selected_option_index, CAST(:selected_option_indices AS JSON),
                        :answer_text, NULL,
                        :is_correct, :points_earned, :auto_graded,
                        NOW(), NOW()
                    )
                    ON CONFLICT (attempt_id, exam_question_id)
                    DO UPDATE SET
                        selected_option_index   = EXCLUDED.selected_option_index,
                        selected_option_indices = EXCLUDED.selected_option_indices,
                        answer_text             = EXCLUDED.answer_text,
                        is_correct              = EXCLUDED.is_correct,
                        points_earned           = EXCLUDED.points_earned,
                        auto_graded             = EXCLUDED.auto_graded,
                        updated_at              = NOW()
                """),
                {
                    "attempt_id": attempt_id,
                    "exam_question_id": int(answer["exam_question_id"]),
                    "selected_option_index": answer.get("selected_option_index"),
                    "selected_option_indices": json.dumps(selected_many) if selected_many is not None else None,
                    "answer_text": answer.get("answer_text") or answer.get("detected_answer"),
                    "is_correct": answer.get("is_correct"),
                    "points_earned": answer.get("points_earned"),
                    "auto_graded": False if _answer_question_type(answer) in {"essay", "short_answer"} else bool(answer.get("auto_graded", answer.get("is_correct") is not None)),
                },
            )

        db.commit()

        ai_request_id: str | None = None
        ai_error: str | None = None
        ai_enabled = _env_bool("OCR_ANALYZE_AI_GRADING", True)
        print(
            f"[OCR_SUBMIT][AI_DECISION] has_ai_grading={has_ai_grading} "
            f"ai_enabled={ai_enabled} written_with_text={len(written_with_text)}",
            flush=True,
        )
        _debug_dump("OCR_SUBMIT_AI_DECISION", {
            "has_ai_grading": has_ai_grading,
            "ai_enabled_from_env": ai_enabled,
            "written_exam_question_ids": [a.get("exam_question_id") for a in written_with_text],
            "written_answers": [
                {
                    "exam_question_id": a.get("exam_question_id"),
                    "type": _answer_question_type(a),
                    "answer_text": a.get("answer_text"),
                    "status": a.get("status"),
                }
                for a in written_with_text
            ],
        })
        if has_ai_grading and ai_enabled:
            try:
                ai_request_id = _send_ocr_submit_ai_grading_request(
                    db=db,
                    attempt_id=attempt_id,
                    exam_id=exam_id,
                    course_id=course_id,
                )
                for answer in written_with_text:
                    answer["ai_request_id"] = ai_request_id
                    answer["ai_status"] = "pending"
                    answer["status"] = "ai_pending"
                db.commit()
            except Exception as exc:
                db.rollback()
                ai_error = str(exc)
                print(f"[OCR_SUBMIT][AI_ERROR] Failed to send normal exam grading request: {exc!r}", flush=True)
                for answer in written_with_text:
                    answer["ai_status"] = "failed"
                    answer["status"] = "needs_review"
                    answer["ai_feedback"] = "AI grading request failed; review manually."
        elif has_ai_grading and not ai_enabled:
            ai_error = "OCR_ANALYZE_AI_GRADING=false; AI grading request was intentionally skipped."
            print(f"[OCR_SUBMIT][AI_SKIP] {ai_error}", flush=True)
            for answer in written_with_text:
                answer["ai_status"] = "skipped"
                answer["status"] = "needs_review"
                answer["ai_feedback"] = ai_error

        return {
            "attempt_id": attempt_id,
            "attempt_status": "submitted" if has_ai_grading else "graded",
            "ai_grading_requested": bool(ai_request_id),
            "ai_request_id": ai_request_id,
            "ai_error": ai_error,
        }
    except HTTPException:
        db.rollback()
        raise
    except Exception as exc:
        db.rollback()
        print(f"[OCR_SUBMIT][ERROR] Failed to create OCR grading attempt: {exc!r}", flush=True)
        print("[OCR_SUBMIT][ERROR_TRACEBACK]", flush=True)
        print(traceback.format_exc(), flush=True)
        raise HTTPException(status_code=500, detail=f"Failed to create OCR grading attempt: {exc}") from exc


def get_exam_scan_attempt_result(*, attempt_id: int, db: Any, current_user: dict) -> dict[str, Any]:
    """Instructor-safe OCR result reader for attempts created from exam scans."""
    from sqlalchemy import text

    ensure_instructor(current_user)
    instructor_id = _safe_int(current_user.get("id"))
    if instructor_id is None:
        raise HTTPException(status_code=401, detail="Unauthorized")

    attempt_row = db.execute(
        text("""
            SELECT
                sea.id, sea.exam_id, sea.status, sea.total_score,
                sea.percentage_score, sea.correct_count, sea.incorrect_count,
                sea.unanswered_count, sea.session_data,
                e.course_id, e.title, e.exam_type, e.total_score AS exam_total_score,
                c.created_by
            FROM student_exam_attempts sea
            JOIN exams e ON e.id = sea.exam_id
            JOIN courses c ON c.id = e.course_id
            WHERE sea.id = :attempt_id
            LIMIT 1
        """),
        {"attempt_id": attempt_id},
    ).mappings().first()
    if not attempt_row:
        raise HTTPException(status_code=404, detail="OCR grading attempt not found")
    if int(attempt_row["created_by"]) != int(instructor_id):
        raise HTTPException(status_code=403, detail="You can only view OCR results for your own courses")

    session_data = attempt_row.get("session_data") or {}
    if isinstance(session_data, str):
        try:
            session_data = json.loads(session_data)
        except Exception:
            session_data = {}
    if session_data.get("source") != "learnova_ocr_scan":
        raise HTTPException(status_code=404, detail="Attempt is not an OCR scan attempt")

    exam_id = int(attempt_row["exam_id"])
    course_id = int(attempt_row["course_id"])
    exam_payload = {
        "exam_id": exam_id,
        "course_id": course_id,
        "title": attempt_row.get("title"),
        "exam_type": attempt_row.get("exam_type"),
        "total_score": attempt_row.get("exam_total_score"),
    }
    questions = _load_exam_questions_for_scan(db=db, exam_id=exam_id, course_id=course_id)

    answer_rows = db.execute(
        text("""
            SELECT
                exam_question_id, selected_option_index, selected_option_indices,
                answer_text, is_correct, points_earned, auto_graded, teacher_feedback
            FROM student_answers
            WHERE attempt_id = :attempt_id
        """),
        {"attempt_id": attempt_id},
    ).mappings().all()
    answers_by_qid = {int(row["exam_question_id"]): dict(row) for row in answer_rows}

    answers: list[dict[str, Any]] = []
    for question in questions:
        qid = int(question["exam_question_id"])
        qtype = str(question.get("type") or "").strip().lower()
        row = answers_by_qid.get(qid, {})
        selected_many = row.get("selected_option_indices")
        if isinstance(selected_many, str):
            try:
                selected_many = json.loads(selected_many)
            except Exception:
                selected_many = None
        answer = {
            "exam_question_id": qid,
            "question_number": int(question.get("question_number") or len(answers) + 1),
            "type": qtype,
            "detected_answer": row.get("answer_text") if qtype in {"multiple_choice", "true_false"} else None,
            "detected_answers": selected_many if isinstance(selected_many, list) else [],
            "selected_option_index": row.get("selected_option_index"),
            "selected_option_indices": selected_many if isinstance(selected_many, list) else None,
            "answer_text": row.get("answer_text"),
            "confidence": 0,
            "status": "graded" if row and row.get("points_earned") is not None else ("ai_pending" if qtype in {"essay", "short_answer"} else "needs_review"),
            "is_correct": row.get("is_correct"),
            "points_earned": float(row["points_earned"]) if row.get("points_earned") is not None else None,
            "max_score": _question_points(qid, questions),
            "regions": [],
            "answer_region": None,
            "ai_grading_payload": None,
            "ai_score": float(row["points_earned"]) if row.get("points_earned") is not None and qtype in {"essay", "short_answer"} else None,
            "ai_status": "completed" if row.get("points_earned") is not None and qtype in {"essay", "short_answer"} else ("pending" if qtype in {"essay", "short_answer"} else None),
            "ai_feedback": row.get("teacher_feedback"),
        }
        answers.append(answer)

    _attach_question_context(answers=answers, questions=questions)
    grade_preview = _build_scan_grade_preview(answers=answers, questions=questions, exam_payload=exam_payload)
    return {
        "scan_id": str(session_data.get("scan_id") or f"attempt_{attempt_id}"),
        "status": str(attempt_row["status"]),
        "language": "eng",
        "exam": {
            "exam_id": exam_id,
            "course_id": course_id,
            "title": attempt_row.get("title"),
            "exam_type": attempt_row.get("exam_type"),
            "template_version": "v1",
        },
        "student": {"student_id": None, "user_id": None, "name": None, "source": "not_used", "confidence": 0, "digits": []},
        "pages": [],
        "answers": answers,
        "grade_preview": grade_preview,
        "processing_time_seconds": None,
        "attempt_id": attempt_id,
        "attempt_status": str(attempt_row["status"]),
        "ai_grading_requested": str(attempt_row["status"]) == "submitted",
        "ai_request_id": None,
        "warnings": [],
    }



def _answer_needs_ai_grading(answer: Any) -> bool:
    answer_type = str(getattr(answer, "type", "") or "").strip().lower()
    if answer_type not in {"short_answer", "essay"}:
        return False
    if bool(getattr(answer, "auto_graded", False)):
        return False
    return bool(str(getattr(answer, "answer_text", "") or "").strip())


def _send_ocr_submit_ai_grading_request(*, db: Any, attempt_id: int, exam_id: int, course_id: int) -> str | None:
    from sqlalchemy import text
    from app.core.ai_service_integration.ai_transport import send_ai_request

    print(
        f"[OCR_SUBMIT][AI] preparing normal exam_grading request "
        f"attempt_id={attempt_id} exam_id={exam_id} course_id={course_id}",
        flush=True,
    )

    diagnostic_rows = db.execute(
        text("""
            SELECT
                eq.id AS exam_question_id,
                eq.exam_id,
                eq.order_index,
                eq.points,
                eq.snapshot_type,
                eq.snapshot_auto_gradable,
                NULLIF(BTRIM(COALESCE(sa.answer_text, '')), '') IS NOT NULL AS has_answer_text,
                LENGTH(COALESCE(sa.answer_text, '')) AS answer_text_length,
                sa.answer_text,
                eq.snapshot_question_text,
                eq.snapshot_expected_answer,
                eq.snapshot_grading_rubric
            FROM exam_questions eq
            LEFT JOIN student_answers sa
              ON sa.exam_question_id = eq.id
             AND sa.attempt_id = :attempt_id
            WHERE eq.exam_id = :exam_id
            ORDER BY eq.order_index ASC, eq.id ASC
        """),
        {"attempt_id": attempt_id, "exam_id": exam_id},
    ).mappings().all()
    _debug_dump("OCR_SUBMIT_AI_DIAGNOSTIC_ALL_EXAM_QUESTIONS", [dict(row) for row in diagnostic_rows])

    # Keep this query and request shape intentionally aligned with the normal
    # student submit flow in domains/exams/service.py. OCR only supplies the
    # answer_text; grading/callback storage remains the normal attempt flow.
    rows = db.execute(
        text("""
            SELECT
                eq.id AS exam_question_id,
                eq.snapshot_question_text,
                eq.snapshot_type,
                eq.snapshot_expected_answer,
                eq.snapshot_grading_rubric,
                eq.points AS max_score,
                sa.answer_text
            FROM exam_questions eq
            JOIN student_answers sa
              ON sa.exam_question_id = eq.id
             AND sa.attempt_id = :attempt_id
            WHERE eq.exam_id = :exam_id
              AND eq.snapshot_type IN ('essay', 'short_answer')
              AND COALESCE(eq.snapshot_auto_gradable, FALSE) = FALSE
              AND NULLIF(BTRIM(COALESCE(sa.answer_text, '')), '') IS NOT NULL
            ORDER BY eq.order_index ASC, eq.id ASC
        """),
        {"attempt_id": attempt_id, "exam_id": exam_id},
    ).mappings().all()

    _debug_dump("OCR_SUBMIT_AI_SELECTED_ROWS", [dict(row) for row in rows])

    if not rows:
        print(
            f"[OCR_SUBMIT][AI] no essay/short_answer rows found for attempt_id={attempt_id} exam_id={exam_id}",
            flush=True,
        )
        return None

    questions = [
        {
            "exam_question_id": int(row["exam_question_id"]),
            "question_text": row["snapshot_question_text"],
            "type": row["snapshot_type"],
            "expected_answer": row["snapshot_expected_answer"],
            "grading_rubric": row["snapshot_grading_rubric"],
            "max_score": float(row["max_score"] or 0),
            "student_answer": row["answer_text"],
        }
        for row in rows
    ]

    body = {
        "attempt_id": attempt_id,
        "exam_id": exam_id,
        "questions": questions,
    }

    _debug_dump("OCR_SUBMIT_AI_PAYLOAD_TO_NORMAL_GRADING", {
        "operation_type": "exam_grading",
        "endpoint_path": "/api/v1/courses/grading/evaluate",
        "course_id": course_id,
        "primary_entity_type": "attempt",
        "primary_entity_id": attempt_id,
        "body": body,
    }, always=True)

    print(
        f"[OCR_SUBMIT][AI] sending normal exam_grading request attempt_id={attempt_id} "
        f"exam_id={exam_id} questions={len(questions)}",
        flush=True,
    )

    try:
        request_id = send_ai_request(
            db,
            operation_type="exam_grading",
            endpoint_path="/api/v1/courses/grading/evaluate",
            course_id=course_id,
            primary_entity_type="attempt",
            primary_entity_id=attempt_id,
            body=body,
        )
    except Exception as exc:
        print(f"[OCR_SUBMIT][AI_ERROR] send_ai_request raised: {exc!r}", flush=True)
        print("[OCR_SUBMIT][AI_ERROR_TRACEBACK]", flush=True)
        print(traceback.format_exc(), flush=True)
        raise

    print(f"[OCR_SUBMIT][AI] request_created request_id={request_id}", flush=True)
    return request_id


def _assert_instructor_owns_course(*, db: Any, course_id: int, current_user: dict) -> None:
    from sqlalchemy import text

    instructor_id = current_user.get("id")
    if not instructor_id:
        raise HTTPException(status_code=401, detail="Unauthorized")

    row = db.execute(
        text("""
            SELECT id, created_by
            FROM courses
            WHERE id = :course_id
            LIMIT 1
        """),
        {"course_id": course_id},
    ).mappings().first()
    if not row:
        raise HTTPException(status_code=404, detail="Course not found")
    if int(row["created_by"]) != int(instructor_id):
        raise HTTPException(status_code=403, detail="You can only scan exams for your own courses")


def _lookup_course_id_for_exam(*, db: Any, exam_id: int) -> int | None:
    from sqlalchemy import text

    row = db.execute(text("SELECT course_id FROM exams WHERE id = :exam_id LIMIT 1"), {"exam_id": exam_id}).mappings().first()
    return int(row["course_id"]) if row else None


def _load_exam_payload(*, db: Any, exam_id: int, course_id: int) -> dict[str, Any]:
    from sqlalchemy import text

    row = db.execute(
        text("""
            SELECT id AS exam_id, course_id, title, exam_type, total_score
            FROM exams
            WHERE id = :exam_id AND course_id = :course_id
            LIMIT 1
        """),
        {"exam_id": exam_id, "course_id": course_id},
    ).mappings().first()
    if not row:
        raise HTTPException(status_code=404, detail="Exam not found")
    return dict(row)


def _load_exam_questions_for_scan(*, db: Any, exam_id: int, course_id: int) -> list[dict[str, Any]]:
    from sqlalchemy import text

    exam_row = db.execute(
        text("SELECT is_published FROM exams WHERE id = :exam_id AND course_id = :course_id LIMIT 1"),
        {"exam_id": exam_id, "course_id": course_id},
    ).mappings().first()
    if not exam_row:
        raise HTTPException(status_code=404, detail="Exam not found")

    if bool(exam_row["is_published"]):
        query = text("""
            SELECT
                eq.id AS exam_question_id, eq.question_id, eq.section_id, eq.order_index,
                eq.points, eq.snapshot_question_text AS question_text,
                eq.snapshot_options AS options, eq.snapshot_type AS type,
                eq.snapshot_expected_answer AS expected_answer,
                eq.snapshot_grading_rubric AS grading_rubric,
                eq.snapshot_max_score AS max_score
            FROM exam_questions eq
            JOIN exam_sections es ON es.id = eq.section_id AND es.exam_id = eq.exam_id
            WHERE eq.exam_id = :exam_id
            ORDER BY es.order_index ASC, eq.order_index ASC, eq.id ASC
        """)
        rows = db.execute(query, {"exam_id": exam_id}).mappings().all()
    else:
        query = text("""
            SELECT
                eq.id AS exam_question_id, eq.question_id, eq.section_id, eq.order_index,
                eq.points, q.question_text, q.options, q.type,
                q.expected_answer, q.grading_rubric, q.max_score
            FROM exam_questions eq
            JOIN exam_sections es ON es.id = eq.section_id AND es.exam_id = eq.exam_id
            JOIN questions q ON q.id = eq.question_id
            WHERE eq.exam_id = :exam_id AND q.course_id = :course_id
            ORDER BY es.order_index ASC, eq.order_index ASC, eq.id ASC
        """)
        rows = db.execute(query, {"exam_id": exam_id, "course_id": course_id}).mappings().all()

    questions: list[dict[str, Any]] = []
    for index, row in enumerate(rows, start=1):
        question = dict(row)
        question["question_number"] = index
        questions.append(question)
    return questions


def _lookup_student(*, db: Any, student_identifier: str, course_id: int | None) -> dict[str, Any] | None:
    from sqlalchemy import text

    user_id = _safe_int(student_identifier)
    params: dict[str, Any] = {"student_identifier": student_identifier, "user_id": user_id}
    if course_id:
        params["course_id"] = course_id
        row = db.execute(
            text("""
                SELECT u.id, u.full_name, u.student_id
                FROM users u
                JOIN course_enrollments ce ON ce.student_id = u.id
                WHERE ce.course_id = :course_id
                  AND (u.student_id = :student_identifier OR u.id = :user_id)
                LIMIT 1
            """),
            params,
        ).mappings().first()
        if row:
            return dict(row)

    row = db.execute(
        text("""
            SELECT id, full_name, student_id
            FROM users
            WHERE student_id = :student_identifier OR id = :user_id
            LIMIT 1
        """),
        params,
    ).mappings().first()
    return dict(row) if row else None


def _apply_objective_grade(answer: dict[str, Any], questions: list[dict[str, Any]]) -> None:
    question = _find_question(answer.get("exam_question_id"), answer.get("question_number"), questions)
    answer["max_score"] = _question_points(answer.get("exam_question_id"), questions)
    if not question:
        answer["is_correct"] = None
        answer["points_earned"] = None
        return

    expected = _normalise_expected_answer(question.get("expected_answer"), question.get("type"))
    detected = _normalise_detected_answer(answer)
    if expected is None or detected is None:
        answer["is_correct"] = None
        answer["points_earned"] = None
        return

    is_correct = expected == detected
    answer["is_correct"] = is_correct
    answer["points_earned"] = float(question.get("points") or question.get("max_score") or 0) if is_correct else 0.0


def _normalise_expected_answer(raw: Any, question_type: Any) -> Any:
    qtype = str(question_type or "").strip().lower()
    if raw is None:
        return None
    if isinstance(raw, dict):
        value = raw.get("answer") or raw.get("correct_answer") or raw.get("expected_answer")
        values = raw.get("answers") or raw.get("correct_answers") or raw.get("correct_option_indices") or raw.get("correct_option_ids")
        if values is not None:
            raw = values
        elif value is not None:
            raw = value
    if qtype == "multi_select":
        if not isinstance(raw, list):
            raw = [raw]
        return sorted(_normalise_one_answer(item) for item in raw if _normalise_one_answer(item) is not None)
    return _normalise_one_answer(raw)


def _normalise_detected_answer(answer: dict[str, Any]) -> Any:
    qtype = str(answer.get("type") or "").strip().lower()
    if qtype == "multi_select":
        values = answer.get("detected_answers") or answer.get("selected_option_indices") or []
        return sorted(_normalise_one_answer(item) for item in values if _normalise_one_answer(item) is not None)
    return _normalise_one_answer(answer.get("detected_answer") if answer.get("detected_answer") is not None else answer.get("selected_option_index"))


def _normalise_one_answer(value: Any) -> Any:
    if value is None:
        return None
    if isinstance(value, int):
        return value
    text_value = str(value).strip().lower()
    if text_value in {"true", "t"}:
        return "true"
    if text_value in {"false", "f"}:
        return "false"
    if len(text_value) == 1 and "a" <= text_value <= "z":
        return ord(text_value) - ord("a")
    try:
        return int(text_value)
    except ValueError:
        return text_value.upper()


def _dedupe_answers(answers: list[dict[str, Any]]) -> list[dict[str, Any]]:
    best: dict[tuple[Any, Any, Any], dict[str, Any]] = {}
    for answer in answers:
        key = (answer.get("exam_question_id"), answer.get("question_number"), answer.get("type"))
        current = best.get(key)
        if current is None or float(answer.get("confidence") or 0) > float(current.get("confidence") or 0):
            best[key] = answer
    return sorted(best.values(), key=lambda item: (_safe_int(item.get("exam_question_id")) or 10**9, _safe_int(item.get("question_number")) or 10**9, str(item.get("type") or "")))


def _ensure_answers_for_all_questions(*, answers: list[dict[str, Any]], questions: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Return exactly one review row for every exam question.

    OCR/OMR can legitimately miss a bubble or a written box. The instructor UI
    still needs a row for that question so it can show "not detected" together
    with the correct answer from the exam bank.
    """
    if not questions:
        return answers

    by_exam_question_id = {
        int(answer["exam_question_id"]): answer
        for answer in answers
        if _safe_int(answer.get("exam_question_id")) is not None
    }
    by_question_number = {
        int(answer["question_number"]): answer
        for answer in answers
        if _safe_int(answer.get("question_number")) is not None
    }

    merged: list[dict[str, Any]] = []
    used_ids: set[int] = set()
    for question in questions:
        exam_question_id = _safe_int(question.get("exam_question_id"))
        question_number = _safe_int(question.get("question_number")) or (len(merged) + 1)
        answer = by_exam_question_id.get(exam_question_id) if exam_question_id is not None else None
        if answer is None:
            answer = by_question_number.get(question_number)
        if answer is None:
            qtype = str(question.get("type") or "").strip().lower() or "question"
            max_score = _question_points(exam_question_id, questions)
            is_objective = qtype in {"multiple_choice", "multi_select", "true_false"}
            answer = {
                "exam_question_id": exam_question_id,
                "question_number": question_number,
                "type": qtype,
                "detected_answer": None,
                "detected_answers": [],
                "selected_option_index": None,
                "selected_option_indices": None,
                "answer_text": None,
                "confidence": 0.0,
                "status": "needs_review",
                "is_correct": False if is_objective else None,
                "points_earned": 0.0 if is_objective else None,
                "max_score": max_score,
                "regions": [],
                "answer_region": None,
                "ai_grading_payload": None,
                "ai_score": None,
                "ai_status": "needs_review" if not is_objective else None,
                "ai_feedback": "No written answer was detected." if not is_objective else None,
                "ai_request_id": None,
            }
        if exam_question_id is not None:
            used_ids.add(exam_question_id)
        merged.append(answer)

    # Keep any extra detections that were not mapped to a known question.
    for answer in answers:
        exam_question_id = _safe_int(answer.get("exam_question_id"))
        if exam_question_id is not None and exam_question_id in used_ids:
            continue
        if exam_question_id is None and answer not in merged:
            merged.append(answer)
    return merged


def _attach_question_context(*, answers: list[dict[str, Any]], questions: list[dict[str, Any]]) -> None:
    for answer in answers:
        question = _find_question(answer.get("exam_question_id"), answer.get("question_number"), questions)
        if not question:
            answer.setdefault("question_text", None)
            answer.setdefault("options", [])
            answer.setdefault("correct_answer", None)
            answer.setdefault("expected_answer", None)
            continue
        qtype = str(question.get("type") or answer.get("type") or "").strip().lower()
        answer["question_text"] = question.get("question_text")
        answer["options"] = _options_payload(question.get("options"))
        answer["expected_answer"] = question.get("expected_answer")
        answer["correct_answer"] = _expected_answer_display(question.get("expected_answer"), qtype, question.get("options"))
        if answer.get("max_score") is None:
            answer["max_score"] = _question_points(question.get("exam_question_id"), questions)
        if qtype in {"multiple_choice", "multi_select", "true_false"}:
            _apply_objective_grade(answer, questions)


def _options_payload(options: Any) -> list[dict[str, Any]]:
    if not isinstance(options, list):
        return []
    payload: list[dict[str, Any]] = []
    for index, option in enumerate(options):
        label = chr(ord("A") + index) if index < 26 else str(index + 1)
        if isinstance(option, dict):
            text_value = option.get("text") or option.get("label") or option.get("value") or ""
        else:
            text_value = option
        payload.append({"label": label, "text": str(text_value or "")})
    return payload


def _expected_answer_display(raw: Any, question_type: Any, options: Any = None) -> str | None:
    if raw is None:
        return None
    qtype = str(question_type or "").strip().lower()
    option_payload = _options_payload(options)

    def one(value: Any) -> str | None:
        if value is None:
            return None
        if isinstance(value, dict):
            value = value.get("answer") or value.get("correct_answer") or value.get("expected_answer") or value.get("value")
        if isinstance(value, int):
            if 0 <= value < 26:
                return chr(ord("A") + value)
            return str(value)
        text = str(value).strip()
        if not text:
            return None
        lower = text.lower()
        if lower in {"true", "t"}:
            return "True"
        if lower in {"false", "f"}:
            return "False"
        if text.isdigit():
            index = int(text)
            if 0 <= index < 26:
                return chr(ord("A") + index)
        if len(text) == 1 and text.upper() in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            return text.upper()
        # Match the stored option text back to a label when possible.
        for option in option_payload:
            if text.strip().lower() == str(option.get("text") or "").strip().lower():
                return str(option.get("label"))
        return text

    if isinstance(raw, dict):
        values = raw.get("answers") or raw.get("correct_answers") or raw.get("correct_option_indices") or raw.get("correct_option_ids")
        value = raw.get("answer") or raw.get("correct_answer") or raw.get("expected_answer")
        raw = values if values is not None else value

    if qtype == "multi_select" or isinstance(raw, list):
        values = raw if isinstance(raw, list) else [raw]
        labels = [label for label in (one(value) for value in values) if label]
        return ", ".join(labels) if labels else None
    return one(raw)


def _build_scan_grade_preview(*, answers: list[dict[str, Any]], questions: list[dict[str, Any]], exam_payload: dict[str, Any]) -> dict[str, Any]:
    """Build instructor-facing score summary from the already graded answers.

    This mirrors the normal exam result idea: objective questions have local
    points, while essay/short-answer points come from the AI grader when it
    returns an immediate result.  Anything without a score is counted as needing
    review so the instructor never sees a fake zero as a finished grade.
    """
    total_score = float(exam_payload.get("total_score") or sum(float(q.get("points") or q.get("max_score") or 0) for q in questions))
    score = 0.0
    correct_count = 0
    incorrect_count = 0
    unanswered_count = 0
    needs_review = 0
    graded_questions = 0

    for answer in answers:
        answer_type = str(answer.get("type") or "").strip().lower()
        text_answer = str(answer.get("answer_text") or answer.get("detected_answer") or "").strip()
        selected_many = answer.get("detected_answers") or answer.get("selected_option_indices") or []
        has_answer = bool(text_answer) or bool(selected_many)
        is_written = answer_type in {"short_answer", "essay"}
        points = answer.get("points_earned")
        is_correct = answer.get("is_correct")
        status = str(answer.get("status") or "").strip().lower()

        if not has_answer:
            unanswered_count += 1
            needs_review += 1
            continue

        if points is None:
            # Written questions are not fully graded until AI/teacher provides points.
            needs_review += 1
            continue

        try:
            earned = float(points or 0)
        except (TypeError, ValueError):
            earned = 0.0
        score += earned
        graded_questions += 1

        if is_correct is True:
            correct_count += 1
        elif is_correct is False or (not is_written and status in {"wrong", "incorrect"}):
            incorrect_count += 1
        elif earned > 0:
            # AI-graded essay/short-answer can be partially correct.  Count it as
            # correct in the top summary when it earned credit, while the exact
            # score remains visible on the question row.
            correct_count += 1
        else:
            incorrect_count += 1

    percentage_score = round((score / total_score) * 100, 2) if total_score else None
    objective_types = {"multiple_choice", "multi_select", "true_false"}
    return {
        "score_so_far": round(score, 2),
        "total_score": round(total_score, 2),
        "percentage_score": percentage_score,
        "graded_questions": graded_questions,
        "correct_count": correct_count,
        "incorrect_count": incorrect_count,
        "unanswered_count": unanswered_count,
        "auto_gradable_questions": sum(1 for q in questions if str(q.get("type") or "").lower() in objective_types),
        "detected_questions": sum(1 for answer in answers if str(answer.get("answer_text") or answer.get("detected_answer") or "").strip() or answer.get("detected_answers")),
        "written_questions": sum(1 for answer in answers if str(answer.get("type") or "").lower() in {"short_answer", "essay"}),
        "needs_review": needs_review,
        "ai_ready": sum(1 for answer in answers if answer.get("status") == "ai_ready" or answer.get("ai_status") == "ai_ready"),
        "ai_graded": sum(1 for answer in answers if answer.get("status") == "ai_graded" or answer.get("ai_status") == "completed"),
        "ai_pending": sum(1 for answer in answers if answer.get("ai_status") in {"pending", "sent"}),
    }


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


def _question_points(exam_question_id: Any, questions: list[dict[str, Any]]) -> float | None:
    question = _find_question(exam_question_id, None, questions)
    if not question:
        return None
    try:
        return float(question.get("points") or question.get("max_score") or 0)
    except (TypeError, ValueError):
        return None


def _safe_int(value: Any) -> int | None:
    try:
        if value is None or value == "":
            return None
        return int(str(value).strip())
    except (TypeError, ValueError):
        return None
