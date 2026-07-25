part of '../instructor_presentation_page.dart';

class CaseStudyTemplate extends SlideTemplateBuilder {
  const CaseStudyTemplate();

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final data = _map(slide.semanticData['case_study'] ?? slide.semanticData['content']);
    final sections = <Map<String, String>>[
      {'title': 'Context', 'value': _string(data['context']), 'color': primary},
      {'title': 'Challenge', 'value': _string(data['challenge']), 'color': warning},
      {'title': 'Evidence', 'value': _string(data['evidence'] ?? data['data']), 'color': indigo},
    ];
    final questions = _stringList(data['questions'] ?? data['discussion_questions']);
    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    final elements = _lightMaster(slide);
    const gap = .24;
    final panelW = (safeWidth - gap * 2) / 3;
    final discussH = .62;
    final panelH = height - discussH - .26;
    for (var i = 0; i < sections.length; i++) {
      final x = safeX + i * (panelW + gap);
      elements.add(_rect(x, top, panelW, panelH, white,
          radius: compactRadius, line: border, shadow: true));
      elements.add(_rect(x, top, panelW, .07, sections[i]['color']!, radius: 7));
      elements.add(_text(sections[i]['title']!.toUpperCase(),
          x + .28, top + .34, panelW - .56, .18,
          size: 9.5, color: sections[i]['color']!, bold: true,
          spacing: 1.0, maxLines: 1, lineHeight: 1.0));
      final sectionUnits =
          PresentationDesignTokens.textUnits(sections[i]['value']!);
      elements.add(_text(sections[i]['value']!, x + .28, top + .78,
          panelW - .56, panelH - 1.00,
          size: sectionUnits > 72 ? 11.8 : 13.2,
          color: inkSoft,
          maxLines: 8,
          verticalAlign: 'middle',
          lineHeight: 1.15));
    }
    final discussY = contentBottom - discussH;
    elements.add(_rect(safeX, discussY, safeWidth, discussH,
        darkBlue, radius: compactRadius));
    elements.add(_text('DISCUSS', safeX + .26, discussY + .22,
        1.12, .16, size: 9.2, color: cyan, bold: true,
        spacing: .9, maxLines: 1, lineHeight: 1.0));
    elements.add(_text(questions.take(2).join('   •   '), safeX + 1.58,
        discussY + .13, safeWidth - 1.88, .30,
        size: 12.2, color: white, maxLines: 2,
        align: TextAlign.center, verticalAlign: 'middle', lineHeight: 1.08));
    return elements;
  }
}
