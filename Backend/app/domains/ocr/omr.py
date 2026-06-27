from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(slots=True)
class Bubble:
    x: int
    y: int
    r: int
    fill_ratio: float
    confidence: float


@dataclass(slots=True)
class StudentIdResult:
    value: str | None
    confidence: float
    digits: list[dict[str, Any]]
    warnings: list[str]


@dataclass(slots=True)
class ObjectiveAnswerResult:
    exam_question_id: int | None
    question_number: int
    type: str
    detected_answer: str | None
    detected_answers: list[str]
    selected_option_index: int | None
    selected_option_indices: list[int] | None
    confidence: float
    status: str
    regions: list[dict[str, Any]]


_OPTION_LABELS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


def detect_bubbles(image: Any) -> list[Bubble]:
    """Detect printed OCR bubbles quickly.

    The old implementation ran HoughCircles on full-resolution aligned pages.
    On 300-DPI photographed PDFs this could take 90+ seconds per page. This
    version caps the working image size, then rescales coordinates back to the
    original page so downstream Student-ID and objective OMR keep working.
    """
    try:
        import cv2
        import numpy as np
    except Exception:
        return []

    if image is None:
        return []

    gray_full = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    height, width = gray_full.shape[:2]

    longest = max(height, width)
    max_work_longest = 1800
    scale = 1.0
    if longest > max_work_longest:
        scale = max_work_longest / float(longest)
        gray = cv2.resize(gray_full, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    else:
        gray = gray_full

    gray = cv2.medianBlur(gray, 5)
    work_h, work_w = gray.shape[:2]
    min_radius = max(5, int(min(work_w, work_h) * 0.003))
    max_radius = max(12, int(min(work_w, work_h) * 0.012))

    circles = cv2.HoughCircles(
        gray,
        cv2.HOUGH_GRADIENT,
        dp=1.35,
        minDist=max(14, min_radius * 3),
        param1=75,
        param2=18,
        minRadius=min_radius,
        maxRadius=max_radius,
    )

    if circles is None:
        return []

    binary_full = cv2.adaptiveThreshold(
        gray_full,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV,
        31,
        9,
    )

    bubbles: list[Bubble] = []
    inv_scale = 1.0 / scale
    for raw in np.round(circles[0, :]).astype("int"):
        x = int(round(float(raw[0]) * inv_scale))
        y = int(round(float(raw[1]) * inv_scale))
        r = max(3, int(round(float(raw[2]) * inv_scale)))
        if x - r < 0 or y - r < 0 or x + r >= width or y + r >= height:
            continue

        mask = np.zeros(binary_full.shape, dtype="uint8")
        inner = max(2, int(r * 0.62))
        cv2.circle(mask, (x, y), inner, 255, -1)
        dark_pixels = cv2.countNonZero(cv2.bitwise_and(binary_full, binary_full, mask=mask))
        area = max(1, cv2.countNonZero(mask))
        fill_ratio = float(dark_pixels) / float(area)
        confidence = min(99.0, abs(fill_ratio - 0.21) * 420.0)
        bubbles.append(Bubble(x=x, y=y, r=r, fill_ratio=fill_ratio, confidence=round(confidence, 2)))

    bubbles.sort(key=lambda b: (b.y, b.x))
    deduped: list[Bubble] = []
    for bubble in bubbles:
        duplicate = False
        for kept in deduped:
            if abs(kept.x - bubble.x) <= max(5, bubble.r // 2) and abs(kept.y - bubble.y) <= max(5, bubble.r // 2):
                duplicate = True
                if bubble.confidence > kept.confidence:
                    kept.x, kept.y, kept.r = bubble.x, bubble.y, bubble.r
                    kept.fill_ratio, kept.confidence = bubble.fill_ratio, bubble.confidence
                break
        if not duplicate:
            deduped.append(bubble)
    return deduped

def read_student_id(image: Any, bubbles: list[Bubble], digits: int = 6) -> StudentIdResult:
    height, width = image.shape[:2]
    # Header region printed by the new PDF template. It intentionally sits on the
    # right to avoid colliding with question bubbles.
    region = [
        b for b in bubbles
        if b.x > width * 0.42 and b.y < height * 0.34
    ]
    if len(region) < digits * 5:
        return StudentIdResult(value=None, confidence=0.0, digits=[], warnings=["Student ID bubble grid was not detected."])

    rows = _group_rows(region, tolerance=max(14, int(height * 0.006)))
    rows = [sorted(row, key=lambda b: b.x) for row in rows if len(row) >= 8]
    rows = sorted(rows, key=lambda row: sum(b.y for b in row) / len(row))[:digits]

    if len(rows) < digits:
        return StudentIdResult(value=None, confidence=0.0, digits=[], warnings=["Student ID bubble rows are incomplete."])

    values: list[str] = []
    digit_payloads: list[dict[str, Any]] = []
    confidences: list[float] = []
    warnings: list[str] = []

    for row_index, row in enumerate(rows):
        cols = sorted(row, key=lambda b: b.x)[:10]
        ranked = sorted(enumerate(cols), key=lambda item: item[1].fill_ratio, reverse=True)
        selected_index, selected = ranked[0]
        second_ratio = ranked[1][1].fill_ratio if len(ranked) > 1 else 0.0
        margin = selected.fill_ratio - second_ratio
        is_marked = selected.fill_ratio >= 0.26 and margin >= 0.045
        confidence = min(99.0, max(0.0, (selected.fill_ratio - 0.18) * 360.0 + margin * 520.0))

        if not is_marked:
            values.append("?")
            warnings.append(f"Student ID digit {row_index + 1} is ambiguous.")
        else:
            values.append(str(selected_index))
        confidences.append(confidence)
        digit_payloads.append({
            "position": row_index + 1,
            "value": str(selected_index) if is_marked else None,
            "confidence": round(confidence, 2),
            "fill_ratio": round(selected.fill_ratio, 4),
            "region": _region(selected),
        })

    value = "".join(values) if all(v != "?" for v in values) else None
    overall = round(sum(confidences) / len(confidences), 2) if confidences else 0.0
    return StudentIdResult(value=value, confidence=overall, digits=digit_payloads, warnings=warnings)


def extract_objective_answers(
    *,
    image: Any,
    bubbles: list[Bubble],
    questions: list[dict[str, Any]],
    student_digits: int = 6,
) -> list[ObjectiveAnswerResult]:
    height, width = image.shape[:2]
    answer_bubbles = [
        b for b in bubbles
        if not (b.x > width * 0.42 and b.y < height * 0.34)
        and b.y > height * 0.12
    ]
    rows = _group_rows(answer_bubbles, tolerance=max(14, int(height * 0.006)))
    rows = [sorted(row, key=lambda b: b.x) for row in rows]
    rows = sorted(rows, key=lambda row: sum(b.y for b in row) / len(row))

    results: list[ObjectiveAnswerResult] = []
    cursor = 0
    objective_questions = [q for q in questions if _normal_type(q.get("type")) in {"multiple_choice", "multi_select", "true_false"}]

    for question_index, question in enumerate(objective_questions, start=1):
        qtype = _normal_type(question.get("type"))
        option_count = _option_count(question)
        exam_question_id = _safe_int(question.get("exam_question_id"))
        question_number = _safe_int(question.get("question_number")) or question_index

        if qtype == "true_false":
            needed_rows = 1
            needed_bubbles = 2
        else:
            needed_rows = option_count
            needed_bubbles = 1

        consumed: list[list[Bubble]] = []
        while cursor < len(rows) and len(consumed) < needed_rows:
            row = rows[cursor]
            cursor += 1
            if qtype == "true_false":
                if len(row) >= 2:
                    consumed.append(row[:2])
            else:
                if len(row) >= 1:
                    consumed.append([row[0]])

        if len(consumed) < needed_rows:
            results.append(ObjectiveAnswerResult(
                exam_question_id=exam_question_id,
                question_number=question_number,
                type=qtype,
                detected_answer=None,
                detected_answers=[],
                selected_option_index=None,
                selected_option_indices=None,
                confidence=0.0,
                status="needs_review",
                regions=[],
            ))
            continue

        flat = [bubble for row in consumed for bubble in row[:needed_bubbles]]
        selected_indices = _select_bubbles(flat if qtype == "true_false" else [row[0] for row in consumed], allow_multiple=qtype == "multi_select")
        labels = [_OPTION_LABELS[i] for i in selected_indices if i < len(_OPTION_LABELS)]
        if qtype == "true_false":
            labels = ["true" if i == 0 else "false" for i in selected_indices]

        confidence = _answer_confidence(flat, selected_indices)
        status = "detected" if labels and confidence >= 62 else "needs_review"
        results.append(ObjectiveAnswerResult(
            exam_question_id=exam_question_id,
            question_number=question_number,
            type=qtype,
            detected_answer=labels[0] if len(labels) == 1 else None,
            detected_answers=labels,
            selected_option_index=selected_indices[0] if len(selected_indices) == 1 and qtype != "multi_select" else None,
            selected_option_indices=selected_indices if qtype == "multi_select" else None,
            confidence=round(confidence, 2),
            status=status,
            regions=[_region(b) for b in flat],
        ))

    return results


def _select_bubbles(bubbles: list[Bubble], *, allow_multiple: bool) -> list[int]:
    if not bubbles:
        return []
    if allow_multiple:
        return [index for index, bubble in enumerate(bubbles) if bubble.fill_ratio >= 0.27]

    ranked = sorted(enumerate(bubbles), key=lambda item: item[1].fill_ratio, reverse=True)
    selected_index, selected = ranked[0]
    second_ratio = ranked[1][1].fill_ratio if len(ranked) > 1 else 0.0
    if selected.fill_ratio >= 0.26 and selected.fill_ratio - second_ratio >= 0.04:
        return [selected_index]
    return []


def _answer_confidence(bubbles: list[Bubble], selected_indices: list[int]) -> float:
    if not bubbles or not selected_indices:
        return 0.0
    ratios = [b.fill_ratio for b in bubbles]
    selected = max(ratios[i] for i in selected_indices if i < len(ratios))
    unselected = [ratio for index, ratio in enumerate(ratios) if index not in selected_indices]
    next_ratio = max(unselected) if unselected else 0.0
    margin = selected - next_ratio
    return min(99.0, max(0.0, (selected - 0.18) * 350.0 + margin * 550.0))


def _group_rows(bubbles: list[Bubble], tolerance: int) -> list[list[Bubble]]:
    rows: list[list[Bubble]] = []
    for bubble in sorted(bubbles, key=lambda b: b.y):
        placed = False
        for row in rows:
            row_y = sum(item.y for item in row) / len(row)
            if abs(row_y - bubble.y) <= tolerance:
                row.append(bubble)
                placed = True
                break
        if not placed:
            rows.append([bubble])
    return rows


def _normal_type(value: Any) -> str:
    return str(value or "").strip().lower()


def _option_count(question: dict[str, Any]) -> int:
    if _normal_type(question.get("type")) == "true_false":
        return 2
    options = question.get("options")
    if isinstance(options, list) and options:
        return len(options)
    if isinstance(options, dict):
        for key in ("options", "choices", "answers"):
            value = options.get(key)
            if isinstance(value, list) and value:
                return len(value)
    return 4


def _safe_int(value: Any) -> int | None:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _region(bubble: Bubble) -> dict[str, int | float]:
    size = bubble.r * 2
    return {
        "x": int(bubble.x - bubble.r),
        "y": int(bubble.y - bubble.r),
        "w": int(size),
        "h": int(size),
        "fill_ratio": round(bubble.fill_ratio, 4),
    }



def extract_objective_answers_from_pages(
    *,
    pages: list[dict[str, Any]],
    questions: list[dict[str, Any]],
) -> list[ObjectiveAnswerResult]:
    """Read objective answers once across all non-cover pages in print order.

    Learnova OCR exports add a dedicated cover page that contains the QR code,
    instructions, and the Student-ID grid.  The previous implementation streamed
    every detected circle from every page.  On real photographed scans this made
    the QR/instruction/student-ID circles on page 1 become Q1/Q2 answers, and it
    also picked circular letters inside the option text instead of the actual
    answer bubble.

    This implementation builds a cleaner stream of answer-bubble rows:
    - skip the generated OCR cover page when there are multiple pages;
    - merge Hough-circle candidates with contour candidates so filled bubbles
      are still seen even when Hough no longer sees a ring;
    - choose the stable option-bubble column instead of the left-most circle in
      each row;
    - compute fill using the inner bubble area and saturated/dark ink, so blue
      pen marks count as filled while the printed outline does not.
    """
    objective_questions = [
        q for q in questions
        if _normal_type(q.get("type")) in {"multiple_choice", "multi_select", "true_false"}
    ]
    expected_choice_rows = sum(
        _option_count(q)
        for q in objective_questions
        if _normal_type(q.get("type")) in {"multiple_choice", "multi_select"}
    )

    choice_rows = _build_choice_option_row_stream(pages=pages, expected_rows=expected_choice_rows)
    true_false_rows = _build_true_false_row_stream(pages=pages)
    choice_cursor = 0
    tf_cursor = 0
    results: list[ObjectiveAnswerResult] = []

    for question_index, question in enumerate(objective_questions, start=1):
        qtype = _normal_type(question.get("type"))
        option_count = _option_count(question)
        exam_question_id = _safe_int(question.get("exam_question_id"))
        question_number = _safe_int(question.get("question_number")) or question_index

        if qtype == "true_false":
            if tf_cursor >= len(true_false_rows):
                results.append(_missing_objective_result(
                    exam_question_id=exam_question_id,
                    question_number=question_number,
                    qtype=qtype,
                ))
                continue
            page_number, bubbles_for_question = true_false_rows[tf_cursor]
            tf_cursor += 1
            selected_pool = bubbles_for_question[:2]
            selected_indices = _select_bubbles(selected_pool, allow_multiple=False)
            labels = ["true" if i == 0 else "false" for i in selected_indices]
            regions = []
            for bubble in selected_pool:
                region = _region(bubble)
                region["page_number"] = page_number
                regions.append(region)
            confidence = _answer_confidence(selected_pool, selected_indices)
        else:
            consumed: list[tuple[int, Bubble]] = []
            while choice_cursor < len(choice_rows) and len(consumed) < option_count:
                consumed.append(choice_rows[choice_cursor])
                choice_cursor += 1

            if len(consumed) < option_count:
                results.append(_missing_objective_result(
                    exam_question_id=exam_question_id,
                    question_number=question_number,
                    qtype=qtype,
                ))
                continue

            selected_pool = [bubble for _, bubble in consumed]
            selected_indices = _select_bubbles(selected_pool, allow_multiple=qtype == "multi_select")
            labels = [_OPTION_LABELS[i] for i in selected_indices if i < len(_OPTION_LABELS)]
            regions = []
            for page_number, bubble in consumed:
                region = _region(bubble)
                region["page_number"] = page_number
                regions.append(region)
            confidence = _answer_confidence(selected_pool, selected_indices)

        status = "detected" if labels and confidence >= 50 else "needs_review"
        results.append(ObjectiveAnswerResult(
            exam_question_id=exam_question_id,
            question_number=question_number,
            type=qtype,
            detected_answer=labels[0] if len(labels) == 1 else None,
            detected_answers=labels,
            selected_option_index=selected_indices[0] if len(selected_indices) == 1 and qtype != "multi_select" else None,
            selected_option_indices=selected_indices if qtype == "multi_select" else None,
            confidence=round(confidence, 2),
            status=status,
            regions=regions,
        ))

    return results


def _missing_objective_result(*, exam_question_id: int | None, question_number: int, qtype: str) -> ObjectiveAnswerResult:
    return ObjectiveAnswerResult(
        exam_question_id=exam_question_id,
        question_number=question_number,
        type=qtype,
        detected_answer=None,
        detected_answers=[],
        selected_option_index=None,
        selected_option_indices=None,
        confidence=0.0,
        status="needs_review",
        regions=[],
    )


def _build_choice_option_row_stream(*, pages: list[dict[str, Any]], expected_rows: int) -> list[tuple[int, Bubble]]:
    rows: list[tuple[int, Bubble]] = []
    for page in _answer_pages(pages):
        image = page.get("image")
        if image is None:
            continue
        page_rows = _choice_rows_for_page(
            image=image,
            bubbles=page.get("bubbles") or [],
            expected_rows=max(1, expected_rows),
        )
        page_number = int(page.get("page_number") or 0)
        rows.extend((page_number, bubble) for bubble in page_rows)
    return rows


def _build_true_false_row_stream(*, pages: list[dict[str, Any]]) -> list[tuple[int, list[Bubble]]]:
    rows: list[tuple[int, list[Bubble]]] = []
    for page in _answer_pages(pages):
        image = page.get("image")
        if image is None:
            continue
        height, width = image.shape[:2]
        candidates = [
            b for b in _objective_bubble_candidates(image=image, hough_bubbles=page.get("bubbles") or [])
            if b.y > height * 0.10 and b.y < height * 0.92 and b.x > width * 0.38
        ]
        grouped = _group_rows(candidates, tolerance=max(18, int(height * 0.007)))
        page_number = int(page.get("page_number") or 0)
        min_radius = _minimum_answer_radius(candidates, image=image)
        for row in grouped:
            strong = [b for b in row if b.r >= min_radius]
            if len(strong) < 2:
                continue
            # True/False is rendered as two bubbles on the same row.  Keep the
            # two strongest/most circular candidates and return them left-to-right.
            selected = sorted(strong, key=lambda b: (b.r, b.confidence), reverse=True)[:2]
            selected = sorted(selected, key=lambda b: b.x)
            rows.append((page_number, selected))
    rows.sort(key=lambda item: (item[0], sum(b.y for b in item[1]) / max(1, len(item[1]))))
    return rows


def _answer_pages(pages: list[dict[str, Any]]) -> list[dict[str, Any]]:
    ordered = sorted(pages, key=lambda p: int(p.get("page_number") or 0))
    if len(ordered) <= 1:
        return ordered

    first = ordered[0]
    first_page_number = int(first.get("page_number") or 0)
    first_bubble_count = len(first.get("bubbles") or [])
    looks_like_learnova_cover = (
        bool(first.get("qr_detected"))
        or (first_page_number == 1 and first_bubble_count >= 80)
    )
    if not looks_like_learnova_cover:
        return ordered

    # Learnova OCR exports deliberately put QR/instructions/Student-ID on page 1.
    # Skipping it avoids treating those circles as Q1 answers.  If the uploaded
    # file does not look like that cover page, keep page 1 so non-cover scans are
    # still analysable.
    return [p for p in ordered if int(p.get("page_number") or 0) != first_page_number]


def _choice_rows_for_page(*, image: Any, bubbles: list[Bubble], expected_rows: int) -> list[Bubble]:
    height, width = image.shape[:2]
    candidates = [
        b for b in _objective_bubble_candidates(image=image, hough_bubbles=bubbles)
        if b.y > height * 0.10
        and b.y < height * 0.92
        and b.x > width * 0.025
        and b.x < width * 0.35
    ]
    if not candidates:
        return []

    cluster = _select_answer_column(candidates=candidates, width=width, expected_rows=expected_rows)
    if not cluster:
        return []

    row_tolerance = max(18, int(height * 0.007))
    grouped = _group_rows(cluster, tolerance=row_tolerance)
    grouped = [sorted(row, key=lambda b: b.x) for row in grouped]
    grouped.sort(key=lambda row: sum(b.y for b in row) / len(row))

    min_radius = max(8.0, _median([b.r for b in cluster]) * 0.55)
    rows: list[Bubble] = []
    for row in grouped:
        strongest = max(row, key=lambda b: (b.r, b.fill_ratio, b.confidence))
        if strongest.r < min_radius:
            continue
        rows.append(strongest)

    if expected_rows > 0 and len(rows) > expected_rows:
        rows = _best_choice_row_window(rows=rows, expected_rows=expected_rows)
    return rows


def _select_answer_column(*, candidates: list[Bubble], width: int, expected_rows: int) -> list[Bubble]:
    if not candidates:
        return []
    tolerance = max(42.0, width * 0.025)
    clusters: list[list[Bubble]] = []
    for bubble in sorted(candidates, key=lambda b: b.x):
        placed = False
        for cluster in clusters:
            if abs(_median([b.x for b in cluster]) - bubble.x) <= tolerance:
                cluster.append(bubble)
                placed = True
                break
        if not placed:
            clusters.append([bubble])

    target_x = width * 0.11
    penalty_scale = max(45.0, width * 0.018)
    best_cluster: list[Bubble] = []
    best_score = float("-inf")
    for cluster in clusters:
        median_x = _median([b.x for b in cluster])
        median_r = _median([b.r for b in cluster])
        row_count = len(_group_rows(cluster, tolerance=max(18, int(width * 0.006))))
        # The real answer column has the biggest printed-circle radius and sits
        # just to the right of A/B/C/D labels.  Text letters can form many small
        # fake circles, so radius and expected row count matter more than raw count.
        score = min(row_count, max(1, expected_rows)) * 2.0 + median_r * 1.5 - abs(median_x - target_x) / penalty_scale
        if score > best_score:
            best_score = score
            best_cluster = cluster
    return best_cluster


def _best_choice_row_window(*, rows: list[Bubble], expected_rows: int) -> list[Bubble]:
    if expected_rows <= 0 or len(rows) <= expected_rows:
        return rows
    best_start = 0
    best_score = float("-inf")
    for start in range(0, len(rows) - expected_rows + 1):
        window = rows[start:start + expected_rows]
        gaps = [window[i + 1].y - window[i].y for i in range(len(window) - 1)]
        if not gaps:
            score = 0.0
        else:
            median_gap = _median(gaps)
            regularity = -sum(abs(gap - median_gap) for gap in gaps) / max(1, len(gaps))
            # Prefer windows with real marked/blank bubble candidates over text-only
            # artifacts by rewarding radius and at least one confident mark.
            score = regularity + _median([b.r for b in window]) * 1.5 + max(b.fill_ratio for b in window) * 30.0
        if score > best_score:
            best_score = score
            best_start = start
    return rows[best_start:best_start + expected_rows]


def _objective_bubble_candidates(*, image: Any, hough_bubbles: list[Bubble]) -> list[Bubble]:
    candidates: list[Bubble] = []
    for bubble in hough_bubbles:
        if bubble.r < 8:
            continue
        candidates.append(Bubble(
            x=int(bubble.x),
            y=int(bubble.y),
            r=int(bubble.r),
            fill_ratio=round(_ink_fill_ratio(image=image, x=bubble.x, y=bubble.y, r=bubble.r), 4),
            confidence=float(bubble.confidence),
        ))
    candidates.extend(_contour_bubble_candidates(image))
    return _dedupe_bubble_candidates(candidates)


def _contour_bubble_candidates(image: Any) -> list[Bubble]:
    try:
        import cv2
        import numpy as np
    except Exception:
        return []
    if image is None:
        return []

    height, width = image.shape[:2]
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image.copy()
    blur = cv2.GaussianBlur(gray, (3, 3), 0)
    binary = cv2.adaptiveThreshold(
        blur,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV,
        35,
        9,
    )
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    results: list[Bubble] = []
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        if w <= 0 or h <= 0:
            continue
        if y < height * 0.06 or y > height * 0.92:
            continue
        if w < 18 or h < 18 or w > 130 or h > 130:
            continue
        aspect = w / max(1, h)
        if aspect < 0.55 or aspect > 1.75:
            continue
        area = float(cv2.contourArea(contour))
        box_area = float(w * h)
        if box_area <= 0 or area / box_area < 0.08:
            continue
        perimeter = float(cv2.arcLength(contour, True))
        circularity = (4.0 * float(np.pi) * area / (perimeter * perimeter)) if perimeter > 0 else 0.0
        if circularity < 0.25:
            continue
        radius = max(w, h) // 2
        cx = x + w // 2
        cy = y + h // 2
        fill_ratio = _ink_fill_ratio(image=image, x=cx, y=cy, r=radius)
        confidence = min(99.0, max(0.0, fill_ratio * 90.0 + circularity * 20.0))
        results.append(Bubble(
            x=int(cx),
            y=int(cy),
            r=int(radius),
            fill_ratio=round(float(fill_ratio), 4),
            confidence=round(float(confidence), 2),
        ))
    return results


def _ink_fill_ratio(*, image: Any, x: int, y: int, r: int) -> float:
    """Measure student ink inside the bubble, ignoring the printed outline.

    Blue/purple pen marks are often missed by grayscale-only thresholding.  We
    therefore count either dark pixels or saturated blue/purple pixels inside the
    inner 55% of the circle.  Blank bubbles remain near zero because the border
    is outside the measured inner area.
    """
    try:
        import cv2
        import numpy as np
    except Exception:
        return 0.0
    if image is None or r <= 0:
        return 0.0

    height, width = image.shape[:2]
    x1 = max(0, int(x - r))
    y1 = max(0, int(y - r))
    x2 = min(width, int(x + r + 1))
    y2 = min(height, int(y + r + 1))
    if x2 <= x1 or y2 <= y1:
        return 0.0

    crop = image[y1:y2, x1:x2]
    if crop.size == 0:
        return 0.0
    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY) if len(crop.shape) == 3 else crop.copy()
    if len(crop.shape) == 3:
        hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
        saturated_ink = (hsv[:, :, 1] > 45) & (hsv[:, :, 2] < 230)
    else:
        saturated_ink = np.zeros(gray.shape, dtype=bool)
    dark_ink = gray < 150
    marked = (dark_ink | saturated_ink).astype("uint8") * 255

    mask = np.zeros(gray.shape, dtype="uint8")
    cv2.circle(mask, (int(x - x1), int(y - y1)), max(3, int(r * 0.55)), 255, -1)
    area = cv2.countNonZero(mask)
    if area <= 0:
        return 0.0
    ink_pixels = cv2.countNonZero(cv2.bitwise_and(marked, marked, mask=mask))
    return float(ink_pixels) / float(area)


def _dedupe_bubble_candidates(candidates: list[Bubble]) -> list[Bubble]:
    kept: list[Bubble] = []
    for bubble in sorted(candidates, key=lambda b: (b.r, b.fill_ratio, b.confidence), reverse=True):
        duplicate = False
        for existing in kept:
            if abs(existing.x - bubble.x) <= max(16, int(max(existing.r, bubble.r) * 0.75)) and abs(existing.y - bubble.y) <= max(16, int(max(existing.r, bubble.r) * 0.75)):
                duplicate = True
                break
        if not duplicate:
            kept.append(bubble)
    kept.sort(key=lambda b: (b.y, b.x))
    return kept


def _minimum_answer_radius(candidates: list[Bubble], *, image: Any) -> float:
    if candidates:
        return max(8.0, _median([b.r for b in candidates]) * 0.55)
    try:
        height, width = image.shape[:2]
        return max(8.0, min(height, width) * 0.003)
    except Exception:
        return 8.0


def _median(values: list[Any]) -> float:
    nums = sorted(float(value) for value in values if value is not None)
    if not nums:
        return 0.0
    mid = len(nums) // 2
    if len(nums) % 2:
        return nums[mid]
    return (nums[mid - 1] + nums[mid]) / 2.0
