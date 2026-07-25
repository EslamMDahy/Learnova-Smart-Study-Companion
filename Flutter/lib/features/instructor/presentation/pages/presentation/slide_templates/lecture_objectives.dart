part of '../instructor_presentation_page.dart';

class LectureObjectivesTemplate extends SlideTemplateBuilder {
  const LectureObjectivesTemplate();

  static const String _navy = '0B1B35';
  static const String _navyBorder = '244363';
  static const String _panelBorder = 'D7E3F0';
  static const String _label = '718198';
  static const String _blueText = '0B5FC4';
  static const String _railText = 'C6D3E3';
  static const String _railFaint = '7890AE';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final objectives = _stringList(
      slide.semanticData['objectives'] ??
          _map(slide.semanticData['content'])['objectives'],
    );
    final cardObjectives = slide.cards
        .map(
          (card) => card.heading +
              (card.body.isEmpty ? '' : ': ${card.body}'),
        )
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final items = (objectives.isNotEmpty ? objectives : cardObjectives)
        .take(6)
        .toList();
    final visible = items.isEmpty
        ? const <String>[
            'Add a measurable learning objective for this lecture.',
          ]
        : items;

    final outcome = _string(
      slide.semanticData['outcome'] ??
          _map(slide.semanticData['content'])['outcome'] ??
          'By the end of this lecture, students should be able to apply the key ideas with confidence.',
    );

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    final elements = _lightMaster(slide);

    const overviewWidth = 2.78;
    const sectionGap = .40;
    final overviewX = safeX;
    final boardX = overviewX + overviewWidth + sectionGap;
    final boardWidth = safeWidth - overviewWidth - sectionGap;

    elements.addAll(
      _overviewPanel(
        x: overviewX,
        y: top,
        width: overviewWidth,
        height: height,
        count: visible.length,
        outcome: outcome,
      ),
    );

    elements.addAll(
      _objectivesBoard(
        items: visible,
        x: boardX,
        y: top,
        width: boardWidth,
        height: height,
      ),
    );

    return elements;
  }

  List<PresentationElement> _overviewPanel({
    required double x,
    required double y,
    required double width,
    required double height,
    required int count,
    required String outcome,
  }) {
    final countLabel = count.toString().padLeft(2, '0');
    final outcomeRtl = _rtl(outcome);

    return [
      _rect(
        x,
        y,
        width,
        height,
        _navy,
        radius: panelRadius,
        line: _navyBorder,
        lineWidth: 1,
        shadow: true,
      ),
      // A short internal accent keeps the panel refined and export-safe.
      _rect(x + .30, y + .28, .66, .045, primary, radius: 4),
      _text(
        'LECTURE OUTCOMES',
        x + .30,
        y + .49,
        width - .60,
        .14,
        size: 7.8,
        color: _railFaint,
        bold: true,
        spacing: 1.15,
        maxLines: 1,
      ),
      _text(
        countLabel,
        x + .28,
        y + .78,
        1.20,
        .62,
        size: 42,
        color: white,
        bold: true,
        maxLines: 1,
        lineHeight: 1.0,
      ),
      _text(
        count == 1 ? 'OBJECTIVE' : 'OBJECTIVES',
        x + 1.38,
        y + 1.01,
        width - 1.68,
        .16,
        size: 9.3,
        color: '76B8FA',
        bold: true,
        spacing: .75,
        maxLines: 1,
      ),
      _line(x + .30, y + 1.61, width - .60, '294566', width: 1),
      _text(
        'EXPECTED OUTCOME',
        x + .30,
        y + 1.91,
        width - .60,
        .14,
        size: 7.4,
        color: _railFaint,
        bold: true,
        spacing: 1.05,
        maxLines: 1,
      ),
      _text(
        outcome,
        x + .30,
        y + 2.22,
        width - .60,
        math.max(1.18, height - 3.20),
        size: 10.8,
        color: _railText,
        maxLines: 7,
        align: outcomeRtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.20,
      ),
      _line(x + .30, y + height - .66, width - .60, '294566', width: 1),
      _text(
        'KNOWLEDGE   •   PRACTICE   •   JUDGMENT',
        x + .30,
        y + height - .38,
        width - .60,
        .11,
        size: 5.9,
        color: _railFaint,
        bold: true,
        spacing: .32,
        maxLines: 1,
      ),
    ];
  }

  List<PresentationElement> _objectivesBoard({
    required List<String> items,
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final layout = _gridFor(items.length, width, height);
    final elements = <PresentationElement>[
      _text(
        'MEASURABLE OUTCOMES',
        x,
        y + .04,
        width - 1.72,
        .15,
        size: 8.0,
        color: _blueText,
        bold: true,
        spacing: 1.12,
        maxLines: 1,
      ),
      _text(
        '${items.length.toString().padLeft(2, '0')}  /  LEARNING PLAN',
        x + width - 1.90,
        y + .04,
        1.90,
        .15,
        size: 7.2,
        color: _label,
        bold: true,
        spacing: .45,
        maxLines: 1,
        align: TextAlign.right,
      ),
      _line(x, y + .35, width, divider, width: 1),
    ];

    for (var index = 0; index < items.length; index++) {
      final row = index ~/ layout.columns;
      final column = index % layout.columns;
      final cardX = x + layout.startX +
          column * (layout.cardWidth + layout.gapX);
      final cardY = y + layout.startY +
          row * (layout.cardHeight + layout.gapY);
      elements.addAll(
        _objectiveCard(
          objective: items[index],
          index: index,
          x: cardX,
          y: cardY,
          width: layout.cardWidth,
          height: layout.cardHeight,
          compact: items.length >= 5,
        ),
      );
    }

    return elements;
  }

  _ObjectiveGrid _gridFor(int count, double width, double height) {
    const headerHeight = .57;
    const gapX = .24;
    const gapY = .18;
    final gridHeight = height - headerHeight;

    if (count == 1) {
      const cardHeight = 1.70;
      final cardWidth = math.min(6.40, width).toDouble();
      return _ObjectiveGrid(
        columns: 1,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        gapX: 0,
        gapY: 0,
        startX: (width - cardWidth) / 2,
        startY: headerHeight + math.max(0.0, (gridHeight - cardHeight) / 2),
      );
    }

    if (count == 2) {
      const cardHeight = 1.72;
      final cardWidth = (width - gapX) / 2;
      return _ObjectiveGrid(
        columns: 2,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        gapX: gapX,
        gapY: 0,
        startX: 0,
        startY: headerHeight + math.max(0.0, (gridHeight - cardHeight) / 2),
      );
    }

    if (count == 3) {
      const cardHeight = 1.08;
      final cardWidth = math.min(6.90, width).toDouble();
      final totalHeight = cardHeight * 3 + gapY * 2;
      return _ObjectiveGrid(
        columns: 1,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        gapX: 0,
        gapY: gapY,
        startX: (width - cardWidth) / 2,
        startY: headerHeight + math.max(0.0, (gridHeight - totalHeight) / 2),
      );
    }

    final columns = 2;
    final rows = (count / columns).ceil();
    final availableCardHeight = (gridHeight - gapY * (rows - 1)) / rows;
    final maximumCardHeight = count >= 5 ? 1.24 : 1.58;
    final cardHeight = math.min(maximumCardHeight, availableCardHeight).toDouble();
    final cardWidth = (width - gapX) / 2;
    final totalHeight = rows * cardHeight + gapY * (rows - 1);

    return _ObjectiveGrid(
      columns: columns,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      gapX: gapX,
      gapY: gapY,
      startX: 0,
      startY: headerHeight + math.max(0.0, (gridHeight - totalHeight) / 2),
    );
  }

  List<PresentationElement> _objectiveCard({
    required String objective,
    required int index,
    required double x,
    required double y,
    required double width,
    required double height,
    required bool compact,
  }) {
    final objectiveRtl = _rtl(objective);
    final action = _actionVerb(objective);
    final number = (index + 1).toString().padLeft(2, '0');
    final eyebrow = objectiveRtl
        ? 'الهدف $number'
        : action.isEmpty
            ? 'OBJECTIVE $number'
            : '$number  /  ${action.toUpperCase()}';
    final bodySize = compact
        ? (width < 4.0 ? 10.2 : 10.8)
        : (width < 4.0 ? 11.0 : 11.6);
    final bodyTop = compact ? .46 : .52;
    final bodyBottom = compact ? .14 : .18;

    return [
      _rect(
        x,
        y,
        width,
        height,
        white,
        radius: compactRadius,
        line: _panelBorder,
        lineWidth: 1,
        shadow: true,
      ),
      // The accent is contained inside the card instead of hanging outside it.
      _rect(x + .24, y + .20, .54, .04, primary, radius: 4),
      _text(
        eyebrow,
        x + .24,
        y + .31,
        width - .48,
        .12,
        size: compact ? 6.7 : 7.1,
        color: _blueText,
        bold: true,
        spacing: objectiveRtl ? 0 : .72,
        maxLines: 1,
        align: objectiveRtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        objective,
        x + .24,
        y + bodyTop,
        width - .48,
        height - bodyTop - bodyBottom,
        size: bodySize,
        color: inkSoft,
        bold: false,
        maxLines: compact ? 3 : 4,
        align: objectiveRtl ? TextAlign.right : TextAlign.left,
        verticalAlign: 'middle',
        lineHeight: 1.16,
      ),
    ];
  }

  String _actionVerb(String objective) {
    if (_rtl(objective)) return '';

    final normalized = objective.trim();
    if (normalized.isEmpty) return '';
    final separator = normalized.indexOf(' ');
    if (separator <= 0) return '';

    final first = normalized
        .substring(0, separator)
        .replaceAll(RegExp(r'[^A-Za-z-]'), '');
    if (first.isEmpty || first.length > 14) return '';

    const measurableVerbs = <String>{
      'analyze',
      'apply',
      'assess',
      'calculate',
      'classify',
      'compare',
      'construct',
      'create',
      'define',
      'demonstrate',
      'describe',
      'design',
      'differentiate',
      'distinguish',
      'evaluate',
      'explain',
      'identify',
      'interpret',
      'justify',
      'model',
      'recognize',
      'solve',
      'summarize',
      'use',
    };

    return measurableVerbs.contains(first.toLowerCase()) ? first : '';
  }
}

class _ObjectiveGrid {
  final int columns;
  final double cardWidth;
  final double cardHeight;
  final double gapX;
  final double gapY;
  final double startX;
  final double startY;

  const _ObjectiveGrid({
    required this.columns,
    required this.cardWidth,
    required this.cardHeight,
    required this.gapX,
    required this.gapY,
    required this.startX,
    required this.startY,
  });
}
