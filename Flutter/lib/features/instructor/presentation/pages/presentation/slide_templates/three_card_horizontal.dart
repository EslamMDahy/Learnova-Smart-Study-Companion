part of '../instructor_presentation_page.dart';

class ThreeCardHorizontalTemplate extends SlideTemplateBuilder {
  const ThreeCardHorizontalTemplate();

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
      elements.addAll(_emptyState(top, areaHeight));
      return elements;
    }

    final rows = (cards.length / 3).ceil();
    const rowGap = .20;
    final rowHeight = (areaHeight - rowGap * (rows - 1)) / rows;
    final dense = rows >= 2 || rowHeight < 2.35;

    for (var row = 0; row < rows; row++) {
      final start = row * 3;
      final items = cards.skip(start).take(3).toList();
      final y = top + row * (rowHeight + rowGap);
      final rowWidth = items.length == 1
          ? 4.15
          : items.length == 2
              ? 8.04
              : safeWidth;
      final x = safeX + (safeWidth - rowWidth) / 2;
      elements.addAll(
        _rowPanel(
          cards: items,
          startIndex: start,
          x: x,
          y: y,
          w: rowWidth,
          h: rowHeight,
          dense: dense,
        ),
      );
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
    const outerPadding = .16;
    const dividerGap = .14;
    final cellWidth =
        (w - outerPadding * 2 - dividerGap * (cards.length - 1)) /
            cards.length;
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
        elements.add(
          _line(
            cellX - dividerGap / 2,
            y + .26,
            .01,
            _rule,
            width: 1,
            verticalHeight: h - .52,
          ),
        );
      }
      elements.addAll(
        _cell(
          card: cards[localIndex],
          index: startIndex + localIndex,
          x: cellX,
          y: y + .14,
          w: cellWidth,
          h: h - .28,
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
    final headingUnits = PresentationDesignTokens.textUnits(card.heading);
    final headingSize = dense
        ? 10.6
        : headingUnits > 45
            ? 13.1
            : 14.6;
    final bodySize = dense
        ? 8.2
        : PresentationDesignTokens.textUnits(card.body) > 155
            ? 9.5
            : 10.4;
    final elements = <PresentationElement>[
      _rect(x + .02, y + .06, .52, .045, _accentColor, radius: 5),
      _text(
        'PILLAR ${(index + 1).toString().padLeft(2, '0')}',
        x + .02,
        y + .24,
        w - .04,
        .14,
        size: dense ? 6.2 : 6.8,
        color: _accentColor,
        bold: true,
        spacing: 1.02,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ];

    var contentTop = y + .55;
    if (hasVisual && h >= 2.50) {
      final imageHeight = dense ? .62 : .86;
      elements.addAll([
        _rect(
          x + .02,
          contentTop,
          w - .04,
          imageHeight,
          _softFill,
          radius: 9,
          line: _rule,
        ),
        _image(
          card.visual!.src,
          x + .07,
          contentTop + .05,
          w - .14,
          imageHeight - .10,
          fit: card.visual!.fit,
          radius: 7,
        ),
      ]);
      contentTop += imageHeight + .14;
    }

    final headingHeight = dense ? .43 : .58;
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
        lineHeight: 1.05,
        verticalAlign: 'middle',
      ),
    );
    contentTop += headingHeight + .11;

    if (hasEquation) {
      final equationHeight = math.max(.48, h - (contentTop - y) - .14).toDouble();
      elements.addAll([
        _rect(
          x + .02,
          contentTop,
          w - .04,
          equationHeight,
          _accentSoft,
          radius: 9,
          line: _accentBorder,
        ),
        _equationElement(
          card.equation!,
          x + .12,
          contentTop + .08,
          w - .24,
          equationHeight - .16,
          color: _navy,
          size: dense ? 12.5 : 15.5,
        ),
      ]);
    } else {
      final bodyHeight =
          math.max(.30, h - (contentTop - y) - .10).toDouble();
      elements.addAll([
        _rect(
          x + .02,
          contentTop,
          w - .04,
          bodyHeight,
          _softFill,
          radius: 9,
          line: _rule,
        ),
        _text(
          card.body,
          x + .20,
          contentTop + .16,
          w - .40,
          math.max(.20, bodyHeight - .30).toDouble(),
          size: bodySize,
          color: inkSoft,
          maxLines: dense ? 4 : 7,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.12,
          verticalAlign: dense ? 'top' : 'middle',
        ),
      ]);
    }
    return elements;
  }

  List<PresentationElement> _emptyState(double top, double height) {
    return [
      _rect(
        1.18,
        top + .45,
        10.97,
        math.max(2.58, height - .90).toDouble(),
        white,
        radius: panelRadius,
        line: _accentBorder,
        shadow: true,
      ),
      _rect(5.94, top + 1.03, 1.45, .045, _accentColor, radius: 5),
      _text(
        'ADD THREE HORIZONTAL CARDS',
        2.36,
        top + 1.43,
        8.61,
        .22,
        size: 10,
        color: _accentColor,
        bold: true,
        spacing: 1.14,
        maxLines: 1,
        align: TextAlign.center,
      ),
      _text(
        'Use three parallel pillars, categories, or perspectives with concise headings and balanced descriptions.',
        2.36,
        top + 2.00,
        8.61,
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
