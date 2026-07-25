part of '../instructor_presentation_page.dart';

class TableTemplate extends SlideTemplateBuilder {
  const TableTemplate();

  // Learnova palette only. The table is built as one cohesive reference
  // surface with a navy header, quiet blue tints, and horizontal accents.
  // Detached vertical accent bars are intentionally avoided.
  static const String _panel = '0B1B35';
  static const String _panelBorder = '27466D';
  static const String _panelText = 'E1EAF5';
  static const String _accentColor = '137FEC';
  static const String _accentDark = '0B5FC4';
  static const String _accentBorder = 'CBE2FB';
  static const String _rule = 'E6EEF8';
  static const String _softFill = 'F7FAFF';
  static const String _firstColumnFill = 'F0F7FF';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final semantic = slide.semanticData;
    final content = _map(semantic['content']);
    final data = _map(semantic['table']);
    final headers =
        _stringList(data['headers'] ?? data['columns']).take(6).toList();
    final rawRows = data['rows'] is List ? data['rows'] as List : const [];
    final rows = <List<String>>[];

    for (final raw in rawRows.take(8)) {
      if (raw is List) {
        rows.add(raw.map((item) => item.toString().trim()).take(6).toList());
      } else if (raw is Map && headers.isNotEmpty) {
        rows.add(headers.map((header) => _string(raw[header])).toList());
      }
    }

    final inferredColumnCount = rows.isEmpty
        ? 0
        : rows.map((row) => row.length).fold<int>(
            0,
            (maximum, length) => math.max(maximum, length).toInt(),
          );
    final columnCount = math.max(
      1,
      math.min(6, headers.isNotEmpty ? headers.length : inferredColumnCount),
    ).toInt();
    final normalizedHeaders = List<String>.generate(
      columnCount,
      (index) => index < headers.length ? headers[index] : 'Column ${index + 1}',
    );
    final normalizedRows = rows
        .map(
          (row) => List<String>.generate(
            columnCount,
            (index) => index < row.length ? row[index] : '',
          ),
        )
        .toList();

    final overview = _string(
      semantic['overview'] ??
          semantic['summary'] ??
          data['overview'] ??
          data['caption'] ??
          data['note'] ??
          content['lead'] ??
          content['summary'],
    );
    final resolvedOverview = overview.isEmpty
        ? 'Use the table to compare the most important values, rules, or characteristics at a glance.'
        : overview;
    final rtl = _rtl(
      '${slide.title} $resolvedOverview '
      '${normalizedHeaders.join(' ')} '
      '${normalizedRows.expand((row) => row).join(' ')}',
    );

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const overviewHeight = .78;
    const gap = .18;
    final boardY = top + overviewHeight + gap;
    final boardHeight = height - overviewHeight - gap;
    final elements = _lightMaster(slide);

    elements.addAll(
      _overviewStrip(
        x: safeX,
        y: top,
        w: safeWidth,
        h: overviewHeight,
        overview: resolvedOverview,
        rowCount: normalizedRows.length,
        columnCount: columnCount,
        rtl: rtl,
      ),
    );
    elements.addAll(
      _tableBoard(
        x: safeX,
        y: boardY,
        w: safeWidth,
        h: boardHeight,
        headers: normalizedHeaders,
        rows: normalizedRows,
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
    required int rowCount,
    required int columnCount,
    required bool rtl,
  }) {
    const metricWidth = 1.06;
    const metricGap = .10;
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
        'TABLE OVERVIEW',
        textX,
        y + .35,
        1.62,
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
        textX + 1.84,
        y + .19,
        textWidth - 1.84,
        .42,
        size: overviewSize,
        color: inkSoft,
        maxLines: 2,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.12,
      ),
      _line(
        metricsX - .18,
        y + .17,
        .01,
        _rule,
        width: 1,
        verticalHeight: h - .34,
      ),
      ..._metric(
        x: metricsX,
        y: y + .16,
        w: metricWidth,
        value: rowCount.toString().padLeft(2, '0'),
        label: rowCount == 1 ? 'RECORD' : 'RECORDS',
      ),
      _line(
        metricsX + metricWidth + metricGap / 2,
        y + .17,
        .01,
        _rule,
        width: 1,
        verticalHeight: h - .34,
      ),
      ..._metric(
        x: metricsX + metricWidth + metricGap,
        y: y + .16,
        w: metricWidth,
        value: columnCount.toString().padLeft(2, '0'),
        label: columnCount == 1 ? 'FIELD' : 'FIELDS',
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

  List<PresentationElement> _tableBoard({
    required double x,
    required double y,
    required double w,
    required double h,
    required List<String> headers,
    required List<List<String>> rows,
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

    if (rows.isEmpty) {
      elements.addAll([
        _rect(x + .34, y + .34, .58, .045, _accentColor, radius: 5),
        _text(
          'REFERENCE TABLE',
          x + .34,
          y + .50,
          1.56,
          .15,
          size: 7.4,
          color: _accentDark,
          bold: true,
          spacing: 1.08,
          maxLines: 1,
          lineHeight: 1.0,
        ),
        _text(
          'Add table.headers and table.rows to the JSON.',
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

    const pad = .18;
    final innerX = x + pad;
    final innerY = y + pad;
    final innerW = w - pad * 2;
    final innerH = h - pad * 2;
    final columnCount = headers.length;
    final headerHeight = columnCount >= 6
        ? .62
        : columnCount == 5
            ? .66
            : .70;
    final rowsHeight = innerH - headerHeight;
    final columnWidths = _columnWidths(
      innerW,
      headers,
      rows,
    );
    final rowHeights = _rowHeights(
      rowsHeight,
      rows,
      columnWidths,
    );
    final headerSize = columnCount >= 6
        ? 8.1
        : columnCount == 5
            ? 8.7
            : columnCount == 4
                ? 9.3
                : 10.0;
    final bodySize = _bodySize(columnCount, rows.length);
    final naturalColumns =
        List<int>.generate(columnCount, (index) => index);
    final visualColumns = rtl ? naturalColumns.reversed.toList() : naturalColumns;

    elements.add(
      _rect(
        innerX,
        innerY,
        innerW,
        headerHeight,
        _panel,
        radius: compactRadius,
        line: _panelBorder,
        lineWidth: 1,
      ),
    );
    elements.add(_rect(innerX + .22, innerY + .14, .50, .04, _accentColor, radius: 5));

    var columnX = innerX;
    for (var visualIndex = 0; visualIndex < visualColumns.length; visualIndex++) {
      final logicalIndex = visualColumns[visualIndex];
      final columnWidth = columnWidths[logicalIndex];
      final header = headers[logicalIndex];
      final centered = _centerColumn(header, rows, logicalIndex);
      final isFirstField = logicalIndex == 0;

      if (visualIndex > 0) {
        elements.add(
          _line(
            columnX,
            innerY + .15,
            .01,
            _panelBorder,
            width: 1,
            verticalHeight: headerHeight - .30,
          ),
        );
      }

      elements.add(
        _text(
          header.toUpperCase(),
          columnX + .16,
          innerY + .23,
          columnWidth - .32,
          headerHeight - .28,
          size: headerSize,
          color: isFirstField ? white : _panelText,
          bold: true,
          spacing: header.length <= 18 ? .32 : 0,
          maxLines: 2,
          align: centered
              ? TextAlign.center
              : rtl
                  ? TextAlign.right
                  : TextAlign.left,
          verticalAlign: 'middle',
          lineHeight: 1.04,
        ),
      );
      columnX += columnWidth;
    }

    var rowY = innerY + headerHeight;
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final rowHeight = rowHeights[rowIndex];
      final fill = rowIndex.isEven ? white : _softFill;

      elements.add(_rect(innerX, rowY, innerW, rowHeight, fill));

      var cellX = innerX;
      for (var visualIndex = 0;
          visualIndex < visualColumns.length;
          visualIndex++) {
        final logicalIndex = visualColumns[visualIndex];
        final columnWidth = columnWidths[logicalIndex];
        final value = row[logicalIndex];
        final isFirstField = logicalIndex == 0;
        final centered = _centerColumn(headers[logicalIndex], rows, logicalIndex);

        if (isFirstField) {
          elements.add(
            _rect(
              cellX,
              rowY,
              columnWidth,
              rowHeight,
              _firstColumnFill,
            ),
          );
          elements.add(
            _rect(
              rtl ? cellX + columnWidth - .54 : cellX + .18,
              rowY + .15,
              .36,
              .035,
              _accentColor,
              radius: 5,
            ),
          );
        }

        if (visualIndex > 0) {
          elements.add(
            _line(
              cellX,
              rowY,
              .01,
              _rule,
              width: .8,
              verticalHeight: rowHeight,
            ),
          );
        }

        final maxLines = rowHeight >= .72
            ? 3
            : rowHeight >= .48
                ? 2
                : 1;
        if (_isFormulaValue(headers[logicalIndex], value)) {
          elements.add(
            _equationElement(
              PresentationEquationContent(
                value: _toLatex(value),
                renderMode: 'svg',
              ),
              cellX + .14,
              rowY + .08,
              columnWidth - .28,
              rowHeight - .16,
              color: inkSoft,
              size: bodySize + 1.05,
            ),
          );
        } else {
          elements.add(
            _text(
              value,
              cellX + .16,
              rowY + (isFirstField ? .20 : .10),
              columnWidth - .32,
              rowHeight - (isFirstField ? .25 : .20),
              size: isFirstField ? bodySize + .15 : bodySize,
              color: isFirstField ? ink : inkSoft,
              bold: isFirstField,
              maxLines: maxLines,
              align: centered
                  ? TextAlign.center
                  : rtl
                      ? TextAlign.right
                      : TextAlign.left,
              verticalAlign: 'middle',
              lineHeight: isFirstField ? 1.05 : 1.10,
            ),
          );
        }

        cellX += columnWidth;
      }

      if (rowIndex < rows.length - 1) {
        elements.add(
          _line(innerX, rowY + rowHeight, innerW, _rule, width: .8),
        );
      }
      rowY += rowHeight;
    }

    return elements;
  }

  List<double> _columnWidths(
    double totalWidth,
    List<String> headers,
    List<List<String>> rows,
  ) {
    final weights = <double>[];
    for (var column = 0; column < headers.length; column++) {
      var maxUnits = _contentUnits(headers[column]);
      for (final row in rows) {
        maxUnits = math.max(maxUnits, _contentUnits(row[column])).toDouble();
      }
      var weight = math.sqrt(math.max(4.0, maxUnits));
      if (_looksLikeExpressionHeader(headers[column])) weight *= .92;
      if (column == 0) weight *= .92;
      weights.add(weight.clamp(2.15, 7.8).toDouble());
    }

    final minimum = headers.length >= 6
        ? 1.34
        : headers.length == 5
            ? 1.46
            : 1.60;
    final minimumTotal = minimum * headers.length;
    final flexibleWidth = math.max(0.0, totalWidth - minimumTotal);
    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);

    return weights
        .map((weight) => minimum + flexibleWidth * weight / totalWeight)
        .toList();
  }

  List<double> _rowHeights(
    double totalHeight,
    List<List<String>> rows,
    List<double> columnWidths,
  ) {
    final weights = <double>[];
    for (final row in rows) {
      var estimatedLines = 1;
      for (var column = 0; column < row.length; column++) {
        final width = math.max(.7, columnWidths[column] - .32).toDouble();
        final charsPerLine = math.max(10, (width * 10.4).floor()).toInt();
        final lines = math.max(1, (row[column].length / charsPerLine).ceil());
        estimatedLines =
            math.max(estimatedLines, math.min(3, lines)).toInt();
      }
      weights.add(1 + (estimatedLines - 1) * .36);
    }

    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);
    return weights.map((weight) => totalHeight * weight / totalWeight).toList();
  }

  double _bodySize(int columnCount, int rowCount) {
    var size = columnCount <= 3
        ? 10.9
        : columnCount == 4
            ? 9.9
            : columnCount == 5
                ? 9.0
                : 8.2;
    if (rowCount >= 7) size -= .55;
    if (rowCount >= 8) size -= .25;
    return size;
  }


  bool _isFormulaValue(String header, String value) {
    final text = value.trim();
    if (text.isEmpty) return false;
    if (_looksLikeExpressionHeader(header) &&
        RegExp(r'[=+\-/*^()|]|[∩∪≤≥≠×÷√∑ΣΩπ]').hasMatch(text)) {
      return true;
    }
    return RegExp(r'\\(?:frac|sum|int|sqrt|cap|cup|le|ge|ne|times|div)')
            .hasMatch(text) ||
        RegExp(r'[∩∪≤≥≠×÷√∑]').hasMatch(text);
  }

  String _toLatex(String value) {
    final text = value.trim();
    if (text.contains(r'\')) return text;
    return text
        .replaceAll('∩', r'\cap ')
        .replaceAll('∪', r'\cup ')
        .replaceAll('×', r'\times ')
        .replaceAll('÷', r'\div ')
        .replaceAll('≤', r'\le ')
        .replaceAll('≥', r'\ge ')
        .replaceAll('≠', r'\ne ')
        .replaceAll('→', r'\rightarrow ')
        .replaceAll('∞', r'\infty ')
        .replaceAll('Ω', r'\Omega ')
        .replaceAll('Σ', r'\Sigma ')
        .replaceAll('π', r'\pi ')
        .replaceAll('−', '-')
        .replaceAll('ᶜ', r'^{c}')
        .replaceAll('²', r'^{2}')
        .replaceAll('³', r'^{3}');
  }

  bool _centerColumn(
    String header,
    List<List<String>> rows,
    int columnIndex,
  ) {
    if (_looksLikeExpressionHeader(header)) return true;
    final values = rows
        .map((row) => row[columnIndex].trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (values.isEmpty) return false;
    final numericCount = values
        .where(
          (value) => RegExp(r'^[-+]?[$€£]?[\d.,%/\s]+$').hasMatch(value),
        )
        .length;
    return numericCount / values.length >= .70;
  }

  bool _looksLikeExpressionHeader(String value) {
    final normalized = value.trim().toLowerCase();
    const keywords = <String>{
      'expression',
      'formula',
      'equation',
      'value',
      'score',
      'rate',
      'percentage',
      'percent',
      'amount',
      'year',
      'date',
      'number',
      'no.',
      '#',
    };
    return keywords.any(normalized.contains);
  }

  double _contentUnits(String value) {
    final text = value.trim();
    if (text.isEmpty) return 4;
    var units = 0.0;
    for (final rune in text.runes) {
      if (rune >= 0x0600 && rune <= 0x06FF) {
        units += 1.12;
      } else if ('MW@#%&'.contains(String.fromCharCode(rune))) {
        units += 1.30;
      } else if ('ilI1.,:;|'.contains(String.fromCharCode(rune))) {
        units += .56;
      } else {
        units += 1.0;
      }
    }
    return units;
  }
}
