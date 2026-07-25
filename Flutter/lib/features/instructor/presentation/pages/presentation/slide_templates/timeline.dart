part of '../instructor_presentation_page.dart';

class TimelineTemplate extends SlideTemplateBuilder {
  const TimelineTemplate();

  // Learnova presentation palette. Timeline intentionally uses the same
  // navy, primary blue, and quiet surface colors as the website and title
  // slide. There are no detached vertical accent bars in this layout.
  static const String _panel = '0B1B35';
  static const String _panelBorder = '27466D';
  static const String _panelText = 'E1EAF5';
  static const String _panelMuted = '7890AE';
  static const String _panelNumber = '173A66';
  static const String _panelAccentText = '76B8FA';

  static const String _accentColor = '137FEC';
  static const String _accentBorder = 'CBE2FB';
  static const String _rule = 'E6EEF8';
  static const String _softFill = 'F7FAFF';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final content = _map(slide.semanticData['content']);
    final items = _itemMaps(
      slide.semanticData['timeline'] ?? slide.semanticData['items'],
    );
    final visible = items.take(6).toList();
    final count = math.max(1, visible.length).toInt();
    final overview = _string(
      slide.semanticData['summary'] ??
          slide.semanticData['overview'] ??
          slide.semanticData['context'] ??
          content['lead'] ??
          content['summary'],
    );
    final resolvedOverview = overview.isEmpty
        ? 'Follow the milestones in order to see how the subject developed over time.'
        : overview;

    final firstLabel = visible.isEmpty ? 'START' : _itemLabel(visible.first, 0);
    final lastLabel = visible.isEmpty
        ? 'END'
        : _itemLabel(visible.last, visible.length - 1);
    final rtl = _rtl(
      '${slide.title} $resolvedOverview '
      '${visible.map((item) => '${item['date']} ${item['label']} ${item['title']} ${item['body']}').join(' ')}',
    );

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const railWidth = 3.18;
    const gap = .34;
    final timelineX = safeX + railWidth + gap;
    final timelineWidth = safeWidth - railWidth - gap;
    final elements = _lightMaster(slide);

    elements.addAll(
      _overviewRail(
        x: safeX,
        y: top,
        w: railWidth,
        h: height,
        count: count,
        overview: resolvedOverview,
        firstLabel: firstLabel,
        lastLabel: lastLabel,
        rtl: rtl,
      ),
    );
    elements.addAll(
      _timelineLedger(
        x: timelineX,
        y: top,
        w: timelineWidth,
        h: height,
        items: visible,
        count: count,
        firstLabel: firstLabel,
        lastLabel: lastLabel,
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
    required String firstLabel,
    required String lastLabel,
    required bool rtl,
  }) {
    final overviewSize = overview.length > 180
        ? 9.8
        : overview.length > 120
            ? 10.6
            : 11.4;

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
        'CHRONOLOGY',
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
        y + .86,
        1.66,
        .92,
        size: 56,
        color: _panelNumber,
        bold: true,
        maxLines: 1,
        lineHeight: .92,
      ),
      _text(
        count == 1 ? 'MILESTONE' : 'MILESTONES',
        x + 1.72,
        y + 1.31,
        1.12,
        .16,
        size: 7.7,
        color: _panelMuted,
        bold: true,
        spacing: 1.10,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: 1.0,
      ),
      _line(x + .34, y + 1.85, w - .68, _panelBorder, width: 1),
      _text(
        'TIMELINE OVERVIEW',
        x + .34,
        y + 2.10,
        w - .68,
        .15,
        size: 7.2,
        color: _panelMuted,
        bold: true,
        spacing: 1.12,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        overview,
        x + .34,
        y + 2.42,
        w - .68,
        math.max(.64, h - 3.46).toDouble(),
        size: overviewSize,
        color: _panelText,
        maxLines: 6,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.18,
      ),
      _line(x + .34, y + h - .78, w - .68, _panelBorder, width: 1),
      _text(
        'PERIOD',
        x + .34,
        y + h - .61,
        w - .68,
        .13,
        size: 6.9,
        color: _panelMuted,
        bold: true,
        spacing: 1.08,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        _compactPeriod(firstLabel, lastLabel),
        x + .34,
        y + h - .36,
        w - .68,
        .22,
        size: 9.2,
        color: _panelText,
        bold: true,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ];
  }

  List<PresentationElement> _timelineLedger({
    required double x,
    required double y,
    required double w,
    required double h,
    required List<Map<String, dynamic>> items,
    required int count,
    required String firstLabel,
    required String lastLabel,
    required bool rtl,
  }) {
    const headerHeight = .91;
    const bottomPadding = .16;
    final rowsTop = y + headerHeight;
    final rowsHeight = h - headerHeight - bottomPadding;
    final rowHeight = rowsHeight / count;
    final dense = count >= 5;
    final veryDense = count >= 6;
    final titleSize = veryDense
        ? 9.6
        : dense
            ? 10.2
            : count == 4
                ? 11.0
                : 12.1;
    final bodySize = veryDense
        ? 8.2
        : dense
            ? 8.7
            : count == 4
                ? 9.4
                : 10.3;
    final titleHeight = dense ? .20 : .25;
    final bodyTop = dense ? .34 : .41;

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
        'TIMELINE LEDGER',
        x + .34,
        y + .40,
        1.80,
        .15,
        size: 7.5,
        color: _accentColor,
        bold: true,
        spacing: 1.16,
        maxLines: 1,
        lineHeight: 1.0,
      ),
      _text(
        _compactPeriod(firstLabel, lastLabel),
        x + w - 3.02,
        y + .40,
        2.68,
        .15,
        size: 7.2,
        color: footer,
        bold: true,
        spacing: .55,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: 1.0,
      ),
      _line(x + .34, y + .72, w - .68, _rule, width: 1),
    ];

    for (var index = 0; index < count; index++) {
      final item = index < items.length ? items[index] : <String, dynamic>{};
      final label = _itemLabel(item, index);
      final title = _string(
        item['title'] ?? item['heading'] ?? item['event'] ?? item['milestone'],
      );
      final body = _string(
        item['body'] ?? item['description'] ?? item['detail'] ?? item['summary'],
      );
      final resolvedTitle = title.isEmpty ? 'Milestone ${index + 1}' : title;
      final rowY = rowsTop + index * rowHeight;
      final numberX = rtl ? x + w - .72 : x + .34;
      final labelX = rtl ? x + w - 2.47 : x + 1.05;
      final contentX = rtl ? x + .34 : x + 2.68;
      final contentWidth = w - 3.02;
      final rowTextAlign = rtl ? TextAlign.right : TextAlign.left;

      if (index.isEven) {
        elements.add(
          _rect(
            x + .16,
            rowY + .03,
            w - .32,
            math.max(.28, rowHeight - .06).toDouble(),
            _softFill,
            radius: compactRadius,
          ),
        );
      }

      elements.addAll([
        _text(
          '${index + 1}'.padLeft(2, '0'),
          numberX,
          rowY + .18,
          .44,
          .16,
          size: 7.6,
          color: _accentColor,
          bold: true,
          spacing: .45,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
        _line(
          rtl ? x + w - .96 : x + .76,
          rowY + .30,
          .14,
          _accentColor,
          width: 1.6,
        ),
        _text(
          label.toUpperCase(),
          labelX,
          rowY + .17,
          1.42,
          dense ? .26 : .31,
          size: dense ? 7.1 : 7.6,
          color: primaryDark,
          bold: true,
          spacing: .72,
          maxLines: 2,
          align: rowTextAlign,
          lineHeight: 1.05,
        ),
        _text(
          resolvedTitle,
          contentX,
          rowY + .12,
          contentWidth,
          titleHeight,
          size: titleSize,
          color: ink,
          bold: true,
          maxLines: dense ? 1 : 2,
          align: rowTextAlign,
          lineHeight: 1.06,
        ),
        if (body.isNotEmpty)
          _text(
            body,
            contentX,
            rowY + bodyTop,
            contentWidth,
            math.max(.12, rowHeight - bodyTop - .08).toDouble(),
            size: bodySize,
            color: muted,
            maxLines: veryDense ? 1 : dense ? 2 : 3,
            align: rowTextAlign,
            lineHeight: 1.12,
          ),
        if (index < count - 1)
          _line(
            x + .34,
            rowY + rowHeight,
            w - .68,
            _rule,
            width: 1,
          ),
      ]);
    }

    return elements;
  }

  String _itemLabel(Map<String, dynamic> item, int index) {
    final value = _string(
      item['date'] ??
          item['label'] ??
          item['phase'] ??
          item['year'] ??
          item['period'],
    );
    return value.isEmpty ? 'Stage ${index + 1}' : value;
  }

  String _compactPeriod(String first, String last) {
    if (first.trim().toLowerCase() == last.trim().toLowerCase()) return first;
    return '$first  →  $last';
  }
}
