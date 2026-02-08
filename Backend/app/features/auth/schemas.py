from typing import Optional
from pydantic import BaseModel, EmailStr,  Field


class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str = Field(min_length=8)
    # account_type: str
    # invite_code: Optional[str] = None
    system_role: Optional[str] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    full_name: str
    email: str

class ForgetPasswordRequest(BaseModel):
    email: EmailStr

class ForgetPasswordResponse(BaseModel):
    message: str

class ResetPasswordRequest(BaseModel):
    token: str = Field(..., min_length=10)
    new_password: str = Field(..., min_length=6)

class ResetPasswordResponse(BaseModel):
    message: str

