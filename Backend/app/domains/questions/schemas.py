from __future__ import annotations

from datetime import datetime
from typing import List, Optional, Any

from pydantic import BaseModel, ConfigDict, Field


class QuestionOptionItem(BaseModel):
    id: str = Field(..., min_length=1, max_length=20)
    text: str = Field(..., min_length=1)

    model_config = ConfigDict(extra="forbid")

class QuestionCreateRequest(BaseModel):
    topic_id: int = Field(..., gt=0)
    question_text: str = Field(..., min_length=1)
    type: str = Field(..., min_length=1)
    difficulty: str = Field(..., min_length=1)

    explanation: Optional[str] = None
    options: Optional[List[QuestionOptionItem]] = None
    expected_answer: Optional[List[str] | str] = None
    grading_rubric: Optional[dict] = None

    model_config = ConfigDict(extra="forbid")

class QuestionCreateResponse(BaseModel):
    id: int
    course_id: int
    topic_id: int
    question_text: str
    explanation: Optional[str] = None
    options: Optional[list] = None
    type: str
    difficulty: str
    source: str
    approval_status: str
    expected_answer: Optional[List[str] | str] = None
    grading_rubric: Optional[dict] = None
    max_score: int
    auto_gradable: bool
    usage_count: int
    success_rate: Optional[float] = None
    average_time_seconds: Optional[float] = None
    tags: Optional[list] = None
    created_by: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(extra="forbid")


class QuestionListItem(BaseModel):
    id: int
    course_id: int
    topic_id: int
    question_text: str
    options: Optional[list] = None
    type: str
    difficulty: str
    source: str
    approval_status: str
    auto_gradable: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(extra="forbid")

class TopicQuestionListResponse(BaseModel):
    course_id: int
    topic_id: int
    questions: List[QuestionListItem]

    model_config = ConfigDict(extra="forbid")

class MaterialQuestionListResponse(BaseModel):
    course_id: int
    module_id: int
    material_id: int
    questions: List[QuestionListItem]

    model_config = ConfigDict(extra="forbid")

class ModuleQuestionListResponse(BaseModel):
    course_id: int
    module_id: int
    questions: List[QuestionListItem]

    model_config = ConfigDict(extra="forbid")

class CourseQuestionListResponse(BaseModel):
    course_id: int
    questions: List[QuestionListItem]

    model_config = ConfigDict(extra="forbid")


class QuestionTopicInfo(BaseModel):
    id: int
    title: str

    model_config = ConfigDict(extra="forbid")

class QuestionLearningOutcomeInfo(BaseModel):
    id: int
    title: str

    model_config = ConfigDict(extra="forbid")

class QuestionGetResponse(BaseModel):
    id: int
    course_id: int
    topic_id: int
    topic: QuestionTopicInfo
    learning_outcomes: List[QuestionLearningOutcomeInfo]

    question_text: str
    explanation: Optional[str] = None
    options: Optional[list] = None
    type: str
    difficulty: str
    source: str
    approval_status: str
    expected_answer: Optional[Any] = None
    grading_rubric: Optional[dict] = None
    max_score: int
    auto_gradable: bool
    usage_count: int
    success_rate: Optional[float] = None
    average_time_seconds: Optional[float] = None
    tags: Optional[list] = None
    created_by: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(extra="forbid")


class QuestionUpdateRequest(BaseModel):
    topic_id: Optional[int] = Field(None, gt=0)
    question_text: Optional[str] = None
    difficulty: Optional[str] = None

    explanation: Optional[str] = None
    options: Optional[List[QuestionOptionItem]] = None
    expected_answer: Optional[List[str] | str] = None
    grading_rubric: Optional[dict] = None
    tags: Optional[list] = None

    model_config = ConfigDict(extra="forbid")


class QuestionGenerationConfig(BaseModel):
    type: str = Field(..., min_length=1)
    difficulty: str = Field(..., min_length=1)
    count: int = Field(..., gt=0)

    model_config = ConfigDict(extra="forbid")

class QuestionGenerationTopicRequest(BaseModel):
    topic_id: int = Field(..., gt=0)
    question_configs: List[QuestionGenerationConfig] = Field(..., min_length=1)

    model_config = ConfigDict(extra="forbid")

class QuestionGenerationRequest(BaseModel):
    topics: List[QuestionGenerationTopicRequest] = Field(..., min_length=1)

    model_config = ConfigDict(extra="forbid")

class QuestionGenerationResponse(BaseModel):
    status: str
    ai_processing_started: bool
    message: Optional[str] = None
    questions: Optional[List[QuestionListItem]] = None

    model_config = ConfigDict(extra="forbid")

class ExtractNativeQuestionsResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    status: str
    ai_processing_started: bool
    message: str


class ApproveQuestionsRequest(BaseModel):
    question_ids: List[int] = Field(..., min_length=1)
    
    model_config = ConfigDict(extra="forbid")

class ApproveQuestionsResponse(BaseModel):
    approved_count: int
    
    model_config = ConfigDict(extra="forbid")


class QuestionImageInitiateRequest(BaseModel):
    content_type: str = Field(..., min_length=1)
    file_size_bytes: int = Field(..., gt=0)

    model_config = ConfigDict(extra="forbid")

class QuestionImageInitiateResponse(BaseModel):
    upload_url: str
    storage_key: str
    content_type: str
    max_bytes: int

    model_config = ConfigDict(extra="forbid")


class QuestionImageConfirmResponse(BaseModel):
    image_key: str
    download_url: str
    expires_in_seconds: int
    updated_at: datetime

    model_config = ConfigDict(extra="forbid")


