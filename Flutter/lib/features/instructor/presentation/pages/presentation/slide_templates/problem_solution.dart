part of '../instructor_presentation_page.dart';

class ProblemSolutionTemplate extends SlideTemplateBuilder {
  const ProblemSolutionTemplate();

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final problem = slide.problem ?? PresentationProblemContent.fromJson(const {});
    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    final elements = _lightMaster(slide);
    const gap = .34;
    final leftW = 5.72;
    final rightX = safeX + leftW + gap;
    final rightW = safeWidth - leftW - gap;

    elements.add(_rect(safeX, top, leftW, height, white,
        radius: panelRadius, line: border, shadow: true));
    elements.add(_text('PROBLEM', safeX + .34, top + .34, 1.25, .18,
        size: 9.5, color: primaryDark, bold: true, spacing: 1.0,
        maxLines: 1, lineHeight: 1.0));
    elements.add(_text(problem.statement, safeX + .34, top + .82,
        leftW - .68, 1.24,
        size: 19, color: ink, bold: true, maxLines: 5, lineHeight: 1.08));
    if (problem.given.isNotEmpty) {
      elements.add(_text('Given: ${problem.given.join('  •  ')}',
          safeX + .34, top + 2.28, leftW - .68, .48,
          size: 12, color: muted, bold: true, maxLines: 2,
          lineHeight: 1.14));
    }
    if ((problem.formula ?? '').isNotEmpty) {
      elements.add(_equationElement(
        PresentationEquationContent(value: problem.formula!),
        safeX + .34, top + 3.00, leftW - .68, .72,
        color: primaryDark, size: 22));
    }
    if ((problem.hint ?? '').isNotEmpty) {
      elements.add(_rect(safeX + .34, contentBottom - .88,
          leftW - .68, .58, primarySoft, radius: 14));
      elements.add(_text('Hint: ${problem.hint}', safeX + .56,
          contentBottom - .72, leftW - 1.12, .24,
          size: 11.5, color: primaryDark, maxLines: 2,
          align: TextAlign.center, lineHeight: 1.10));
    }

    elements.add(_rect(rightX, top, rightW, height, darkBlue,
        radius: panelRadius, shadow: true));
    elements.add(_text('SOLUTION PATH', rightX + .36, top + .34,
        2.35, .18,
        size: 9.5, color: cyan, bold: true, spacing: 1.0,
        maxLines: 1, lineHeight: 1.0));
    final steps = problem.solutionSteps.take(5).toList();
    final stepTop = top + .92;
    final answer = problem.finalAnswer ?? problem.answer;
    final reserved = problem.showAnswer && (answer ?? '').isNotEmpty ? .78 : .20;
    final stepH = (height - .92 - reserved) / math.max(1, steps.length);
    for (var i = 0; i < steps.length; i++) {
      final y = stepTop + i * stepH;
      elements.add(_oval(rightX + .36, y + stepH / 2 - .17, .34, '1B4A82'));
      elements.add(_text('${i + 1}', rightX + .45,
          y + stepH / 2 - .04, .16, .10,
          size: 8, color: white, bold: true, maxLines: 1,
          align: TextAlign.center, lineHeight: 1.0));
      elements.add(_text(steps[i], rightX + .92, y + .02,
          rightW - 1.30, stepH - .04,
          size: 12.8, color: white, maxLines: 2,
          verticalAlign: 'middle', lineHeight: 1.13));
    }
    if (problem.showAnswer && (answer ?? '').isNotEmpty) {
      elements.add(_rect(rightX + .36, contentBottom - .66,
          rightW - .72, .44, '123F52', radius: 14, line: '1D766B'));
      elements.add(_text('Answer: $answer', rightX + .58,
          contentBottom - .54, rightW - 1.16, .18,
          size: 13, color: 'A7F3D0', bold: true, maxLines: 1,
          align: TextAlign.center, lineHeight: 1.0));
    }
    return elements;
  }
}
