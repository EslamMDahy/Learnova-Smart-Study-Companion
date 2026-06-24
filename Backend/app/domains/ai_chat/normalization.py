from __future__ import annotations

import json
from collections.abc import Mapping
from typing import Any


_SOURCE_LIST_KEYS = ("sources", "items", "documents", "results", "data")
_TITLE_KEYS = (
    "title",
    "source",
    "name",
    "filename",
    "file_name",
    "document_title",
    "material_title",
    "material",
    "url",
    "path",
)
_PAGE_KEYS = ("page", "page_number", "page_no", "pageIndex", "page_index")


def normalize_sources(value: Any) -> list[dict[str, Any]]:
    """Return a response-safe list of source objects.

    Older rows and some AI callbacks can store `sources` as `{}`, `null`, a
    JSON string, or source dictionaries with extra metadata. The public chat
    response model only needs a stable list of `{title, page?}` objects, so this
    function coerces bad/legacy shapes instead of letting FastAPI raise a 500.
    """

    if value is None or value == "" or value == {}:
        return []

    if isinstance(value, str):
        raw = value.strip()
        if not raw:
            return []
        try:
            return normalize_sources(json.loads(raw))
        except (TypeError, ValueError, json.JSONDecodeError):
            return [{"title": raw}]

    if isinstance(value, Mapping):
        for key in _SOURCE_LIST_KEYS:
            nested = value.get(key)
            if isinstance(nested, list):
                return normalize_sources(nested)
        return []

    if not isinstance(value, list):
        return []

    normalized: list[dict[str, Any]] = []
    for item in value:
        source = _normalize_source_item(item)
        if source is not None:
            normalized.append(source)

    return normalized


def normalize_message_row(row: Mapping[str, Any]) -> dict[str, Any]:
    data = dict(row)
    data["sources"] = normalize_sources(data.get("sources"))
    return data


def sources_json(value: Any) -> str:
    return json.dumps(normalize_sources(value), ensure_ascii=False)


def _normalize_source_item(item: Any) -> dict[str, Any] | None:
    if item is None or item == {}:
        return None

    if isinstance(item, str):
        title = item.strip()
        return {"title": title} if title else None

    if not isinstance(item, Mapping):
        return None

    title = ""
    for key in _TITLE_KEYS:
        raw_title = item.get(key)
        if raw_title is not None:
            title = str(raw_title).strip()
            if title:
                break

    if not title:
        return None

    source: dict[str, Any] = {"title": title}
    page = _extract_page(item)
    if page is not None:
        source["page"] = page

    return source


def _extract_page(item: Mapping[str, Any]) -> int | None:
    for key in _PAGE_KEYS:
        raw_page = item.get(key)
        if raw_page is None or raw_page == "":
            continue
        try:
            page = int(raw_page)
        except (TypeError, ValueError):
            continue
        if page >= 0:
            return page
    return None
