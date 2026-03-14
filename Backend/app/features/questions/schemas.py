from __future__ import annotations

from typing import List, Optional, Literal, Annotated
from pydantic import BaseModel, Field, ConfigDict


# -----------------------
# Shared constrained types
# -----------------------
ChoiceId = Annotated[str, Field(min_length=1, max_length=10)]
QuestionText = Annotated[str, Field(min_length=1, max_length=4000)]
ExplanationText = Annotated[Optional[str], Field(default=None, max_length=8000)]

# Pylance-safe int constraints (بدل conint)
MaxScore = Annotated[Optional[int], Field(default=None, ge=1, le=100)]

# Pylance-safe list constraints
ChoicesList = Annotated[List["MCQChoice"], Field(min_length=2, max_length=8)]
QuestionsList = Annotated[List["QuestionMCQCreate"], Field(min_length=1, max_length=200)]


# -----------------------
# MCQ option models
# -----------------------
class MCQChoice(BaseModel):
    id: ChoiceId = Field(..., description="Choice id, e.g. A/B/C/D")
    text: Annotated[str, Field(min_length=1, max_length=2000)]

    model_config = ConfigDict(extra="forbid")


class MCQOptions(BaseModel):
    # stored in DB as JSONB
    choices: ChoicesList

    model_config = ConfigDict(extra="forbid")


# -----------------------
# Request models
# -----------------------
class QuestionMCQCreate(BaseModel):
    question_text: QuestionText = Field(..., description="Question text")
    options: MCQOptions
    expected_answer: ChoiceId = Field(..., description="Correct choice id, e.g. B")
    explanation: ExplanationText

    # optional overrides (frontend may send, otherwise server defaults)
    difficulty: Optional[Literal["easy", "medium", "hard"]] = Field(default=None)
    max_score: MaxScore

    model_config = ConfigDict(extra="forbid")


class MaterialQuestionsBatchCreateRequest(BaseModel):
    questions: QuestionsList

    model_config = ConfigDict(extra="forbid")


# -----------------------
# Response models
# -----------------------
class QuestionCreatedItem(BaseModel):
    id: int
    question_text: str
    created_at: str  # ISO string

    model_config = ConfigDict(extra="forbid")


class MaterialQuestionsBatchCreateResponse(BaseModel):
    course_id: int
    module_id: int
    material_id: int
    created_count: int
    questions: List[QuestionCreatedItem]

    model_config = ConfigDict(extra="forbid")