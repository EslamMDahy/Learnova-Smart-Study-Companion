part of '../instructor_presentation_page.dart';

class TwoCardHorizontalTemplate extends SlideTemplateBuilder {
  const TwoCardHorizontalTemplate();

  static const String _accentColor = '137FEC';
  static const String _accentSoft = 'E8F3FF';
  static const String _accentBorder = 'CBE2FB';
  static const String _rule = 'E6EEF8';
  static const String _softFill = 'F7FAFF';
  static const String _navy = '0B1B35';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final cards = slide.cards;
    if (cards.length > 6) {
      return const AdaptiveCardsTemplate().build(slide);
    }
    final elements = _lightMaster(slide);
    final top = _contentTopFor(slide);
    final areaHeight = contentBottom - top;
    if (cards.isEmpty) {
      elements.addAll(_emptyState(top, areaHeight, 2));
      return elements;
    }

    final rows = (cards.length / 2).ceil();
    const rowGap = .20;
    final rowHeight = (areaHeight - rowGap * (rows - 1)) / rows;
    final dense = rows >= 3 || rowHeight < 1.25;

    for (var row = 0; row < rows; row++) {
      final start = row * 2;
      final items = cards.skip(start).take(2).toList();
      final y = top + row * (rowHeight + rowGap);
      if (items.length == 1) {
        const singleWidth = 7.76;
        final x = safeX + (safeWidth - singleWidth) / 2;
        elements.addAll(
          _rowPanel(
            cards: items,
            startIndex: start,
            x: x,
            y: y,
            w: singleWidth,
            h: rowHeight,
            dense: dense,
          ),
        );
      } else {
        elements.addAll(
          _rowPanel(
            cards: items,
            startIndex: start,
            x: safeX,
            y: y,
            w: safeWidth,
            h: rowHeight,
            dense: dense,
          ),
        );
      }
    }

    return elements;
  }

  List<PresentationElement> _rowPanel({
    required List<PresentationCardContent> cards,
    required int startIndex,
    required double x,
    required double y,
    required double w,
    required double h,
    required bool dense,
  }) {
    const outerPadding = .18;
    const dividerGap = .18;
    final cellCount = cards.length;
    final cellWidth =
        (w - outerPadding * 2 - dividerGap * (cellCount - 1)) / cellCount;
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
    ];

    for (var localIndex = 0; localIndex < cards.length; localIndex++) {
      final cellX = x + outerPadding + localIndex * (cellWidth + dividerGap);
      if (localIndex > 0) {
        final dividerX = cellX - dividerGap / 2;
        elements.add(
          _line(
            dividerX,
            y + .28,
            .01,
            _rule,
            width: 1,
            verticalHeight: h - .56,
          ),
        );
      }
      elements.addAll(
        _cell(
          card: cards[localIndex],
          index: startIndex + localIndex,
          x: cellX,
          y: y + .16,
          w: cellWidth,
          h: h - .32,
          dense: dense,
        ),
      );
    }

    return elements;
  }

  List<PresentationElement> _cell({
    required PresentationCardContent card,
    required int index,
    required double x,
    required double y,
    required double w,
    required double h,
    required bool dense,
  }) {
    final rtl = _rtl('${card.heading} ${card.body}');
    final hasVisual = card.visual != null && card.visual!.src.isNotEmpty;
    final hasEquation = card.equation != null && card.equation!.value.isNotEmpty;
    final headingSize = dense
        ? 11.3
        : PresentationDesignTokens.textUnits(card.heading) > 52
            ? 14.0
            : 16.0;
    final bodySize = dense
        ? 8.8
        : PresentationDesignTokens.textUnits(card.body) > 180
            ? 10.2
            : 11.2;
    final elements = <PresentationElement>[
      _rect(x + .02, y + .06, .56, .045, _accentColor, radius: 5),
      _text(
        'CARD ${(index + 1).toString().padLeft(2, '0')}',
        x + .02,
        y + .25,
        w - .04,
        .14,
        size: dense ? 6.5 : 7.2,
        color: _accentColor,
        bold: true,
        spacing: 1.08,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ];

    var contentTop = y + .57;
    if (hasVisual && h >= 2.30) {
      final imageHeight = dense ? .68 : .92;
      elements.addAll([
        _rect(
          x + .02,
          contentTop,
          w - .04,
          imageHeight,
          _softFill,
          radius: 10,
          line: _rule,
        ),
        _image(
          card.visual!.src,
          x + .08,
          contentTop + .06,
          w - .16,
          imageHeight - .12,
          fit: card.visual!.fit,
          radius: 8,
        ),
      ]);
      contentTop += imageHeight + .18;
    }

    final headingHeight = dense ? .46 : .62;
    elements.add(
      _text(
        card.heading,
        x + .02,
        contentTop,
        w - .04,
        headingHeight,
        size: headingSize,
        color: ink,
        bold: true,
        maxLines: 2,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.06,
        verticalAlign: 'middle',
      ),
    );
    contentTop += headingHeight + .12;

    if (hasEquation) {
      final equationHeight = math.max(.54, h - (contentTop - y) - .16).toDouble();
      elements.addAll([
        _rect(
          x + .02,
          contentTop,
          w - .04,
          equationHeight,
          _accentSoft,
          radius: 10,
          line: _accentBorder,
        ),
        _equationElement(
          card.equation!,
          x + .16,
          contentTop + .09,
          w - .32,
          equationHeight - .18,
          color: _navy,
          size: dense ? 14 : 18,
        ),
      ]);
    } else {
      final bodyHeight =
          math.max(.34, h - (contentTop - y) - .12).toDouble();
      elements.addAll([
        _rect(
          x + .02,
          contentTop,
          w - .04,
          bodyHeight,
          _softFill,
          radius: 10,
          line: _rule,
        ),
        _text(
          card.body,
          x + .20,
          contentTop + .18,
          w - .40,
          math.max(.22, bodyHeight - .34).toDouble(),
          size: bodySize,
          color: inkSoft,
          maxLines: dense ? 4 : 7,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.13,
          verticalAlign: dense ? 'top' : 'middle',
        ),
      ]);
    }
    return elements;
  }

  List<PresentationElement> _emptyState(
    double top,
    double height,
    int count,
  ) {
    return [
      _rect(
        1.40,
        top + .45,
        10.53,
        math.max(2.58, height - .90).toDouble(),
        white,
        radius: panelRadius,
        line: _accentBorder,
        shadow: true,
      ),
      _rect(5.94, top + 1.03, 1.45, .045, _accentColor, radius: 5),
      _text(
        'ADD $count HORIZONTAL CARDS',
        2.55,
        top + 1.43,
        8.23,
        .22,
        size: 10,
        color: _accentColor,
        bold: true,
        spacing: 1.14,
        maxLines: 1,
        align: TextAlign.center,
      ),
      _text(
        'Use parallel headings and comparable levels of detail so both ideas scan at the same pace.',
        2.55,
        top + 2.00,
        8.23,
        .72,
        size: 15.5,
        color: inkSoft,
        maxLines: 3,
        align: TextAlign.center,
        lineHeight: 1.14,
      ),
    ];
  }
}
