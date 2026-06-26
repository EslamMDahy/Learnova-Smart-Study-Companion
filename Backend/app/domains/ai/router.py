from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.orm import Session
import traceback
from app.db.session import get_db
from app.core.ai_service_integration.ai_callback_verifier import verify_ai_callback_request

from . import service

router = APIRouter(prefix="/ai", tags=["AI"])


@router.post("/callback", status_code=status.HTTP_200_OK)
async def ai_callback(
    request: Request,
    db: Session = Depends(get_db),):
    try:
        verified_callback = await verify_ai_callback_request(request)
        return service.handle_ai_callback(verified_callback=verified_callback, db=db,)
    except Exception as e:
        print("=== AI CALLBACK 500 ERROR ===")
        traceback.print_exc()
        raise
