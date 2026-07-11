part of '../instructor_presentation_page.dart';

class WorkedExampleTemplate extends SlideTemplateBuilder {
  const WorkedExampleTemplate();

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final problem =
        slide.problem ?? PresentationProblemContent.fromJson(const {});
    final finalAnswer = problem.finalAnswer ?? problem.answer ?? '';
    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    final elements = _lightMaster(slide);
    final problemUnits =
        PresentationDesignTokens.textUnits(problem.statement);
    final problemH = problemUnits > 55 ? 1.00 : .84;
    const answerH = .58;
    const gap = .22;
    final cardY = top + problemH + gap;
    final cardH = height - problemH - answerH - gap * 2;
    final cardW = (safeWidth - gap * 2) / 3;

    elements.add(_rect(safeX, top, safeWidth, problemH, primarySoft,
        radius: compactRadius, line: 'C7E2FF'));
    elements.add(_text('PROBLEM', safeX + .24, top + .27, .92, .16,
        size: 9.2,
        color: primaryDark,
        bold: true,
        spacing: 1.0,
        maxLines: 1,
        lineHeight: 1.0));
    elements.add(_text(problem.statement, safeX + 1.38, top + .15,
        safeWidth - 1.66, problemH - .30,
        size: problemUnits > 55 ? 15.2 : 16.5,
        color: ink,
        bold: true,
        maxLines: 3,
        verticalAlign: 'middle',
        lineHeight: 1.08));

    final columns = <Map<String, String>>[
      {
        'title': 'Given',
        'value': problem.given.isEmpty ? '—' : problem.given.join('\n'),
        'color': primary,
      },
      {
        'title': 'Formula',
        'value': problem.formula ?? '—',
        'color': indigo,
      },
      {
        'title': 'Substitute',
        'value': problem.solutionSteps.take(3).join('\n'),
        'color': cyan,
      },
    ];

    for (var i = 0; i < columns.length; i++) {
      final x = safeX + i * (cardW + gap);
      elements.add(_rect(x, cardY, cardW, cardH, white,
          radius: compactRadius, line: border, shadow: true));
      elements.add(_rect(x, cardY, cardW, .07,
          columns[i]['color']!, radius: 7));
      elements.add(_text(columns[i]['title']!.toUpperCase(),
          x + .26, cardY + .32, cardW - .52, .18,
          size: 9.5,
          color: columns[i]['color']!,
          bold: true,
          spacing: .9,
          maxLines: 1,
          lineHeight: 1.0));
      final value = columns[i]['value']!;
      if (i == 1 && value != '—') {
        final formulaUnits = PresentationDesignTokens.textUnits(value);
        final formulaSize = formulaUnits > 24
            ? 15.5
            : formulaUnits > 17
                ? 18.0
                : 21.0;
        elements.add(_equationElement(
          PresentationEquationContent(value: value),
          x + .26,
          cardY + .82,
          cardW - .52,
          cardH - 1.08,
          color: ink,
          size: formulaSize,
        ));
      } else {
        final valueUnits = PresentationDesignTokens.textUnits(value);
        final valueSize = i == 2
            ? (valueUnits > 75 ? 11.2 : 12.2)
            : (valueUnits > 38 ? 12.2 : 13.2);
        elements.add(_text(value, x + .26, cardY + .76,
            cardW - .52, cardH - 1.02,
            size: valueSize,
            color: inkSoft,
            bold: i == 0,
            maxLines: i == 2 ? 7 : 5,
            align: TextAlign.center,
            verticalAlign: 'middle',
            lineHeight: 1.13));
      }
    }

    final answerY = contentBottom - answerH;
    elements.add(_rect(safeX, answerY, safeWidth, answerH,
        darkBlue, radius: compactRadius));
    elements.add(_text('FINAL ANSWER', safeX + .26, answerY + .20,
        1.42, .15,
        size: 9.2,
        color: cyan,
        bold: true,
        spacing: .9,
        maxLines: 1,
        lineHeight: 1.0));
    elements.add(_text(
      finalAnswer.isEmpty
          ? problem.solutionSteps.skip(2).join(' ')
          : finalAnswer,
      safeX + 1.88,
      answerY + .12,
      safeWidth - 2.18,
      .30,
      size: PresentationDesignTokens.textUnits(
                  finalAnswer.isEmpty
                      ? problem.solutionSteps.skip(2).join(' ')
                      : finalAnswer,
                ) >
                32
            ? 13.8
            : 15.2,
      color: white,
      bold: true,
      maxLines: 1,
      align: TextAlign.center,
      verticalAlign: 'middle',
      lineHeight: 1.0,
    ));
    return elements;
  }
}
