part of '../instructor_presentation_page.dart';

class DiagramTemplate extends SlideTemplateBuilder {
  const DiagramTemplate();

  // Learnova palette only. The diagram uses restrained navy/blue surfaces,
  // quiet connectors, and horizontal accents inside nodes. Detached vertical
  // accent bars are intentionally avoided so preview and PowerPoint stay
  // visually consistent at different scales.
  static const String _panel = '0B1B35';
  static const String _panelBorder = '27466D';
  static const String _panelText = 'E1EAF5';
  static const String _panelMuted = '7890AE';
  static const String _panelAccentText = '76B8FA';

  static const String _accentColor = '137FEC';
  static const String _accentDark = '0B5FC4';
  static const String _accentBorder = 'CBE2FB';
  static const String _connector = 'B9CCE2';
  static const String _rule = 'E6EEF8';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final data = slide.semanticData;
    final content = _map(data['content']);
    final diagram = _map(data['diagram']);
    final nodes = _itemMaps(diagram['nodes']).take(12).toList();
    final edges = _itemMaps(diagram['edges']).take(20).toList();
    final overview = _string(
      data['overview'] ??
          data['summary'] ??
          data['context'] ??
          content['lead'] ??
          content['summary'],
    );
    final resolvedOverview = overview.isEmpty
        ? 'Read the relationships in sequence to understand how the main ideas connect.'
        : overview;
    final rtl = _rtl(
      '${slide.title} $resolvedOverview '
      '${nodes.map((node) => '${node['title']} ${node['body']}').join(' ')}',
    );

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const overviewHeight = .78;
    const boardGap = .18;
    final boardY = top + overviewHeight + boardGap;
    final boardHeight = height - overviewHeight - boardGap;
    final elements = _lightMaster(slide);

    elements.addAll(
      _overviewStrip(
        x: safeX,
        y: top,
        w: safeWidth,
        h: overviewHeight,
        overview: resolvedOverview,
        nodeCount: nodes.length,
        edgeCount: edges.length,
        rtl: rtl,
      ),
    );

    elements.addAll(
      _diagramBoard(
        x: safeX,
        y: boardY,
        w: safeWidth,
        h: boardHeight,
        nodes: nodes,
        edges: edges,
        rtl: rtl,
      ),
    );

    return elements;
  }

  List<PresentationElement> _overviewStrip({
    required double x,
    required double y,
    required double w,
    required double h,
    required String overview,
    required int nodeCount,
    required int edgeCount,
    required bool rtl,
  }) {
    const metricWidth = 1.08;
    const metricGap = .12;
    final metricsTotal = metricWidth * 2 + metricGap;
    final metricsX = x + w - metricsTotal - .28;
    final textX = x + .32;
    final textWidth = metricsX - textX - .28;
    final overviewSize = overview.length > 175
        ? 8.2
        : overview.length > 120
            ? 8.8
            : 9.4;

    return [
      _rect(
        x,
        y,
        w,
        h,
        white,
        radius: compactRadius,
        line: _accentBorder,
        lineWidth: 1,
      ),
      _rect(textX, y + .22, .48, .04, _accentColor, radius: 5),
      _text(
        'DIAGRAM OVERVIEW',
        textX,
        y + .35,
        1.66,
        .14,
        size: 7.2,
        color: _accentDark,
        bold: true,
        spacing: 1.05,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        overview,
        textX + 1.88,
        y + .19,
        textWidth - 1.88,
        .42,
        size: overviewSize,
        color: inkSoft,
        maxLines: 2,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.12,
      ),
      _line(metricsX - .18, y + .17, .01, _rule,
          width: 1, verticalHeight: h - .34),
      ..._metric(
        x: metricsX,
        y: y + .16,
        w: metricWidth,
        value: nodeCount.toString().padLeft(2, '0'),
        label: nodeCount == 1 ? 'NODE' : 'NODES',
      ),
      _line(metricsX + metricWidth + metricGap / 2, y + .17, .01, _rule,
          width: 1, verticalHeight: h - .34),
      ..._metric(
        x: metricsX + metricWidth + metricGap,
        y: y + .16,
        w: metricWidth,
        value: edgeCount.toString().padLeft(2, '0'),
        label: edgeCount == 1 ? 'LINK' : 'LINKS',
      ),
    ];
  }

  List<PresentationElement> _metric({
    required double x,
    required double y,
    required double w,
    required String value,
    required String label,
  }) {
    return [
      _text(
        value,
        x,
        y,
        w,
        .25,
        size: 15.5,
        color: primaryDark,
        bold: true,
        maxLines: 1,
        align: TextAlign.center,
        lineHeight: 1.0,
      ),
      _text(
        label,
        x,
        y + .34,
        w,
        .12,
        size: 6.7,
        color: footer,
        bold: true,
        spacing: 1.0,
        maxLines: 1,
        align: TextAlign.center,
        lineHeight: 1.0,
      ),
    ];
  }

  List<PresentationElement> _diagramBoard({
    required double x,
    required double y,
    required double w,
    required double h,
    required List<Map<String, dynamic>> nodes,
    required List<Map<String, dynamic>> edges,
    required bool rtl,
  }) {
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

    if (nodes.isEmpty) {
      elements.addAll([
        _rect(x + .34, y + .34, .58, .045, _accentColor, radius: 5),
        _text(
          'SYSTEM MAP',
          x + .34,
          y + .50,
          1.42,
          .15,
          size: 7.4,
          color: _accentDark,
          bold: true,
          spacing: 1.08,
          maxLines: 1,
          lineHeight: 1.0,
        ),
        _text(
          'Add diagram.nodes and diagram.edges to the JSON.',
          x + .72,
          y + h / 2 - .16,
          w - 1.44,
          .34,
          size: 17,
          color: muted,
          maxLines: 1,
          align: TextAlign.center,
        ),
      ]);
      return elements;
    }

    final levelGroups = <int, List<_DiagramNodeRef>>{};
    for (var index = 0; index < nodes.length; index++) {
      final node = nodes[index];
      final level = _int(node['level'], index ~/ 3);
      final id = _string(node['id']).isEmpty ? 'node_$index' : _string(node['id']);
      levelGroups
          .putIfAbsent(level, () => <_DiagramNodeRef>[])
          .add(_DiagramNodeRef(id: id, index: index, data: node));
    }

    final levels = levelGroups.keys.toList()..sort();
    const boardPad = .30;
    const stageHeaderHeight = .52;
    const nodeBottomPad = .26;
    final nodeAreaY = y + stageHeaderHeight;
    final nodeAreaHeight = h - stageHeaderHeight - nodeBottomPad;
    final levelCount = math.max(1, levels.length).toInt();
    final horizontalGap = levelCount <= 3
        ? .42
        : levelCount == 4
            ? .30
            : levelCount == 5
                ? .20
                : .14;
    final availableWidth = w - boardPad * 2 - horizontalGap * (levelCount - 1);
    final columnWidth = availableWidth / levelCount;
    final positions = <String, Rect>{};
    final refsById = <String, _DiagramNodeRef>{};

    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      final group = levelGroups[levels[levelIndex]]!;
      final visualIndex = rtl ? levels.length - 1 - levelIndex : levelIndex;
      final columnX = x + boardPad + visualIndex * (columnWidth + horizontalGap);
      final gapY = group.length >= 4
          ? .10
          : group.length == 3
              ? .14
              : .18;
      final calculatedNodeHeight =
          (nodeAreaHeight - gapY * (group.length - 1)) / group.length;
      final nodeHeight = math.min(1.24, calculatedNodeHeight).toDouble();
      final totalHeight = group.length * nodeHeight + gapY * (group.length - 1);
      final startY = nodeAreaY + (nodeAreaHeight - totalHeight) / 2;

      elements.addAll(
        _stageLabel(
          x: columnX,
          y: y + .19,
          w: columnWidth,
          levelIndex: levelIndex,
          rtl: rtl,
        ),
      );

      for (var itemIndex = 0; itemIndex < group.length; itemIndex++) {
        final ref = group[itemIndex];
        final rect = Rect.fromLTWH(
          columnX,
          startY + itemIndex * (nodeHeight + gapY),
          columnWidth,
          nodeHeight,
        );
        positions[ref.id] = rect;
        refsById[ref.id] = ref;
      }
    }

    // Draw all connectors first so the nodes remain crisp and readable on top.
    for (final edge in edges) {
      final from = positions[_string(edge['from'])];
      final to = positions[_string(edge['to'])];
      if (from == null || to == null) continue;
      elements.addAll(_connectorElements(from, to));
    }

    positions.forEach((id, rect) {
      final ref = refsById[id];
      if (ref == null) return;
      final level = _int(ref.data['level'], 0);
      final isAnchor = level == levels.first;
      elements.addAll(
        _nodeCard(
          rect: rect,
          ref: ref,
          isAnchor: isAnchor,
          levelCount: levelCount,
          rtl: rtl,
        ),
      );
    });

    return elements;
  }

  List<PresentationElement> _stageLabel({
    required double x,
    required double y,
    required double w,
    required int levelIndex,
    required bool rtl,
  }) {
    final label = 'STAGE ${(levelIndex + 1).toString().padLeft(2, '0')}';
    return [
      _text(
        label,
        x,
        y,
        w,
        .13,
        size: 6.7,
        color: footer,
        bold: true,
        spacing: .92,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _line(x, y + .22, w, _rule, width: 1),
    ];
  }

  List<PresentationElement> _connectorElements(Rect from, Rect to) {
    final elements = <PresentationElement>[];
    final sameColumn = (from.center.dx - to.center.dx).abs() < .08;

    if (sameColumn) {
      final startY = from.center.dy < to.center.dy ? from.bottom : from.top;
      final endY = from.center.dy < to.center.dy ? to.top : to.bottom;
      final x = from.center.dx;
      elements.add(
        _line(
          x,
          math.min(startY, endY),
          .01,
          _connector,
          width: 1.4,
          verticalHeight: (endY - startY).abs(),
        ),
      );
      return elements;
    }

    final forward = to.center.dx > from.center.dx;
    final startX = forward ? from.right : from.left;
    final endX = forward ? to.left : to.right;
    final startY = from.center.dy;
    final endY = to.center.dy;
    final midX = (startX + endX) / 2;

    elements.add(_line(
      math.min(startX, midX),
      startY,
      (midX - startX).abs(),
      _connector,
      width: 1.4,
    ));
    elements.add(_line(
      midX,
      math.min(startY, endY),
      .01,
      _connector,
      width: 1.4,
      verticalHeight: (endY - startY).abs(),
    ));
    elements.add(_line(
      math.min(midX, endX),
      endY,
      (endX - midX).abs(),
      _connector,
      width: 1.4,
    ));

    // A small terminal marker communicates direction without using large
    // arrows or detached vertical color bars.
    elements.add(_oval(endX - .045, endY - .045, .09, _accentColor));
    return elements;
  }

  List<PresentationElement> _nodeCard({
    required Rect rect,
    required _DiagramNodeRef ref,
    required bool isAnchor,
    required int levelCount,
    required bool rtl,
  }) {
    final title = _string(ref.data['title'] ?? ref.data['label']);
    final resolvedTitle = title.isEmpty ? ref.id : title;
    final body = _string(ref.data['body'] ?? ref.data['description']);
    final compactWidth = rect.width < 2.05 || levelCount >= 6;
    final compactHeight = rect.height < .90;
    final veryCompact = rect.height < .70;
    final horizontalPad = compactWidth ? .16 : .20;
    final titleSize = compactWidth
        ? (compactHeight ? 8.8 : 9.5)
        : (compactHeight ? 9.8 : 10.8);
    final bodySize = compactWidth
        ? (compactHeight ? 7.2 : 7.8)
        : (compactHeight ? 7.8 : 8.6);
    final titleTop = rect.top + (compactHeight ? .33 : .38);
    final titleHeight = compactHeight ? .27 : .34;
    final bodyTop = titleTop + titleHeight + (compactHeight ? .02 : .05);
    final bodyHeight = rect.bottom - bodyTop - .10;
    final align = rtl ? TextAlign.right : TextAlign.left;
    final fill = isAnchor ? _panel : white;
    final line = isAnchor ? _panelBorder : _accentBorder;
    final titleColor = isAnchor ? white : ink;
    final bodyColor = isAnchor ? _panelText : muted;
    final metaColor = isAnchor ? _panelMuted : footer;
    final accentColor = isAnchor ? _panelAccentText : _accentColor;

    final elements = <PresentationElement>[
      _rect(
        rect.left,
        rect.top,
        rect.width,
        rect.height,
        fill,
        radius: compactRadius,
        line: line,
        lineWidth: 1,
        shadow: !compactHeight,
      ),
      _rect(
        rtl ? rect.right - horizontalPad - .42 : rect.left + horizontalPad,
        rect.top + .13,
        .42,
        .035,
        accentColor,
        radius: 5,
      ),
      _text(
        'NODE ${(ref.index + 1).toString().padLeft(2, '0')}',
        rect.left + horizontalPad,
        rect.top + .21,
        rect.width - horizontalPad * 2,
        .10,
        size: compactWidth ? 5.7 : 6.2,
        color: metaColor,
        bold: true,
        spacing: .72,
        maxLines: 1,
        align: align,
        lineHeight: 1.0,
      ),
      _text(
        resolvedTitle,
        rect.left + horizontalPad,
        titleTop,
        rect.width - horizontalPad * 2,
        titleHeight,
        size: titleSize,
        color: titleColor,
        bold: true,
        maxLines: 2,
        align: align,
        lineHeight: 1.04,
      ),
    ];

    if (body.isNotEmpty && !veryCompact && bodyHeight > .12) {
      elements.add(
        _text(
          body,
          rect.left + horizontalPad,
          bodyTop,
          rect.width - horizontalPad * 2,
          bodyHeight,
          size: bodySize,
          color: bodyColor,
          maxLines: compactHeight ? 1 : 2,
          align: align,
          lineHeight: 1.10,
        ),
      );
    }

    return elements;
  }
}

class _DiagramNodeRef {
  const _DiagramNodeRef({
    required this.id,
    required this.index,
    required this.data,
  });

  final String id;
  final int index;
  final Map<String, dynamic> data;
}
