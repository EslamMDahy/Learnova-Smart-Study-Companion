from __future__ import annotations

from datetime import datetime
from typing import Any, List, Optional, Union

from pydantic import BaseModel, ConfigDict, Field


class ExamCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    instructions: Optional[str] = None
    exam_type: str
    duration_minutes: Optional[int] = Field(default=None, gt=0)
    max_attempts: int = Field(default=1, gt=0)
    passing_score: Optional[float] = Field(default=None, ge=0)
    shuffle_questions: bool = False
    shuffle_options: bool = False
    available_from: Optional[datetime] = None
    available_to: Optional[datetime] = None
    access_code: Optional[str] = Field(default=None, max_length=50)


class ExamUpdateRequest(BaseModel):
    title: Optional[str] = Field(default=None, max_length=255)
    description: Optional[str] = None
    instructions: Optional[str] = None
    exam_type: Optional[str] = None
    duration_minutes: Optional[int] = Field(default=None, gt=0)
    max_attempts: Optional[int] = Field(default=None, gt=0)
    passing_score: Optional[float] = Field(default=None, ge=0)
    shuffle_questions: Optional[bool] = None
    shuffle_options: Optional[bool] = None
    available_from: Optional[datetime] = None
    available_to: Optional[datetime] = None
    access_code: Optional[str] = Field(default=None, max_length=50)

    model_config = ConfigDict(extra="forbid")


class ExamResponse(BaseModel):
    id: int
    course_id: int
    title: str
    description: Optional[str]
    instructions: Optional[str]
    exam_type: str
    duration_minutes: Optional[int]
    max_attempts: int
    passing_score: Optional[float]
    total_questions: int
    total_score: float
    is_published: bool
    is_auto_generated: bool
    shuffle_questions: bool
    shuffle_options: bool
    available_from: Optional[datetime]
    available_to: Optional[datetime]
    enable_proctoring: bool
    prevent_copy_paste: bool
    prevent_tab_switch: bool
    require_webcam: bool
    require_microphone: bool
    access_code: Optional[str]
    ip_restrictions: Optional[dict]
    created_by: int
    created_at: datetime
    updated_at: datetime


class ExamListItemResponse(BaseModel):
    id: int
    course_id: int
    title: str
    description: Optional[str]
    exam_type: str
    duration_minutes: Optional[int]
    max_attempts: int
    passing_score: Optional[float]
    total_questions: int
    total_score: float
    is_published: bool
    is_auto_generated: bool
    shuffle_questions: bool
    shuffle_options: bool
    available_from: Optional[datetime]
    available_to: Optional[datetime]
    created_by: int
    created_at: datetime
    updated_at: datetime


class ExamListResponse(BaseModel):
    course_id: int
    total: int
    exams: List[ExamListItemResponse]


class ExamSectionCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    question_type: str
    time_limit_minutes: Optional[int] = Field(default=None, gt=0)
    must_complete: bool = True

    model_config = ConfigDict(extra="forbid")


class ExamSectionUpdateRequest(BaseModel):
    title: Optional[str] = Field(default=None, max_length=255)
    description: Optional[str] = None
    question_type: Optional[str] = None
    time_limit_minutes: Optional[int] = Field(default=None, gt=0)
    must_complete: Optional[bool] = None

    model_config = ConfigDict(extra="forbid")


class ExamQuestionDetailResponse(BaseModel):
    exam_question_id: int
    question_id: int
    section_id: int
    order_index: int
    points: float
    custom_points: Optional[float]
    custom_instructions: Optional[str]

    topic_id: int
    question_text: str
    explanation: Optional[str]
    options: Optional[Any]
    type: str
    difficulty: str
    source: Optional[str]
    approval_status: Optional[str]
    expected_answer: Optional[Any]
    grading_rubric: Optional[Any]
    max_score: float
    auto_gradable: bool
    tags: Optional[Any]
    image_url: Optional[str]

    model_config = ConfigDict(extra="forbid")


class ExamSectionResponse(BaseModel):
    id: int
    exam_id: int
    title: str
    description: Optional[str]
    question_type: str
    order_index: int
    question_count: int
    section_score: float
    time_limit_minutes: Optional[int]
    must_complete: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(extra="forbid")


class ExamSectionDetailsResponse(BaseModel):
    id: int
    exam_id: int
    title: str
    description: Optional[str]
    question_type: str
    order_index: int
    question_count: int
    section_score: float
    time_limit_minutes: Optional[int]
    must_complete: bool
    created_at: datetime
    updated_at: datetime
    questions: List[ExamQuestionDetailResponse]

    model_config = ConfigDict(extra="forbid")


class ExamSectionReorderRequest(BaseModel):
    section_ids: List[int] = Field(..., min_length=1)

    model_config = ConfigDict(extra="forbid")


class ExamSectionReorderResponse(BaseModel):
    exam_id: int
    course_id: int
    section_ids: List[int]
    message: str

    model_config = ConfigDict(extra="forbid")


class ExamSectionDeleteResponse(BaseModel):
    exam_id: int
    course_id: int
    deleted_section_id: int
    message: str

    model_config = ConfigDict(extra="forbid")


class ExamAddQuestionsRequest(BaseModel):
    question_ids: List[int] = Field(..., min_length=1)


class ExamQuestionItemResponse(BaseModel):
    id: int
    exam_id: int
    section_id: Optional[int]
    question_id: int
    order_index: int
    points: float
    custom_points: Optional[float]
    custom_instructions: Optional[str]


class ExamAddQuestionsResponse(BaseModel):
    exam_id: int
    course_id: int
    section_id: int
    added_count: int
    section_question_count: int
    section_score: float
    exam_total_questions: int
    exam_total_score: float
    questions: List[ExamQuestionItemResponse]


class ExamRemoveQuestionResponse(BaseModel):
    exam_id: int
    course_id: int
    section_id: int
    removed_exam_question_id: int
    section_question_count: int
    section_score: float
    total_questions: int
    total_score: float
    message: str

    model_config = ConfigDict(extra="forbid")


class ExamQuestionReorderRequest(BaseModel):
    exam_question_ids: List[int] = Field(..., min_length=1)

    model_config = ConfigDict(extra="forbid")


class ExamQuestionReorderResponse(BaseModel):
    exam_id: int
    course_id: int
    section_id: int
    exam_question_ids: List[int]
    message: str

    model_config = ConfigDict(extra="forbid")


class ExamDetailsResponse(BaseModel):
    id: int
    course_id: int
    title: str
    description: Optional[str]
    instructions: Optional[str]
    exam_type: str
    duration_minutes: Optional[int]
    max_attempts: int
    passing_score: Optional[float]
    total_questions: int
    total_score: float
    is_published: bool
    is_auto_generated: bool
    shuffle_questions: bool
    shuffle_options: bool
    available_from: Optional[datetime]
    available_to: Optional[datetime]
    enable_proctoring: bool
    prevent_copy_paste: bool
    prevent_tab_switch: bool
    require_webcam: bool
    require_microphone: bool
    access_code: Optional[str]
    ip_restrictions: Optional[Any]
    created_by: int
    created_at: datetime
    updated_at: datetime
    sections: List[ExamSectionDetailsResponse]

    model_config = ConfigDict(extra="forbid")


class ExamPublishResponse(BaseModel):
    exam_id: int
    course_id: int
    is_published: bool
    total_questions: int
    total_score: float
    message: str

    model_config = ConfigDict(extra="forbid")


class ExamTemplateListItemResponse(BaseModel):
    id: int
    name: str
    exam_type: str
    is_default: bool
    duration_minutes: Optional[int]
    total_questions: int
    total_score: float
    sections_count: int

    model_config = ConfigDict(extra="forbid")


class ExamTemplateListResponse(BaseModel):
    course_id: int
    total: int
    templates: List[ExamTemplateListItemResponse]

    model_config = ConfigDict(extra="forbid")


class ExamTemplateSectionResponse(BaseModel):
    id: int
    template_id: int
    title: str
    question_type: str
    question_count: int
    points_per_question: float
    section_score: float
    order_index: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(extra="forbid")


class ExamTemplateDetailsResponse(BaseModel):
    id: int
    course_id: int
    name: str
    exam_type: str
    is_default: bool
    duration_minutes: Optional[int]
    max_attempts: int
    passing_score: Optional[float]
    shuffle_questions: bool
    shuffle_options: bool
    total_questions: int
    total_score: float
    created_at: datetime
    updated_at: datetime
    sections: List[ExamTemplateSectionResponse]

    model_config = ConfigDict(extra="forbid")


class ExamTemplateCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    exam_type: str = Field(..., min_length=1, max_length=100)
    duration_minutes: Optional[int] = Field(default=None, gt=0)
    max_attempts: int = Field(default=1, ge=0)
    passing_score: Optional[float] = Field(default=None, ge=0)
    shuffle_questions: bool = True
    shuffle_options: bool = True

    model_config = ConfigDict(extra="forbid")


class ExamTemplateUpdateRequest(BaseModel):
    name: Optional[str] = Field(default=None, max_length=255)
    exam_type: Optional[str] = Field(default=None, max_length=100)
    duration_minutes: Optional[int] = Field(default=None, gt=0)
    max_attempts: Optional[int] = Field(default=None, ge=0)
    passing_score: Optional[float] = Field(default=None, ge=0)
    shuffle_questions: Optional[bool] = None
    shuffle_options: Optional[bool] = None

    model_config = ConfigDict(extra="forbid")


class ExamTemplateDeleteResponse(BaseModel):
    course_id: int
    deleted_template_id: int
    message: str

    model_config = ConfigDict(extra="forbid")


class ExamTemplateSectionCreateRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    question_type: str = Field(..., min_length=1, max_length=100)
    question_count: int = Field(..., gt=0)
    points_per_question: float = Field(..., gt=0)

    model_config = ConfigDict(extra="forbid")


class ExamTemplateSectionUpdateRequest(BaseModel):
    title: Optional[str] = Field(default=None, max_length=255)
    question_type: Optional[str] = Field(default=None, max_length=100)
    question_count: Optional[int] = Field(default=None, gt=0)
    points_per_question: Optional[float] = Field(default=None, gt=0)

    model_config = ConfigDict(extra="forbid")


class ExamTemplateSectionDeleteResponse(BaseModel):
    course_id: int
    template_id: int
    deleted_section_id: int
    total_questions: int
    total_score: float
    message: str

    model_config = ConfigDict(extra="forbid")


class SectionDifficultyDistribution(BaseModel):
    easy: float = 0
    medium: float = 0
    hard: float = 0

    model_config = ConfigDict(extra="forbid")

class GenerateExamFromTemplateRequest(BaseModel):
    title: str
    topic_ids: Optional[List[int]] = None
    section_difficulty_distribution: dict[str, SectionDifficultyDistribution]

    model_config = ConfigDict(extra="forbid")

class GeneratedExamQuestionItemResponse(BaseModel):
    question_id: int
    topic_id: int
    question_text: str
    type: str
    difficulty: str
    explanation: Optional[str]
    options: Optional[Any]
    expected_answer: Optional[Any]
    max_score: float
    auto_gradable: bool
    tags: Optional[Any]

    model_config = ConfigDict(extra="forbid")


class GeneratedExamSectionResponse(BaseModel):
    id: int
    template_section_id: int
    title: str
    question_type: str
    question_count: int
    points_per_question: float
    section_score: float
    order_index: int
    time_limit_minutes: Optional[int]
    must_complete: bool
    questions: List[GeneratedExamQuestionItemResponse]

    model_config = ConfigDict(extra="forbid")


class GenerateExamFromTemplateResponse(BaseModel):
    id: int
    course_id: int
    title: str
    exam_type: str
    is_published: bool
    duration_minutes: Optional[int]
    max_attempts: int
    shuffle_questions: bool
    shuffle_options: bool
    total_questions: int
    total_score: float
    created_at: datetime
    updated_at: datetime
    sections: List[GeneratedExamSectionResponse]

    model_config = ConfigDict(extra="forbid")


class StudentExamListItemResponse(BaseModel):
    id: int
    course_id: int
    title: str
    description: Optional[str]
    exam_type: str
    duration_minutes: Optional[int]
    max_attempts: int
    passing_score: Optional[float]
    total_questions: int
    total_score: float
    available_from: Optional[datetime]
    available_to: Optional[datetime]
    is_available: bool

    model_config = ConfigDict(extra="forbid")

class StudentExamListResponse(BaseModel):
    course_id: int
    total: int
    exams: List[StudentExamListItemResponse]

    model_config = ConfigDict(extra="forbid")


class StudentExamQuestionOptionResponse(BaseModel):
    id: str
    text: str

    model_config = ConfigDict(extra="forbid")


class StudentExamQuestionResponse(BaseModel):
    exam_question_id: int
    question_id: int
    order_index: int
    points: float
    question_text: str
    type: str
    difficulty: str
    options: Optional[List[StudentExamQuestionOptionResponse]]
    auto_gradable: bool
    image_url: Optional[str]

    model_config = ConfigDict(extra="forbid")


class StudentExamSectionResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    question_type: str
    order_index: int
    question_count: int
    section_score: float
    time_limit_minutes: Optional[int]
    must_complete: bool
    questions: List[StudentExamQuestionResponse]

    model_config = ConfigDict(extra="forbid")


class StudentAttemptExamResponse(BaseModel):
    exam_id: int
    attempt_id: int
    attempt_number: int
    status: str
    started_at: datetime
    expires_at: Optional[datetime]
    title: str
    description: Optional[str]
    instructions: Optional[str]
    exam_type: str
    duration_minutes: Optional[int]
    total_questions: int
    total_score: float
    shuffle_questions: bool
    shuffle_options: bool
    enable_proctoring: bool
    prevent_copy_paste: bool
    prevent_tab_switch: bool
    require_webcam: bool
    require_microphone: bool
    sections: List[StudentExamSectionResponse]

    model_config = ConfigDict(extra="forbid")


class CodeAnswerText(BaseModel):
    code: str
    language: Optional[str] = None

    model_config = ConfigDict(extra="forbid")


class StudentSubmitAnswerRequest(BaseModel):
    exam_question_id: int
    selected_option_index: Optional[str] = None
    selected_option_indices: Optional[List[str]] = None
    answer_text: Optional[Union[str, CodeAnswerText]] = None
    time_taken_seconds: Optional[int] = None

    model_config = ConfigDict(extra="forbid")


class StudentSubmitAnswerResponse(BaseModel):
    attempt_id: int
    exam_question_id: int
    saved: bool

    model_config = ConfigDict(extra="forbid")


class StudentSubmitExamRequest(BaseModel):
    answers: Optional[List[StudentSubmitAnswerRequest]] = None
    time_spent_seconds: Optional[int] = None

    model_config = ConfigDict(extra="forbid")


class StudentSubmitExamResponse(BaseModel):
    attempt_id: int
    exam_id: int
    status: str
    total_score: Optional[float]
    percentage_score: Optional[float]
    is_passed: Optional[bool]
    correct_count: Optional[int]
    incorrect_count: Optional[int]
    unanswered_count: Optional[int]
    submitted_at: datetime

    model_config = ConfigDict(extra="forbid")



class StudentExamAttemptSummaryResponse(BaseModel):
    attempt_id: int
    attempt_number: int
    status: str
    started_at: datetime
    submitted_at: Optional[datetime]
    graded_at: Optional[datetime]
    total_score: float
    earned_score: Optional[float]
    percentage_score: Optional[float]
    is_passed: Optional[bool]

    model_config = ConfigDict(extra="forbid")


class StudentExamAttemptsListResponse(BaseModel):
    exam_id: int
    attempts: List[StudentExamAttemptSummaryResponse]

    model_config = ConfigDict(extra="forbid")



class StudentAnswerDetail(BaseModel):
    selected_option_index: Optional[int]
    selected_option_indices: Optional[List[int]]
    answer_text: Optional[str]

    model_config = ConfigDict(extra="forbid")


class StudentExamResultQuestionResponse(BaseModel):
    exam_question_id: int
    question_id: int
    order_index: int
    question_text: str
    type: str
    difficulty: str
    points: float
    options: Optional[List[StudentExamQuestionOptionResponse]]
    explanation: Optional[str]
    student_answer: StudentAnswerDetail
    correct_answer: Optional[Union[str, List[str]]]
    is_correct: Optional[bool]
    points_earned: Optional[float]
    teacher_feedback: Optional[str]
    image_url: Optional[str]

    model_config = ConfigDict(extra="forbid")


class StudentExamResultSectionResponse(BaseModel):
    id: int
    title: str
    order_index: int
    section_score: float
    questions: List[StudentExamResultQuestionResponse]

    model_config = ConfigDict(extra="forbid")


class StudentExamResultResponse(BaseModel):
    exam_id: int
    attempt_id: int
    attempt_number: int
    status: str
    is_fully_graded: bool
    started_at: datetime
    submitted_at: Optional[datetime]
    graded_at: Optional[datetime]
    time_spent_seconds: int
    total_score: float
    earned_score: Optional[float]
    percentage_score: Optional[float]
    is_passed: Optional[bool]
    correct_count: Optional[int]
    incorrect_count: Optional[int]
    unanswered_count: Optional[int]
    sections: List[StudentExamResultSectionResponse]

    model_config = ConfigDict(extra="forbid")



    


