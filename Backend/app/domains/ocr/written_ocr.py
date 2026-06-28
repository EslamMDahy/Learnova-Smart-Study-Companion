from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from app.core.config import settings

from .handwriting import read_handwritten_answer
from .service import normalise_lang


@dataclass(slots=True)
class WrittenAnswerResult:
    exam_question_id: int | None
    question_number: int
    type: str
    answer_text: str
    confidence: float
    status: str
    region: dict[str, int] | None
    ai_grading_payload: dict[str, Any]
    crop_image: Any | None = None


def _debug_enabled() -> bool:
    return str(os.getenv("OCR_DEBUG_WRITTEN", os.getenv("OCR_DEBUG_SAVE_CROPS", "false"))).strip().lower() in {"1", "true", "yes", "on"}


def _debug(message: str) -> None:
    if _debug_enabled():
        print(f"[OCR_DEBUG][written] {message}", flush=True)


def _debug_dir() -> Path:
    out_dir = Path(os.getenv("OCR_DEBUG_CROP_DIR", "ocr_debug_crops"))
    out_dir.mkdir(parents=True, exist_ok=True)
    return out_dir


def _save_debug_image(name: str, image: Any) -> None:
    if str(os.getenv("OCR_DEBUG_SAVE_CROPS", "false")).strip().lower() not in {"1", "true", "yes", "on"}:
        return
    try:
        import cv2
        path = _debug_dir() / name
        cv2.imwrite(str(path), image)
        _debug(f"saved_image={path}")
    except Exception as exc:
        _debug(f"save_image_failed name={name} error={exc}")


def _ink_stats(image: Any) -> dict[str, Any]:
    try:
        import cv2
        import numpy as np
        if image is None:
            return {"shape": None, "dark_ratio": 0.0, "ink_bbox": None}
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image.copy()
        blur = cv2.GaussianBlur(gray, (3, 3), 0)
        _, binary = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        # Remove the obvious printed border so the number reflects handwriting/ink inside.
        h, w = binary.shape[:2]
        mask = binary.copy()
        border = max(4, min(h, w) // 80)
        mask[:border, :] = 0
        mask[-border:, :] = 0
        mask[:, :border] = 0
        mask[:, -border:] = 0
        ys, xs = np.where(mask > 0)
        bbox = None
        if len(xs) and len(ys):
            bbox = (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
        return {
            "shape": tuple(int(v) for v in image.shape[:2]),
            "dark_ratio": round(float(np.count_nonzero(mask)) / float(mask.size or 1), 5),
            "ink_pixels": int(np.count_nonzero(mask)),
            "ink_bbox": bbox,
        }
    except Exception as exc:
        return {"error": str(exc)}


def extract_written_answers(
    *,
    image: Any,
    questions: list[dict[str, Any]],
    lang: str,
) -> list[WrittenAnswerResult]:
    """Crop written answer boxes and read student handwriting."""
    lang = normalise_lang(lang)
    regions = _detect_written_regions(image)
    written_questions = [
        q for q in questions
        if str(q.get("type") or "").strip().lower() in {"short_answer", "essay"}
    ]
    _debug(f"single_page written_questions={len(written_questions)} regions={regions}")

    results: list[WrittenAnswerResult] = []
    for index, question in enumerate(written_questions):
        qn = _safe_int(question.get("question_number")) or (index + 1)
        region = regions[index] if index < len(regions) else None
        if region is None:
            text = ""
            raw_text = ""
            confidence = 0.0
            status = "needs_review"
            engine = "answer_box_not_detected"
            _debug(f"q{qn}: no_region")
        else:
            crop = _crop(image, region)
            _debug(f"q{qn}: selected_region={region} crop_stats={_ink_stats(crop)}")
            _save_debug_image(f"q{qn}_answer_crop.png", crop)
            ocr = read_handwritten_answer(crop=crop, question=question, lang=lang)
            text = ocr.text
            raw_text = ocr.raw_text
            confidence = ocr.confidence
            engine = ocr.engine
            if _looks_like_wrong_crop(text) or _looks_like_wrong_crop(raw_text):
                _debug(f"q{qn}: wrong_crop_rejected engine={engine} raw={raw_text!r} clean={text!r}")
                text = ""
                confidence = 0.0
                status = "needs_review"
                engine = f"{engine}_wrong_crop_rejected"
            else:
                status = "ai_ready" if text.strip() and confidence >= 35 else "needs_review"
            _debug(f"q{qn}: final engine={engine} conf={confidence} status={status} raw={raw_text!r} clean={text!r}")

        payload = build_ai_grading_payload(
            question=question,
            answer_text=text,
            raw_ocr_text=raw_text,
            ocr_engine=engine,
            region=region,
            confidence=confidence,
        )
        results.append(WrittenAnswerResult(
            exam_question_id=_safe_int(question.get("exam_question_id")),
            question_number=qn,
            type=str(question.get("type") or "written"),
            answer_text=text,
            confidence=round(confidence, 2),
            status=status,
            region=region,
            ai_grading_payload=payload,
            crop_image=crop if region is not None else None,
        ))

    return results


def build_ai_grading_payload(
    *,
    question: dict[str, Any],
    answer_text: str,
    raw_ocr_text: str = "",
    ocr_engine: str = "unknown",
    region: dict[str, int] | None,
    confidence: float,
) -> dict[str, Any]:
    return {
        "operation_type": "exam_written_answer_grading",
        "exam_question_id": question.get("exam_question_id"),
        "question_id": question.get("question_id"),
        "question_type": question.get("type"),
        "question_text": question.get("question_text"),
        "expected_answer": question.get("expected_answer"),
        "grading_rubric": question.get("grading_rubric"),
        "max_score": question.get("points") or question.get("max_score"),
        "student_answer_text": answer_text,
        "raw_ocr_text": raw_ocr_text,
        "ocr_engine": ocr_engine,
        "ocr_confidence": round(confidence, 2),
        "answer_region": region,
        "review_policy": (
            "Grade the student_answer_text. Use raw_ocr_text only as OCR context. "
            "Return needs_review=true when OCR ambiguity changes the meaning."
        ),
    }


def _detect_written_regions(image: Any) -> list[dict[str, int]]:
    """Detect printed answer boxes, not arbitrary page text."""
    try:
        import cv2
    except Exception as exc:
        _debug(f"detect_regions_import_failed error={exc}")
        return []

    if image is None:
        _debug("detect_regions: image=None")
        return []

    height, width = image.shape[:2]
    _debug(f"detect_regions: image_shape={(height, width)}")
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image.copy()

    gray = cv2.GaussianBlur(gray, (3, 3), 0)
    binary = cv2.adaptiveThreshold(
        gray,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV,
        35,
        11,
    )

    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (max(36, width // 7), 1))
    v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, max(24, height // 28)))
    horizontal = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel, iterations=1)
    vertical = cv2.morphologyEx(binary, cv2.MORPH_OPEN, v_kernel, iterations=1)
    lines = cv2.add(horizontal, vertical)
    lines = cv2.dilate(lines, cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5)), iterations=1)
    lines = cv2.morphologyEx(lines, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_RECT, (17, 17)), iterations=1)
    _save_debug_image("detect_binary.png", binary)
    _save_debug_image("detect_lines.png", lines)

    contours, _ = cv2.findContours(lines, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    _debug(f"detect_regions: border_contours={len(contours)}")
    candidates: list[dict[str, int | float | str]] = []
    rejected: list[str] = []
    page_area = float(width * height)

    for idx, contour in enumerate(contours):
        x, y, w, h = cv2.boundingRect(contour)
        if w <= 0 or h <= 0:
            continue
        area = float(w * h)
        aspect = w / max(1, h)
        border_score = _answer_box_border_score(binary, x, y, w, h)
        reason = None
        if w < width * 0.50:
            reason = "too_narrow"
        elif h < height * 0.045:
            reason = "too_short"
        elif h > height * 0.40:
            reason = "too_tall"
        elif y < height * 0.08:
            reason = "too_high"
        elif area < page_area * 0.018:
            reason = "area_small"
        elif area > page_area * 0.45:
            reason = "area_large"
        elif aspect < 2.0:
            reason = "aspect_low"
        elif border_score < 0.23:
            reason = "border_low"

        msg = f"#{idx} box=({x},{y},{w},{h}) aspect={aspect:.2f} area={area/page_area:.4f} border={border_score:.3f}"
        if reason:
            rejected.append(f"reject_{reason} {msg}")
            continue
        candidates.append({"x": int(x), "y": int(y), "w": int(w), "h": int(h), "score": float(border_score), "source": "border_box"})
        _debug(f"accept_border {msg}")

    for line in rejected[:12]:
        _debug(line)
    if len(rejected) > 12:
        _debug(f"... {len(rejected) - 12} more rejected border contours")

    if not candidates:
        edges = cv2.Canny(gray, 60, 180)
        edges = cv2.dilate(edges, cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3)), iterations=1)
        _save_debug_image("detect_edges.png", edges)
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        _debug(f"detect_regions: edge_contours={len(contours)}")
        edge_rejected: list[str] = []
        for idx, contour in enumerate(contours):
            x, y, w, h = cv2.boundingRect(contour)
            area = float(w * h)
            aspect = w / max(1, h)
            peri = cv2.arcLength(contour, True)
            approx = cv2.approxPolyDP(contour, 0.03 * peri, True)
            border_score = _answer_box_border_score(binary, x, y, w, h)
            reason = None
            if w < width * 0.55:
                reason = "too_narrow"
            elif h < height * 0.05:
                reason = "too_short"
            elif h > height * 0.38:
                reason = "too_tall"
            elif y < height * 0.10:
                reason = "too_high"
            elif area < page_area * 0.02:
                reason = "area_small"
            elif area > page_area * 0.45:
                reason = "area_large"
            elif len(approx) < 4 or len(approx) > 10:
                reason = f"approx_{len(approx)}"
            elif border_score < 0.17:
                reason = "border_low"
            msg = f"#{idx} box=({x},{y},{w},{h}) aspect={aspect:.2f} area={area/page_area:.4f} approx={len(approx)} border={border_score:.3f}"
            if reason:
                edge_rejected.append(f"reject_{reason} {msg}")
                continue
            candidates.append({"x": int(x), "y": int(y), "w": int(w), "h": int(h), "score": float(border_score), "source": "edge_box"})
            _debug(f"accept_edge {msg}")
        for line in edge_rejected[:12]:
            _debug(line)
        if len(edge_rejected) > 12:
            _debug(f"... {len(edge_rejected) - 12} more rejected edge contours")

    regions = _dedupe_answer_regions(candidates)
    regions.sort(key=lambda r: (int(r.get("page_number", 0)), r["y"], r["x"]))
    final_regions = [{"x": int(r["x"]), "y": int(r["y"]), "w": int(r["w"]), "h": int(r["h"])} for r in regions]
    _debug(f"detect_regions: candidates={candidates} final={final_regions}")
    return final_regions


def _answer_box_border_score(binary: Any, x: int, y: int, w: int, h: int) -> float:
    import numpy as np

    height, width = binary.shape[:2]
    pad = max(2, min(w, h) // 120)
    x1 = max(0, x)
    y1 = max(0, y)
    x2 = min(width, x + w)
    y2 = min(height, y + h)
    if x2 <= x1 + 8 or y2 <= y1 + 8:
        return 0.0

    top = binary[y1:min(y2, y1 + pad + 3), x1:x2]
    bottom = binary[max(y1, y2 - pad - 3):y2, x1:x2]
    left = binary[y1:y2, x1:min(x2, x1 + pad + 3)]
    right = binary[y1:y2, max(x1, x2 - pad - 3):x2]
    samples = [top, bottom, left, right]
    ratios = [float(np.count_nonzero(s)) / float(s.size or 1) for s in samples]
    return sum(ratios) / len(ratios)


def _dedupe_answer_regions(regions: list[dict[str, int | float | str]]) -> list[dict[str, int | float | str]]:
    kept: list[dict[str, int | float | str]] = []
    for region in sorted(regions, key=lambda r: (float(r.get("score", 0)), int(r["w"]) * int(r["h"])), reverse=True):
        rx1, ry1 = int(region["x"]), int(region["y"])
        rx2, ry2 = rx1 + int(region["w"]), ry1 + int(region["h"])
        duplicate = False
        for existing in kept:
            ex1, ey1 = int(existing["x"]), int(existing["y"])
            ex2, ey2 = ex1 + int(existing["w"]), ey1 + int(existing["h"])
            ix1, iy1 = max(rx1, ex1), max(ry1, ey1)
            ix2, iy2 = min(rx2, ex2), min(ry2, ey2)
            inter = max(0, ix2 - ix1) * max(0, iy2 - iy1)
            area = max(1, int(region["w"]) * int(region["h"]))
            earea = max(1, int(existing["w"]) * int(existing["h"]))
            if inter / min(area, earea) > 0.55:
                duplicate = True
                break
        if not duplicate:
            kept.append(region)
    return sorted(kept, key=lambda r: (int(r["y"]), int(r["x"])))


def _crop(image: Any, region: dict[str, int]):
    height, width = image.shape[:2]
    pad_x = max(10, int(region["w"] * 0.018))
    pad_y = max(10, int(region["h"] * 0.035))
    x1 = max(0, region["x"] + pad_x)
    y1 = max(0, region["y"] + pad_y)
    x2 = min(width, region["x"] + region["w"] - pad_x)
    y2 = min(height, region["y"] + region["h"] - pad_y)
    _debug(f"crop: region={region} pad=({pad_x},{pad_y}) crop_box=({x1},{y1},{x2},{y2}) page_shape={(height, width)}")
    return image[y1:y2, x1:x2]


def _is_footer_region(region: dict[str, int], image: Any) -> bool:
    """Reject footer/page-number regions that look like answer boxes after edge detection."""
    height, width = image.shape[:2]
    y = int(region.get("y", 0))
    h = int(region.get("h", 0))
    x = int(region.get("x", 0))
    w = int(region.get("w", 0))
    # Learnova pages have a long footer line + page number near the bottom. The edge
    # detector can falsely detect it as a large rectangle. These regions should never
    # be used as written answers.
    # Do not reject real lower-page essay boxes.  The second essay answer in
    # Learnova legacy sheets often starts around 65-70% of the page height and is
    # tall.  Reject only thin footer/page-number strips.
    if y > height * 0.82 and h < height * 0.16:
        return True
    if (y + h) > height * 0.965 and h < height * 0.16:
        return True
    # Bottom-wide strips are almost always footer borders, not answer boxes.
    if y > height * 0.76 and w > width * 0.60 and h < height * 0.14:
        return True
    # Right-lower blocks are commonly page number/footer crops when they are thin.
    if y > height * 0.78 and x > width * 0.30 and h < height * 0.18:
        return True
    return False


def _question_page_hint(question: dict[str, Any]) -> int | None:
    """Read a page number from any common metadata shape if the backend has it."""
    direct_keys = (
        "page_number", "answer_page", "answer_page_number", "page", "page_index",
        "template_page", "printed_page", "question_page_number",
    )
    for key in direct_keys:
        value = _safe_int(question.get(key))
        if value is not None:
            # Some metadata uses zero-based pages.
            return value + 1 if key == "page_index" and value == 0 else value

    for key in ("answer_region", "answer_box", "region", "layout", "metadata"):
        payload = question.get(key)
        if isinstance(payload, dict):
            for nested_key in direct_keys:
                value = _safe_int(payload.get(nested_key))
                if value is not None:
                    return value + 1 if nested_key == "page_index" and value == 0 else value
    return None


def _crop_answer_content(region_crop: Any, *, debug_prefix: str = "answer") -> Any:
    """If a detected region contains the printed question + answer box, keep only the box interior."""
    try:
        import cv2
        import numpy as np
    except Exception as exc:
        _debug(f"{debug_prefix}: crop_answer_content_import_failed error={exc}")
        return region_crop

    if region_crop is None or region_crop.size == 0:
        return region_crop

    gray = cv2.cvtColor(region_crop, cv2.COLOR_BGR2GRAY) if len(region_crop.shape) == 3 else region_crop.copy()
    # Detect dark horizontal/vertical ruling lines. We use binary_inv because answer box
    # borders are dark on white paper.
    blur = cv2.GaussianBlur(gray, (3, 3), 0)
    binary = cv2.adaptiveThreshold(
        blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 35, 9
    )
    h, w = binary.shape[:2]
    if h < 80 or w < 200:
        return region_crop

    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (max(80, w // 3), 1))
    horizontal = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel, iterations=1)
    # Sum rows and cluster the rows that contain long ruling lines.
    row_hits = np.where(np.count_nonzero(horizontal, axis=1) > max(80, int(w * 0.28)))[0]
    clusters: list[tuple[int, int]] = []
    if row_hits.size:
        start = prev = int(row_hits[0])
        for value in row_hits[1:]:
            value = int(value)
            if value <= prev + 3:
                prev = value
            else:
                clusters.append((start, prev))
                start = prev = value
        clusters.append((start, prev))

    # Candidate answer box interior is the largest gap between two long horizontal lines.
    best: tuple[int, int] | None = None
    best_gap = 0
    centers = [int((a + b) / 2) for a, b in clusters]
    for top, bottom in zip(centers, centers[1:]):
        gap = bottom - top
        if gap < h * 0.22:
            continue
        # Prefer the answer area under the question text, not footer lines.
        if top > h * 0.82:
            continue
        if gap > best_gap:
            best_gap = gap
            best = (top, bottom)

    if best is None:
        _debug(f"{debug_prefix}: answer_box_inner_not_found clusters={clusters[:8]} shape={(h, w)}")
        return region_crop

    top, bottom = best
    margin_y = max(8, int((bottom - top) * 0.035))
    y1 = min(h - 1, top + margin_y)
    y2 = max(y1 + 1, bottom - margin_y)

    # Use vertical lines to trim left/right border if available.
    v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, max(60, (y2 - y1) // 3)))
    vertical = cv2.morphologyEx(binary[y1:y2, :], cv2.MORPH_OPEN, v_kernel, iterations=1)
    col_hits = np.where(np.count_nonzero(vertical, axis=0) > max(40, int((y2 - y1) * 0.20)))[0]
    x1, x2 = 0, w
    if col_hits.size >= 2:
        left = int(col_hits.min())
        right = int(col_hits.max())
        if right - left > w * 0.45:
            margin_x = max(10, int((right - left) * 0.015))
            x1 = min(w - 1, left + margin_x)
            x2 = max(x1 + 1, right - margin_x)
    else:
        margin_x = max(10, int(w * 0.015))
        x1, x2 = margin_x, w - margin_x

    answer_crop = region_crop[y1:y2, x1:x2]
    _debug(
        f"{debug_prefix}: answer_box_inner crop=({x1},{y1},{x2},{y2}) "
        f"from_region_shape={(h, w)} clusters={clusters[:8]} stats={_ink_stats(answer_crop)}"
    )
    _save_debug_image(f"{debug_prefix}_answer_box_inner.png", answer_crop)
    return answer_crop



def _try_extract_written_answers_with_page_vision(
    *,
    pages: list[dict[str, Any]],
    written_questions: list[dict[str, Any]],
) -> list[WrittenAnswerResult] | None:
    """Use one local vision request to extract all written answers.

    This mode is activated with OCR_WRITTEN_EXTRACTION_MODE=vision_page and
    OCR_VISION_ENABLED=true.  It deliberately bypasses Tesseract/TrOCR for the
    written answers so scanned handwriting is not converted into garbage text.
    """
    mode = str(getattr(settings, "ocr_written_extraction_mode", "local") or "local").strip().lower()
    if mode not in {"vision", "vision_page", "ai_vision", "ollama_vision", "page_vision"}:
        return None
    if not written_questions:
        return []

    try:
        from .vision_grading import extract_written_answers_from_pages_with_vision, written_page_vision_enabled
    except Exception as exc:
        _debug(f"page_vision_import_failed error={exc!r}")
        return None if bool(getattr(settings, "ocr_vision_page_fallback_to_local_ocr", True)) else []

    if not written_page_vision_enabled():
        _debug("page_vision_requested_but_disabled; set OCR_VISION_ENABLED=true")
        return None if bool(getattr(settings, "ocr_vision_page_fallback_to_local_ocr", True)) else _empty_written_results(written_questions, engine="page_vision_disabled")

    vision_by_qn = extract_written_answers_from_pages_with_vision(pages=pages, questions=written_questions)
    if not vision_by_qn:
        _debug("page_vision_no_results")
        return None if bool(getattr(settings, "ocr_vision_page_fallback_to_local_ocr", True)) else _empty_written_results(written_questions, engine="page_vision_no_results")

    results: list[WrittenAnswerResult] = []
    for index, question in enumerate(written_questions):
        qn = _safe_int(question.get("question_number")) or (index + 1)
        item = vision_by_qn.get(qn)
        if item is None:
            text = ""
            confidence = 0.0
            status = "needs_review"
            engine = "page_vision_missing_question"
            raw_text = ""
        else:
            text = str(getattr(item, "extracted_answer", "") or "").strip()
            raw_text = text
            confidence = float(getattr(item, "confidence", 0.0) or 0.0)
            engine = str(getattr(item, "engine", "page_vision") or "page_vision")
            status = "ai_ready" if text and confidence >= 35 else "needs_review"
            if bool(getattr(item, "needs_review", False)) and not text:
                status = "needs_review"

        payload = build_ai_grading_payload(
            question=question,
            answer_text=text,
            raw_ocr_text=raw_text,
            ocr_engine=engine,
            region=None,
            confidence=confidence,
        )
        if item is not None:
            payload["vision_feedback"] = getattr(item, "feedback", None)
            payload["vision_raw_response"] = getattr(item, "raw_response", None)

        results.append(WrittenAnswerResult(
            exam_question_id=_safe_int(question.get("exam_question_id")),
            question_number=qn,
            type=str(question.get("type") or "written"),
            answer_text=text,
            confidence=round(confidence, 2),
            status=status,
            region=None,
            ai_grading_payload=payload,
            crop_image=None,
        ))

    _debug(f"page_vision_results={[{'qn': r.question_number, 'text': r.answer_text, 'conf': r.confidence} for r in results]}")
    return results


def _empty_written_results(written_questions: list[dict[str, Any]], *, engine: str) -> list[WrittenAnswerResult]:
    results: list[WrittenAnswerResult] = []
    for index, question in enumerate(written_questions):
        qn = _safe_int(question.get("question_number")) or (index + 1)
        payload = build_ai_grading_payload(
            question=question,
            answer_text="",
            raw_ocr_text="",
            ocr_engine=engine,
            region=None,
            confidence=0.0,
        )
        results.append(WrittenAnswerResult(
            exam_question_id=_safe_int(question.get("exam_question_id")),
            question_number=qn,
            type=str(question.get("type") or "written"),
            answer_text="",
            confidence=0.0,
            status="needs_review",
            region=None,
            ai_grading_payload=payload,
            crop_image=None,
        ))
    return results

def _safe_int(value: Any) -> int | None:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _looks_like_wrong_crop(text: str) -> bool:
    lowered = (text or "").lower()
    suspicious = [
        "powered by", "upload file", "community portal", "recent changes",
        "helplearn", "learnova page", "page ", "student name", "student id",
        "time allowed", "course code", "no. of questions",
    ]
    return any(token in lowered for token in suspicious)


def extract_written_answers_from_pages(
    *,
    pages: list[dict[str, Any]],
    questions: list[dict[str, Any]],
    lang: str,
) -> list[WrittenAnswerResult]:
    """Read written answers once across all pages in question order."""
    lang = normalise_lang(lang)
    written_questions = [
        q for q in questions
        if str(q.get("type") or "").strip().lower() in {"short_answer", "essay"}
    ]
    _debug(f"start: pages={len(pages)} written_questions={len(written_questions)} question_numbers={[q.get('question_number') for q in written_questions]}")

    vision_results = _try_extract_written_answers_with_page_vision(
        pages=pages,
        written_questions=written_questions,
    )
    if vision_results is not None:
        return vision_results

    # Store candidate answer regions with their page image. We intentionally skip footer
    # detections because the edge detector can see the Learnova footer/page-number strip
    # as a large rectangle; that is exactly what caused q1 to read "Page 102 / Powered by".
    region_stream: list[dict[str, Any]] = []
    sorted_pages = sorted(pages, key=lambda p: int(p.get("page_number") or 0))
    total_pages = len(sorted_pages)

    for page in sorted_pages:
        image = page.get("image")
        page_number = int(page.get("page_number") or 0)
        if image is None:
            _debug(f"page={page_number}: image=None")
            continue
        _debug(f"page={page_number}: image_shape={getattr(image, 'shape', None)}")
        _save_debug_image(f"page_{page_number}_input.png", image)
        regions = _detect_written_regions(image)
        _debug(f"page={page_number}: detected_regions={regions}")
        for idx, region in enumerate(regions):
            region_with_page = dict(region)
            region_with_page["page_number"] = page_number
            if _is_footer_region(region_with_page, image):
                _debug(f"page={page_number} region#{idx}: skip_footer region={region_with_page}")
                continue

            raw_crop = _crop(image, region)
            stats = _ink_stats(raw_crop)
            _debug(f"page={page_number} region#{idx}: region={region_with_page} stats={stats}")
            _save_debug_image(f"page_{page_number}_region_{idx}_crop.png", raw_crop)

            # Strong preference for non-cover pages. Learnova generated PDFs use page 1
            # for header/instructions/QR, while questions start on later pages.
            cover_penalty = -1000 if total_pages > 1 and page_number <= 1 else 0
            dark_ratio = float(stats.get("dark_ratio") or 0.0)
            score = cover_penalty + (dark_ratio * 100.0) - (int(region.get("y", 0)) / max(1, image.shape[0]))
            region_stream.append({
                "page_number": page_number,
                "image": image,
                "region": region_with_page,
                "stats": stats,
                "score": score,
            })

    region_stream.sort(key=lambda item: (int(item["page_number"]), int(item["region"]["y"]), int(item["region"]["x"])))
    _debug(
        "region_stream_count="
        f"{len(region_stream)} regions={[item['region'] for item in region_stream]}"
    )

    results: list[WrittenAnswerResult] = []
    used_region_ids: set[tuple[int, int, int, int, int]] = set()

    for index, question in enumerate(written_questions):
        qn = _safe_int(question.get("question_number")) or (index + 1)
        page_hint = _question_page_hint(question)

        available = [
            item for item in region_stream
            if (
                int(item["page_number"]),
                int(item["region"]["x"]),
                int(item["region"]["y"]),
                int(item["region"]["w"]),
                int(item["region"]["h"]),
            ) not in used_region_ids
        ]
        if page_hint is not None:
            hinted = [item for item in available if int(item["page_number"]) == page_hint]
            if hinted:
                available = hinted
                _debug(f"q{qn}: using_page_hint={page_hint} candidates={len(available)}")
            else:
                _debug(f"q{qn}: page_hint={page_hint} no matching detected region; fallback_candidates={len(available)}")
        else:
            # Without DB coordinates/page metadata, prefer non-cover pages if possible.
            non_cover = [item for item in available if int(item["page_number"]) > 1]
            if non_cover:
                available = non_cover
                _debug(f"q{qn}: no_page_hint prefer_non_cover candidates={len(available)}")

        # If multiple written questions exist, keep page/y order; for this exam there is
        # one candidate on page 2 after footer rejection.
        available.sort(key=lambda item: (int(item["page_number"]), int(item["region"]["y"]), int(item["region"]["x"])))
        record = available[0] if available else None

        if record is None:
            region = None
            text = ""
            raw_text = ""
            confidence = 0.0
            status = "needs_review"
            engine = "answer_box_not_detected"
            _debug(f"q{qn}: no_answer_region")
        else:
            region = dict(record["region"])
            image = record["image"]
            rid = (
                int(record["page_number"]), int(region["x"]), int(region["y"]),
                int(region["w"]), int(region["h"]),
            )
            used_region_ids.add(rid)
            crop_region = {k: int(region[k]) for k in ("x", "y", "w", "h")}
            raw_crop = _crop(image, crop_region)
            _save_debug_image(f"q{qn}_page{region.get('page_number')}_answer_region_raw.png", raw_crop)
            crop = _crop_answer_content(raw_crop, debug_prefix=f"q{qn}_page{region.get('page_number')}")
            _save_debug_image(f"q{qn}_page{region.get('page_number')}_answer_crop.png", crop)
            _debug(
                f"q{qn}: selected_region={region} raw_stats={_ink_stats(raw_crop)} "
                f"answer_stats={_ink_stats(crop)}"
            )
            ocr = read_handwritten_answer(crop=crop, question=question, lang=lang)
            text = ocr.text
            raw_text = ocr.raw_text
            confidence = ocr.confidence
            engine = ocr.engine
            if _looks_like_wrong_crop(text) or _looks_like_wrong_crop(raw_text):
                _debug(f"q{qn}: wrong_crop_rejected engine={engine} raw={raw_text!r} clean={text!r}")
                text = ""
                confidence = 0.0
                status = "needs_review"
                engine = f"{engine}_wrong_crop_rejected"
            else:
                status = "ai_ready" if text.strip() and confidence >= 35 else "needs_review"
            _debug(f"q{qn}: final engine={engine} conf={confidence} status={status} raw={raw_text!r} clean={text!r}")

        payload = build_ai_grading_payload(
            question=question,
            answer_text=text,
            raw_ocr_text=raw_text,
            ocr_engine=engine,
            region=region,
            confidence=confidence,
        )
        results.append(WrittenAnswerResult(
            exam_question_id=_safe_int(question.get("exam_question_id")),
            question_number=qn,
            type=str(question.get("type") or "written"),
            answer_text=text,
            confidence=round(confidence, 2),
            status=status,
            region=region,
            ai_grading_payload=payload,
            crop_image=crop if region is not None else None,
        ))
    return results
