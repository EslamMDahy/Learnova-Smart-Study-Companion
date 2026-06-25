"""add native_extraction to question_source_enum

Revision ID: 375e1b75bdfb
Revises: fcb00f5e9f1a
Create Date: 2026-06-25 03:17:37.896793

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '375e1b75bdfb'
down_revision: Union[str, Sequence[str], None] = 'fcb00f5e9f1a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.execute("ALTER TYPE question_source_enum ADD VALUE 'native_extraction'")

def downgrade():
    pass
