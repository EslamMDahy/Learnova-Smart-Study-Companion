part of '../instructor_presentation_page.dart';

class MultipleChoiceTemplate extends SlideTemplateBuilder {
  const MultipleChoiceTemplate();

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final problem = slide.problem ?? PresentationProblemContent.fromJson(const {});
    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    final elements = _lightMaster(slide);
    elements.add(_text(problem.statement, safeX + .18, top + .04,
        safeWidth - .36, .82,
        size: 20.5, color: ink, bold: true, maxLines: 3,
        align: TextAlign.center, lineHeight: 1.07));
    final choices = problem.choices.take(4).toList();
    const gapX = .30;
    const gapY = .26;
    final choiceW = (safeWidth - gapX) / 2;
    final choiceTop = top + 1.18;
    final choiceH = (height - 1.18 - gapY - .52) / 2;
    for (var i = 0; i < choices.length; i++) {
      final col = i % 2;
      final row = i ~/ 2;
      final x = safeX + col * (choiceW + gapX);
      final y = choiceTop + row * (choiceH + gapY);
      final isAnswer = problem.showAnswer &&
          (problem.answer ?? '').trim().isNotEmpty &&
          choices[i].trim() == problem.answer!.trim();
      final fill = isAnswer ? 'E8FFF6' : white;
      final lineColor = isAnswer ? success : border;
      elements.add(_rect(x, y, choiceW, choiceH, fill,
          radius: compactRadius, line: lineColor, shadow: true));
      elements.add(_oval(x + .24, y + choiceH / 2 - .25, .50,
          isAnswer ? success : (i.isEven ? primary : indigo)));
      elements.add(_text(String.fromCharCode(65 + i), x + .38,
          y + choiceH / 2 - .045, .22, .10,
          size: 8.8, color: white, bold: true, maxLines: 1,
          align: TextAlign.center, lineHeight: 1.0));
      elements.add(_text(choices[i], x + .98, y + .12,
          choiceW - 1.30, choiceH - .24,
          size: 15.5, color: inkSoft, bold: isAnswer, maxLines: 3,
          verticalAlign: 'middle', lineHeight: 1.10));
    }
    if ((problem.hint ?? '').isNotEmpty) {
      elements.add(_text('Hint: ${problem.hint}', safeX + .60,
          contentBottom - .36, safeWidth - 1.20, .22,
          size: 11.5, color: muted, italic: true, maxLines: 2,
          align: TextAlign.center, lineHeight: 1.10));
    }
    return elements;
  }
}
