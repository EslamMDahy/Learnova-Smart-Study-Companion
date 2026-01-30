from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=255)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    invite_code: str = Field(min_length=1, max_length=100)  # عندك في DB غالبًا varchar


class RegisterResponse(BaseModel):
    ok: bool = True
    message: str = "Registration successful. Please verify your email."
