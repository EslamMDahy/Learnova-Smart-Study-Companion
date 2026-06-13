from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import AIChatMessageType, AIChatContextType


class SourceItem(BaseModel):
    title: str
    page: Optional[int] = None
    model_config = ConfigDict(extra="forbid")


class SessionCreateRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)
    model_config = ConfigDict(extra="forbid")


class SessionResponse(BaseModel):
    id: int
    course_id: Optional[int]
    session_title: Optional[str]
    is_active: bool
    started_at: datetime
    last_message_at: Optional[datetime]
    model_config = ConfigDict(extra="forbid")


class MessageResponse(BaseModel):
    id: int
    session_id: int
    message_type: AIChatMessageType
    content: str
    sources: Optional[List[SourceItem]]
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


class CreateSessionResponse(BaseModel):
    session: SessionResponse
    message: MessageResponse
    model_config = ConfigDict(extra="forbid")