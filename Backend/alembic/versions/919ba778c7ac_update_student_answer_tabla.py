"""update student answer tabla

Revision ID: 919ba778c7ac
Revises: dfbfb121f6ef
Create Date: 2026-07-15 09:15:29.006881

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '919ba778c7ac'
down_revision: Union[str, Sequence[str], None] = 'dfbfb121f6ef'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.alter_column(
        'student_answers', 'answer_text',
        existing_type=sa.TEXT(),
        type_=postgresql.JSONB(astext_type=sa.Text()),
        existing_nullable=True,
        postgresql_using='to_jsonb(answer_text)'
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.alter_column(
        'student_answers', 'answer_text',
        existing_type=postgresql.JSONB(astext_type=sa.Text()),
        type_=sa.TEXT(),
        existing_nullable=True,
        postgresql_using="answer_text #>> '{}'"
    )