# app/core/emailer.py

import os
import smtplib
from email.message import EmailMessage


def send_email(to: str, subject: str, body: str):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASS")
    smtp_from = os.getenv("SMTP_FROM") or smtp_user

    if not all([smtp_host, smtp_port, smtp_user, smtp_pass]):
        raise RuntimeError("Missing SMTP configuration")

    msg = EmailMessage()
    msg["From"] = smtp_from
    msg["To"] = to
    msg["Subject"] = subject
    msg.set_content(body)

    with smtplib.SMTP(smtp_host, smtp_port) as server:
        server.starttls()
        server.login(smtp_user, smtp_pass)
        server.send_message(msg)
