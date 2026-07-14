from dotenv import load_dotenv
load_dotenv() 
# test_export_handler.py (يتحط في جذر المشروع، مؤقت، يتمسح بعد الاختبار)

from app.db.session import SessionLocal
from app.domains.questions.service import question_bank_xlsx_export_handler

db = SessionLocal()
try:
    result = question_bank_xlsx_export_handler(db=db, payload={"course_id": 2})
    print(result)
finally:
    db.close()