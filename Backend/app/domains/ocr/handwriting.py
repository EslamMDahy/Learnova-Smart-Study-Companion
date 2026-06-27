from __future__ import annotations

import json
import os
import re
import tempfile
from dataclasses import dataclass
from difflib import SequenceMatcher
from pathlib import Path
from typing import Any

from app.core.config import settings


@dataclass(slots=True)
class HandwritingOcrResult:
    text: str
    raw_text: str
    confidence: float
    engine: str
    word_count: int


_TROCR_READER: "TrOcrReader | None" = None


def _debug_enabled() -> bool:
    return str(os.getenv("OCR_DEBUG_WRITTEN", os.getenv("OCR_DEBUG_SAVE_CROPS", "false"))).strip().lower() in {"1", "true", "yes", "on"}


def _debug(message: str) -> None:
    if _debug_enabled():
        print(f"[OCR_DEBUG][handwriting] {message}", flush=True)


def _save_debug_image(name: str, image: Any) -> None:
    if str(os.getenv("OCR_DEBUG_SAVE_CROPS", "false")).strip().lower() not in {"1", "true", "yes", "on"}:
        return
    try:
        import cv2
        out_dir = Path(os.getenv("OCR_DEBUG_CROP_DIR", "ocr_debug_crops"))
        out_dir.mkdir(parents=True, exist_ok=True)
        path = out_dir / name
        cv2.imwrite(str(path), image)
        _debug(f"saved_image={path}")
    except Exception as exc:
        _debug(f"save_image_failed name={name} error={exc}")


def read_handwritten_answer(*, crop: Any, question: dict[str, Any], lang: str = "eng") -> HandwritingOcrResult:
    """Read one written-answer crop.

    Primary engine is TrOCR because it is better suited to handwriting than
    Tesseract.  However, in local CPU setups TrOCR can occasionally return an
    empty string for a valid crop.  In that case we still run a Tesseract
    fallback and choose the better candidate instead of showing "No text
    extracted" to the instructor.
    """
    engine = str(getattr(settings, "ocr_handwriting_engine", os.getenv("OCR_HANDWRITING_ENGINE", "auto")) or "auto").strip().lower()
    if engine not in {"auto", "trocr", "tesseract"}:
        engine = "auto"
    _debug(f"read_answer start engine={engine} lang={lang} crop_shape={getattr(crop, 'shape', None)} qn={question.get('question_number')} type={question.get('type')}")

    if engine == "tesseract":
        return _read_with_tesseract(crop=crop, question=question, lang=lang)

    trocr_result: HandwritingOcrResult | None = None
    try:
        trocr_result = _read_with_trocr(crop=crop, question=question)
    except Exception as exc:
        _debug(f"trocr_exception={type(exc).__name__}: {exc}")
        trocr_result = HandwritingOcrResult(text="", raw_text="", confidence=0.0, engine="trocr_unavailable", word_count=0)
    _debug(f"trocr_result conf={trocr_result.confidence} words={trocr_result.word_count} raw={trocr_result.raw_text!r} clean={trocr_result.text!r}")

    # Do not return an empty TrOCR result when another free local OCR engine can
    # still recover a useful answer. This is important for scanned answer boxes
    # with connected handwriting or low contrast.
    if trocr_result.text.strip() and trocr_result.confidence >= 35:
        return trocr_result

    tesseract_result = _read_with_tesseract(crop=crop, question=question, lang=lang)
    _debug(f"tesseract_result engine={tesseract_result.engine} conf={tesseract_result.confidence} words={tesseract_result.word_count} raw={tesseract_result.raw_text!r} clean={tesseract_result.text!r}")
    if not trocr_result.text.strip() and tesseract_result.text.strip():
        return HandwritingOcrResult(
            text=tesseract_result.text,
            raw_text=tesseract_result.raw_text,
            confidence=max(tesseract_result.confidence, 36.0),
            engine=f"trocr_empty_{tesseract_result.engine}_fallback",
            word_count=tesseract_result.word_count,
        )

    if tesseract_result.text.strip():
        trocr_score = _ocr_candidate_score(text=trocr_result.text, confidence=trocr_result.confidence, question=question)
        tess_score = _ocr_candidate_score(text=tesseract_result.text, confidence=tesseract_result.confidence, question=question)
        if tess_score > trocr_score + 6:
            return HandwritingOcrResult(
                text=tesseract_result.text,
                raw_text=tesseract_result.raw_text,
                confidence=tesseract_result.confidence,
                engine=f"trocr_low_conf_{tesseract_result.engine}_fallback",
                word_count=tesseract_result.word_count,
            )

    return trocr_result


class TrOcrReader:
    def __init__(self) -> None:
        import torch
        from transformers import TrOCRProcessor, VisionEncoderDecoderModel

        model_name = str(getattr(settings, "ocr_trocr_model", os.getenv("OCR_TROCR_MODEL", "microsoft/trocr-base-handwritten")) or "microsoft/trocr-base-handwritten")
        _debug(f"loading_trocr_model={model_name}")
        self.processor = TrOCRProcessor.from_pretrained(model_name)
        self.model = VisionEncoderDecoderModel.from_pretrained(model_name)
        requested_device = str(getattr(settings, "ocr_trocr_device", os.getenv("OCR_TROCR_DEVICE", "auto")) or "auto").strip().lower()
        if requested_device == "cuda" and torch.cuda.is_available():
            self.device = "cuda"
        elif requested_device == "cpu":
            self.device = "cpu"
        else:
            self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.model.to(self.device)
        self.model.eval()
        self.torch = torch
        _debug(f"trocr_model_ready device={self.device}")

    def read_line(self, pil_image: Any) -> str:
        with self.torch.inference_mode():
            pixel_values = self.processor(images=pil_image, return_tensors="pt").pixel_values.to(self.device)
            generated_ids = self.model.generate(
                pixel_values,
                max_length=int(getattr(settings, "ocr_trocr_max_length", 96)),
                num_beams=int(getattr(settings, "ocr_trocr_num_beams", 4)),
            )
            text = self.processor.batch_decode(generated_ids, skip_special_tokens=True)[0]
        return _basic_clean(text)


def _get_trocr_reader() -> TrOcrReader:
    global _TROCR_READER
    if _TROCR_READER is None:
        _TROCR_READER = TrOcrReader()
    return _TROCR_READER


def _read_with_trocr(*, crop: Any, question: dict[str, Any]) -> HandwritingOcrResult:
    cv2, np = _import_cv2_numpy()
    from PIL import Image

    if crop is None or getattr(crop, "size", 0) == 0:
        return HandwritingOcrResult(text="", raw_text="", confidence=0.0, engine="trocr", word_count=0)

    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY) if len(crop.shape) == 3 else crop.copy()
    _debug(f"trocr input_gray_shape={gray.shape}")
    _save_debug_image("trocr_00_input_gray.png", gray)
    gray = _trim_answer_box_border(gray)
    _debug(f"trocr after_trim_shape={gray.shape}")
    _save_debug_image("trocr_01_after_trim.png", gray)
    gray = _crop_to_ink(gray)
    _debug(f"trocr after_crop_to_ink_shape={gray.shape}")
    _save_debug_image("trocr_02_crop_to_ink.png", gray)
    lines = _segment_handwriting_lines(gray)
    _debug(f"trocr segmented_lines={len(lines)} shapes={[getattr(line, 'shape', None) for line in lines]}")
    if not lines:
        lines = [_prepare_trocr_image(gray)]
        _debug(f"trocr fallback_single_line_shape={getattr(lines[0], 'shape', None)}")

    reader = _get_trocr_reader()
    texts: list[str] = []
    for idx, line in enumerate(lines):
        _save_debug_image(f"trocr_line_{idx}.png", line)
        pil = Image.fromarray(line).convert("RGB")
        text = reader.read_line(pil)
        _debug(f"trocr line#{idx} text={text!r}")
        if text:
            texts.append(text)

    raw_text = _basic_clean("\n".join(texts))
    _debug(f"trocr raw_joined={raw_text!r}")
    cleaned = cleanup_answer_text(raw_text, question)
    word_count = len(re.findall(r"\w+", cleaned))
    confidence = _estimate_handwriting_confidence(text=cleaned, raw_text=raw_text, question=question, engine="trocr")
    return HandwritingOcrResult(text=cleaned, raw_text=raw_text, confidence=confidence, engine="trocr", word_count=word_count)


def _read_with_tesseract(*, crop: Any, question: dict[str, Any], lang: str) -> HandwritingOcrResult:
    cv2, np = _import_cv2_numpy()
    pytesseract = _import_pytesseract()
    from pytesseract import Output

    variants = _tesseract_preprocess_variants(crop)
    _debug(f"tesseract variants={len(variants)} shapes={[getattr(v, 'shape', None) for v in variants]}")
    for idx, variant in enumerate(variants):
        _save_debug_image(f"tesseract_variant_{idx}.png", variant)
    if not variants:
        return HandwritingOcrResult(text="", raw_text="", confidence=0.0, engine="tesseract", word_count=0)

    configs = [
        "--oem 1 --psm 6 -c preserve_interword_spaces=1",
        "--oem 1 --psm 11 -c preserve_interword_spaces=1",
    ]
    user_words_path = _write_user_words_file(question)
    if user_words_path:
        configs = [f'{config} --user-words "{user_words_path}"' for config in configs]

    timeout_seconds = int(getattr(settings, "ocr_tesseract_timeout_seconds", 45))
    best_text = ""
    best_conf = 0.0
    best_score = -1.0
    try:
        for image in variants:
            for config in configs:
                try:
                    kwargs: dict[str, Any] = {"lang": lang, "config": config, "output_type": Output.DICT}
                    if timeout_seconds > 0:
                        kwargs["timeout"] = timeout_seconds
                    data = pytesseract.image_to_data(image, **kwargs)
                except TypeError:
                    try:
                        data = pytesseract.image_to_data(image, lang=lang, config=config, output_type=Output.DICT)
                    except Exception:
                        continue
                except Exception:
                    continue
                text, conf = _text_from_tesseract_data(data)
                score = _ocr_candidate_score(text=text, confidence=conf, question=question)
                _debug(f"tesseract candidate variant_shape={getattr(image, 'shape', None)} config={config!r} conf={conf} score={score:.2f} text={text!r}")
                if score > best_score:
                    best_text, best_conf, best_score = text, conf, score
    finally:
        if user_words_path:
            try:
                Path(user_words_path).unlink(missing_ok=True)
            except Exception:
                pass

    cleaned = cleanup_answer_text(best_text, question)
    confidence = max(best_conf, _estimate_handwriting_confidence(text=cleaned, raw_text=best_text, question=question, engine="tesseract"))
    return HandwritingOcrResult(
        text=cleaned,
        raw_text=best_text,
        confidence=round(min(99.0, max(0.0, confidence)), 2),
        engine="tesseract",
        word_count=len(re.findall(r"\w+", cleaned)),
    )


def _tesseract_preprocess_variants(crop: Any) -> list[Any]:
    cv2, np = _import_cv2_numpy()
    if crop is None or getattr(crop, "size", 0) == 0:
        return []
    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY) if len(crop.shape) == 3 else crop.copy()
    gray = _trim_answer_box_border(gray)
    gray = _crop_to_ink(gray)
    gray = _resize_for_handwriting(gray)
    clahe = cv2.createCLAHE(clipLimit=2.3, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    denoised = cv2.fastNlMeansDenoising(enhanced, None, 7, 7, 21)
    sharpened = cv2.addWeighted(denoised, 1.45, cv2.GaussianBlur(denoised, (0, 0), 1.2), -0.45, 0)
    _, otsu = cv2.threshold(sharpened, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    adaptive = cv2.adaptiveThreshold(sharpened, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 41, 13)
    ink = 255 - adaptive
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 1))
    connected = 255 - cv2.dilate(ink, kernel, iterations=1)
    return [cv2.copyMakeBorder(v, 28, 28, 28, 28, cv2.BORDER_CONSTANT, value=255) for v in [sharpened, otsu, adaptive, connected]]


def _prepare_trocr_image(gray: Any) -> Any:
    cv2, np = _import_cv2_numpy()
    gray = _resize_for_handwriting(gray, target_longest=1300)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)
    return cv2.copyMakeBorder(enhanced, 24, 24, 24, 24, cv2.BORDER_CONSTANT, value=255)


def _segment_handwriting_lines(gray: Any) -> list[Any]:
    """Split a handwritten answer box into line images for TrOCR.

    TrOCR works best on one text line at a time.  The previous projection-based
    splitter could merge the whole answer into one huge line when the student's
    handwriting touched across rows, causing empty/garbled OCR.  This version
    removes the printed answer-box borders, clusters connected handwriting
    components by vertical position, and returns clean per-line crops.
    """
    cv2, np = _import_cv2_numpy()
    gray = _prepare_trocr_image(gray)

    # Remove printed answer-box lines before detecting handwriting.  Long black
    # borders otherwise dominate the projection and can make all rows look busy.
    work = _remove_printed_box_lines(gray)
    blur = cv2.GaussianBlur(work, (3, 3), 0)
    _, binary = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

    # Light opening removes scanner specks while preserving pen strokes.
    binary = cv2.morphologyEx(
        binary,
        cv2.MORPH_OPEN,
        cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2)),
        iterations=1,
    )

    # Connect characters into word-ish components, but do not connect separate
    # handwriting lines vertically.
    connected = cv2.dilate(
        binary,
        cv2.getStructuringElement(cv2.MORPH_RECT, (7, 2)),
        iterations=1,
    )
    contours, _ = cv2.findContours(connected, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    height, width = gray.shape[:2]
    boxes: list[tuple[int, int, int, int]] = []
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        if w < 4 or h < 7:
            continue
        if w * h < 45:
            continue
        # Ignore remaining border fragments and full-width page lines.
        if w > width * 0.82 and h < height * 0.08:
            continue
        if h > height * 0.45:
            continue
        boxes.append((x, y, w, h))

    _debug(f"line_seg boxes={len(boxes)} gray_shape={gray.shape}")
    if boxes:
        # Cluster components by y center.  The threshold scales with estimated
        # line height and handles large handwriting in photographed scans.
        median_h = float(np.median([h for _, _, _, h in boxes])) if boxes else 20.0
        gap_threshold = max(22.0, min(70.0, median_h * 2.2))
        items = sorted(((y + h / 2.0, x, y, w, h) for x, y, w, h in boxes), key=lambda item: item[0])
        clusters: list[list[tuple[float, int, int, int, int]]] = []
        for item in items:
            if not clusters:
                clusters.append([item])
                continue
            current_center = float(np.mean([it[0] for it in clusters[-1]]))
            if abs(item[0] - current_center) <= gap_threshold:
                clusters[-1].append(item)
            else:
                clusters.append([item])

        line_images: list[Any] = []
        for cluster in clusters:
            xs = [int(it[1]) for it in cluster]
            ys = [int(it[2]) for it in cluster]
            x2s = [int(it[1] + it[3]) for it in cluster]
            y2s = [int(it[2] + it[4]) for it in cluster]
            x1 = max(0, min(xs) - 34)
            y1 = max(0, min(ys) - 22)
            x2 = min(width, max(x2s) + 34)
            y2 = min(height, max(y2s) + 22)
            if x2 - x1 < 42 or y2 - y1 < 16:
                continue
            # Drop footer/bottom-border fragments with very few components.
            if len(cluster) <= 2 and (y1 > height * 0.72 or x2 - x1 > width * 0.70):
                continue
            line = gray[y1:y2, x1:x2]
            line_images.append(cv2.copyMakeBorder(line, 18, 18, 18, 18, cv2.BORDER_CONSTANT, value=255))

        if line_images:
            _debug(f"line_seg component_clusters={len(clusters)} returned_lines={len(line_images[:10])}")
            return line_images[:10]

    # Projection fallback for unusually connected handwriting.
    projection = np.count_nonzero(binary, axis=1)
    threshold = max(3, int(width * 0.010))
    rows = np.where(projection > threshold)[0]
    if len(rows) == 0:
        _debug("line_seg projection_rows=0")
        return []

    spans: list[tuple[int, int]] = []
    start = int(rows[0])
    prev = int(rows[0])
    for row in rows[1:]:
        current = int(row)
        if current - prev > 12:
            spans.append((start, prev))
            start = current
        prev = current
    spans.append((start, prev))

    line_images = []
    for start, end in spans:
        if end - start < 10:
            continue
        y1 = max(0, start - 24)
        y2 = min(height, end + 24)
        line_bin = binary[y1:y2, :]
        ys, xs = np.where(line_bin > 0)
        if len(xs) >= 8:
            x1 = max(0, int(xs.min()) - 34)
            x2 = min(width, int(xs.max()) + 34)
        else:
            x1, x2 = 0, width
        if x2 - x1 >= 42:
            line_images.append(cv2.copyMakeBorder(gray[y1:y2, x1:x2], 18, 18, 18, 18, cv2.BORDER_CONSTANT, value=255))
    return line_images[:10]


def _remove_printed_box_lines(gray: Any) -> Any:
    cv2, np = _import_cv2_numpy()
    height, width = gray.shape[:2]
    blur = cv2.GaussianBlur(gray, (3, 3), 0)
    _, binary = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    h_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (max(80, width // 4), 1))
    v_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, max(80, height // 3)))
    horizontal = cv2.morphologyEx(binary, cv2.MORPH_OPEN, h_kernel, iterations=1)
    vertical = cv2.morphologyEx(binary, cv2.MORPH_OPEN, v_kernel, iterations=1)
    lines = cv2.dilate(cv2.add(horizontal, vertical), cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3)), iterations=1)
    cleaned = gray.copy()
    cleaned[lines > 0] = 255
    return cleaned

def _trim_answer_box_border(gray: Any) -> Any:
    height, width = gray.shape[:2]
    pad_x = max(6, int(width * 0.012))
    pad_y = max(6, int(height * 0.025))
    if height <= pad_y * 2 or width <= pad_x * 2:
        return gray
    return gray[pad_y:height - pad_y, pad_x:width - pad_x]


def _crop_to_ink(gray: Any) -> Any:
    cv2, np = _import_cv2_numpy()
    blur = cv2.GaussianBlur(gray, (3, 3), 0)
    _, binary = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2))
    binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel, iterations=1)
    ys, xs = np.where(binary > 0)
    if len(xs) < 12 or len(ys) < 12:
        return gray
    height, width = gray.shape[:2]
    x1 = max(0, int(xs.min()) - 18)
    y1 = max(0, int(ys.min()) - 18)
    x2 = min(width, int(xs.max()) + 18)
    y2 = min(height, int(ys.max()) + 18)
    if x2 <= x1 or y2 <= y1:
        return gray
    return gray[y1:y2, x1:x2]


def _resize_for_handwriting(gray: Any, *, target_longest: int = 1900) -> Any:
    cv2, np = _import_cv2_numpy()
    height, width = gray.shape[:2]
    longest = max(height, width)
    if longest < target_longest:
        scale = min(3.0, target_longest / max(1, longest))
    elif longest > 3200:
        scale = 3200 / longest
    else:
        scale = 1.0
    if abs(scale - 1.0) < 0.02:
        return gray
    return cv2.resize(gray, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)


def cleanup_answer_text(raw: str, question: dict[str, Any]) -> str:
    """Return the OCR text as written, with only neutral whitespace cleanup.

    Do not apply domain-specific substitutions here.  The OCR layer must only
    extract the student's handwriting; grading/correction belongs to the grader
    and must work across different courses and exams without hardcoded word
    replacements.
    """
    text = _basic_clean(raw)
    if not text:
        return ""
    text = re.sub(r"[{}<>|~^]+", " ", text)
    text = re.sub(r"\s+([,.;:])", r"\1", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text

def _question_context(question: dict[str, Any]) -> str:
    parts: list[str] = []
    for key in ("question_text", "expected_answer", "grading_rubric"):
        value = question.get(key)
        if value is None:
            continue
        if isinstance(value, (dict, list)):
            try:
                parts.append(json.dumps(value, ensure_ascii=False))
            except Exception:
                parts.append(str(value))
        else:
            parts.append(str(value))
    return "\n".join(parts)


def _context_words(context: str) -> list[str]:
    stop = {"the", "and", "for", "with", "that", "this", "what", "how", "why", "where", "which", "question", "answer", "provide", "explain", "describe", "example", "each", "when", "from"}
    words: list[str] = []
    seen: set[str] = set()
    for word in re.findall(r"[A-Za-z][A-Za-z0-9]*(?:-[A-Za-z0-9]+)?", context or ""):
        lower = word.lower()
        if len(word) < 3 or lower in stop or lower in seen:
            continue
        seen.add(lower)
        words.append(word)
    return words


def _write_user_words_file(question: dict[str, Any]) -> str | None:
    words = _context_words(_question_context(question))
    if not words:
        return None
    try:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".words", delete=False) as handle:
            for word in words:
                handle.write(f"{word}\n")
            return handle.name
    except Exception:
        return None


def _text_from_tesseract_data(data: dict[str, list[Any]]) -> tuple[str, float]:
    tokens: list[str] = []
    confidences: list[float] = []
    lines: dict[tuple[int, int, int], list[str]] = {}
    for index, text_value in enumerate(data.get("text", [])):
        token = str(text_value or "").strip()
        if not token:
            continue
        try:
            key = (int(data.get("block_num", [0])[index]), int(data.get("par_num", [0])[index]), int(data.get("line_num", [index])[index]))
        except Exception:
            key = (0, 0, index)
        lines.setdefault(key, []).append(token)
        tokens.append(token)
        try:
            conf = float(data.get("conf", [])[index])
            if conf >= 0:
                confidences.append(conf)
        except Exception:
            pass
    ordered_lines = [" ".join(lines[key]) for key in sorted(lines)]
    confidence = round(sum(confidences) / len(confidences), 2) if confidences else 0.0
    return _basic_clean("\n".join(ordered_lines)), confidence


def _ocr_candidate_score(*, text: str, confidence: float, question: dict[str, Any]) -> float:
    context_terms = set(word.lower() for word in _context_words(_question_context(question)))
    tokens = [token.lower() for token in re.findall(r"[A-Za-z][A-Za-z0-9-]{2,}", text or "")]
    hits = sum(1 for token in tokens if token in context_terms)
    weird = len(re.findall(r"[{}<>|~^]", text or "")) + len(re.findall(r"\b[A-Za-z]{1}\b", text or "")) * 0.35
    return (confidence * 1.15) + min(len(tokens), 90) * 0.6 + hits * 10 - weird * 6


def _estimate_handwriting_confidence(*, text: str, raw_text: str, question: dict[str, Any], engine: str) -> float:
    if not text.strip():
        return 0.0
    context_terms = set(word.lower() for word in _context_words(_question_context(question)))
    tokens = [token.lower() for token in re.findall(r"[A-Za-z][A-Za-z0-9-]{2,}", text)]
    hits = sum(1 for token in tokens if token in context_terms)
    weird = len(re.findall(r"[{}<>|~^]", raw_text or ""))
    base = 68.0 if engine == "trocr" else 45.0
    return round(min(96.0, max(20.0, base + hits * 3.5 + min(len(tokens), 25) * 0.7 - weird * 4)), 2)


def _basic_clean(raw: str) -> str:
    text = str(raw or "").replace("—", "-").replace("–", "-").replace("’", "'")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\s+([,.;:])", r"\1", text)
    text = re.sub(r"[\r\n]{3,}", "\n\n", text)
    return text.strip()


def _import_cv2_numpy():
    try:
        import cv2
        import numpy as np
        return cv2, np
    except Exception as exc:
        raise RuntimeError("OCR requires opencv-python and numpy") from exc


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
        raise RuntimeError("OCR requires pytesseract and Tesseract") from exc
