import os
import smtplib
from email.message import EmailMessage


def send_email(to_email: str, subject: str, body: str):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASS")

    if not smtp_host or not smtp_user or not smtp_pass:
        raise RuntimeError("Missing SMTP env vars: SMTP_HOST/SMTP_USER/SMTP_PASS")

    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = smtp_user
    msg["To"] = to_email
    msg.set_content(body)

    with smtplib.SMTP(smtp_host, smtp_port) as server:
        server.starttls()          # يشفر الاتصال (TLS)
        server.login(smtp_user, smtp_pass)
        server.send_message(msg)
