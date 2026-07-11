part of '../instructor_presentation_page.dart';

class EquationExplanationTemplate extends SlideTemplateBuilder {
  const EquationExplanationTemplate();

  // Learnova palette only. The equation is treated as the visual anchor,
  // while interpretation and reading notes sit on quiet, cohesive surfaces.
  // Detached vertical accent bars are intentionally avoided.
  static const String _panel = '0B1B35';
  static const String _panelBorder = '27466D';
  static const String _panelMuted = '91A6BF';
  static const String _accentColor = '137FEC';
  static const String _accentDark = '0B5FC4';
  static const String _softFill = 'F0F7FF';
  static const String _softBorder = 'CBE2FB';
  static const String _rule = 'E6EEF8';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final semantic = slide.semanticData;
    final equation = slide.equation ??
        PresentationEquationContent.fromJson(semantic['equation'] ?? '');
    final content = _map(semantic['content']);
    final explanation = _string(
      equation.explanation ??
          content['lead'] ??
          content['body'] ??
          semantic['explanation'],
    );
    final bullets = _stringList(
      content['bullets'] ?? semantic['bullets'] ?? semantic['points'],
    ).take(5).toList();
    final rtl = _rtl(
      '${slide.title} $explanation ${bullets.join(' ')}',
    );

    final top = _contentTopFor(slide);
    const formulaHeight = 1.54;
    const sectionGap = .26;
    final lowerY = top + formulaHeight + sectionGap;
    final lowerHeight = contentBottom - lowerY;
    const panelGap = .34;
    const explanationWidth = 4.12;
    final notesWidth = safeWidth - explanationWidth - panelGap;
    final explanationX = rtl
        ? safeX + safeWidth - explanationWidth
        : safeX;
    final notesX = rtl
        ? safeX
        : safeX + explanationWidth + panelGap;
    final formulaSize = _formulaSize(equation.value);
    final elements = _lightMaster(slide);

    // Formula stage: one cohesive navy surface with restrained horizontal
    // accents. Keeping the equation on a single stage makes it stable in both
    // the web preview and PowerPoint export.
    elements.add(
      _rect(
        safeX,
        top,
        safeWidth,
        formulaHeight,
        _panel,
        radius: panelRadius,
        line: _panelBorder,
        lineWidth: 1,
        shadow: true,
      ),
    );
    elements.add(
      _rect(safeX + .38, top + .25, .50, .045, _accentColor, radius: 5),
    );
    elements.add(
      _text(
        (equation.label ?? 'KEY EQUATION').toUpperCase(),
        safeX + .38,
        top + .38,
        3.35,
        .16,
        size: 8.2,
        color: _panelMuted,
        bold: true,
        spacing: 1.20,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );
    elements.add(
      _text(
        'FORMULA ${(slide.slideNumber ?? 1).toString().padLeft(2, '0')}',
        safeX + safeWidth - 2.05,
        top + .38,
        1.67,
        .16,
        size: 7.6,
        color: _panelMuted,
        bold: true,
        spacing: 1.0,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: 1.0,
      ),
    );
    elements.add(
      _line(
        safeX + .38,
        top + .66,
        safeWidth - .76,
        _panelBorder,
        width: 1,
      ),
    );
    elements.add(
      _equationElement(
        equation,
        safeX + .46,
        top + .72,
        safeWidth - .92,
        .64,
        color: white,
        size: formulaSize,
      ),
    );

    // Interpretation panel. The blue accent remains inside the surface and is
    // horizontal, so it cannot appear as a detached column after scaling.
    elements.add(
      _rect(
        explanationX,
        lowerY,
        explanationWidth,
        lowerHeight,
        _softFill,
        radius: compactRadius,
        line: _softBorder,
        lineWidth: 1,
      ),
    );
    elements.add(
      _rect(
        explanationX + .32,
        lowerY + .30,
        .46,
        .04,
        _accentColor,
        radius: 5,
      ),
    );
    elements.add(
      _text(
        'WHAT IT MEANS',
        explanationX + .32,
        lowerY + .43,
        explanationWidth - .64,
        .16,
        size: 7.8,
        color: _accentDark,
        bold: true,
        spacing: 1.10,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );

    final explanationText = explanation.isNotEmpty
        ? explanation
        : 'Use the reading notes to identify the role of each part of the expression.';
    final explanationSize = _explanationSize(explanationText, lowerHeight);
    elements.add(
      _text(
        explanationText,
        explanationX + .32,
        lowerY + .79,
        explanationWidth - .64,
        math.max(.72, lowerHeight - 1.45).toDouble(),
        size: explanationSize,
        color: inkSoft,
        maxLines: 7,
        align: rtl ? TextAlign.right : TextAlign.left,
        verticalAlign: 'middle',
        lineHeight: 1.16,
      ),
    );
    elements.add(
      _line(
        explanationX + .32,
        lowerY + lowerHeight - .45,
        explanationWidth - .64,
        _softBorder,
        width: 1,
      ),
    );
    elements.add(
      _text(
        'INTERPRETATION',
        explanationX + .32,
        lowerY + lowerHeight - .28,
        explanationWidth - .64,
        .11,
        size: 6.6,
        color: muted,
        bold: true,
        spacing: 1.0,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );

    // Reading notes are kept in one editorial ledger rather than a collection
    // of cards. Rows align to a shared rhythm and use only subtle dividers.
    elements.add(
      _rect(
        notesX,
        lowerY,
        notesWidth,
        lowerHeight,
        white,
        radius: compactRadius,
        line: border,
        lineWidth: 1,
        shadow: true,
      ),
    );
    elements.add(
      _rect(notesX + .32, lowerY + .30, .46, .04, _accentColor, radius: 5),
    );
    elements.add(
      _text(
        'HOW TO READ IT',
        notesX + .32,
        lowerY + .43,
        notesWidth - 2.10,
        .16,
        size: 7.8,
        color: _accentDark,
        bold: true,
        spacing: 1.10,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    );
    elements.add(
      _text(
        '${bullets.length.toString().padLeft(2, '0')} NOTES',
        notesX + notesWidth - 1.52,
        lowerY + .43,
        1.20,
        .16,
        size: 7.2,
        color: muted,
        bold: true,
        spacing: .80,
        maxLines: 1,
        align: TextAlign.right,
        lineHeight: 1.0,
      ),
    );
    elements.add(
      _line(
        notesX + .32,
        lowerY + .70,
        notesWidth - .64,
        _rule,
        width: 1,
      ),
    );

    if (bullets.isEmpty) {
      elements.add(
        _text(
          explanationText,
          notesX + .38,
          lowerY + .94,
          notesWidth - .76,
          lowerHeight - 1.20,
          size: 13.2,
          color: inkSoft,
          maxLines: 6,
          align: rtl ? TextAlign.right : TextAlign.left,
          verticalAlign: 'middle',
          lineHeight: 1.16,
        ),
      );
      return elements;
    }

    final rowsTop = lowerY + .76;
    final rowHeight = (lowerHeight - .82) / bullets.length;
    final noteSize = bullets.length >= 5
        ? 10.2
        : bullets.length == 4
            ? 10.8
            : 11.7;

    for (var index = 0; index < bullets.length; index++) {
      final y = rowsTop + index * rowHeight;
      final number = '${index + 1}'.padLeft(2, '0');

      if (index > 0) {
        elements.add(
          _line(
            notesX + .32,
            y,
            notesWidth - .64,
            _rule,
            width: .8,
          ),
        );
      }

      if (rtl) {
        elements.add(
          _text(
            number,
            notesX + notesWidth - .70,
            y + .08,
            .38,
            rowHeight - .16,
            size: 7.4,
            color: _accentDark,
            bold: true,
            maxLines: 1,
            align: TextAlign.right,
            verticalAlign: 'middle',
            lineHeight: 1.0,
          ),
        );
        elements.add(
          _rect(
            notesX + notesWidth - 1.10,
            y + rowHeight / 2 - .02,
            .24,
            .035,
            _accentColor,
            radius: 5,
          ),
        );
        elements.add(
          _text(
            bullets[index],
            notesX + .34,
            y + .06,
            notesWidth - 1.64,
            rowHeight - .12,
            size: noteSize,
            color: inkSoft,
            maxLines: 2,
            align: TextAlign.right,
            verticalAlign: 'middle',
            lineHeight: 1.12,
          ),
        );
      } else {
        elements.add(
          _text(
            number,
            notesX + .32,
            y + .08,
            .38,
            rowHeight - .16,
            size: 7.4,
            color: _accentDark,
            bold: true,
            maxLines: 1,
            verticalAlign: 'middle',
            lineHeight: 1.0,
          ),
        );
        elements.add(
          _rect(
            notesX + .77,
            y + rowHeight / 2 - .02,
            .24,
            .035,
            _accentColor,
            radius: 5,
          ),
        );
        elements.add(
          _text(
            bullets[index],
            notesX + 1.15,
            y + .06,
            notesWidth - 1.49,
            rowHeight - .12,
            size: noteSize,
            color: inkSoft,
            maxLines: 2,
            verticalAlign: 'middle',
            lineHeight: 1.12,
          ),
        );
      }
    }

    return elements;
  }

  double _formulaSize(String value) {
    final length = value.trim().length;
    if (length > 100) return 21;
    if (length > 76) return 24;
    if (length > 54) return 27;
    if (length > 36) return 30;
    return 34;
  }

  double _explanationSize(String value, double availableHeight) {
    final units = value.trim().length;
    if (availableHeight < 2.55 || units > 230) return 11.6;
    if (units > 175) return 12.2;
    if (units > 120) return 13.0;
    return 13.8;
  }
}
