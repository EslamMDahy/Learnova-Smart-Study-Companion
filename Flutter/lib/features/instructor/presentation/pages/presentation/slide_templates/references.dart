part of '../instructor_presentation_page.dart';

class ReferencesTemplate extends SlideTemplateBuilder {
  const ReferencesTemplate();

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
    final references = _stringList(
      slide.semanticData['references'] ?? slide.semanticData['sources'],
    ).where((item) => item.trim().isNotEmpty).take(12).toList();
    final rtl = _rtl('${slide.title} ${references.join(' ')}');
    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const indexWidth = 3.06;
    const gap = .34;
    final registerX = safeX + indexWidth + gap;
    final registerWidth = safeWidth - indexWidth - gap;
    final elements = _lightMaster(slide);

    elements.addAll(
      _indexPanel(
        x: safeX,
        y: top,
        w: indexWidth,
        h: height,
        count: references.length,
        rtl: rtl,
      ),
    );
    elements.addAll(
      _referenceRegister(
        x: registerX,
        y: top,
        w: registerWidth,
        h: height,
        references: references,
        rtl: rtl,
      ),
    );

    return elements;
  }

  List<PresentationElement> _indexPanel({
    required double x,
    required double y,
    required double w,
    required double h,
    required int count,
    required bool rtl,
  }) {
    final countText = count.toString().padLeft(2, '0');
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
      _rect(x + .32, y + .32, .60, .045, _accentColor, radius: 5),
      _text(
        'SOURCE INDEX',
        x + .32,
        y + .53,
        w - .64,
        .15,
        size: 7.6,
        color: _panelAccentText,
        bold: true,
        spacing: 1.20,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        countText,
        x + .32,
        y + .91,
        w - .64,
        .72,
        size: 45,
        color: white,
        bold: true,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        count == 1 ? 'REFERENCE' : 'REFERENCES',
        x + .32,
        y + 1.70,
        w - .64,
        .15,
        size: 7.1,
        color: _panelMuted,
        bold: true,
        spacing: 1.18,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _line(x + .32, y + 2.10, w - .64, _panelBorder, width: 1),
      _text(
        'CITATION NOTE',
        x + .32,
        y + 2.42,
        w - .64,
        .15,
        size: 7.0,
        color: _panelMuted,
        bold: true,
        spacing: 1.15,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        'Use one consistent citation style and keep titles, authors, editions, and links complete.',
        x + .32,
        y + 2.78,
        w - .64,
        1.18,
        size: 11.0,
        color: _panelText,
        maxLines: 6,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.14,
      ),
      _line(x + .32, y + h - .72, w - .64, _panelBorder, width: 1),
      _text(
        'LEARNOVA / ACADEMIC SOURCES',
        x + .32,
        y + h - .43,
        w - .64,
        .14,
        size: 6.7,
        color: _panelMuted,
        bold: true,
        spacing: .90,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ];
  }

  List<PresentationElement> _referenceRegister({
    required double x,
    required double y,
    required double w,
    required double h,
    required List<String> references,
    required bool rtl,
  }) {
    final count = references.length;
    final twoColumns = count > 6;
    final columns = twoColumns ? 2 : 1;
    final perColumn = twoColumns ? (count / 2).ceil() : math.max(1, count);
    const headerHeight = .78;
    const sidePadding = .30;
    const columnGap = .28;
    final columnWidth =
        (w - sidePadding * 2 - columnGap * (columns - 1)) / columns;
    final rowsHeight = h - headerHeight - .18;
    final rowHeight = rowsHeight / math.max(1, perColumn);
    final dense = count >= 9 || rowHeight < .68;
    final bodySize = dense
        ? 9.2
        : count >= 6
            ? 10.1
            : 11.2;
    final maxLines = dense ? 3 : 4;

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
      _rect(x + .30, y + .24, .58, .045, _accentColor, radius: 5),
      _text(
        'REFERENCE REGISTER',
        x + .30,
        y + .40,
        2.50,
        .15,
        size: 7.5,
        color: _accentColor,
        bold: true,
        spacing: 1.18,
        maxLines: 1,
        lineHeight: 1.0,
      ),
      _text(
        twoColumns ? 'TWO-COLUMN INDEX' : 'SINGLE-COLUMN INDEX',
        x + w - 2.18,
        y + .40,
        1.88,
        .15,
        size: 6.8,
        color: footer,
        bold: true,
        spacing: .75,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: 1.0,
      ),
      _line(x + .30, y + .70, w - .60, _rule, width: 1),
    ];

    if (references.isEmpty) {
      elements.addAll([
        _rect(
          x + .30,
          y + 1.05,
          w - .60,
          h - 1.36,
          _softFill,
          radius: 14,
          line: _rule,
        ),
        _text(
          'Add the books, articles, datasets, course notes, or web sources used in this lecture.',
          x + .78,
          y + 2.12,
          w - 1.56,
          .84,
          size: 15,
          color: muted,
          maxLines: 4,
          align: TextAlign.center,
          lineHeight: 1.16,
          verticalAlign: 'middle',
        ),
      ]);
      return elements;
    }

    for (var index = 0; index < references.length; index++) {
      final column = twoColumns && index >= perColumn ? 1 : 0;
      final row = column == 0 ? index : index - perColumn;
      final itemX = x + sidePadding + column * (columnWidth + columnGap);
      final itemY = y + headerHeight + row * rowHeight;
      final numberWidth = dense ? .38 : .44;
      final textX = rtl ? itemX : itemX + numberWidth + .16;
      final textWidth = columnWidth - numberWidth - .16;
      final numberX = rtl ? itemX + columnWidth - numberWidth : itemX;

      if (row.isOdd) {
        elements.add(
          _rect(
            itemX,
            itemY + .03,
            columnWidth,
            math.max(.30, rowHeight - .06).toDouble(),
            _softFill,
            radius: 9,
          ),
        );
      }
      elements.addAll([
        _text(
          '${index + 1}'.padLeft(2, '0'),
          numberX,
          itemY + .16,
          numberWidth,
          .15,
          size: dense ? 7.2 : 7.8,
          color: _accentColor,
          bold: true,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
        _line(
          numberX,
          itemY + .43,
          numberWidth,
          _accentColor,
          width: 1.5,
        ),
        _text(
          references[index],
          textX,
          itemY + .10,
          textWidth,
          math.max(.28, rowHeight - .18).toDouble(),
          size: bodySize,
          color: inkSoft,
          maxLines: maxLines,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.12,
          verticalAlign: 'middle',
        ),
      ]);
    }

    return elements;
  }
}
