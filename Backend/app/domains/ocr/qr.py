from __future__ import annotations

import base64
import hashlib
import hmac
import json
from io import BytesIO
from typing import Any

from app.core.config import settings


QR_PREFIX = "LNVSCAN:"


def _secret() -> str:
    return (
        getattr(settings, "exam_scan_secret", "")
        or getattr(settings, "ai_shared_secret", "")
        or getattr(settings, "jwt_secret", "")
        or "learnova-dev-scan-secret"
    )


def sign_payload(payload: dict[str, Any]) -> str:
    canonical = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hmac.new(_secret().encode("utf-8"), canonical.encode("utf-8"), hashlib.sha256).hexdigest()


def build_exam_qr_payload(*, exam_id: int, course_id: int, template_version: str = "v1") -> dict[str, Any]:
    payload = {
        "exam_id": int(exam_id),
        "course_id": int(course_id),
        "template_version": template_version,
        "source": "learnova_exam_print",
    }
    payload["signature"] = sign_payload(payload)
    return payload


def encode_payload(payload: dict[str, Any]) -> str:
    encoded = base64.urlsafe_b64encode(
        json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    ).decode("ascii").rstrip("=")
    return f"{QR_PREFIX}{encoded}"


def decode_payload(raw: str | None) -> dict[str, Any] | None:
    value = (raw or "").strip()
    if not value:
        return None

    if value.startswith(QR_PREFIX):
        value = value[len(QR_PREFIX):]
        padding = "=" * (-len(value) % 4)
        try:
            decoded = base64.urlsafe_b64decode(f"{value}{padding}").decode("utf-8")
            payload = json.loads(decoded)
        except Exception:
            return None
    else:
        # Newer templates use signed JSON. Older exported OCR templates in this
        # project used a plain string: "exam_id:12,course_id:3". Support both so
        # already-printed sheets remain scannable.
        try:
            payload = json.loads(value)
        except Exception:
            payload = _decode_legacy_key_value_payload(value)

    if not isinstance(payload, dict):
        return None
    return payload


def _decode_legacy_key_value_payload(value: str) -> dict[str, Any] | None:
    pairs: dict[str, str] = {}
    for chunk in value.split(','):
        if ':' not in chunk:
            continue
        key, raw_val = chunk.split(':', 1)
        key = key.strip().lower()
        raw_val = raw_val.strip()
        if key:
            pairs[key] = raw_val

    exam_id = _safe_int(pairs.get('exam_id') or pairs.get('exam'))
    course_id = _safe_int(pairs.get('course_id') or pairs.get('course'))
    if not exam_id and not course_id:
        return None

    return {
        "exam_id": exam_id,
        "course_id": course_id,
        "template_version": pairs.get("template_version") or "legacy_v1",
        "source": "learnova_legacy_exam_qr",
        "signature": None,
    }


def _safe_int(value: Any) -> int | None:
    try:
        if value is None or value == "":
            return None
        return int(str(value).strip())
    except (TypeError, ValueError):
        return None

def verify_payload(payload: dict[str, Any] | None) -> bool:
    if not payload:
        return False

    # Backward compatibility for PDFs that were generated before signed QR
    # payloads were added. The endpoint is instructor-only, and the exam/course
    # ownership is validated against the authenticated instructor later.
    if payload.get("source") == "learnova_legacy_exam_qr":
        return bool(payload.get("exam_id") or payload.get("course_id"))

    supplied = str(payload.get("signature") or "").strip()
    if not supplied:
        return False
    unsigned = dict(payload)
    unsigned.pop("signature", None)
    expected = sign_payload(unsigned)
    return hmac.compare_digest(supplied, expected)

def make_qr_data_uri(payload: dict[str, Any]) -> str:
    # qrcode is intentionally imported lazily so the API remains bootable if the
    # PDF export path is not used in an environment missing the package.
    # Some environments have qrcode installed without a working image backend;
    # never let QR rendering break PDF export.
    try:
        import qrcode

        image = qrcode.make(encode_payload(payload))
        buffer = BytesIO()
        image.save(buffer, format="PNG")
        encoded = base64.b64encode(buffer.getvalue()).decode("ascii")
        return f"data:image/png;base64,{encoded}"
    except Exception:
        return ""


def read_qr_from_image(image: Any) -> dict[str, Any] | None:
    try:
        import cv2
    except Exception:
        return None

    detector = cv2.QRCodeDetector()

    candidates = [image]
    try:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        candidates.append(gray)
    except Exception:
        pass

    for candidate in candidates:
        try:
            data, _points, _straight = detector.detectAndDecode(candidate)
        except Exception:
            data = ""
        payload = decode_payload(data)
        if payload:
            return payload

    return None
