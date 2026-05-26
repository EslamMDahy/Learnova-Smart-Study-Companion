from __future__ import annotations

import html
import random
from typing import Any

from weasyprint import HTML

from app.core.config import settings
from .handler import render_question_handler


def build_exam_export_context(*, exam_row: dict, course_row: dict, question_rows: list[dict],
                              include_learnova_logo: bool, include_course_title: bool, 
                              include_course_code: bool, include_exam_metadata: bool,
                              include_instructions: bool, include_points: bool,
                              include_student_info_fields: bool, include_answer_space: bool,
                              effective_shuffle_questions: bool, effective_shuffle_options: bool,) -> dict:
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
        "course": {
            "title": course_row.get("title"),
            "course_code": course_row.get("course_code"),
        },
        "display": {
            "include_learnova_logo": include_learnova_logo,
            "include_course_title": include_course_title,
            "include_course_code": include_course_code,
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
    course = context.get("course") or {}
    display = context["display"]
    questions = context["questions"]

    title = html.escape(str(exam.get("title") or "Exam"))
    exam_type = html.escape(str(exam.get("exam_type") or "exam"))

    course_title = html.escape(str(course.get("title") or ""))
    course_code = html.escape(str(course.get("course_code") or ""))

    duration_minutes = exam.get("duration_minutes")
    time_allowed = (
        f"{html.escape(str(duration_minutes))} minutes"
        if duration_minutes
        else "Not limited"
    )

    total_questions = html.escape(str(exam.get("total_questions") or 0))
    total_marks = html.escape(str(exam.get("total_score") or 0))

    # =========================
    # 2) Render header parts
    # =========================
    logo_html = ""
    if display.get("include_learnova_logo"):
        logo_html = f"""
        <div class="brand-logo">
            <img src="{html.escape(str(settings.email_logo_url or ''))}" alt="Learnova">
        </div>
        """

    course_title_html = ""
    if display.get("include_course_title") and course_title:
        course_title_html = f"""
        <div class="info-line">
            <span class="label">Course:</span>
            <span>{course_title}</span>
        </div>
        """

    course_code_html = ""
    if display.get("include_course_code") and course_code:
        course_code_html = f"""
        <div class="info-line">
            <span class="label">Course Code:</span>
            <span>{course_code}</span>
        </div>
        """

    metadata_html = ""
    if display.get("include_exam_metadata"):
        metadata_html = f"""
        <div class="stats-column">
            <div class="info-line">
                <span class="label">Time Allowed:</span>
                <span>{time_allowed}</span>
            </div>
            <div class="info-line">
                <span class="label">No. of Questions:</span>
                <span>{total_questions}</span>
            </div>
            <div class="info-line">
                <span class="label">Total Marks:</span>
                <span>{total_marks}</span>
            </div>
        </div>
        """

    student_info_html = ""
    if display.get("include_student_info_fields"):
        student_info_html = """
        <div class="student-column">
            <div class="student-line">
                <span class="label">Student Name:</span>
                <span class="blank-line"></span>
            </div>
            <div class="student-line">
                <span class="label">Student ID:</span>
                <span class="blank-line"></span>
            </div>
            <div class="student-line">
                <span class="label">Date:</span>
                <span class="blank-line"></span>
            </div>
        </div>
        """

    instructions_html = ""
    if display.get("include_instructions") and exam.get("instructions"):
        instructions_html = f"""
        <section class="instructions">
            <div class="section-title">Instructions</div>
            <div class="instructions-text">{html.escape(str(exam.get("instructions") or ""))}</div>
        </section>
        <div class="thin-separator"></div>
        """

    # =========================
    # 3) Render questions
    # =========================
    questions_html = "\n".join(
        f"""
        <section class="question-wrapper">
            {render_question_handler(question=question, context=context)}
        </section>
        """
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
            @page {{
                size: A4;
                margin: 18mm 14mm 16mm 14mm;

                @bottom-left {{
                    content: "Powered by Learnova";
                    font-family: Arial, sans-serif;
                    font-size: 11px;
                    color: #111111;
                    border-top: 2px solid #111111;
                    padding-top: 5px;
                    width: 100%;
                }}

                @bottom-right {{
                    content: "Page " counter(page) " of " counter(pages);
                    font-family: Arial, sans-serif;
                    font-size: 11px;
                    color: #111111;
                    border-top: 2px solid #111111;
                    padding-top: 5px;
                    width: 35mm;
                    text-align: right;
                    white-space: nowrap;
                }}
            }}

            * {{
                box-sizing: border-box;
            }}

            body {{
                font-family: Arial, sans-serif;
                color: #111111;
                font-size: 11px;
                line-height: 1.35;
                margin: 0;
                padding: 0;
            }}

            .exam-header {{
                width: 100%;
                display: table;
                table-layout: fixed;
                margin-bottom: 8px;
            }}

            .header-cell {{
                display: table-cell;
                vertical-align: top;
                padding-right: 10px;
            }}

            .logo-cell {{
                width: 65px;
            }}

            .course-column {{
                width: 29%;
                padding-left: 18px;
            }}

            .stats-cell {{
                width: 29%;
            }}

            .stats-column {{
                width: 100%;
            }}

            .student-column {{
                width: 34%;
                padding-right: 0;
            }}

            .brand-logo img {{
                width: 62px;
                height: 62px;
                object-fit: contain;
                display: block;
            }}

            .info-line {{
                margin-bottom: 3px;
                white-space: nowrap;
            }}

            .label {{
                font-weight: bold;
            }}

            .exam-title {{
                margin-top: 5px;
                font-weight: bold;
                font-size: 12px;
                line-height: 1.25;
            }}

            .student-line {{
                display: table;
                width: 100%;
                margin-bottom: 5px;
            }}

            .student-line .label {{
                display: table-cell;
                width: 78px;
                white-space: nowrap;
            }}

            .blank-line {{
                display: table-cell;
                border-bottom: 1px solid #111111;
                height: 12px;
            }}

            .thick-separator {{
                border-top: 2px solid #111111;
                margin: 8px 0 8px;
            }}

            .thin-separator {{
                border-top: 1px solid #777777;
                margin: 8px 0 10px;
            }}

            .instructions {{
                margin: 0 0 8px;
            }}

            .section-title {{
                font-weight: bold;
                margin-bottom: 3px;
            }}

            .instructions-text {{
                white-space: pre-line;
                font-size: 11px;
            }}

            .questions-area {{
                margin-top: 0;
            }}

            .question-wrapper {{
                padding: 8px 0 9px;
                border-bottom: 1px solid #777777;
                page-break-inside: avoid;
                break-inside: avoid;
            }}

            .question-block {{
                margin-bottom: 0;
                page-break-inside: avoid;
                break-inside: avoid;
            }}

            .question-title {{
                display: table;
                width: 100%;
                font-weight: bold;
                margin-bottom: 7px;
            }}

            .question-main {{
                display: table-cell;
                vertical-align: top;
                padding-right: 10px;
            }}

            .question-side {{
                display: table-cell;
                vertical-align: top;
                width: 78px;
                text-align: right;
                white-space: nowrap;
            }}

            .points {{
                font-weight: bold;
            }}

            .true-false-box {{
                display: inline-block;
                margin-right: 8px;
                font-weight: normal;
            }}

            .options-list {{
                margin-top: 3px;
            }}

            .option {{
                display: table;
                width: 100%;
                margin: 3px 0;
            }}

            .option-label {{
                display: table-cell;
                width: 20px;
                font-weight: bold;
            }}

            .option-text {{
                display: table-cell;
            }}

            .answer-lines {{
                margin-top: 8px;
            }}

            .answer-line {{
                height: 16px;
                border-bottom: 1px dotted #555555;
            }}
        </style>
    </head>
    <body>
        <header class="exam-header">
            <div class="header-cell logo-cell">
                {logo_html}
            </div>

            <div class="header-cell course-column">
                {course_title_html}
                {course_code_html}
                <div class="info-line">
                    <span class="label">Exam Type:</span>
                    <span>{exam_type}</span>
                </div>
                <div class="exam-title">{title}</div>
            </div>

            <div class="header-cell stats-cell">
                {metadata_html}
            </div>

            <div class="header-cell student-column">
                {student_info_html}
            </div>
        </header>

        <div class="thick-separator"></div>

        {instructions_html}

        <main class="questions-area">
            {questions_html}
        </main>
    </body>
    </html>
    """



def convert_html_to_pdf(html_content: str):
    # =========================
    # 1) Convert HTML to PDF bytes
    # =========================
    return HTML(string=html_content).write_pdf()