from __future__ import annotations

from enum import Enum
from typing import Literal, Optional, List
from pydantic import BaseModel, Field, ConfigDict, model_validator
from datetime import datetime

from app.models.enums import CourseStatus



class CourseType(str, Enum):
    individual = "individual"
    organization = "organization"

class CourseVisibilityLevel(str, Enum):
    private = "private"
    public = "public"
    unlisted = "unlisted"

class CourseInviteStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    revoked = "revoked"
    expired = "expired"





class CourseCreateRequest(BaseModel):
    course_type: CourseType = Field(..., description="organization | individual")
    organization_id: Optional[int] = Field(default=None, description="Required if course_type=organization")

    title: str = Field(..., min_length=1, max_length=255)
    course_code: Optional[str] = Field(default=None, max_length=50, description="Optional course code shown in UI")
    description: Optional[str] = None

    is_open_for_enrollment: bool
    visibility_level: CourseVisibilityLevel
    requires_enrollment_approval: bool = False

    # learning_outcomes: Optional[list[str]] = None
    tags: Optional[list[str]] = None
    category: Optional[str] = Field(default=None, max_length=100)
    status: Optional[CourseStatus] = Field(
        default=None,
        description="draft | published | archived"
    )

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
    course_code: Optional[str] = None
    course_type: CourseType
    organization_id: Optional[int]
    is_open_for_enrollment: bool
    visibility_level: CourseVisibilityLevel
    requires_enrollment_approval: bool

    # keep parity with DB model
    status: CourseStatus
    published_at: Optional[datetime] = None

    model_config = ConfigDict(extra="forbid", use_enum_values=True)


class CourseUpdateRequest(BaseModel):
    title: Optional[str] = Field(default=None, max_length=255)
    description: Optional[str] = None
    
    category: Optional[str] = Field(default=None, max_length=50)
    course_code: Optional[str] = Field(default=None, max_length=50)

    is_open_for_enrollment: Optional[bool] = None
    requires_enrollment_approval: Optional[bool] = None
    visibility_level: Optional[CourseVisibilityLevel] = None

    tags: Optional[list[str]] = None


    model_config = ConfigDict(extra="forbid")


class CourseAssetUploadRequest(BaseModel):
    content_type: str
    file_size_bytes: int

    model_config = ConfigDict(extra="forbid")


class CourseCoverConfirmResponse(BaseModel):
    cover_url: str
    updated_at: str

    model_config = ConfigDict(extra="forbid")


class CourseInvitesUploadResponse(BaseModel):
    course_id: int

    total_rows: int = Field(..., ge=0, description="Total rows read from the Excel sheet (excluding header if any)")
    extracted_emails: int = Field(..., ge=0, description="How many email-like values were extracted")
    inserted: int = Field(..., ge=0, description="How many new invitations were created")
    skipped_existing: int = Field(..., ge=0, description="How many were skipped because (course_id, invited_email) already exists")
    invalid_emails: int = Field(..., ge=0, description="How many values were rejected as invalid emails")

    # token_expires_at: datetime = Field(..., description="Expiration timestamp used for newly created invitations (UTC)")

    # useful for UI/debugging without returning huge lists
    sample_invalid_emails: list[str] = Field(default_factory=list, max_length=20)
    sample_existing_emails: list[str] = Field(default_factory=list, max_length=20)

    model_config = ConfigDict(extra="forbid")




class CourseInvitesSendRequest(BaseModel):
    # لو موجود => resend لواحد معين
    email: Optional[str] = Field(default=None, max_length=320, description="If provided, send invitation only to this email")

    # افتراضيًا هنرسل pending + expired
    include_expired: bool = Field(default=True, description="If true, also send to expired invitations by rotating token")

    # TODO لاحقًا للrate limiting override
    force: bool = Field(default=False, description="Future use: bypass rate limiting (admin/instructor)")

    model_config = ConfigDict(extra="forbid")

class CourseInvitesSendResponse(BaseModel):
    course_id: int

    # كم invite اتعمل له إرسال (نجح)
    sent: int = Field(..., ge=0)

    # كان فيه invites مش eligible (accepted/revoked) أو مش موجودة في حالة email واحدة
    skipped_not_eligible: int = Field(..., ge=0)

    # في حالة حصل fails أثناء الإرسال (SMTP… إلخ)
    failed: int = Field(..., ge=0)

    # معلومات مساعدة للـ UI
    target_email: Optional[str] = None
    attempted: int = Field(..., ge=0)

    # آخر وقت إرسال
    last_sent_at: Optional[datetime] = None

    # samples للديباج/الواجهة
    sample_failed_emails: list[str] = Field(default_factory=list, max_length=20)
    sample_skipped_emails: list[str] = Field(default_factory=list, max_length=20)

    model_config = ConfigDict(extra="forbid")




class CourseInviteAcceptRequest(BaseModel):
    token: str = Field(..., min_length=10, max_length=4096, description="Raw invitation token from email link")
    model_config = ConfigDict(extra="forbid")

class CourseInviteAcceptResponse(BaseModel):
    message: str
    course_id: int
    enrollment_id: int | None = None
    enrolled: bool = True
    accepted_at: datetime | None = None

    model_config = ConfigDict(extra="forbid")



class MyCourseItem(BaseModel):
    id: int
    
    title: str
    description: Optional[str] = None

    instructor_name: Optional[str] = None
    instructor_avatar_url: Optional[str] = None

    course_code: Optional[str] = None

    cover_url: Optional[str] = None

    course_type: str 
    organization_id: Optional[int] = None

    status: str
    visibility_level: str  
    is_open_for_enrollment: bool

    category: Optional[str] = None
    tags: Optional[list[str]] = None

    created_by: int
    created_at: datetime
    updated_at: datetime

    average_rating: Optional[float]
    total_ratings: Optional[int] = None
    enrollment_count: Optional[int] = None
    pending_invites: Optional[int] = None

    model_config = ConfigDict(extra="forbid")

class MyCoursesResponse(BaseModel):
    items: list[MyCourseItem] = Field(default_factory=list)
    total: int = 0

    model_config = ConfigDict(extra="forbid")



class PublishCourseResponse(BaseModel):
    id: int
    status: str
    message: str

    model_config = ConfigDict(extra="forbid")



class CourseInvitationItem(BaseModel):
    id: int
    course_id: int
    created_by: int
    invited_email: str
    invited_user_id: Optional[int]
    status: CourseInviteStatus

    token_expires_at: datetime
    sent_at: Optional[datetime]
    last_sent_at: Optional[datetime]
    send_count: int
    accepted_at: Optional[datetime]
    revoked_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    invited_user_exists: bool  # helper للفرونت

    model_config = ConfigDict(extra="forbid")

class CourseInvitationsListResponse(BaseModel):
    course_id: int
    total: int
    items: List[CourseInvitationItem]

    model_config = ConfigDict(extra="forbid")


class CourseEnrollResponse(BaseModel):
    enrollment_id: int
    course_id: int
    status: str
    enrollment_type: str
    enrolled_at: datetime

    model_config = ConfigDict(from_attributes=True)


class EnrollmentRequestItem(BaseModel):
    enrollment_id: int
    student_id: int
    full_name: str
    email: str
    status: str
    enrolled_at: datetime

    model_config = ConfigDict(from_attributes=True)

class CourseEnrollmentRequestsResponse(BaseModel):
    course_id: int
    total: int
    requests: list[EnrollmentRequestItem]

    model_config = ConfigDict(from_attributes=True)


class EnrollmentRequestUpdateRequest(BaseModel):
    status: Literal["approved", "declined"]

class EnrollmentRequestUpdateResponse(BaseModel):
    enrollment_id: int
    status: str

    model_config = ConfigDict(from_attributes=True)


class CourseAutocompleteResponse(BaseModel):
    suggestions: list[str]

    model_config = ConfigDict(from_attributes=True)


class CourseSearchResult(BaseModel):
    id: int
    title: str
    description: str | None = None
    course_code: str | None = None
    category: str | None = None
    tags: list | None = None
    cover_image_key: str | None = None
    banner_image_key: str | None = None
    cover_url: str | None = None
    banner_url: str | None = None
    course_type: str | None = None
    organization_id: int | None = None
    visibility_level: str | None = None
    is_open_for_enrollment: bool = True
    status: str | None = None
    created_by: int | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    enrollment_count: int | None = None
    average_rating: float | None = None
    total_ratings: int | None = None
    requires_enrollment_approval: bool = False
    instructor_name: str | None = None
    instructor_avatar_url: str | None = None
    rank: float | None = None

    model_config = ConfigDict(from_attributes=True)

class CourseSearchResponse(BaseModel):
    total: int
    limit: int
    offset: int
    results: list[CourseSearchResult]

    model_config = ConfigDict(from_attributes=True)



