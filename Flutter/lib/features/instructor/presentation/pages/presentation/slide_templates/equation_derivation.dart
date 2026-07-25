part of '../instructor_presentation_page.dart';

class EquationDerivationTemplate extends SlideTemplateBuilder {
  const EquationDerivationTemplate();

  // Learnova palette only. The derivation is presented as a formal ledger:
  // one dark goal rail and one cohesive sequence surface. All accents are
  // horizontal and contained inside their parent panels, which keeps the
  // geometry stable in both the Flutter preview and PowerPoint export.
  static const String _panel = '0B1B35';
  static const String _panelBorder = '27466D';
  static const String _panelText = 'E1EAF5';
  static const String _panelMuted = '91A6BF';
  static const String _accentColor = '137FEC';
  static const String _accentDark = '0B5FC4';
  static const String _softFill = 'F0F7FF';
  static const String _softBorder = 'CBE2FB';
  static const String _rowAlt = 'F8FBFF';
  static const String _rule = 'E6EEF8';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final semantic = slide.semanticData;
    final rawSteps = slide.equation?.steps.isNotEmpty == true
        ? slide.equation!.steps
        : _itemMaps(semantic['derivation'] ?? semantic['steps']);
    final steps = rawSteps
        .take(5)
        .map(_EquationDerivationStep.fromJson)
        .where((step) => step.equation.value.trim().isNotEmpty)
        .toList();

    if (steps.isEmpty) {
      if (slide.equation != null) {
        return const EquationExplanationTemplate().build(slide);
      }
      return _lightMaster(slide);
    }

    final overview = _string(
      semantic['overview'] ??
          semantic['summary'] ??
          semantic['lead'] ??
          slide.equation?.explanation,
    );
    final rtl = _rtl(
      '${slide.title} $overview ${steps.map((step) => '${step.equation.value} ${step.explanation}').join(' ')}',
    );
    final targetEquation = _targetEquation(slide, steps);
    final targetLabel = _string(
      slide.equation?.label ?? semantic['result_label'] ?? semantic['target_label'],
    );

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const railWidth = 3.26;
    const gap = .30;
    final ledgerWidth = safeWidth - railWidth - gap;
    final railX = rtl ? safeX + safeWidth - railWidth : safeX;
    final ledgerX = rtl ? safeX : safeX + railWidth + gap;
    final elements = _lightMaster(slide);

    _buildGoalRail(
      elements,
      x: railX,
      y: top,
      w: railWidth,
      h: height,
      stepCount: steps.length,
      overview: overview,
      targetEquation: targetEquation,
      targetLabel: targetLabel,
      rtl: rtl,
    );

    _buildDerivationLedger(
      elements,
      x: ledgerX,
      y: top,
      w: ledgerWidth,
      h: height,
      steps: steps,
      rtl: rtl,
    );

    return elements;
  }

  void _buildGoalRail(
    List<PresentationElement> elements, {
    required double x,
    required double y,
    required double w,
    required double h,
    required int stepCount,
    required String overview,
    required PresentationEquationContent targetEquation,
    required String targetLabel,
    required bool rtl,
  }) {
    final readableOverview = overview.isNotEmpty
        ? overview
        : 'Follow each equivalent expression and record the reason for every transformation.';
    final overviewSize = _overviewSize(readableOverview);

    elements.add(
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
    );
    elements.add(_rect(x + .34, y + .27, .50, .045, _accentColor, radius: 5));
    elements.add(
      _text(
        'DERIVATION PATH',
        x + .34,
        y + .41,
        w - .68,
        .15,
        size: 7.8,
        color: _panelMuted,
        bold: true,
        spacing: 1.10,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );

    elements.add(
      _text(
        stepCount.toString().padLeft(2, '0'),
        x + .34,
        y + .69,
        1.18,
        .49,
        size: 31,
        color: white,
        bold: true,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );
    elements.add(
      _text(
        stepCount == 1 ? 'LOGICAL STEP' : 'LOGICAL STEPS',
        x + 1.56,
        y + .88,
        w - 1.90,
        .15,
        size: 7.2,
        color: _panelText,
        bold: true,
        spacing: .85,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );
    elements.add(_line(x + .34, y + 1.35, w - .68, _panelBorder, width: 1));

    elements.add(
      _text(
        'PURPOSE',
        x + .34,
        y + 1.60,
        w - .68,
        .14,
        size: 7.2,
        color: _panelMuted,
        bold: true,
        spacing: 1.0,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );
    elements.add(
      _text(
        readableOverview,
        x + .34,
        y + 1.88,
        w - .68,
        math.max(.84, h - 3.52).toDouble(),
        size: overviewSize,
        color: _panelText,
        maxLines: 7,
        align: rtl ? TextAlign.right : TextAlign.left,
        verticalAlign: 'top',
        lineHeight: 1.16,
      ),
    );

    final resultTop = y + h - 1.48;
    elements.add(_line(x + .34, resultTop, w - .68, _panelBorder, width: 1));
    elements.add(
      _text(
        (targetLabel.isNotEmpty ? targetLabel : 'TARGET RESULT').toUpperCase(),
        x + .34,
        resultTop + .22,
        w - .68,
        .14,
        size: 7.1,
        color: _panelMuted,
        bold: true,
        spacing: 1.0,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );
    elements.add(
      _equationElement(
        targetEquation,
        x + .28,
        resultTop + .47,
        w - .56,
        .72,
        color: white,
        size: _targetFormulaSize(targetEquation.value),
      ),
    );
  }

  void _buildDerivationLedger(
    List<PresentationElement> elements, {
    required double x,
    required double y,
    required double w,
    required double h,
    required List<_EquationDerivationStep> steps,
    required bool rtl,
  }) {
    elements.add(
      _rect(
        x,
        y,
        w,
        h,
        white,
        radius: panelRadius,
        line: border,
        lineWidth: 1,
        shadow: true,
      ),
    );
    elements.add(_rect(x + .32, y + .28, .46, .04, _accentColor, radius: 5));
    elements.add(
      _text(
        'DERIVATION LEDGER',
        x + .32,
        y + .41,
        w - .64,
        .15,
        size: 7.8,
        color: _accentDark,
        bold: true,
        spacing: 1.10,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );

    const markerWidth = .82;
    final expressionWidth = math.max(3.54, w * .51).toDouble();
    const columnGap = .20;
    final reasoningWidth = w - markerWidth - expressionWidth - columnGap - .64;
    final markerX = rtl ? x + w - .32 - markerWidth : x + .32;
    final expressionX = rtl
        ? x + w - .32 - markerWidth - expressionWidth
        : x + .32 + markerWidth;
    final reasoningX = rtl
        ? x + .32
        : expressionX + expressionWidth + columnGap;

    elements.add(
      _text(
        'STEP',
        markerX,
        y + .69,
        markerWidth,
        .12,
        size: 6.8,
        color: muted,
        bold: true,
        spacing: .80,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );
    elements.add(
      _text(
        'EXPRESSION',
        expressionX,
        y + .69,
        expressionWidth,
        .12,
        size: 6.8,
        color: muted,
        bold: true,
        spacing: .80,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );
    elements.add(
      _text(
        'REASONING',
        reasoningX,
        y + .69,
        reasoningWidth,
        .12,
        size: 6.8,
        color: muted,
        bold: true,
        spacing: .80,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );
    elements.add(_line(x + .32, y + .90, w - .64, _rule, width: 1));

    final availableTop = y + .91;
    final availableHeight = h - .99;
    final maxRowHeight = steps.length <= 2
        ? 1.32
        : steps.length == 3
            ? 1.12
            : steps.length == 4
                ? .93
                : .76;
    final rowHeight = math.min(maxRowHeight, availableHeight / steps.length).toDouble();
    final usedHeight = rowHeight * steps.length;
    final rowsTop = availableTop +
        math.max(0.0, (availableHeight - usedHeight) / 2).toDouble();

    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      final rowY = rowsTop + index * rowHeight;
      final isLast = index == steps.length - 1;
      final fill = isLast ? _softFill : (index.isOdd ? _rowAlt : white);

      elements.add(
        _rect(
          x + .12,
          rowY,
          w - .24,
          rowHeight,
          fill,
          radius: isLast ? compactRadius : 0,
          line: isLast ? _softBorder : null,
          lineWidth: isLast ? .8 : 0.0,
        ),
      );
      if (index > 0 && !isLast) {
        elements.add(_line(x + .32, rowY, w - .64, _rule, width: .8));
      }

      final number = '${index + 1}'.padLeft(2, '0');
      elements.add(
        _text(
          number,
          markerX,
          rowY + .12,
          markerWidth,
          .14,
          size: 7.7,
          color: _accentDark,
          bold: true,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
      );
      elements.add(
        _rect(
          rtl ? markerX + markerWidth - .28 : markerX,
          rowY + rowHeight / 2 - .018,
          .28,
          .036,
          _accentColor,
          radius: 5,
        ),
      );
      if (step.label.isNotEmpty) {
        elements.add(
          _text(
            step.label.toUpperCase(),
            markerX,
            rowY + rowHeight - .27,
            markerWidth,
            .11,
            size: 5.9,
            color: muted,
            bold: true,
            spacing: .55,
            maxLines: 1,
            align: rtl ? TextAlign.right : TextAlign.left,
            lineHeight: 1.0,
          ),
        );
      }

      elements.add(
        _equationElement(
          step.equation,
          expressionX + .02,
          rowY + .08,
          expressionWidth - .04,
          rowHeight - .16,
          color: isLast ? _accentDark : ink,
          size: _stepFormulaSize(step.equation.value, steps.length),
        ),
      );

      final explanation = step.explanation.isNotEmpty
          ? step.explanation
          : (isLast
              ? 'The target expression is now isolated.'
              : 'Apply an equivalent transformation to continue the derivation.');
      elements.add(
        _text(
          explanation,
          reasoningX,
          rowY + .08,
          reasoningWidth,
          rowHeight - .16,
          size: _reasoningSize(explanation, steps.length),
          color: inkSoft,
          maxLines: steps.length >= 5 ? 2 : 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          verticalAlign: 'middle',
          lineHeight: 1.12,
        ),
      );
    }
  }

  PresentationEquationContent _targetEquation(
    PresentationSlide slide,
    List<_EquationDerivationStep> steps,
  ) {
    final source = slide.equation;
    if (source != null && source.value.trim().isNotEmpty) return source;
    return steps.last.equation;
  }

  double _targetFormulaSize(String value) {
    final length = value.trim().length;
    if (length > 90) return 13.5;
    if (length > 68) return 15.0;
    if (length > 48) return 17.0;
    if (length > 32) return 19.0;
    return 21.5;
  }

  double _stepFormulaSize(String value, int stepCount) {
    final length = value.trim().length;
    var size = stepCount >= 5
        ? 18.0
        : stepCount == 4
            ? 20.0
            : 22.0;
    if (length > 95) size -= 5.0;
    else if (length > 70) size -= 3.5;
    else if (length > 48) size -= 2.0;
    return math.max(13.0, size).toDouble();
  }

  double _reasoningSize(String value, int stepCount) {
    final length = value.trim().length;
    var size = stepCount >= 5
        ? 9.6
        : stepCount == 4
            ? 10.2
            : 11.0;
    if (length > 135) size -= .9;
    else if (length > 95) size -= .5;
    return math.max(8.6, size).toDouble();
  }

  double _overviewSize(String value) {
    final length = value.trim().length;
    if (length > 240) return 10.3;
    if (length > 180) return 10.8;
    if (length > 120) return 11.3;
    return 11.8;
  }
}

class _EquationDerivationStep {
  final PresentationEquationContent equation;
  final String explanation;
  final String label;

  const _EquationDerivationStep({
    required this.equation,
    required this.explanation,
    required this.label,
  });

  factory _EquationDerivationStep.fromJson(Map<String, dynamic> raw) {
    String text(dynamic value) => value?.toString().trim() ?? '';

    return _EquationDerivationStep(
      equation: PresentationEquationContent.fromJson(raw),
      explanation: text(raw['explanation'] ?? raw['body'] ?? raw['note']),
      label: text(raw['label'] ?? raw['operation'] ?? raw['action']),
    );
  }
}
