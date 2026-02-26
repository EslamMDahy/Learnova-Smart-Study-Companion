from __future__ import annotations

from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class MaterialInitUploadRequest(BaseModel):
    filename: str = Field(..., min_length=1, max_length=255, description="Original filename")
    content_type: str = Field(..., min_length=1, max_length=100, description="Must be application/pdf")
    file_size_bytes: int = Field(..., gt=0, le=50 * 1024 * 1024, description="Max 50MB")

    # Optional metadata (MVP-friendly)
    title: Optional[str] = Field(default=None, max_length=255)
    description: Optional[str] = Field(default=None)

    model_config = ConfigDict(extra="forbid")

class MaterialInitUploadResponse(BaseModel):
    material_id: int
    module_id: int
    course_id: int

    upload_url: str
    storage_key: str
    bucket: str

    content_type: str
    max_bytes: int
    expires_in_seconds: Optional[int] = None  # Supabase may not expose it cleanly

    status: str  # e.g., "draft_upload"
    created_at: Optional[datetime] = None

    model_config = ConfigDict(extra="forbid")



class MaterialConfirmUploadRequest(BaseModel):
    # decide publish here (your preference)
    publish_now: bool = Field(default=False)

    model_config = ConfigDict(extra="forbid")

class MaterialConfirmUploadResponse(BaseModel):
    material_id: int
    module_id: int
    status: str  # e.g., "ready"
    is_published: bool
    published_at: Optional[datetime] = None

    # Optional convenience for frontend demo
    download_url: Optional[str] = None

    model_config = ConfigDict(extra="forbid")