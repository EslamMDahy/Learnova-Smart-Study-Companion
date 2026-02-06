from pydantic import BaseModel, Field
from typing import Optional


class CreateOrganizationRequest(BaseModel):
    name: str = Field(min_length=2, max_length=255)
    description: str = Field(min_length=2, max_length=50)  # جاي من Flutter
    logo_url: Optional[str] = Field(default=None, max_length=512)


class OrganizationOut(BaseModel):
    id: int
    name: str
    description: str
    logo_url: Optional[str] = None
    owner_id: int
    subscription_plan_id: int
    invite_code: str
    subscription_status: str


class CreateOrganizationResponse(BaseModel):
    organization: OrganizationOut
