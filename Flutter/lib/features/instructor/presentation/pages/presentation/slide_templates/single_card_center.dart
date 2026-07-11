part of '../instructor_presentation_page.dart';

class SingleCardCenterTemplate extends SlideTemplateBuilder {
  const SingleCardCenterTemplate();

  static const String _panel = '0B1B35';
  static const String _panelBorder = '27466D';
  static const String _panelText = 'E1EAF5';
  static const String _panelMuted = '7890AE';
  static const String _panelAccentText = '76B8FA';
  static const String _accentColor = '137FEC';
  static const String _accentSoft = 'E8F3FF';
  static const String _accentBorder = 'CBE2FB';
  static const String _softFill = 'F7FAFF';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final elements = _lightMaster(slide);
    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    if (slide.cards.isEmpty) {
      elements.addAll(_emptyState(top, height));
      return elements;
    }

    final card = slide.cards.first;
    final rtl = _rtl('${card.heading} ${card.body}');
    const panelWidth = 10.25;
    final x = safeX + (safeWidth - panelWidth) / 2;
    final y = top + .08;
    final h = height - .16;

    elements.addAll(
      _focusCard(
        card: card,
        x: x,
        y: y,
        w: panelWidth,
        h: h,
        rtl: rtl,
      ),
    );
    return elements;
  }

  List<PresentationElement> _focusCard({
    required PresentationCardContent card,
    required double x,
    required double y,
    required double w,
    required double h,
    required bool rtl,
  }) {
    final hasVisual = card.visual != null && card.visual!.src.isNotEmpty;
    final hasEquation = card.equation != null && card.equation!.value.isNotEmpty;
    final headingUnits = PresentationDesignTokens.textUnits(card.heading);
    final headingSize = headingUnits > 80
        ? 20.0
        : headingUnits > 52
            ? 23.0
            : 27.0;
    final bodyUnits = PresentationDesignTokens.textUnits(card.body);
    final bodySize = bodyUnits > 300
        ? 11.2
        : bodyUnits > 190
            ? 12.2
            : 13.3;
    const railWidth = 2.42;
    const gap = .42;
    final contentX = x + railWidth + gap;
    final contentW = w - railWidth - gap - .42;

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
      _rect(
        x + .18,
        y + .18,
        railWidth,
        h - .36,
        _panel,
        radius: 15,
        line: _panelBorder,
        lineWidth: 1,
      ),
      _rect(x + .48, y + .48, .58, .045, _accentColor, radius: 5),
      _text(
        'FOCUS CARD',
        x + .48,
        y + .69,
        railWidth - .60,
        .15,
        size: 7.5,
        color: _panelAccentText,
        bold: true,
        spacing: 1.20,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        '01',
        x + .48,
        y + 1.08,
        railWidth - .60,
        .66,
        size: 42,
        color: white,
        bold: true,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _line(x + .48, y + 1.92, railWidth - .60, _panelBorder, width: 1),
      _text(
        hasVisual
            ? 'VISUAL BRIEF'
            : hasEquation
                ? 'FORMULA FOCUS'
                : 'CORE IDEA',
        x + .48,
        y + 2.20,
        railWidth - .60,
        .15,
        size: 7.0,
        color: _panelMuted,
        bold: true,
        spacing: 1.12,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        hasVisual
            ? 'One image and one message, presented with a clear academic hierarchy.'
            : hasEquation
                ? 'Read the expression first, then connect it to the explanation.'
                : 'A single centered idea designed for emphasis and retention.',
        x + .48,
        y + 2.55,
        railWidth - .60,
        1.28,
        size: 10.3,
        color: _panelText,
        maxLines: 6,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.13,
      ),
      _line(x + .48, y + h - .72, railWidth - .60, _panelBorder, width: 1),
      _text(
        'LEARNOVA / FOCUS',
        x + .48,
        y + h - .43,
        railWidth - .60,
        .14,
        size: 6.7,
        color: _panelMuted,
        bold: true,
        spacing: .92,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _rect(contentX, y + .46, .62, .045, _accentColor, radius: 5),
      _text(
        'PRIMARY MESSAGE',
        contentX,
        y + .68,
        contentW,
        .15,
        size: 7.5,
        color: _accentColor,
        bold: true,
        spacing: 1.18,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ];

    if (hasVisual) {
      const visualWidth = 3.16;
      final textWidth = contentW - visualWidth - .38;
      final visualX = rtl ? contentX : contentX + textWidth + .38;
      final textX = rtl ? contentX + visualWidth + .38 : contentX;
      elements.addAll([
        _rect(
          visualX,
          y + 1.05,
          visualWidth,
          h - 1.50,
          _softFill,
          radius: 14,
          line: _accentBorder,
        ),
        _image(
          card.visual!.src,
          visualX + .12,
          y + 1.17,
          visualWidth - .24,
          h - 2.02,
          fit: card.visual!.fit,
          radius: 11,
        ),
        if (_string(card.visual!.caption).isNotEmpty)
          _text(
            _string(card.visual!.caption),
            visualX + .18,
            y + h - .68,
            visualWidth - .36,
            .32,
            size: 8.5,
            color: muted,
            maxLines: 2,
            align: rtl ? TextAlign.right : TextAlign.left,
            lineHeight: 1.10,
          ),
        _text(
          card.heading,
          textX,
          y + 1.17,
          textWidth,
          1.18,
          size: headingSize,
          color: ink,
          bold: true,
          maxLines: 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.04,
          verticalAlign: 'middle',
        ),
        _line(textX, y + 2.56, textWidth, _ruleColor, width: 1),
        _text(
          card.body,
          textX,
          y + 2.85,
          textWidth,
          h - 3.28,
          size: bodySize,
          color: inkSoft,
          maxLines: 9,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.15,
        ),
      ]);
    } else {
      elements.add(
        _text(
          card.heading,
          contentX,
          y + 1.08,
          contentW,
          hasEquation ? .72 : 1.12,
          size: headingSize,
          color: ink,
          bold: true,
          maxLines: hasEquation ? 2 : 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.04,
          verticalAlign: 'middle',
        ),
      );
      if (hasEquation) {
        elements.addAll([
          _rect(
            contentX,
            y + 2.02,
            contentW,
            1.22,
            _accentSoft,
            radius: 13,
            line: _accentBorder,
          ),
          _equationElement(
            card.equation!,
            contentX + .22,
            y + 2.20,
            contentW - .44,
            .86,
            color: darkBlue,
            size: card.equation!.value.length > 60 ? 19 : 24,
          ),
          if (card.body.isNotEmpty)
            _text(
              card.body,
              contentX,
              y + 3.56,
              contentW,
              h - 4.02,
              size: bodySize,
              color: inkSoft,
              maxLines: 7,
              align: rtl ? TextAlign.right : TextAlign.left,
              lineHeight: 1.15,
            ),
        ]);
      } else {
        elements.addAll([
          _line(contentX, y + 2.43, contentW, _ruleColor, width: 1),
          _text(
            card.body,
            contentX,
            y + 2.76,
            contentW,
            h - 3.20,
            size: bodySize,
            color: inkSoft,
            maxLines: 10,
            align: rtl ? TextAlign.right : TextAlign.left,
            lineHeight: 1.16,
            verticalAlign: 'middle',
          ),
        ]);
      }
    }

    return elements;
  }

  static const String _ruleColor = 'E6EEF8';

  List<PresentationElement> _emptyState(double top, double height) {
    return [
      _rect(
        2.18,
        top + .42,
        8.98,
        math.max(2.72, height - .84).toDouble(),
        white,
        radius: panelRadius,
        line: _accentBorder,
        shadow: true,
      ),
      _rect(5.96, top + 1.02, 1.42, .045, _accentColor, radius: 5),
      _text(
        'ADD ONE FOCUS CARD',
        3.10,
        top + 1.42,
        7.14,
        .22,
        size: 10,
        color: _accentColor,
        bold: true,
        spacing: 1.18,
        maxLines: 1,
        align: TextAlign.center,
      ),
      _text(
        'Use a concise heading and one supporting explanation, visual, or equation.',
        3.10,
        top + 2.00,
        7.14,
        .72,
        size: 16,
        color: inkSoft,
        maxLines: 3,
        align: TextAlign.center,
        lineHeight: 1.14,
      ),
    ];
  }
}
