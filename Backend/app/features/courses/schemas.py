from __future__ import annotations

from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict, model_validator
from datetime import datetime



class CourseType(str, Enum):
    individual = "individual"
    organization = "organization"

class CourseVisibilityLevel(str, Enum):
    private = "private"
    public = "public"
    unlisted = "unlisted"

class CourseCreateRequest(BaseModel):
    course_type: CourseType = Field(..., description="organization | individual")
    organization_id: Optional[int] = Field(default=None, description="Required if course_type=organization")

    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    cover_image_url: Optional[str] = Field(default=None, max_length=512)
    banner_image_url: Optional[str] = Field(default=None, max_length=512)

    is_public: bool
    visibility_level: CourseVisibilityLevel
    requires_enrollment_approval: bool = False

    learning_outcomes: Optional[list[str]] = None
    tags: Optional[list[str]] = None
    category: Optional[str] = Field(default=None, max_length=100)

    model_config = ConfigDict(extra="forbid")

    @model_validator(mode="after")
    def validate_org_rules(self):
        if self.course_type == CourseType.organization and not self.organization_id:
            raise ValueError("organization_id is required when course_type=organization")
        if self.course_type == CourseType.individual and self.organization_id is not None:
            raise ValueError("organization_id must be null when course_type=individual")
        return self

class CourseCreateResponse(BaseModel):
    id: int
    title: str
    course_type: CourseType
    organization_id: Optional[int]
    is_public: bool
    visibility_level: CourseVisibilityLevel
    requires_enrollment_approval: bool

    model_config = ConfigDict(extra="forbid", use_enum_values=True)



class CourseInvitesUploadResponse(BaseModel):
    course_id: int

    total_rows: int = Field(..., ge=0, description="Total rows read from the Excel sheet (excluding header if any)")
    extracted_emails: int = Field(..., ge=0, description="How many email-like values were extracted")
    inserted: int = Field(..., ge=0, description="How many new invitations were created")
    skipped_existing: int = Field(..., ge=0, description="How many were skipped because (course_id, invited_email) already exists")
    invalid_emails: int = Field(..., ge=0, description="How many values were rejected as invalid emails")

    token_expires_at: datetime = Field(..., description="Expiration timestamp used for newly created invitations (UTC)")

    # useful for UI/debugging without returning huge lists
    sample_invalid_emails: list[str] = Field(default_factory=list, max_length=20)
    sample_existing_emails: list[str] = Field(default_factory=list, max_length=20)

    model_config = ConfigDict(extra="forbid")

