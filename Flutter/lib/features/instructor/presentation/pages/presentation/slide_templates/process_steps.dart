part of '../instructor_presentation_page.dart';

class ProcessStepsTemplate extends SlideTemplateBuilder {
  const ProcessStepsTemplate();

  // Learnova presentation palette. Keep this template aligned with the
  // website theme and the title-slide visual system.
  static const String _panel = '0B1B35';
  static const String _panelBorder = '27466D';
  static const String _panelText = 'E1EAF5';
  static const String _panelMuted = '7890AE';
  static const String _panelNumber = '173A66';
  static const String _panelAccentText = '76B8FA';

  static const String _accentColor = '137FEC';
  static const String _accentSoft = 'E8F3FF';
  static const String _accentBorder = 'CBE2FB';
  static const String _rule = 'E6EEF8';
  static const String _softFill = 'F7FAFF';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final content = _map(slide.semanticData['content']);
    final raw = slide.semanticData['process'] ??
        slide.semanticData['steps'] ??
        content['steps'];
    final items = _itemMaps(raw);
    final List<Map<String, dynamic>> steps = items.isNotEmpty
        ? items
        : slide.cards
            .map<Map<String, dynamic>>((card) => {
                  'title': card.heading,
                  'body': card.body,
                  'icon': card.icon,
                })
            .toList();
    final visible = steps.take(6).toList();
    final count = math.max(1, visible.length).toInt();
    final overview = _string(
      slide.semanticData['summary'] ??
          slide.semanticData['overview'] ??
          slide.semanticData['outcome'] ??
          content['lead'] ??
          content['summary'],
    );
    final resolvedOverview = overview.isEmpty
        ? 'Each stage builds on the decisions made in the step before it.'
        : overview;
    final rtl = _rtl(
      '${slide.title} $resolvedOverview ${visible.map((item) => '${item['title']} ${item['body']}').join(' ')}',
    );

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const railWidth = 3.18;
    const gap = .34;
    final processX = safeX + railWidth + gap;
    final processWidth = safeWidth - railWidth - gap;
    final elements = _lightMaster(slide);

    elements.addAll(
      _overviewRail(
        x: safeX,
        y: top,
        w: railWidth,
        h: height,
        count: count,
        overview: resolvedOverview,
        rtl: rtl,
      ),
    );
    elements.addAll(
      _processPanel(
        x: processX,
        y: top,
        w: processWidth,
        h: height,
        steps: visible,
        count: count,
        rtl: rtl,
      ),
    );

    return elements;
  }

  List<PresentationElement> _overviewRail({
    required double x,
    required double y,
    required double w,
    required double h,
    required int count,
    required String overview,
    required bool rtl,
  }) {
    final overviewSize = overview.length > 180
        ? 10.0
        : overview.length > 120
            ? 10.8
            : 11.6;

    return [
      _rect(
        x,
        y,
        w,
        h,
        _panel,
        radius: panelRadius,
        line: _panelBorder,
        lineWidth: 1,
        shadow: true,
      ),
      _rect(x + .34, y + .34, .62, .045, _accentColor, radius: 5),
      _text(
        'STRUCTURED METHOD',
        x + .34,
        y + .55,
        w - .68,
        .15,
        size: 7.6,
        color: _panelAccentText,
        bold: true,
        spacing: 1.22,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        count.toString().padLeft(2, '0'),
        x + .30,
        y + .93,
        1.66,
        .92,
        size: 56,
        color: _panelNumber,
        bold: true,
        maxLines: 1,
        lineHeight: .92,
      ),
      _text(
        count == 1 ? 'STEP' : 'STEPS',
        x + 1.76,
        y + 1.39,
        1.02,
        .16,
        size: 8.0,
        color: _panelMuted,
        bold: true,
        spacing: 1.24,
        maxLines: 1,
        lineHeight: 1.0,
      ),
      _line(x + .34, y + 2.04, w - .68, _panelBorder, width: 1),
      _text(
        'PROCESS OVERVIEW',
        x + .34,
        y + 2.31,
        w - .68,
        .15,
        size: 7.2,
        color: _panelMuted,
        bold: true,
        spacing: 1.15,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        overview,
        x + .34,
        y + 2.67,
        w - .68,
        math.max(.72, h - 3.62).toDouble(),
        size: overviewSize,
        color: _panelText,
        maxLines: 6,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.18,
      ),
      _line(x + .34, y + h - .72, w - .68, _panelBorder, width: 1),
      _text(
        'START',
        x + .34,
        y + h - .45,
        .72,
        .13,
        size: 7.0,
        color: _panelMuted,
        bold: true,
        spacing: .95,
        maxLines: 1,
        lineHeight: 1.0,
      ),
      _line(x + 1.09, y + h - .385, w - 2.18, _accentColor, width: 1.6),
      _text(
        'OUTCOME',
        x + w - 1.20,
        y + h - .45,
        .86,
        .13,
        size: 7.0,
        color: _panelMuted,
        bold: true,
        spacing: .88,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: 1.0,
      ),
    ];
  }

  List<PresentationElement> _processPanel({
    required double x,
    required double y,
    required double w,
    required double h,
    required List<Map<String, dynamic>> steps,
    required int count,
    required bool rtl,
  }) {
    const headerHeight = .98;
    const bottomPadding = .18;
    final rowsTop = y + headerHeight;
    final rowsHeight = h - headerHeight - bottomPadding;
    final rowHeight = rowsHeight / count;
    final dense = count >= 5;
    final titleSize = dense
        ? 10.7
        : count == 4
            ? 11.5
            : 12.6;
    final bodySize = dense
        ? 9.4
        : count == 4
            ? 10.1
            : 11.0;

    final elements = <PresentationElement>[
      _rect(
        x,
        y,
        w,
        h,
        white,
        radius: panelRadius,
        line: _accentBorder,
        lineWidth: 1,
        shadow: true,
      ),
      _rect(x + .34, y + .24, .58, .045, _accentColor, radius: 5),
      _text(
        'PROCESS MAP',
        x + .34,
        y + .40,
        1.58,
        .15,
        size: 7.5,
        color: _accentColor,
        bold: true,
        spacing: 1.18,
        maxLines: 1,
        lineHeight: 1.0,
      ),
      _text(
        'STEP',
        rtl ? x + w - .98 : x + .34,
        y + .66,
        .58,
        .15,
        size: 7.0,
        color: footer,
        bold: true,
        spacing: .92,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        'ACTION',
        rtl ? x + w - 3.02 : x + 1.10,
        y + .66,
        1.64,
        .15,
        size: 7.0,
        color: footer,
        bold: true,
        spacing: .92,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        'PURPOSE',
        rtl ? x + .34 : x + 3.22,
        y + .66,
        w - 3.56,
        .15,
        size: 7.0,
        color: footer,
        bold: true,
        spacing: .92,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _line(x + .34, y + .87, w - .68, _rule, width: 1),
    ];

    for (var index = 0; index < count; index++) {
      final item = index < steps.length ? steps[index] : <String, dynamic>{};
      final title = _string(item['title'] ?? item['heading']).isEmpty
          ? 'Step ${index + 1}'
          : _string(item['title'] ?? item['heading']);
      final body = _string(item['body'] ?? item['description']);
      final rowY = rowsTop + index * rowHeight;
      final numberX = rtl ? x + w - .82 : x + .34;
      final titleX = rtl ? x + w - 3.02 : x + 1.10;
      final bodyX = rtl ? x + .34 : x + 3.22;
      final titleWidth = body.isEmpty ? w - 1.78 : 1.72;
      final bodyWidth = w - 3.56;
      final boxSize = math.min(.46, rowHeight - .14).toDouble();
      final boxY = rowY + (rowHeight - boxSize) / 2;

      if (index.isOdd) {
        elements.add(
          _rect(
            x + .18,
            rowY + .03,
            w - .36,
            math.max(.20, rowHeight - .06).toDouble(),
            _softFill,
            radius: 10,
          ),
        );
      }

      elements.addAll([
        _rect(
          numberX,
          boxY,
          boxSize,
          boxSize,
          _accentSoft,
          radius: 9,
          line: _accentBorder,
          lineWidth: .8,
        ),
        _text(
          '${index + 1}'.padLeft(2, '0'),
          numberX,
          boxY + boxSize * .34,
          boxSize,
          boxSize * .24,
          size: dense ? 7.1 : 7.7,
          color: _accentColor,
          bold: true,
          spacing: .28,
          maxLines: 1,
          align: TextAlign.center,
          lineHeight: 1.0,
        ),
        _text(
          title,
          titleX,
          rowY + .08,
          titleWidth,
          math.max(.20, rowHeight - .16).toDouble(),
          size: body.isEmpty ? titleSize + 1.2 : titleSize,
          color: ink,
          bold: true,
          maxLines: body.isEmpty ? 2 : (dense ? 2 : 3),
          align: rtl ? TextAlign.right : TextAlign.left,
          verticalAlign: 'middle',
          lineHeight: 1.06,
        ),
        if (body.isNotEmpty)
          _text(
            body,
            bodyX,
            rowY + .07,
            bodyWidth,
            math.max(.20, rowHeight - .14).toDouble(),
            size: bodySize,
            color: inkSoft,
            maxLines: dense ? 2 : 3,
            align: rtl ? TextAlign.right : TextAlign.left,
            verticalAlign: 'middle',
            lineHeight: 1.12,
          ),
      ]);

      if (index < count - 1) {
        elements.add(
          _line(
            x + .34,
            rowY + rowHeight,
            w - .68,
            _rule,
            width: .8,
          ),
        );
      }
    }

    return elements;
  }
}
