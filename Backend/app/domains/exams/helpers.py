from __future__ import annotations

import html
import random
import qrcode
import base64
import qrcode.image.svg

from typing import Any

from weasyprint import HTML

from io import BytesIO

from app.core.config import settings
from .handler import render_question_handler

from datetime import datetime, timezone
from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session



def build_exam_export_context(*, exam_row: dict, course_row: dict, section_rows: list[dict], question_rows: list[dict],
                              include_learnova_logo: bool, include_course_title: bool, include_course_code: bool, include_exam_metadata: bool,
                              include_instructions: bool, include_section_descriptions: bool, include_points: bool, include_student_info_fields: bool,
                              include_answer_space: bool, include_ocr_support: bool, effective_shuffle_questions: bool, effective_shuffle_options: bool,) -> dict:
    # =========================
    # 1) Prepare sections
    # =========================
    sections = []
    section_map = {}

    for section in section_rows:
        section_id = int(section["section_id"])

        section_data = {
            "id": section_id,
            "title": section.get("title"),
            "description": section.get("description"),
            "question_type": section.get("question_type"),
            "question_type_label": _format_question_type_label(
                question_type=section.get("question_type"),
            ),
            "order_index": section.get("order_index"),
            "total_questions": 0,
            "total_score": 0,
            "questions": [],
        }

        sections.append(section_data)
        section_map[section_id] = section_data

    # =========================
    # 2) Attach questions to sections
    # =========================
    for row in question_rows:
        question = dict(row)
        section_id = question.get("section_id")

        if section_id is None:
            continue

        section = section_map.get(int(section_id))
        if not section:
            continue

        section["questions"].append(question)

    # =========================
    # 3) Normalize questions inside each section
    # =========================
    flat_questions = []

    for section in sections:
        questions = list(section["questions"])

        if effective_shuffle_questions:
            random.shuffle(questions)

        normalized_questions = []

        for index, question in enumerate(questions, start=1):
            options = question.get("options")

            if effective_shuffle_options and isinstance(options, list):
                options = list(options)
                random.shuffle(options)

            normalized_question = {
                **question,
                "question_number": index,
                "options": options,
            }

            normalized_questions.append(normalized_question)
            flat_questions.append(normalized_question)

        section["questions"] = normalized_questions
        section["total_questions"] = len(normalized_questions)
        section["total_score"] = sum(
            float(question.get("points") or question.get("max_score") or 0)
            for question in normalized_questions
        )

    # =========================
    # 4) Build export context
    # =========================
    return {
        "exam": {
            "id": exam_row.get("id"),
            "title": exam_row.get("title"),
            "description": exam_row.get("description"),
            "instructions": exam_row.get("instructions"),
            "exam_type": exam_row.get("exam_type"),
            "duration_minutes": exam_row.get("duration_minutes"),
            "total_questions": len(flat_questions),
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
            "include_section_descriptions": include_section_descriptions,
            "include_points": include_points,
            "include_student_info_fields": include_student_info_fields,
            "include_answer_space": include_answer_space,
            "include_ocr_support": include_ocr_support,
            "shuffle_questions": effective_shuffle_questions,
            "shuffle_options": effective_shuffle_options,
        },
        "sections": sections,
        "questions": flat_questions,
    }


def render_exam_pdf_html(context: dict):
    # =========================
    # 1) Extract context
    # =========================
    exam = context["exam"]
    course = context.get("course") or {}
    display = context["display"]
    sections = context.get("sections") or []
    questions = context.get("questions") or []

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
    if display.get("include_student_info_fields") and not display.get("include_ocr_support"):
        student_info_html = """
        <div class="student-fields">
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

    ocr_mode_class = "ocr-mode" if display.get("include_ocr_support") else ""

    instructions_html = ""
    if display.get("include_instructions") and exam.get("instructions"):
        instructions_html = f"""
        <section class="instructions">
            <div class="section-title">Instructions</div>
            <div class="instructions-text">{html.escape(str(exam.get("instructions") or ""))}</div>
        </section>
        <div class="thin-separator"></div>
        """

    ocr_section_html = ""
    if display.get("include_ocr_support"):
        ocr_section_html = _render_ocr_section(
            exam=exam,
            course=course,
        )

    # =========================
    # 3) Render questions / sections
    # =========================
    questions_html = ""

    if sections:
        rendered_sections = []

        question_type_labels = {
            "multiple_choice": "Multiple Choice",
            "multi_select": "Multiple Select",
            "true_false": "True / False",
            "short_answer": "Short Answer",
            "essay": "Essay",
        }

        for section in sections:
            section_title = html.escape(str(section.get("title") or "Question"))
            raw_question_type = str(section.get("question_type") or "").strip().lower()
            question_type_label = html.escape(
                str(
                    section.get("question_type_label")
                    or question_type_labels.get(
                        raw_question_type,
                        raw_question_type.replace("_", " ").title() or "Questions",
                    )
                )
            )

            section_score = section.get("total_score")

            if section_score is None:
                formatted_section_score = "0"
            else:
                try:
                    numeric_section_score = float(section_score)
                    if numeric_section_score.is_integer():
                        formatted_section_score = str(int(numeric_section_score))
                    else:
                        formatted_section_score = str(numeric_section_score)
                except (TypeError, ValueError):
                    formatted_section_score = html.escape(str(section_score))

            section_score_label = (
                "mark"
                if formatted_section_score == "1"
                else "marks"
            )

            section_description_html = ""
            if display.get("include_section_descriptions") and section.get("description"):
                section_description_text = html.escape(str(section.get("description") or ""))
                section_description_html = f'<div class="exam-section-description">{section_description_text}</div>'

            section_questions = section.get("questions") or []

            section_questions_html = "\n".join(
                f"""
                <section class="question-wrapper">
                    {render_question_handler(question=question, context=context)}
                </section>
                """
                for question in section_questions
            )

            rendered_sections.append(
                f"""
                <section class="exam-section">
                    <div class="exam-section-title-row">
                        <span class="exam-section-main">
                            {section_title}: {question_type_label}
                        </span>
                        <span class="exam-section-score">
                            ({formatted_section_score} {section_score_label})
                        </span>
                    </div>

                    {section_description_html}

                    <div class="exam-section-questions">
                        {section_questions_html}
                    </div>
                </section>
                """
            )

        questions_html = "\n".join(rendered_sections)

    else:
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

            /* ========================= */
            /* Header                    */
            /* ========================= */

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

            .stats-cell.ocr-mode {{
                width: 54%;
                padding-left: 130px;
            }}

            .stats-column {{
                width: 100%;
            }}

            .student-column {{
                width: 27%;
                padding-right: 0;
            }}

            .student-fields {{
                width: 100%;
            }}

            .brand-logo img {{
                width: 62px;
                height: 62px;
                object-fit: contain;
                display: block;
            }}

            .info-line {{
                margin-bottom: 3px;
                white-space: normal;
                overflow-wrap: break-word;
                word-break: normal;
            }}

            .label {{
                font-weight: bold;
            }}

            .exam-title {{
                margin-top: 5px;
                font-weight: bold;
                font-size: 12px;
                line-height: 1.25;
                white-space: normal;
                overflow-wrap: break-word;
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

            /* ========================= */
            /* Separators                */
            /* ========================= */

            .thick-separator {{
                border-top: 2px solid #111111;
                margin: 8px 0 8px;
            }}

            .thin-separator {{
                border-top: 1px solid #777777;
                margin: 8px 0 10px;
            }}

            /* ========================= */
            /* Instructions              */
            /* ========================= */

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

            /* ========================= */
            /* OCR Section               */
            /* ========================= */

            .ocr-section {{
                margin: 10px 0;
                page-break-after: always;
            }}

            .ocr-top-row {{
                display: table;
                width: 100%;
                margin-bottom: 8px;
            }}

            .ocr-student-info {{
                display: table-cell;
                vertical-align: top;
                width: 40%;
                padding-right: 10px;
            }}

            .ocr-id-section {{
                display: table-cell;
                vertical-align: top;
                width: 60%;
                text-align: right;
            }}

            .ocr-id-label {{
                font-weight: bold;
                font-size: 11px;
                margin-bottom: 4px;
                text-align: left;
            }}

            .ocr-id-grid {{
                display: inline-block;
            }}

            .id-columns-row {{
                display: flex;
                margin-bottom: 2px;
            }}

            .id-col-header {{
                width: 24px;
                text-align: center;
                font-size: 11px;
                font-weight: bold;
                color: #111111;
            }}

            .id-write-row {{
                display: flex;
                margin-bottom: 4px;
            }}

            .id-write-box {{
                width: 20px;
                height: 20px;
                border: 1px solid #111111;
                margin-right: 4px;
                display: inline-block;
            }}

            .id-digit-row {{
                display: flex;
                margin-bottom: 2px;
            }}

            .id-bubble {{
                width: 20px;
                height: 20px;
                border: 1px solid #111111;
                border-radius: 50%;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                font-size: 9px;
                margin-right: 4px;
                text-align: center;
            }}

            .ocr-instructions {{
                margin: 8px 0;
            }}

            .ocr-instructions-list {{
                margin: 4px 0 0 0;
                padding-left: 16px;
                font-size: 11px;
            }}

            .ocr-instructions-list li {{
                margin-bottom: 3px;
            }}

            .ocr-bottom-row {{
                display: table;
                width: 100%;
                margin-top: 8px;
            }}

            .ocr-qr-block {{
                display: table-cell;
                vertical-align: middle;
                width: 80px;
                padding-right: 12px;
            }}

            .qr-image {{
                width: 75px;
                height: 75px;
                display: block;
            }}

            .ocr-exam-data {{
                display: table-cell;
                vertical-align: middle;
            }}

            /* ========================= */
            /* Exam Sections             */
            /* ========================= */

            .questions-area {{
                margin-top: 0;
            }}

            .exam-section {{
                margin-top: 12px;
            }}

            .exam-section:first-child {{
                margin-top: 0;
            }}

            .exam-section + .exam-section {{
                margin-top: 16px;
            }}

            .exam-section-title-row {{
                display: table;
                width: 100%;
                font-weight: bold;
                font-size: 13px;
                padding-bottom: 0px;
                margin-bottom: 0px;
                page-break-after: avoid;
            }}

            .exam-section-main {{
                display: table-cell;
                vertical-align: top;
                padding-right: 10px;
            }}

            .exam-section-score {{
                display: table-cell;
                vertical-align: top;
                width: 75px;
                text-align: right;
                white-space: nowrap;
            }}

            .exam-section-description {{
                font-size: 11px;
                font-style: italic;
                margin: 0 0 6px;
                white-space: pre-line;
            }}

            .exam-section-questions {{
                margin-left: 4mm;
                padding-left: 1mm;
            }}

            /* ========================= */
            /* Questions                 */
            /* ========================= */

            .question-wrapper {{
                padding: 6px 0 7px;
                border-bottom: 1px solid #777777;
                page-break-inside: avoid;
                break-inside: avoid;
            }}

            .exam-section-questions .question-wrapper:first-child {{
                padding-top: 4px;
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

            /* ========================= */
            /* Standard Options          */
            /* ========================= */

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

            /* ========================= */
            /* Standard Answer Lines     */
            /* ========================= */

            .answer-lines {{
                margin-top: 8px;
            }}

            .answer-line {{
                height: 16px;
                border-bottom: 1px dotted #555555;
            }}

            /* ========================= */
            /* True / False              */
            /* ========================= */

            .true-false-box {{
                display: inline-block;
                margin-right: 8px;
                font-weight: normal;
            }}

            /* ========================= */
            /* OCR Questions             */
            /* ========================= */

            .ocr-bubble {{
                display: inline-block;
                width: 14px;
                height: 14px;
                border: 1px solid #111111;
                border-radius: 50%;
                margin-right: 6px;
                vertical-align: middle;
            }}

            .ocr-option-label {{
                display: table-cell;
                width: 14px;
                font-weight: bold;
                padding-right: 4px;
            }}

            .ocr-option-text {{
                display: inline;
                vertical-align: middle;
            }}

            .ocr-answer-box-short {{
                border: 1px solid #111111;
                margin-top: 8px;
                height: 150px;
                width: 100%;
            }}

            .ocr-answer-box-essay {{
                border: 1px solid #111111;
                margin-top: 8px;
                height: 240px;
                width: 100%;
            }}

            .tf-ocr-question-main {{
                display: table-cell;
                vertical-align: top;
                padding-right: 10px;
                width: 500px;
            }}

            .question-side-tf-ocr {{
                display: table-cell;
                vertical-align: top;
                width: 100px;
                text-align: right;
                white-space: nowrap;
            }}

            .tf-ocr-inline {{
                display: inline-flex;
                gap: 10px;
                vertical-align: middle;
            }}

            .tf-ocr-option-inline {{
                display: inline-flex;
                flex-direction: column;
                align-items: center;
                gap: 2px;
            }}

            .tf-ocr-label {{
                font-size: 10px;
                font-weight: bold;
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

            <div class="header-cell stats-cell {ocr_mode_class}">
                {metadata_html}
            </div>

            <div class="header-cell student-column">
                {student_info_html}
            </div>
        </header>

        <div class="thick-separator"></div>

        {ocr_section_html}

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


def _format_question_type_label(*, question_type):
    # =========================
    # 1) Format section question type for display
    # =========================
    normalized_type = str(question_type or "").strip().lower()

    labels = {
        "multiple_choice": "Multiple Choice",
        "multi_select": "Multiple Select",
        "true_false": "True / False",
        "short_answer": "Short Answer",
        "essay": "Essay",
    }

    return labels.get(normalized_type, normalized_type.replace("_", " ").title())


def _render_ocr_section(*, exam: dict, course: dict):
    # =========================
    # 1) Prepare data
    # =========================
    exam_id = str(exam.get("id") or "")
    course_id = str(course.get("id") or "")
    course_title = html.escape(str(course.get("title") or ""))
    exam_title = html.escape(str(exam.get("title") or ""))
    duration_minutes = exam.get("duration_minutes")
    time_allowed = (
        f"{html.escape(str(duration_minutes))} minutes"
        if duration_minutes
        else "Not limited"
    )

    # =========================
    # 2) Generate QR code as base64 image
    # =========================
    qr_data = f"exam_id:{exam_id},course_id:{course_id}"
    qr = qrcode.QRCode(box_size=4, border=2)
    qr.add_data(qr_data)
    qr.make(fit=True)
    qr_image = qr.make_image(fill_color="black", back_color="white")
    buffer = BytesIO()
    qr_image.save(buffer)
    qr_b64 = base64.b64encode(buffer.getvalue()).decode("utf-8")
    qr_img_html = f'<img src="data:image/png;base64,{qr_b64}" class="qr-image" alt="QR Code">'

    # =========================
    # 3) Generate student ID bubble grid (10 digits, 0-9 each)
    # =========================
    write_row = "".join(
        f'<span class="id-write-box"></span>'
        for _ in range(10)
    )

    digit_rows = []
    for digit in range(10):
        bubbles = "".join(
            f'<span class="id-bubble">{digit}</span>'
            for _ in range(10)
        )
        digit_rows.append(f'<div class="id-digit-row">{bubbles}</div>')

    id_grid_html = f'<div class="id-write-row">{write_row}</div>' + "\n".join(digit_rows)

    # =========================
    # 4) Render full OCR section
    # =========================
    return f"""
    <div class="ocr-section">

        <div class="ocr-top-row">
            <div class="ocr-student-info" style="padding-top: 30px;">
                <div class="student-line">
                    <span class="label">Student Name:</span>
                    <span class="blank-line"></span>
                </div>
                <div class="student-line" style="margin-top: 6px;">
                    <span class="label">Date:</span>
                    <span class="blank-line"></span>
                </div>
            </div>
            <div class="ocr-id-section">
                <div class="ocr-id-grid">
                    <div class="ocr-id-label">Student ID</div>
                    <div class="id-columns-row">
                        {"".join(f'<span class="id-col-header">{i + 1}</span>' for i in range(10))}
                    </div>
                    {id_grid_html}
                </div>
            </div>
        </div>

        <div class="thin-separator"></div>

        <div class="ocr-instructions">
            <span class="label">Instructions: </span>
            <ul class="ocr-instructions-list">
                <li>Use a dark pen or pencil only. Do not use light-colored or erasable pens.</li>
                <li>Fill each bubble completely and darkly. Partially filled bubbles may not be read correctly.</li>
                <li>To fix a mistake, erase completely before filling another bubble.</li>
                <li>Fill your Student ID from left to right using one bubble per column. Fill remaining columns with zero.</li>
                <li>For Multiple Choice questions: fill only one bubble per question.</li>
                <li>For Multi-Select questions: fill all correct answer bubbles.</li>
                <li>For written questions: write clearly inside the answer box only. Do not write outside the borders.</li>
                <li>Do not fold, tear, or damage this paper in any way.</li>
                <li>Do not write anything outside the designated areas.</li>
                <li>Make sure the QR code at the bottom of this page is not covered or damaged.</li>
            </ul>
        </div>

        <div class="thin-separator"></div>

        <div class="ocr-bottom-row">
            <div class="ocr-qr-block">
                {qr_img_html}
            </div>
            <div class="ocr-exam-data">
                <div class="info-line"><span class="label">Course:</span> {course_title}</div>
                <div class="info-line"><span class="label">Exam:</span> {exam_title}</div>
                <div class="info-line"><span class="label">Duration:</span> {time_allowed}</div>
            </div>
        </div>

    </div>
    <div class="thick-separator"></div>
    """




def save_ai_exam_grading_results(*, db: Session, attempt_id: int, exam_id: int, results: list[dict],) -> dict:
    try:
        # =========================
        # 1) Fetch attempt + student_id
        # =========================
        attempt_row = db.execute(
            text("""
                SELECT id, student_id, exam_id
                FROM student_exam_attempts
                WHERE id = :attempt_id
                  AND exam_id = :exam_id
                LIMIT 1
            """),
            {
                "attempt_id": attempt_id,
                "exam_id":    exam_id,
            },
        ).mappings().first()

        if not attempt_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Attempt not found",
            )

        student_id = int(attempt_row["student_id"])

        # =========================
        # 2) Fetch exam questions for points bounds + question_id
        # =========================
        result_question_ids = [int(item["exam_question_id"]) for item in results]

        exam_question_rows = db.execute(
            text("""
                SELECT
                    eq.id          AS exam_question_id,
                    eq.points      AS max_score,
                    eq.question_id
                FROM exam_questions eq
                WHERE eq.exam_id = :exam_id
                  AND eq.id      = ANY(:question_ids)
            """),
            {
                "exam_id":      exam_id,
                "question_ids": result_question_ids,
            },
        ).mappings().all()

        exam_questions_by_id: dict[int, dict] = {
            int(row["exam_question_id"]): dict(row)
            for row in exam_question_rows
        }

        # =========================
        # 3) Fetch exam total_score + passing_score
        # =========================
        exam_row = db.execute(
            text("""
                SELECT total_score, passing_score
                FROM exams
                WHERE id = :exam_id
                LIMIT 1
            """),
            {"exam_id": exam_id},
        ).mappings().first()

        if not exam_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exam not found",
            )

        # =========================
        # 4) Update student_answers for each result
        # =========================
        for item in results:
            qid           = int(item["exam_question_id"])
            points_earned = float(item["points_earned"])
            feedback      = item.get("feedback")
            is_correct    = points_earned > 0

            eq_row = exam_questions_by_id.get(qid)
            if not eq_row:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"exam_question_id {qid} does not belong to exam {exam_id}",
                )

            if points_earned > float(eq_row["max_score"]):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"points_earned {points_earned} exceeds max_score {eq_row['max_score']} for exam_question_id {qid}",
                )

            db.execute(
                text("""
                    UPDATE student_answers
                    SET is_correct       = :is_correct,
                        points_earned    = :points_earned,
                        auto_graded      = TRUE,
                        teacher_feedback = :feedback,
                        updated_at       = NOW()
                    WHERE attempt_id       = :attempt_id
                      AND exam_question_id = :exam_question_id
                """),
                {
                    "attempt_id":       attempt_id,
                    "exam_question_id": qid,
                    "is_correct":       is_correct,
                    "points_earned":    points_earned,
                    "feedback":         feedback,
                },
            )

        # =========================
        # 5) Recalculate total score from all student_answers
        # =========================
        score_row = db.execute(
            text("""
                SELECT
                    COALESCE(SUM(points_earned), 0)                                  AS total_score,
                    COALESCE(SUM(CASE WHEN is_correct = TRUE  THEN 1 ELSE 0 END), 0) AS correct_count,
                    COALESCE(SUM(CASE WHEN is_correct = FALSE THEN 1 ELSE 0 END), 0) AS incorrect_count,
                    COALESCE(SUM(CASE WHEN is_correct IS NULL THEN 1 ELSE 0 END), 0) AS unanswered_count
                FROM student_answers
                WHERE attempt_id = :attempt_id
            """),
            {"attempt_id": attempt_id},
        ).mappings().first()

        if not score_row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to calculate attempt scores",
            )

        exam_total_score = float(exam_row["total_score"]) if exam_row["total_score"] else 1.0
        new_total_score  = float(score_row["total_score"])
        percentage_score = round((new_total_score / exam_total_score) * 100, 2)

        passing_score = exam_row["passing_score"]
        is_passed     = None
        if passing_score is not None:
            is_passed = percentage_score >= float(passing_score)

        # =========================
        # 6) Update attempt to graded
        # =========================
        db.execute(
            text("""
                UPDATE student_exam_attempts
                SET status           = 'graded',
                    graded_at        = NOW(),
                    total_score      = :total_score,
                    percentage_score = :percentage_score,
                    is_passed        = :is_passed,
                    correct_count    = :correct_count,
                    incorrect_count  = :incorrect_count,
                    unanswered_count = :unanswered_count
                WHERE id = :attempt_id
            """),
            {
                "attempt_id":       attempt_id,
                "total_score":      new_total_score,
                "percentage_score": percentage_score,
                "is_passed":        is_passed,
                "correct_count":    int(score_row["correct_count"]),
                "incorrect_count":  int(score_row["incorrect_count"]),
                "unanswered_count": int(score_row["unanswered_count"]),
            },
        )

        # =========================
        # 7) Update student_question_progress
        # =========================
        for item in results:
            qid    = int(item["exam_question_id"])
            eq_row = exam_questions_by_id.get(qid)

            if not eq_row:
                continue

            real_question_id = int(eq_row["question_id"])
            is_correct       = float(item["points_earned"]) > 0

            answer_row = db.execute(
                text("""
                    SELECT time_taken_seconds
                    FROM student_answers
                    WHERE attempt_id       = :attempt_id
                      AND exam_question_id = :exam_question_id
                    LIMIT 1
                """),
                {
                    "attempt_id":       attempt_id,
                    "exam_question_id": qid,
                },
            ).mappings().first()

            if not answer_row:
                continue

            time_taken = float(answer_row["time_taken_seconds"] or 0)

            db.execute(
                text("""
                    INSERT INTO student_question_progress (
                        student_id, question_id,
                        times_attempted, times_correct, times_wrong,
                        average_time_seconds, mastery_level,
                        last_attempted_at, last_correct_at
                    )
                    VALUES (
                        :student_id, :question_id,
                        1,
                        :times_correct,
                        :times_wrong,
                        :average_time_seconds,
                        'beginner',
                        NOW(),
                        :last_correct_at
                    )
                    ON CONFLICT (student_id, question_id)
                    DO UPDATE SET
                        times_attempted      = student_question_progress.times_attempted + 1,
                        times_correct        = student_question_progress.times_correct + :times_correct,
                        times_wrong          = student_question_progress.times_wrong + :times_wrong,
                        average_time_seconds = (
                            (student_question_progress.average_time_seconds * student_question_progress.times_attempted) + :average_time_seconds
                        ) / (student_question_progress.times_attempted + 1),
                        last_attempted_at    = NOW(),
                        last_correct_at      = CASE WHEN :is_correct THEN NOW() ELSE student_question_progress.last_correct_at END
                """),
                {
                    "student_id":           student_id,
                    "question_id":          real_question_id,
                    "times_correct":        1 if is_correct else 0,
                    "times_wrong":          0 if is_correct else 1,
                    "average_time_seconds": time_taken,
                    "last_correct_at":      datetime.now(timezone.utc) if is_correct else None,
                    "is_correct":           is_correct,
                },
            )

        return {
            "attempt_id":       attempt_id,
            "exam_id":          exam_id,
            "total_score":      new_total_score,
            "percentage_score": percentage_score,
            "is_passed":        is_passed,
            "correct_count":    int(score_row["correct_count"]),
            "incorrect_count":  int(score_row["incorrect_count"]),
            "unanswered_count": int(score_row["unanswered_count"]),
        }

    except HTTPException:
        raise

    except SQLAlchemyError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error while saving AI exam grading results",
        ) from exc

