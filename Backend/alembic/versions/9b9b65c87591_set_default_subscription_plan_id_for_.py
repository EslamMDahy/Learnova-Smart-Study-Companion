"""set default subscription_plan_id for organizations

Revision ID: 9b9b65c87591
Revises: 24f4c0aec0a1
Create Date: 2026-02-05 00:47:38.967481

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9b9b65c87591'
down_revision: Union[str, Sequence[str], None] = '24f4c0aec0a1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
