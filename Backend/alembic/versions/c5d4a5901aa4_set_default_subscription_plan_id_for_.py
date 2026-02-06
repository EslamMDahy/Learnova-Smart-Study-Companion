"""set default subscription_plan_id for organizations

Revision ID: c5d4a5901aa4
Revises: 9b9b65c87591
Create Date: 2026-02-05 00:48:23.069157

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c5d4a5901aa4'
down_revision: Union[str, Sequence[str], None] = '9b9b65c87591'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.alter_column(
        "organizations",
        "subscription_plan_id",
        server_default=sa.text("1"),
        existing_type=sa.Integer(),
        existing_nullable=False,
    )

def downgrade():
    op.alter_column(
        "organizations",
        "subscription_plan_id",
        server_default=None,
        existing_type=sa.Integer(),
        existing_nullable=False,
    )
