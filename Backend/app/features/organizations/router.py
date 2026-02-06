from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.deps import get_current_user
from app.features.organizations.schemas import CreateOrganizationRequest, CreateOrganizationResponse
from . import service

router = APIRouter(prefix="/organizations", tags=["Organizations"])


@router.post("", response_model=CreateOrganizationResponse, status_code=201)
def create_organization(
    payload: CreateOrganizationRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),):
    return service.create_organization(payload, db, current_user)
