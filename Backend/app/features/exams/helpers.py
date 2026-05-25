from __future__ import annotations

import html
import random
from typing import Any

from weasyprint import HTML

from .handler import render_question_handler


def build_exam_export_context(*,
                              exam_row: dict,
                              question_rows: list[dict],
                              include_learnova_logo: bool,
                              include_exam_metadata: bool,
                              include_instructions: bool,
                              include_points: bool,
                              include_student_info_fields: bool,
                              include_answer_space: bool,
                              effective_shuffle_questions: bool,
                              effective_shuffle_options: bool,):
    # =========================
    # 1) Prepare questions copy
    # =========================
    questions = [dict(row) for row in question_rows]

    if effective_shuffle_questions:
        random.shuffle(questions)

    # =========================
    # 2) Normalize questions
    # =========================
    normalized_questions = []

    for index, question in enumerate(questions, start=1):
        options = question.get("options")

        if effective_shuffle_options and isinstance(options, list):
            options = list(options)
            random.shuffle(options)

        normalized_questions.append({
            **question,
            "question_number": index,
            "options": options,
        })

    # =========================
    # 3) Build export context
    # =========================
    return {
        "exam": {
            "id": exam_row.get("id"),
            "title": exam_row.get("title"),
            "description": exam_row.get("description"),
            "instructions": exam_row.get("instructions"),
            "exam_type": exam_row.get("exam_type"),
            "duration_minutes": exam_row.get("duration_minutes"),
            "total_questions": len(normalized_questions),
            "total_score": exam_row.get("total_score"),
        },
        "display": {
            "include_learnova_logo": include_learnova_logo,
            "include_exam_metadata": include_exam_metadata,
            "include_instructions": include_instructions,
            "include_points": include_points,
            "include_student_info_fields": include_student_info_fields,
            "include_answer_space": include_answer_space,
        },
        "questions": normalized_questions,
    }


def render_exam_pdf_html(context: dict):
    # =========================
    # 1) Extract context
    # =========================
    exam = context["exam"]
    display = context["display"]
    questions = context["questions"]

    title = html.escape(str(exam.get("title") or "Exam"))
    exam_type = html.escape(str(exam.get("exam_type") or "exam"))

    # =========================
    # 2) Render header
    # =========================
    logo_html = ""
    if display.get("include_learnova_logo"):
        logo_html = "<div class='logo'>Learnova</div>"

    metadata_html = ""
    if display.get("include_exam_metadata"):
        metadata_html = f"""
        <div class="metadata">
            <span>Type: {exam_type}</span>
            <span>Questions: {html.escape(str(exam.get("total_questions") or 0))}</span>
            <span>Total Score: {html.escape(str(exam.get("total_score") or 0))}</span>
            <span>Duration: {html.escape(str(exam.get("duration_minutes") or "Not limited"))}</span>
        </div>
        """

    instructions_html = ""
    if display.get("include_instructions") and exam.get("instructions"):
        instructions_html = f"""
        <div class="instructions">
            <strong>Instructions:</strong>
            <p>{html.escape(str(exam.get("instructions") or ""))}</p>
        </div>
        """

    student_info_html = ""
    if display.get("include_student_info_fields"):
        student_info_html = """
        <div class="student-info">
            <div>Name: ____________________________</div>
            <div>Student ID: ______________________</div>
            <div>Date: ____________________________</div>
        </div>
        """

    # =========================
    # 3) Render questions
    # =========================
    questions_html = "\n".join(
        render_question_handler(question=question, context=context)
        for question in questions
    )

    # =========================
    # 4) Return full HTML document
    # =========================
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {{
                font-family: Arial, sans-serif;
                color: #111827;
                line-height: 1.5;
                padding: 24px;
            }}
            .logo {{
                font-size: 22px;
                font-weight: bold;
                margin-bottom: 12px;
            }}
            h1 {{
                margin-bottom: 8px;
            }}
            .metadata {{
                display: flex;
                flex-wrap: wrap;
                gap: 12px;
                font-size: 13px;
                margin-bottom: 16px;
            }}
            .instructions {{
                border: 1px solid #ddd;
                padding: 12px;
                margin-bottom: 16px;
            }}
            .student-info {{
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 10px;
                margin-bottom: 24px;
            }}
            .question-block {{
                margin-bottom: 22px;
                page-break-inside: avoid;
            }}
            .question-title {{
                font-weight: bold;
                margin-bottom: 8px;
            }}
            .option {{
                margin: 4px 0;
            }}
            .answer-space {{
                margin-top: 12px;
                min-height: 60px;
                border-bottom: 1px solid #aaa;
            }}
            .essay-space {{
                margin-top: 12px;
                min-height: 160px;
                border: 1px solid #ccc;
            }}
        </style>
    </head>
    <body>
        {logo_html}
        <h1>{title}</h1>
        {metadata_html}
        {student_info_html}
        {instructions_html}
        {questions_html}
    </body>
    </html>
    """


def convert_html_to_pdf(html_content: str):
    # =========================
    # 1) Convert HTML to PDF bytes
    # =========================
    return HTML(string=html_content).write_pdf()