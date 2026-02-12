from typing import Optional, Literal
from pydantic import BaseModel, EmailStr, Field

# =========================
# Profile
# =========================

class UpdateProfileRequest(BaseModel):
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None

    # في DB اسمها phone_number
    # ولو Flutter/قديم بيبعت phone هنقبله alias
    phone: Optional[str] = Field(default=None, alias="phone")

    bio: Optional[str] = None
    language_preference: Optional[str] = None

    class Config:
        populate_by_name = True  # يخلي alias يشتغل للـ input


class UpdateProfileResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    avatar_url: Optional[str] = None
    phone_number: Optional[str] = None
    bio: Optional[str] = None
    system_role: str
    language_preference: Optional[str] = None


# =========================
# Password
# =========================

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class ChangePasswordResponse(BaseModel):
    message: str
    email_notification_sent: bool


# =========================
# Delete Account
# =========================

class RequestDeleteAccountRequest(BaseModel):
    current_password: str


class RequestDeleteAccountResponse(BaseModel):
    message: str
    email_sent: bool


class ConfirmDeleteAccountRequest(BaseModel):
    otp: str


class ConfirmDeleteAccountResponse(BaseModel):
    message: str


# =========================
# Preferences (user_preferences)
# =========================

ThemeMode = Literal["light", "dark", "system"]
ProfileVisibility = Literal["public", "private", "connections"]

class PreferencesResponse(BaseModel):
    email_notifications: bool = True
    assignment_alerts: bool = True
    course_updates: bool = True
    announcement_notifications: bool = True
    grading_notifications: bool = True
    deadline_reminders: bool = True

    theme_mode: ThemeMode = "light"
    profile_visibility: ProfileVisibility = "private"
    show_online_status: bool = True


class UpdatePreferencesRequest(BaseModel):
    email_notifications: bool = True
    assignment_alerts: bool = True
    course_updates: bool = True
    announcement_notifications: bool = True
    grading_notifications: bool = True
    deadline_reminders: bool = True

    theme_mode: ThemeMode = "light"
    profile_visibility: ProfileVisibility = "private"
    show_online_status: bool = True
