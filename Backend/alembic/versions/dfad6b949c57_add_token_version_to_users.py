"""add token_version to users

Revision ID: dfad6b949c57
Revises: 66797c55cccf
Create Date: 2026-02-06 09:25:41.716884

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'dfad6b949c57'
down_revision: Union[str, Sequence[str], None] = '66797c55cccf'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
