"""adding defult to the status colum

Revision ID: 06850f35c3fe
Revises: c90c4bcad301
Create Date: 2026-02-06 12:48:58.995072

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '06850f35c3fe'
down_revision: Union[str, Sequence[str], None] = 'c90c4bcad301'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
