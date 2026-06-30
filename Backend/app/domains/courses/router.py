from fastapi import APIRouter, Depends, File, UploadFile, Form, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.deps import get_current_user
from . import service
from .schemas import (CourseCreateRequest,
                      CourseCreateResponse,
                      CourseUpdateRequest,
                      CourseAssetUploadRequest,
                      CourseCoverConfirmResponse,
                      MyCourseItem,
                      CourseInvitesUploadResponse,
                      CourseInvitesSendRequest, 
                      CourseInvitesSendResponse,
                      CourseInviteAcceptRequest,
                      CourseInviteAcceptResponse,
                      MyCoursesResponse,
                      PublishCourseResponse,
                      CourseInvitationsListResponse,
                      CourseEnrollResponse,
                      CourseEnrollmentRequestsResponse,
                      EnrollmentRequestUpdateRequest,
                      EnrollmentRequestUpdateResponse,
                      CourseAutocompleteResponse,
                      CourseSearchResponse)

router = APIRouter(prefix="/courses", tags=["Courses"])

@router.post("", response_model=CourseCreateResponse, status_code=status.HTTP_201_CREATED)
def create_course(
    payload: CourseCreateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.create_course(
        payload=payload, 
        db=db, 
        current_user=current_user)

@router.patch("/{course_id}", response_model=MyCourseItem,)
def update_course(
    course_id: int,
    payload: CourseUpdateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.update_course(
        course_id=course_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.post("/{course_id}/cover/initiate", status_code=200)
def initiate_course_cover_upload_route(
    course_id: int,
    payload: CourseAssetUploadRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.initiate_course_cover_upload(
        course_id=course_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.post("/{course_id}/cover/confirm", status_code=200, response_model=CourseCoverConfirmResponse)
def confirm_course_cover_upload_route(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.confirm_course_cover_upload(
        course_id=course_id,
        db=db,
        current_user=current_user,)

@router.post("/{course_id}/invitations/upload", response_model=CourseInvitesUploadResponse,status_code=status.HTTP_201_CREATED,)
def upload_course_invitations_excel(
    course_id: int,
    file: UploadFile = File(..., description="Excel file (.xlsx) containing invited emails"),
    # optional: لو الفرونت محتاج يبعت حاجات زيادة مع الملف (مش ضروري غالبًا)
    sheet_name: str | None = Form(default=None, description="Optional Excel sheet name"),
    email_column: str = Form(default="email", description="Column name that contains emails"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.upload_course_invitations_excel(
        course_id=course_id,
        file=file,
        sheet_name=sheet_name,
        email_column=email_column,
        db=db,
        current_user=current_user,)

@router.post("/{course_id}/invitations/send",response_model=CourseInvitesSendResponse,status_code=status.HTTP_200_OK,)
def send_course_invitations(
    course_id: int,
    payload: CourseInvitesSendRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.send_course_invitations(
        course_id=course_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.post("/invitations/accept",response_model=CourseInviteAcceptResponse,status_code=status.HTTP_200_OK,)
def accept_course_invitation(
    payload: CourseInviteAcceptRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.accept_course_invitation(
        payload=payload, 
        db=db, 
        current_user=current_user)

@router.get("/my", response_model=MyCoursesResponse, status_code=status.HTTP_200_OK,)
def get_my_courses(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.get_my_courses(
        db=db, 
        current_user=current_user)

@router.post("/{course_id}/publish",response_model=PublishCourseResponse,status_code=status.HTTP_200_OK,)
def publish_course(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.publish_course(
        course_id=course_id, 
        db=db, 
        current_user=current_user)

@router.get("/{course_id}/invitations", response_model=CourseInvitationsListResponse)
def list_course_invitations(
    course_id: int,
    limit: int = 200,
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.list_course_invitations(
        course_id=course_id,
        limit=limit,
        offset=offset,
        db=db,
        current_user=current_user,)

@router.post("/{course_id}/enroll", response_model=CourseEnrollResponse, status_code=status.HTTP_201_CREATED,)
def enroll_in_course_endpoint(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.enroll_in_course(
        course_id=course_id,
        db=db,
        current_user=current_user,)

@router.get("/{course_id}/enrollment-requests", response_model=CourseEnrollmentRequestsResponse, status_code=status.HTTP_200_OK,)
def list_enrollment_requests_endpoint(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.list_enrollment_requests(
        course_id=course_id,
        db=db,
        current_user=current_user,)

@router.patch("/{course_id}/enrollment-requests/{enrollment_id}", response_model=EnrollmentRequestUpdateResponse, status_code=status.HTTP_200_OK,)
def update_enrollment_request_endpoint(
    course_id: int,
    enrollment_id: int,
    payload: EnrollmentRequestUpdateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.update_enrollment_request(
        course_id=course_id,
        enrollment_id=enrollment_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.get("/search/autocomplete", response_model=CourseAutocompleteResponse, status_code=status.HTTP_200_OK,)
def course_autocomplete_endpoint(
    q: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.course_autocomplete(
        q=q,
        db=db,
        current_user=current_user,)

@router.get("/search", response_model=CourseSearchResponse, status_code=status.HTTP_200_OK,)
def course_search_endpoint(
    q: str,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.course_search(
        q=q,
        limit=limit,
        offset=offset,
        db=db,
        current_user=current_user,)

