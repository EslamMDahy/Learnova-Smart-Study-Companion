from __future__ import annotations

from datetime import datetime
from typing import Any, List, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.enums import AIChatMessageType, AIChatContextType


class SessionCreateRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)

    model_config = ConfigDict(extra="forbid")


class SessionResponse(BaseModel):
    id: int
    course_id: Optional[int]
    context_type: Optional[AIChatContextType] = None
    session_title: Optional[str]
    is_active: bool
    started_at: datetime
    last_message_at: Optional[datetime]

    model_config = ConfigDict(extra="forbid")


class CreateSessionResponse(BaseModel):
    session: SessionResponse
    message: "MessageResponse"

    model_config = ConfigDict(extra="forbid")


class SessionListResponse(BaseModel):
    course_id: int
    total: int
    sessions: List[SessionResponse]

    model_config = ConfigDict(extra="forbid")


class SourceItem(BaseModel):
    title: str
    page: Optional[int] = None

    # AI callbacks can include extra metadata such as url, score, chunk_id, etc.
    # The frontend only needs title/page, so ignore the rest instead of turning
    # an otherwise valid assistant answer into a 500 response validation error.
    model_config = ConfigDict(extra="ignore")


class MessageResponse(BaseModel):
    id: int
    session_id: int
    message_type: AIChatMessageType
    content: str
    sources: Optional[list] = []
    created_at: datetime

    model_config = ConfigDict(extra="forbid")



class SessionWithMessagesResponse(BaseModel):
    id: int
    course_id: Optional[int]
    context_type: AIChatContextType
    session_title: Optional[str]
    is_active: bool
    started_at: datetime
    last_message_at: Optional[datetime]
    messages: List[MessageResponse]

    model_config = ConfigDict(extra="forbid")
