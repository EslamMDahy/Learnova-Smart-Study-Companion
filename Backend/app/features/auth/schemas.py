from pydantic import BaseModel, EmailStr,  Field


class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    invite_code: str  # خليه str عشان في DB غالبًا varchar

class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
