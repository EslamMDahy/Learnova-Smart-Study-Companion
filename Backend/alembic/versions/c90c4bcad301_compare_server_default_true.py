"""compare_server_default=True,

Revision ID: c90c4bcad301
Revises: c5d4a5901aa4
Create Date: 2026-02-05 00:56:01.315605

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c90c4bcad301'
down_revision: Union[str, Sequence[str], None] = 'c5d4a5901aa4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
