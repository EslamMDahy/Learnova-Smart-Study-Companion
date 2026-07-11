part of '../instructor_presentation_page.dart';

class ConceptExplanationTemplate extends SlideTemplateBuilder {
  const ConceptExplanationTemplate();

  static const String _navy = '0B1B35';
  static const String _navySoft = '102746';
  static const String _navyLine = '27466D';
  static const String _railText = 'D9E5F3';
  static const String _railMuted = '8FA5BE';
  static const String _label = '718198';
  static const String _blueText = '0B5FC4';
  static const String _ideaLine = 'DCE7F2';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final content = _map(slide.semanticData['content']);
    final lead = _string(content['lead'] ?? slide.semanticData['lead']);
    final body = _string(
      content['body'] ??
          content['explanation'] ??
          slide.semanticData['body'],
    );
    final bullets = _stringList(
      content['bullets'] ?? slide.semanticData['bullets'],
    ).take(4).toList();
    final keyTerm = _string(
      content['key_term'] ??
          slide.semanticData['key_term'] ??
          'KEY CONCEPT',
    );
    final definition = _string(
      content['definition'] ?? slide.semanticData['definition'],
    );
    final example = _string(
      content['example'] ?? slide.semanticData['example'],
    );

    final leadText = lead.isNotEmpty
        ? lead
        : (body.isNotEmpty ? body : definition);
    final bodyText = body.isNotEmpty && body != leadText ? body : '';
    final definitionText = definition.isNotEmpty
        ? definition
        : (leadText.isNotEmpty ? leadText : bodyText);

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    final elements = _lightMaster(slide);

    // The split follows the same editorial rhythm as the title slide:
    // a wide reading field and one calm, self-contained concept rail.
    // No vertical accent is placed outside a panel, so browser scaling and
    // PowerPoint rendering cannot turn it into a detached blue column.
    const conceptWidth = 3.64;
    const columnGap = .42;
    final narrativeWidth = safeWidth - conceptWidth - columnGap;
    final conceptX = safeX + narrativeWidth + columnGap;

    elements.addAll(
      _editorialNarrative(
        x: safeX,
        y: top,
        width: narrativeWidth,
        height: height,
        lead: leadText,
        body: bodyText,
        bullets: bullets,
      ),
    );

    if (slide.visual != null && slide.visual!.src.trim().isNotEmpty) {
      elements.addAll(
        _visualRail(
          visual: slide.visual!,
          x: conceptX,
          y: top,
          width: conceptWidth,
          height: height,
          keyTerm: keyTerm,
          definition: definitionText,
          example: example,
        ),
      );
    } else {
      elements.addAll(
        _conceptRail(
          x: conceptX,
          y: top,
          width: conceptWidth,
          height: height,
          keyTerm: keyTerm,
          definition: definitionText,
          example: example,
        ),
      );
    }

    return elements;
  }

  List<PresentationElement> _editorialNarrative({
    required double x,
    required double y,
    required double width,
    required double height,
    required String lead,
    required String body,
    required List<String> bullets,
  }) {
    final rtl = _rtl('$lead $body');
    final leadUnits = PresentationDesignTokens.textUnits(lead);
    final leadSize = leadUnits > 108
        ? 13.2
        : leadUnits > 82
            ? 14.0
            : 15.0;
    final leadLines = _wrappedLineCount(
      lead,
      width: width - .04,
      fontSize: leadSize,
      maxLines: 3,
    );
    final leadHeight = math.max(
      .42,
      _textBlockHeight(leadLines, leadSize, 1.16, padding: .14),
    ).toDouble();

    final bodyUnits = PresentationDesignTokens.textUnits(body);
    final bodySize = bodyUnits > 165
        ? 9.8
        : bodyUnits > 118
            ? 10.4
            : 10.9;
    final bodyLines = body.isEmpty
        ? 0
        : _wrappedLineCount(
            body,
            width: width - .04,
            fontSize: bodySize,
            maxLines: 4,
          );
    final bodyHeight = body.isEmpty
        ? 0.0
        : math.max(
            .34,
            _textBlockHeight(bodyLines, bodySize, 1.20, padding: .12),
          ).toDouble();

    final elements = <PresentationElement>[
      // Horizontal accents only. They stay inside the reading field and keep
      // the same visual language as the title slide without creating bars.
      _rect(x, y + .05, .38, .035, primary, radius: 3),
      _text(
        'CONCEPT EXPLANATION',
        x + .50,
        y + .015,
        width - .50,
        .16,
        size: 7.5,
        color: _blueText,
        bold: true,
        spacing: 1.02,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        lead,
        x,
        y + .34,
        width - .04,
        leadHeight,
        size: leadSize,
        color: inkSoft,
        maxLines: 3,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.16,
      ),
    ];

    var cursorY = y + .34 + leadHeight + .10;
    if (body.isNotEmpty) {
      elements.add(
        _text(
          body,
          x,
          cursorY,
          width - .04,
          bodyHeight,
          size: bodySize,
          color: muted,
          maxLines: 4,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.20,
        ),
      );
      cursorY += bodyHeight + .18;
    }

    if (bullets.isEmpty) {
      elements.add(
        _line(x, y + height - .04, width, divider, width: 1),
      );
      return elements;
    }

    elements.addAll([
      _line(x, cursorY, width, divider, width: 1),
      _text(
        'KEY IDEAS',
        x,
        cursorY + .18,
        width,
        .14,
        size: 7.2,
        color: _label,
        bold: true,
        spacing: 1.08,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ]);

    final ideasTop = cursorY + .48;
    final availableHeight = math.max(.72, y + height - ideasTop).toDouble();
    final columns = bullets.length <= 2 ? 1 : 2;
    final rows = (bullets.length / columns).ceil();
    const gapX = .44;
    const gapY = .14;
    final itemWidth = (width - gapX * (columns - 1)) / columns;
    final itemHeight =
        (availableHeight - gapY * (rows - 1)) / rows;

    for (var index = 0; index < bullets.length; index++) {
      final column = index % columns;
      final row = index ~/ columns;
      final itemX = x + column * (itemWidth + gapX);
      final itemY = ideasTop + row * (itemHeight + gapY);
      final itemRtl = _rtl(bullets[index]);
      final parts = _splitIdea(bullets[index], index);
      final heading = parts.key;
      final description = parts.value;
      final descriptionUnits =
          PresentationDesignTokens.textUnits(description);
      final descriptionSize = descriptionUnits > 72
          ? 9.1
          : descriptionUnits > 52
              ? 9.6
              : 10.1;

      elements.addAll([
        _line(itemX, itemY, itemWidth, _ideaLine, width: 1),
        _rect(itemX, itemY, .34, .032, primary, radius: 3),
        _text(
          '${index + 1}'.padLeft(2, '0'),
          itemRtl ? itemX + itemWidth - .34 : itemX,
          itemY + .16,
          .34,
          .12,
          size: 7.2,
          color: _blueText,
          bold: true,
          maxLines: 1,
          align: itemRtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
        _text(
          heading,
          itemRtl ? itemX : itemX + .50,
          itemY + .13,
          itemWidth - .50,
          .16,
          size: 7.6,
          color: _label,
          bold: true,
          spacing: .72,
          maxLines: 1,
          align: itemRtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
        _text(
          description,
          itemRtl ? itemX : itemX + .50,
          itemY + .38,
          itemWidth - .50,
          math.max(.26, itemHeight - .43).toDouble(),
          size: descriptionSize,
          color: inkSoft,
          maxLines: 3,
          align: itemRtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.14,
        ),
      ]);
    }

    return elements;
  }

  MapEntry<String, String> _splitIdea(String value, int index) {
    final text = value.trim();
    final separator = text.contains(':')
        ? ':'
        : (text.contains('：') ? '：' : '');
    if (separator.isNotEmpty) {
      final position = text.indexOf(separator);
      final heading = text.substring(0, position).trim();
      final description = text.substring(position + separator.length).trim();
      if (heading.isNotEmpty && description.isNotEmpty) {
        return MapEntry(heading.toUpperCase(), description);
      }
    }
    return MapEntry('KEY IDEA ${index + 1}', text);
  }

  List<PresentationElement> _conceptRail({
    required double x,
    required double y,
    required double width,
    required double height,
    required String keyTerm,
    required String definition,
    required String example,
  }) {
    final term = keyTerm.trim().isEmpty ? 'KEY CONCEPT' : keyTerm.trim();
    final rtl = _rtl('$term $definition $example');
    final termUnits = PresentationDesignTokens.textUnits(term);
    final termSize = termUnits > 28
        ? 16.0
        : termUnits > 18
            ? 18.2
            : 20.4;
    final definitionUnits = PresentationDesignTokens.textUnits(definition);
    final definitionSize = definitionUnits > 112
        ? 9.8
        : definitionUnits > 78
            ? 10.5
            : 11.2;
    final hasExample = example.isNotEmpty;
    final exampleHeight = hasExample ? 1.02 : 0.0;
    final exampleY = y + height - exampleHeight - .24;
    final definitionY = y + 2.03;
    final definitionBottom = hasExample ? exampleY - .20 : y + height - .28;
    final definitionHeight =
        math.max(.72, definitionBottom - definitionY).toDouble();

    final elements = <PresentationElement>[
      _rect(
        x,
        y,
        width,
        height,
        _navy,
        radius: panelRadius,
        line: _navyLine,
        lineWidth: 1,
        shadow: true,
      ),
      // Accent is deliberately horizontal and inset inside the panel.
      _rect(x + .34, y + .34, .56, .042, primary, radius: 4),
      _text(
        'KEY TERM',
        x + .34,
        y + .54,
        width - .68,
        .14,
        size: 7.2,
        color: _railMuted,
        bold: true,
        spacing: 1.08,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        term,
        x + .34,
        y + .86,
        width - .68,
        .54,
        size: termSize,
        color: white,
        bold: true,
        maxLines: 2,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.04,
      ),
      _line(x + .34, y + 1.51, width - .68, _navyLine, width: 1),
      _text(
        'DEFINITION',
        x + .34,
        y + 1.73,
        width - .68,
        .14,
        size: 7.0,
        color: _railMuted,
        bold: true,
        spacing: 1.02,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        definition,
        x + .34,
        definitionY,
        width - .68,
        definitionHeight,
        size: definitionSize,
        color: _railText,
        maxLines: hasExample ? 6 : 9,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.16,
      ),
    ];

    if (hasExample) {
      elements.addAll([
        _rect(
          x + .25,
          exampleY,
          width - .50,
          exampleHeight,
          _navySoft,
          radius: 12,
          line: _navyLine,
          lineWidth: .8,
        ),
        _rect(x + .44, exampleY + .18, .34, .032, '76B8FA', radius: 3),
        _text(
          'IN PRACTICE',
          x + .44,
          exampleY + .31,
          width - .88,
          .12,
          size: 6.8,
          color: '76B8FA',
          bold: true,
          spacing: .96,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
        _text(
          example,
          x + .44,
          exampleY + .52,
          width - .88,
          .34,
          size: 8.8,
          color: _railText,
          maxLines: 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.12,
        ),
      ]);
    }

    return elements;
  }

  List<PresentationElement> _visualRail({
    required PresentationVisualContent visual,
    required double x,
    required double y,
    required double width,
    required double height,
    required String keyTerm,
    required String definition,
    required String example,
  }) {
    final caption = _string(visual.caption);
    final term = keyTerm.trim().isEmpty ? 'KEY CONCEPT' : keyTerm.trim();
    final rtl = _rtl('$term $definition $example');
    final imageHeight = caption.isEmpty ? 1.58 : 1.38;
    final captionHeight = caption.isEmpty ? 0.0 : .28;
    final termY = y + .28 + imageHeight + captionHeight + .24;
    final definitionY = termY + .70;
    final hasExample = example.isNotEmpty;
    final exampleHeight = hasExample ? .78 : 0.0;
    final exampleY = y + height - exampleHeight - .22;
    final definitionBottom = hasExample ? exampleY - .14 : y + height - .24;
    final definitionHeight =
        math.max(.48, definitionBottom - definitionY).toDouble();

    final elements = <PresentationElement>[
      _rect(
        x,
        y,
        width,
        height,
        _navy,
        radius: panelRadius,
        line: _navyLine,
        lineWidth: 1,
        shadow: true,
      ),
      _rect(x + .28, y + .26, width - .56, imageHeight, _navySoft,
          radius: 13, line: _navyLine, lineWidth: .8),
      _image(
        visual.src,
        x + .34,
        y + .32,
        width - .68,
        imageHeight - .12,
        fit: visual.fit,
        radius: 10,
      ),
      if (caption.isNotEmpty)
        _text(
          caption,
          x + .34,
          y + .36 + imageHeight,
          width - .68,
          .22,
          size: 7.8,
          color: _railMuted,
          maxLines: 2,
          align: _rtl(caption) ? TextAlign.right : TextAlign.left,
          lineHeight: 1.08,
        ),
      _rect(x + .34, termY - .12, .48, .038, primary, radius: 3),
      _text(
        'KEY TERM',
        x + .34,
        termY,
        width - .68,
        .12,
        size: 6.8,
        color: _railMuted,
        bold: true,
        spacing: 1.0,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        term,
        x + .34,
        termY + .24,
        width - .68,
        .36,
        size: 16.0,
        color: white,
        bold: true,
        maxLines: 2,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.04,
      ),
      _text(
        definition,
        x + .34,
        definitionY,
        width - .68,
        definitionHeight,
        size: 9.5,
        color: _railText,
        maxLines: hasExample ? 5 : 7,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.15,
      ),
    ];

    if (hasExample) {
      elements.addAll([
        _rect(
          x + .27,
          exampleY,
          width - .54,
          exampleHeight,
          _navySoft,
          radius: 10,
          line: _navyLine,
          lineWidth: .8,
        ),
        _text(
          example,
          x + .44,
          exampleY + .16,
          width - .88,
          .43,
          size: 8.5,
          color: _railText,
          maxLines: 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.10,
        ),
      ]);
    }

    return elements;
  }
}
