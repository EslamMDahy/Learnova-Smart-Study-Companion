part of '../instructor_presentation_page.dart';

class PracticeActivityTemplate extends SlideTemplateBuilder {
  const PracticeActivityTemplate();

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final activity = _map(slide.semanticData['activity'] ?? slide.semanticData['content']);
    final task = _string(activity['task'] ?? activity['prompt']);
    final instructions = _stringList(activity['instructions'] ?? activity['steps']);
    final duration = _string(activity['duration'] ?? activity['time']);
    final deliverable = _string(activity['deliverable'] ?? activity['output']);
    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    final elements = _lightMaster(slide);
    const leftW = 4.26;
    const gap = .34;
    final rightX = safeX + leftW + gap;
    final rightW = safeWidth - leftW - gap;
    elements.add(_rect(safeX, top, leftW, height, darkBlue,
        radius: panelRadius, shadow: true));
    elements.add(_text('YOUR TASK', safeX + .36, top + .36,
        2.20, .20, size: 9.8, color: cyan, bold: true,
        spacing: 1.1, maxLines: 1, lineHeight: 1.0));
    final taskUnits = PresentationDesignTokens.textUnits(task);
    final taskSize = taskUnits > 42
        ? 17.5
        : taskUnits > 32
            ? 19.0
            : 21.0;
    elements.add(_text(task, safeX + .36, top + .92,
        leftW - .72, height - 1.92,
        size: taskSize, color: white, bold: true, maxLines: 7,
        lineHeight: 1.08));
    if (duration.isNotEmpty) {
      elements.add(_rect(safeX + .36, contentBottom - .76,
          1.48, .42, '173D6B', radius: 14));
      elements.add(_text(duration, safeX + .54,
          contentBottom - .64, 1.12, .16,
          size: 9.5, color: 'DDEBFA', bold: true, maxLines: 1,
          align: TextAlign.center, lineHeight: 1.0));
    }
    elements.add(_rect(rightX, top, rightW, height, white,
        radius: panelRadius, line: border, shadow: true));
    elements.add(_text('INSTRUCTIONS', rightX + .36, top + .36,
        2.60, .20, size: 9.8, color: primaryDark, bold: true,
        spacing: 1.1, maxLines: 1, lineHeight: 1.0));
    final visible = instructions.take(5).toList();
    final startY = top + .94;
    final reserved = deliverable.isNotEmpty ? .84 : .18;
    final itemH = (height - .94 - reserved) / math.max(1, visible.length);
    for (var i = 0; i < visible.length; i++) {
      final y = startY + i * itemH;
      final accent = _accent(i);
      elements.add(_oval(rightX + .36, y + itemH / 2 - .17, .34, accent.color));
      elements.add(_text('${i + 1}', rightX + .45,
          y + itemH / 2 - .04, .16, .10,
          size: 8, color: white, bold: true, maxLines: 1,
          align: TextAlign.center, lineHeight: 1.0));
      elements.add(_text(visible[i], rightX + .94, y + .02,
          rightW - 1.30, itemH - .04,
          size: 13.3, color: inkSoft, maxLines: 2,
          verticalAlign: 'middle', lineHeight: 1.14));
    }
    if (deliverable.isNotEmpty) {
      elements.add(_rect(rightX + .36, contentBottom - .70,
          rightW - .72, .54, primarySoft, radius: 14));
      elements.add(_text('Deliverable: $deliverable', rightX + .58,
          contentBottom - .62, rightW - 1.16, .38,
          size: PresentationDesignTokens.textUnits(deliverable) > 30
              ? 9.6
              : 10.4,
          color: primaryDark,
          bold: true,
          maxLines: 2,
          align: TextAlign.center,
          verticalAlign: 'middle',
          lineHeight: 1.06));
    }
    return elements;
  }
}
