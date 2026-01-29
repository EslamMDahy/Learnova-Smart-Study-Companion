from pydantic import BaseModel, EmailStr


class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    invite_code: str  # خليه str عشان في DB غالبًا varchar
