part of '../instructor_presentation_page.dart';

class SummaryTemplate extends SlideTemplateBuilder {
  const SummaryTemplate();

  static const String _panel = '0B1B35';
  static const String _panelBorder = '27466D';
  static const String _panelText = 'E1EAF5';
  static const String _panelMuted = '7890AE';
  static const String _panelAccentText = '76B8FA';
  static const String _accentColor = '137FEC';
  static const String _accentSoft = 'E8F3FF';
  static const String _accentBorder = 'CBE2FB';
  static const String _rule = 'E6EEF8';
  static const String _softFill = 'F7FAFF';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final semantic = slide.semanticData;
    final content = _map(semantic['content']);
    final summary = _map(semantic['summary'] ?? semantic['content']);
    final points = _stringList(
      summary['points'] ??
          summary['bullets'] ??
          semantic['points'] ??
          content['points'] ??
          content['bullets'],
    ).where((point) => point.trim().isNotEmpty).take(6).toList();
    final takeaway = _string(
      summary['takeaway'] ??
          summary['key_takeaway'] ??
          semantic['takeaway'] ??
          semantic['key_takeaway'] ??
          content['takeaway'],
    );
    final next = _string(
      summary['next'] ??
          summary['next_steps'] ??
          semantic['next'] ??
          semantic['next_steps'] ??
          content['next'],
    );

    final rtl = _rtl(
      '${slide.title} $takeaway $next ${points.join(' ')}',
    );
    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const insightWidth = 3.48;
    const gap = .36;
    final recapX = safeX + insightWidth + gap;
    final recapWidth = safeWidth - insightWidth - gap;
    final elements = _lightMaster(slide);

    elements.addAll(
      _takeawayPanel(
        x: safeX,
        y: top,
        w: insightWidth,
        h: height,
        takeaway: takeaway,
        next: next,
        pointCount: points.length,
        rtl: rtl,
      ),
    );
    elements.addAll(
      _recapPanel(
        x: recapX,
        y: top,
        w: recapWidth,
        h: height,
        points: points,
        rtl: rtl,
      ),
    );

    return elements;
  }

  List<PresentationElement> _takeawayPanel({
    required double x,
    required double y,
    required double w,
    required double h,
    required String takeaway,
    required String next,
    required int pointCount,
    required bool rtl,
  }) {
    final resolvedTakeaway = takeaway.isEmpty
        ? 'Connect the central ideas before moving to the next topic.'
        : takeaway;
    final takeawayUnits = PresentationDesignTokens.textUnits(resolvedTakeaway);
    final takeawaySize = takeawayUnits > 115
        ? 15.0
        : takeawayUnits > 85
            ? 16.5
            : takeawayUnits > 58
                ? 18.0
                : 20.0;
    final hasNext = next.isNotEmpty;
    final takeawayHeight = hasNext
        ? math.max(1.38, h - 2.78).toDouble()
        : math.max(2.08, h - 2.08).toDouble();

    final elements = <PresentationElement>[
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
        'LECTURE SYNTHESIS',
        x + .34,
        y + .54,
        w - .68,
        .15,
        size: 7.6,
        color: _panelAccentText,
        bold: true,
        spacing: 1.18,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        'KEY TAKEAWAY',
        x + .34,
        y + .96,
        w - .68,
        .16,
        size: 7.2,
        color: _panelMuted,
        bold: true,
        spacing: 1.15,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        resolvedTakeaway,
        x + .34,
        y + 1.31,
        w - .68,
        takeawayHeight,
        size: takeawaySize,
        color: _panelText,
        bold: true,
        maxLines: 7,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.10,
      ),
    ];

    if (hasNext) {
      final nextY = y + h - 1.33;
      elements.addAll([
        _line(x + .34, nextY - .23, w - .68, _panelBorder, width: 1),
        _text(
          'UP NEXT',
          x + .34,
          nextY,
          w - .68,
          .14,
          size: 7.0,
          color: _panelMuted,
          bold: true,
          spacing: 1.14,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
        _text(
          next,
          x + .34,
          nextY + .30,
          w - .68,
          .65,
          size: next.length > 78
              ? 9.6
              : next.length > 48
                  ? 10.4
                  : 11.2,
          color: _panelText,
          bold: true,
          maxLines: 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.10,
        ),
      ]);
    } else {
      elements.addAll([
        _line(x + .34, y + h - .72, w - .68, _panelBorder, width: 1),
        _text(
          '${pointCount.toString().padLeft(2, '0')} CORE IDEAS',
          x + .34,
          y + h - .45,
          w - .68,
          .14,
          size: 7.0,
          color: _panelMuted,
          bold: true,
          spacing: 1.02,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
      ]);
    }

    return elements;
  }

  List<PresentationElement> _recapPanel({
    required double x,
    required double y,
    required double w,
    required double h,
    required List<String> points,
    required bool rtl,
  }) {
    final count = math.max(1, points.length).toInt();
    const headerHeight = .92;
    const bottomPadding = .18;
    final rowsTop = y + headerHeight;
    final rowsHeight = h - headerHeight - bottomPadding;
    final rowHeight = rowsHeight / count;
    final dense = count >= 5 || rowHeight < .68;
    final pointSize = dense
        ? 10.4
        : count == 4
            ? 11.2
            : count == 3
                ? 12.0
                : 13.0;
    final numberX = rtl ? x + w - .79 : x + .34;
    final textX = rtl ? x + .34 : x + 1.18;
    final textWidth = w - 1.52;

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
        'LECTURE RECAP',
        x + .34,
        y + .40,
        2.02,
        .15,
        size: 7.5,
        color: _accentColor,
        bold: true,
        spacing: 1.18,
        maxLines: 1,
        lineHeight: 1.0,
      ),
      _text(
        '${points.length.toString().padLeft(2, '0')} KEY IDEAS',
        x + w - 2.10,
        y + .40,
        1.76,
        .15,
        size: 7.0,
        color: footer,
        bold: true,
        spacing: .84,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: 1.0,
      ),
      _line(x + .34, y + .74, w - .68, _rule, width: 1),
    ];

    for (var index = 0; index < count; index++) {
      final point = index < points.length ? points[index] : '';
      final rowY = rowsTop + index * rowHeight;
      if (index.isOdd) {
        elements.add(
          _rect(
            x + .18,
            rowY + .03,
            w - .36,
            math.max(.30, rowHeight - .06).toDouble(),
            _softFill,
            radius: 10,
          ),
        );
      }

      final badgeSize = math.min(.46, rowHeight - .15).toDouble();
      final badgeY = rowY + (rowHeight - badgeSize) / 2;
      elements.addAll([
        _rect(
          numberX,
          badgeY,
          badgeSize,
          badgeSize,
          _accentSoft,
          radius: 9,
          line: _accentBorder,
          lineWidth: .8,
        ),
        _text(
          '${index + 1}'.padLeft(2, '0'),
          numberX,
          badgeY,
          badgeSize,
          badgeSize,
          size: dense ? 7.3 : 7.8,
          color: _accentColor,
          bold: true,
          maxLines: 1,
          align: TextAlign.center,
          verticalAlign: 'middle',
          lineHeight: 1.0,
        ),
        _line(
          rtl ? x + w - 1.12 : x + .94,
          rowY + rowHeight / 2,
          .18,
          _accentColor,
          width: 1.8,
        ),
        _text(
          point,
          textX,
          rowY + .07,
          textWidth,
          math.max(.26, rowHeight - .14).toDouble(),
          size: pointSize,
          color: inkSoft,
          maxLines: dense ? 2 : 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          verticalAlign: 'middle',
          lineHeight: 1.13,
        ),
        if (index < count - 1)
          _line(
            x + .34,
            rowY + rowHeight,
            w - .68,
            _rule,
            width: .8,
          ),
      ]);
    }

    return elements;
  }
}
