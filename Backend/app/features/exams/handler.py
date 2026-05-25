from __future__ import annotations

import html
from typing import Any


def render_question_handler(*, question: dict, context: dict):
    # =========================
    # 1) Dispatch by question type
    # =========================
    question_type = str(question.get("type") or "").strip().lower()

    if question_type == "multiple_choice":
        options = question.get("options")

        if _is_multi_answer_question(question):
            return render_multi_choice_question(
                question=question,
                context=context,
            )

        return render_single_choice_question(
            question=question,
            context=context,
        )

    if question_type == "true_false":
        return render_true_false_question(
            question=question,
            context=context,
        )

    if question_type == "short_answer":
        return render_short_answer_question(
            question=question,
            context=context,
        )

    if question_type == "essay":
        return render_essay_question(
            question=question,
            context=context,
        )

    return render_unknown_question(
        question=question,
        context=context,
    )


def render_single_choice_question(*, question: dict, context: dict):
    # =========================
    # 1) Render single-choice question
    # =========================
    return _render_choice_question(
        question=question,
        context=context,
        marker="○",
    )


def render_multi_choice_question(*, question: dict, context: dict):
    # =========================
    # 1) Render multi-choice question
    # =========================
    return _render_choice_question(
        question=question,
        context=context,
        marker="☐",
    )


def render_true_false_question(*, question: dict, context: dict):
    # =========================
    # 1) Extract display settings
    # =========================
    display = context.get("display", {})
    include_points = bool(display.get("include_points"))

    # =========================
    # 2) Render question text
    # =========================
    question_number = html.escape(str(question.get("question_number") or ""))
    question_text = html.escape(str(question.get("question_text") or ""))
    points_html = _render_points(question=question) if include_points else ""

    return f"""
    <div class="question-block">
        <div class="question-title">
            {question_number}. {question_text} {points_html}
        </div>
        <div class="option">○ True</div>
        <div class="option">○ False</div>
    </div>
    """


def render_short_answer_question(*, question: dict, context: dict):
    # =========================
    # 1) Render written-answer question
    # =========================
    return _render_written_question(
        question=question,
        context=context,
        answer_class="answer-space",
    )


def render_essay_question(*, question: dict, context: dict):
    # =========================
    # 1) Render essay question
    # =========================
    return _render_written_question(
        question=question,
        context=context,
        answer_class="essay-space",
    )


def render_unknown_question(*, question: dict, context: dict):
    # =========================
    # 1) Render unsupported question safely
    # =========================
    display = context.get("display", {})
    include_points = bool(display.get("include_points"))

    question_number = html.escape(str(question.get("question_number") or ""))
    question_text = html.escape(str(question.get("question_text") or ""))
    question_type = html.escape(str(question.get("type") or "unknown"))
    points_html = _render_points(question=question) if include_points else ""

    return f"""
    <div class="question-block">
        <div class="question-title">
            {question_number}. {question_text} {points_html}
        </div>
        <div class="option">Unsupported question type: {question_type}</div>
    </div>
    """


def _render_choice_question(*, question: dict, context: dict, marker: str):
    # =========================
    # 1) Extract display settings
    # =========================
    display = context.get("display", {})
    include_points = bool(display.get("include_points"))
    include_answer_space = bool(display.get("include_answer_space"))

    # =========================
    # 2) Render question header
    # =========================
    question_number = html.escape(str(question.get("question_number") or ""))
    question_text = html.escape(str(question.get("question_text") or ""))
    points_html = _render_points(question=question) if include_points else ""

    # =========================
    # 3) Render options
    # =========================
    options_html = _render_options(
        options=question.get("options"),
        marker=marker,
    )

    answer_space_html = ""
    if include_answer_space:
        answer_space_html = "<div class='answer-space'></div>"

    return f"""
    <div class="question-block">
        <div class="question-title">
            {question_number}. {question_text} {points_html}
        </div>
        {options_html}
        {answer_space_html}
    </div>
    """


def _render_written_question(*, question: dict, context: dict, answer_class: str):
    # =========================
    # 1) Extract display settings
    # =========================
    display = context.get("display", {})
    include_points = bool(display.get("include_points"))
    include_answer_space = bool(display.get("include_answer_space"))

    # =========================
    # 2) Render question header
    # =========================
    question_number = html.escape(str(question.get("question_number") or ""))
    question_text = html.escape(str(question.get("question_text") or ""))
    points_html = _render_points(question=question) if include_points else ""

    answer_space_html = ""
    if include_answer_space:
        answer_space_html = f"<div class='{html.escape(answer_class)}'></div>"

    return f"""
    <div class="question-block">
        <div class="question-title">
            {question_number}. {question_text} {points_html}
        </div>
        {answer_space_html}
    </div>
    """


def _render_options(*, options: Any, marker: str):
    # =========================
    # 1) Validate options shape
    # =========================
    if not isinstance(options, list) or not options:
        return "<div class='option'>No options provided</div>"

    # =========================
    # 2) Render options
    # =========================
    rendered_options = []

    for option in options:
        option_text = _extract_option_text(option=option)
        rendered_options.append(
            f"<div class='option'>{html.escape(marker)} {html.escape(option_text)}</div>"
        )

    return "\n".join(rendered_options)


def _extract_option_text(*, option: Any):
    # =========================
    # 1) Extract option text safely
    # =========================
    if isinstance(option, dict):
        return str(
            option.get("text")
            or option.get("label")
            or option.get("value")
            or ""
        )

    return str(option or "")


def _render_points(*, question: dict):
    # =========================
    # 1) Render question points
    # =========================
    points = question.get("points")

    if points is None:
        points = question.get("max_score")

    return f"<span class='points'>({html.escape(str(points or 0))} pts)</span>"


def _is_multi_answer_question(question: dict):
    # =========================
    # 1) Detect multi-answer multiple choice
    # =========================
    expected_answer = question.get("expected_answer")

    if isinstance(expected_answer, list):
        return True

    if isinstance(expected_answer, dict):
        answers = (
            expected_answer.get("answers")
            or expected_answer.get("correct_answers")
            or expected_answer.get("correct_option_ids")
        )
        return isinstance(answers, list) and len(answers) > 1

    return False