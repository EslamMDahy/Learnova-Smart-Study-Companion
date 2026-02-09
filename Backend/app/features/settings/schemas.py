from typing import Optional
from pydantic import BaseModel, EmailStr


class UpdateProfileRequest(BaseModel):
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None

    # موجودين في UI لكن DB لسه مفيهاش حقول لهم
    phone: Optional[str] = None
    bio: Optional[str] = None

class UpdateProfileResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    avatar_url: Optional[str] = None
    system_role: str



class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class ChangePasswordResponse(BaseModel):
    message: str
    email_notification_sent: bool
