import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.deps import get_current_user

from . import service
from .schemas import (QuestionCreateRequest, 
                      QuestionCreateResponse,
                      TopicQuestionListResponse,
                      MaterialQuestionListResponse,
                      ModuleQuestionListResponse,
                      CourseQuestionListResponse,
                      QuestionGetResponse,
                      QuestionUpdateRequest,
                      QuestionGenerationRequest,
                      QuestionGenerationResponse,
                      ExtractNativeQuestionsResponse,
                      ApproveQuestionsRequest,
                      ApproveQuestionsResponse,
                      QuestionImageInitiateRequest,
                      QuestionImageInitiateResponse,
                      QuestionImageConfirmResponse,
                      QuestionBankExportJobResponse)


router = APIRouter(prefix="/courses/{course_id}", tags=["Questions"],)


@router.post("/questions", response_model=QuestionCreateResponse, status_code=status.HTTP_201_CREATED)
def create_question(
    course_id: int,
    payload: QuestionCreateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.create_question(
        course_id=course_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.get("/modules/{module_id}/materials/{material_id}/topics/{topic_id}/questions", response_model=TopicQuestionListResponse,status_code=status.HTTP_200_OK,)
def list_topic_questions(
    course_id: int,
    module_id: int,
    material_id: int,
    topic_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.list_topic_questions(
        course_id=course_id,
        module_id=module_id,
        material_id=material_id,
        topic_id=topic_id,
        db=db,
        current_user=current_user,)

@router.get("/modules/{module_id}/materials/{material_id}/topics/{topic_id}/questions/pending", response_model=TopicQuestionListResponse, status_code=status.HTTP_200_OK,)
def list_pending_questions(
    course_id: int,
    module_id: int,
    material_id: int,
    topic_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.list_pending_questions(
        course_id=course_id,
        module_id=module_id,
        material_id=material_id,
        topic_id=topic_id,
        db=db,
        current_user=current_user,)

@router.get("/modules/{module_id}/materials/{material_id}/questions", response_model=MaterialQuestionListResponse,status_code=status.HTTP_200_OK,)
def list_material_questions(
    course_id: int,
    module_id: int,
    material_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.list_material_questions(
        course_id=course_id,
        module_id=module_id,
        material_id=material_id,
        db=db,
        current_user=current_user,)

@router.get("/modules/{module_id}/questions", response_model=ModuleQuestionListResponse, status_code=status.HTTP_200_OK,)
def list_module_questions(
    course_id: int,
    module_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.list_module_questions(
        course_id=course_id,
        module_id=module_id,
        db=db,
        current_user=current_user,)


@router.get("/questions", response_model=CourseQuestionListResponse, status_code=status.HTTP_200_OK,)
def list_course_questions(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.list_course_questions(
        course_id=course_id,
        db=db,
        current_user=current_user,)

@router.get("/questions/{question_id}", response_model=QuestionGetResponse, status_code=status.HTTP_200_OK)
def get_question(
    course_id: int,
    question_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.get_question(
        course_id=course_id,
        question_id=question_id,
        db=db,
        current_user=current_user,)

@router.patch("/questions/{question_id}/update", response_model=QuestionCreateResponse, status_code=status.HTTP_200_OK)
def update_question(
    course_id: int,
    question_id: int,
    payload: QuestionUpdateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.update_question(
        course_id=course_id,
        question_id=question_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.post("/questions/ai-generate", response_model=QuestionGenerationResponse, status_code=status.HTTP_200_OK,)
def generate_questions(
    course_id: int,
    payload: QuestionGenerationRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.generate_questions_for_topics(
        course_id=course_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.post("/materials/{material_id}/questions/extract-native", response_model=ExtractNativeQuestionsResponse, status_code=status.HTTP_200_OK,)
def extract_native_questions(
    course_id: int,
    material_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.extract_native_questions_from_material(
        course_id=course_id,
        material_id=material_id,
        db=db,
        current_user=current_user,)

@router.get("/materials/{material_id}/questions/extract-native/stream", status_code=status.HTTP_200_OK,)
async def stream_native_questions_endpoint(
    course_id: int,
    material_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return await service.stream_native_questions(
        course_id=course_id,
        material_id=material_id,
        db=db,
        current_user=current_user,)

@router.get("/questions/generation/stream", status_code=status.HTTP_200_OK,)
async def stream_question_generation_endpoint(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return await service.stream_question_generation(
        course_id=course_id,
        db=db,
        current_user=current_user,)

@router.patch("/modules/{module_id}/materials/{material_id}/topics/{topic_id}/questions/approve", response_model=ApproveQuestionsResponse, status_code=status.HTTP_200_OK,)
def approve_questions(
    course_id: int,
    module_id: int,
    material_id: int,
    topic_id: int,
    payload: ApproveQuestionsRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.approve_questions(
        course_id=course_id,
        module_id=module_id,
        material_id=material_id,
        topic_id=topic_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.post("/questions/{question_id}/image/initiate", response_model=QuestionImageInitiateResponse,)
def initiate_question_image_upload_route(
    course_id: int,
    question_id: int,
    payload: QuestionImageInitiateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.initiate_question_image_upload(
        course_id=course_id,
        question_id=question_id,
        payload=payload,
        db=db,
        current_user=current_user,)

@router.post("/questions/{question_id}/image/confirm", response_model=QuestionImageConfirmResponse,)
def confirm_question_image_upload_route(
    course_id: int,
    question_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.confirm_question_image_upload(
        course_id=course_id,
        question_id=question_id,
        db=db,
        current_user=current_user,)

@router.post("/questions/export", response_model=QuestionBankExportJobResponse, status_code=status.HTTP_202_ACCEPTED,)
def request_question_bank_export(
    course_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.request_question_bank_export(
        course_id=course_id,
        db=db,
        current_user=current_user,)

@router.get("/questions/export/{job_id}/stream")
async def stream_question_bank_export(
    course_id: int,
    job_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return await service.stream_question_bank_export(
        course_id=course_id,
        job_id=job_id,
        db=db,
        current_user=current_user,)


@router.get("/questions/export/{job_id}/download")
def download_question_bank_export(
    course_id: int,
    job_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user),):
    return service.download_question_bank_export(
        course_id=course_id,
        job_id=job_id,
        db=db,
        current_user=current_user,)



