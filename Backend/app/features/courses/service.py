from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text, bindparam
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from .schemas import CourseCreateRequest

def create_course(*, payload: CourseCreateRequest, db: Session, current_user: dict):
    role = current_user.get("system_role")
    if role != "instructor":
        raise HTTPException(status_code=403, detail="Only instructors can create courses")

    instructor_id = current_user["id"]

    stmt = text("""
        INSERT INTO courses (
            organization_id,
            created_by,
            title,
            description,
            cover_image_url,
            banner_image_url,
            is_public,
            visibility_level,
            requires_enrollment_approval,
            learning_outcomes,
            category,
            tags,
            course_type,
            enrollment_count,
            total_ratings,
            status,
            created_at,
            updated_at
        )
        VALUES (
            :organization_id,
            :created_by,
            :title,
            :description,
            :cover_image_url,
            :banner_image_url,
            :is_public,
            :visibility_level,
            :requires_enrollment_approval,
            :learning_outcomes,
            :category,
            :tags,
            :course_type,
            0,
            0,
            'draft',
            NOW(),
            NOW()
        )
        RETURNING
            id, title, course_type, organization_id, is_public, visibility_level, requires_enrollment_approval
    """).bindparams(
        bindparam("learning_outcomes", type_=JSONB),
        bindparam("tags", type_=JSONB),
    )

    params = {
        "organization_id": payload.organization_id,
        "created_by": instructor_id,
        "title": payload.title,
        "description": payload.description,
        "cover_image_url": payload.cover_image_url,
        "banner_image_url": payload.banner_image_url,
        "is_public": payload.is_public,
        "visibility_level": payload.visibility_level.value,
        "requires_enrollment_approval": payload.requires_enrollment_approval,
        "learning_outcomes": payload.learning_outcomes,  # list[str] | None
        "category": payload.category,
        "tags": payload.tags,  # list[str] | None
        "course_type": payload.course_type.value,
    }

    try:
        row = db.execute(stmt, params).mappings().first()
        if not row:
            raise HTTPException(status_code=503, detail="Failed to create course")
        db.commit()
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=409, detail="Course creation violates a constraint") from e
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Database error") from e

    return row
