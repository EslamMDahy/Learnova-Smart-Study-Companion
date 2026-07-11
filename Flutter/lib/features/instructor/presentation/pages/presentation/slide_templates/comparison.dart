part of '../instructor_presentation_page.dart';

class ComparisonTemplate extends SlideTemplateBuilder {
  const ComparisonTemplate();

  static const String _navyPanel = '0B1B35';
  static const String _navyBorder = '27466D';
  static const String _navyText = 'D6E1EE';
  static const String _navyMuted = '7F96B2';
  static const String _navyRule = '29415F';

  static const String _lightPanel = 'F7FAFD';
  static const String _lightBorder = 'CFE0EE';
  static const String _lightMuted = '647792';
  static const String _lightRule = 'D9E6F0';
  static const String _teal = '0B8FA8';
  static const String _tealSoft = 'DDF3F6';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final comparison = _map(slide.semanticData['comparison']);
    final left = _map(comparison['left']);
    final right = _map(comparison['right']);
    final leftPoints =
        _stringList(left['points'] ?? left['bullets']).take(5).toList();
    final rightPoints =
        _stringList(right['points'] ?? right['bullets']).take(5).toList();

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const gap = .28;
    final panelWidth = (safeWidth - gap) / 2;
    final sharedCount =
        math.max(1, math.max(leftPoints.length, rightPoints.length)).toInt();
    final hasSubtitle = _string(left['subtitle']).isNotEmpty ||
        _string(right['subtitle']).isNotEmpty;
    final elements = _lightMaster(slide);

    _comparisonPanel(
      elements,
      x: safeX,
      y: top,
      w: panelWidth,
      h: height,
      data: left,
      points: leftPoints,
      sharedCount: sharedCount,
      hasSharedSubtitle: hasSubtitle,
      marker: 'A',
      fallbackLabel: 'CONCEPT A',
      fallbackTitle: 'Option A',
      fill: _navyPanel,
      borderColor: _navyBorder,
      accentColor: primary,
      titleColor: white,
      bodyColor: _navyText,
      mutedColor: _navyMuted,
      ruleColor: _navyRule,
      markerColor: '18375F',
    );

    _comparisonPanel(
      elements,
      x: safeX + panelWidth + gap,
      y: top,
      w: panelWidth,
      h: height,
      data: right,
      points: rightPoints,
      sharedCount: sharedCount,
      hasSharedSubtitle: hasSubtitle,
      marker: 'B',
      fallbackLabel: 'CONCEPT B',
      fallbackTitle: 'Option B',
      fill: _lightPanel,
      borderColor: _lightBorder,
      accentColor: _teal,
      titleColor: ink,
      bodyColor: inkSoft,
      mutedColor: _lightMuted,
      ruleColor: _lightRule,
      markerColor: _tealSoft,
    );

    return elements;
  }

  void _comparisonPanel(
    List<PresentationElement> elements, {
    required double x,
    required double y,
    required double w,
    required double h,
    required Map<String, dynamic> data,
    required List<String> points,
    required int sharedCount,
    required bool hasSharedSubtitle,
    required String marker,
    required String fallbackLabel,
    required String fallbackTitle,
    required String fill,
    required String borderColor,
    required String accentColor,
    required String titleColor,
    required String bodyColor,
    required String mutedColor,
    required String ruleColor,
    required String markerColor,
  }) {
    final title = _string(data['title']).isEmpty
        ? fallbackTitle
        : _string(data['title']);
    final subtitle = _string(data['subtitle']);
    final label = _string(data['label']).isEmpty
        ? fallbackLabel
        : _string(data['label']).toUpperCase();
    final rtl = _rtl('$title $subtitle ${points.join(' ')}');
    final panelTitleSize = title.length > 48
        ? 16.5
        : title.length > 34
            ? 18.0
            : 20.5;

    // Both panels use the same header and row geometry. This keeps related
    // ideas aligned in web preview and in the exported PowerPoint.
    final headerHeight = hasSharedSubtitle ? 1.88 : 1.52;
    final pointsTop = y + headerHeight + .18;
    final availableHeight =
        math.max(.90, y + h - pointsTop - .18).toDouble();
    final rowGap = sharedCount <= 3 ? .05 : .02;
    final rowHeight =
        (availableHeight - rowGap * (sharedCount - 1)) / sharedCount;
    final longestPoint = points.fold<int>(
      0,
      (value, point) => point.length > value ? point.length : value,
    );
    final pointSize = longestPoint > 145
        ? 9.2
        : longestPoint > 95
            ? 10.0
            : sharedCount >= 5
                ? 10.8
                : sharedCount == 4
                    ? 11.6
                    : 12.7;

    elements.addAll([
      _rect(
        x,
        y,
        w,
        h,
        fill,
        radius: panelRadius,
        line: borderColor,
        lineWidth: 1,
        shadow: true,
      ),

      // Accents stay horizontal and inside the panel; there are no detached
      // vertical bars that can shift during scaling or PowerPoint export.
      _rect(x + .36, y + .34, .58, .045, accentColor, radius: 5),
      _text(
        label,
        x + .36,
        y + .54,
        w - 1.42,
        .15,
        size: 7.6,
        color: accentColor,
        bold: true,
        spacing: 1.18,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        marker,
        x + w - .94,
        y + .23,
        .58,
        .58,
        size: 34,
        color: markerColor,
        bold: true,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: .92,
      ),
      _text(
        title,
        x + .36,
        y + .82,
        w - .72,
        .58,
        size: panelTitleSize,
        color: titleColor,
        bold: true,
        maxLines: 2,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.04,
      ),
      if (hasSharedSubtitle)
        _text(
          subtitle,
          x + .36,
          y + 1.43,
          w - .72,
          .38,
          size: 10.7,
          color: subtitle.isEmpty ? mutedColor : bodyColor,
          maxLines: 2,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.12,
        ),
      _line(
        x + .36,
        y + headerHeight,
        w - .72,
        ruleColor,
        width: 1,
      ),
    ]);

    for (var index = 0; index < sharedCount; index++) {
      final rowY = pointsTop + index * (rowHeight + rowGap);
      final hasPoint = index < points.length && points[index].trim().isNotEmpty;
      final point = hasPoint ? points[index] : '';
      final numberX = rtl ? x + w - .76 : x + .36;
      final textX = rtl ? x + .36 : x + .98;
      final textWidth = w - 1.34;

      if (hasPoint) {
        elements.addAll([
          _text(
            '${index + 1}'.padLeft(2, '0'),
            numberX,
            rowY + .08,
            .40,
            .13,
            size: 7.8,
            color: accentColor,
            bold: true,
            spacing: .45,
            maxLines: 1,
            align: rtl ? TextAlign.right : TextAlign.left,
            lineHeight: 1.0,
          ),
          _line(
            rtl ? numberX + .12 : numberX,
            rowY + .33,
            .26,
            accentColor,
            width: 2.0,
          ),
          _text(
            point,
            textX,
            rowY + .02,
            textWidth,
            math.max(.22, rowHeight - .08).toDouble(),
            size: pointSize,
            color: bodyColor,
            maxLines: sharedCount >= 4 ? 3 : 4,
            align: rtl ? TextAlign.right : TextAlign.left,
            verticalAlign: 'middle',
            lineHeight: 1.13,
          ),
        ]);
      }

      if (index < sharedCount - 1) {
        elements.add(
          _line(
            x + .36,
            rowY + rowHeight + rowGap / 2,
            w - .72,
            ruleColor,
            width: .8,
          ),
        );
      }
    }
  }
}
