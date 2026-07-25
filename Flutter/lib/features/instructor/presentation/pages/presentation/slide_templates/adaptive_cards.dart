part of '../instructor_presentation_page.dart';

class AdaptiveCardsTemplate extends SlideTemplateBuilder {
  const AdaptiveCardsTemplate();

  static const String _accentColor = '137FEC';
  static const String _accentSoft = 'E8F3FF';
  static const String _accentBorder = 'CBE2FB';
  static const String _rule = 'E6EEF8';
  static const String _softFill = 'F7FAFF';
  static const String _navy = '0B1B35';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final cards = slide.cards;
    if (cards.length == 1) {
      return const SingleCardCenterTemplate().build(slide);
    }
    if (cards.length == 2) {
      return const TwoCardHorizontalTemplate().build(slide);
    }
    if (cards.length == 3) {
      return const ThreeCardHorizontalTemplate().build(slide);
    }

    final elements = _lightMaster(slide);
    final top = _contentTopFor(slide);
    final areaHeight = contentBottom - top;
    if (cards.isEmpty) {
      elements.addAll(_emptyState(top, areaHeight));
      return elements;
    }

    final count = cards.length;
    final columns = count == 4
        ? 2
        : count <= 6
            ? 3
            : count == 9
                ? 3
                : 4;
    final rows = (count / columns).ceil();
    const boardHeader = .54;
    final gapX = columns >= 4 ? .14 : .18;
    final gapY = rows >= 3 ? .13 : .18;
    final gridHeight = areaHeight - boardHeader;
    final cardWidth = (safeWidth - gapX * (columns - 1)) / columns;
    final cardHeight = (gridHeight - gapY * (rows - 1)) / rows;
    final dense = rows >= 3 || columns >= 4;

    elements.addAll([
      _text(
        'CONTENT FRAMEWORK',
        safeX,
        top + .04,
        2.35,
        .15,
        size: 7.4,
        color: _accentColor,
        bold: true,
        spacing: 1.16,
        maxLines: 1,
        lineHeight: 1.0,
      ),
      _text(
        '${count.toString().padLeft(2, '0')} CARDS  •  $columns COLUMNS',
        safeX + safeWidth - 2.80,
        top + .04,
        2.80,
        .15,
        size: 6.8,
        color: footer,
        bold: true,
        spacing: .72,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: 1.0,
      ),
      _line(safeX, top + .36, safeWidth, _rule, width: 1),
    ]);

    for (var index = 0; index < count; index++) {
      final row = index ~/ columns;
      final column = index % columns;
      final itemsInRow = math.min(columns, count - row * columns);
      final rowWidth = itemsInRow * cardWidth + (itemsInRow - 1) * gapX;
      final startX = safeX + (safeWidth - rowWidth) / 2;
      final x = startX + column * (cardWidth + gapX);
      final y = top + boardHeader + row * (cardHeight + gapY);
      elements.addAll(
        _gridCard(
          card: cards[index],
          index: index,
          x: x,
          y: y,
          w: cardWidth,
          h: cardHeight,
          dense: dense,
        ),
      );
    }

    return elements;
  }

  List<PresentationElement> _gridCard({
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
    final bodyUnits = PresentationDesignTokens.textUnits(card.body);
    final headingSize = dense
        ? 9.2
        : headingUnits > 48
            ? 11.2
            : 12.5;
    final bodySize = dense
        ? 7.4
        : bodyUnits > 145
            ? 8.7
            : 9.5;
    final fill = index.isOdd ? _softFill : white;
    final elements = <PresentationElement>[
      _rect(
        x,
        y,
        w,
        h,
        fill,
        radius: compactRadius,
        line: _accentBorder,
        lineWidth: 1,
        shadow: !dense,
      ),
      _rect(x + .18, y + .18, .48, .04, _accentColor, radius: 5),
      _text(
        '${index + 1}'.padLeft(2, '0'),
        x + w - .52,
        y + .17,
        .34,
        .13,
        size: dense ? 6.1 : 6.8,
        color: _accentColor,
        bold: true,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: 1.0,
      ),
      _text(
        'KEY IDEA',
        x + .18,
        y + .37,
        w - .36,
        .13,
        size: dense ? 5.8 : 6.4,
        color: footer,
        bold: true,
        spacing: 1.02,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ];

    var contentTop = y + .64;
    if (hasVisual && h >= 1.65) {
      final imageHeight = dense ? .46 : .62;
      elements.add(
        _image(
          card.visual!.src,
          x + .18,
          contentTop,
          w - .36,
          imageHeight,
          fit: card.visual!.fit,
          radius: 7,
        ),
      );
      contentTop += imageHeight + .10;
    }

    final headingHeight = dense ? .34 : .43;
    elements.add(
      _text(
        card.heading,
        x + .18,
        contentTop,
        w - .36,
        headingHeight,
        size: headingSize,
        color: ink,
        bold: true,
        maxLines: 2,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.04,
      ),
    );
    contentTop += headingHeight + .08;

    if (hasEquation) {
      final equationHeight = math.max(.34, h - (contentTop - y) - .16).toDouble();
      elements.addAll([
        _rect(
          x + .18,
          contentTop,
          w - .36,
          equationHeight,
          _accentSoft,
          radius: 8,
          line: _accentBorder,
        ),
        _equationElement(
          card.equation!,
          x + .27,
          contentTop + .06,
          w - .54,
          equationHeight - .12,
          color: _navy,
          size: dense ? 10.5 : 13.0,
        ),
      ]);
    } else {
      elements.addAll([
        _line(x + .18, contentTop, w - .36, _rule, width: 1),
        _text(
          card.body,
          x + .18,
          contentTop + .11,
          w - .36,
          math.max(.20, h - (contentTop - y) - .22).toDouble(),
          size: bodySize,
          color: inkSoft,
          maxLines: dense ? 4 : 6,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.11,
        ),
      ]);
    }

    return elements;
  }

  List<PresentationElement> _emptyState(double top, double height) {
    return [
      _rect(
        1.42,
        top + .45,
        10.49,
        math.max(2.58, height - .90).toDouble(),
        white,
        radius: panelRadius,
        line: _accentBorder,
        shadow: true,
      ),
      _rect(5.94, top + 1.03, 1.45, .045, _accentColor, radius: 5),
      _text(
        'ADD STRUCTURED CARDS',
        2.58,
        top + 1.43,
        8.17,
        .22,
        size: 10,
        color: _accentColor,
        bold: true,
        spacing: 1.14,
        maxLines: 1,
        align: TextAlign.center,
      ),
      _text(
        'The layout adapts automatically from one focused card to a twelve-card framework.',
        2.58,
        top + 2.00,
        8.17,
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
