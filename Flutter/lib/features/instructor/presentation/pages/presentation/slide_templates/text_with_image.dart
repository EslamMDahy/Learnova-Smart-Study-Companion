part of '../instructor_presentation_page.dart';

class TextWithImageTemplate extends SlideTemplateBuilder {
  const TextWithImageTemplate();

  static const String _navy = '0B1B35';
  static const String _label = '6F8099';
  static const String _rule = 'D8E5F3';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final content = _map(slide.semanticData['content']);
    final lead = _string(content['lead'] ?? slide.semanticData['lead']);
    final body = _string(content['body'] ?? slide.semanticData['body']);
    final bullets = _stringList(
      content['bullets'] ?? slide.semanticData['bullets'],
    ).take(4).toList();
    final visual = slide.visual;
    final imageLeft = visual?.position == 'left';
    final rtl = _rtl('$lead $body ${bullets.join(' ')}');

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const visualWidth = 5.08;
    const gap = .62;
    final textWidth = safeWidth - visualWidth - gap;
    final visualX = imageLeft ? safeX : safeX + textWidth + gap;
    final textX = imageLeft ? safeX + visualWidth + gap : safeX;

    final elements = _lightMaster(slide);
    elements.addAll(
      _buildVisualPanel(
        visual: visual,
        x: visualX,
        y: top,
        width: visualWidth,
        height: height,
      ),
    );
    elements.addAll(
      _buildEditorialContent(
        lead: lead,
        body: body,
        bullets: bullets,
        x: textX,
        y: top,
        width: textWidth,
        height: height,
        rtl: rtl,
      ),
    );
    return elements;
  }

  List<PresentationElement> _buildVisualPanel({
    required PresentationVisualContent? visual,
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final caption = _string(visual?.caption);
    final hasCaption = caption.isNotEmpty;
    final captionHeight = hasCaption ? .82 : .24;
    final imageHeight = height - captionHeight - .16;
    final elements = <PresentationElement>[
      _rect(
        x,
        y,
        width,
        height,
        white,
        radius: panelRadius,
        line: border,
        lineWidth: 1,
        shadow: true,
      ),
    ];

    if (visual != null && visual.src.trim().isNotEmpty) {
      elements.add(
        _image(
          visual.src,
          x + .12,
          y + .12,
          width - .24,
          imageHeight,
          fit: visual.fit,
          radius: compactRadius,
        ),
      );
    } else {
      elements.addAll([
        _rect(
          x + .12,
          y + .12,
          width - .24,
          imageHeight,
          _navy,
          radius: compactRadius,
        ),
        _line(x + .42, y + .56, .72, primary, width: 3.5),
        _text(
          'VISUAL',
          x + .42,
          y + .82,
          width - .84,
          .30,
          size: 18,
          color: white,
          bold: true,
          spacing: 1.4,
          maxLines: 1,
        ),
      ]);
    }

    if (hasCaption) {
      final captionLines = _wrappedLineCount(
        caption,
        width: width - .74,
        fontSize: 9.4,
        maxLines: 2,
      );
      final captionTextHeight = math.min(
        .36,
        math.max(.18, _textBlockHeight(captionLines, 9.4, 1.10)),
      ).toDouble();
      final captionY = y + height - .66;
      elements.addAll([
        _line(x + .24, captionY - .12, .52, primary, width: 3),
        _text(
          'VISUAL NOTE',
          x + .24,
          captionY,
          1.18,
          .13,
          size: 7.2,
          color: primaryDark,
          bold: true,
          spacing: 1.15,
          maxLines: 1,
          lineHeight: 1.0,
        ),
        _text(
          caption,
          x + 1.50,
          captionY - .01,
          width - 1.74,
          captionTextHeight,
          size: 9.4,
          color: muted,
          maxLines: 2,
          lineHeight: 1.10,
        ),
      ]);
    }

    return elements;
  }

  List<PresentationElement> _buildEditorialContent({
    required String lead,
    required String body,
    required List<String> bullets,
    required double x,
    required double y,
    required double width,
    required double height,
    required bool rtl,
  }) {
    final elements = <PresentationElement>[
      _line(x, y + .03, .62, primary, width: 3.5),
      _line(x + .70, y + .03, .16, cyan, width: 3.5),
      _text(
        'VISUAL EXPLANATION',
        x,
        y + .19,
        width,
        .14,
        size: 7.6,
        color: primaryDark,
        bold: true,
        spacing: 1.15,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ];

    var cursorY = y + .51;

    if (lead.isNotEmpty) {
      final leadUnits = PresentationDesignTokens.textUnits(lead);
      final leadSize = leadUnits > 46
          ? 17.0
          : leadUnits > 34
              ? 18.2
              : 19.4;
      final leadLines = _wrappedLineCount(
        lead,
        width: width,
        fontSize: leadSize,
        maxLines: 3,
      );
      final leadHeight = math.min(
        bullets.isEmpty ? 1.02 : .86,
        math.max(.48, _textBlockHeight(leadLines, leadSize, 1.10)),
      ).toDouble();
      elements.add(
        _text(
          lead,
          x,
          cursorY,
          width,
          leadHeight,
          size: leadSize,
          color: ink,
          bold: false,
          maxLines: 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.10,
        ),
      );
      cursorY += leadHeight + .18;
    }

    if (body.isNotEmpty) {
      final bodyUnits = PresentationDesignTokens.textUnits(body);
      final bodySize = bodyUnits > 92
          ? 12.3
          : bodyUnits > 66
              ? 13.0
              : 13.6;
      final bodyLines = _wrappedLineCount(
        body,
        width: width,
        fontSize: bodySize,
        maxLines: 4,
      );
      final bodyHeight = math.min(
        bullets.isEmpty ? 1.04 : .82,
        math.max(.42, _textBlockHeight(bodyLines, bodySize, 1.18)),
      ).toDouble();
      elements.add(
        _text(
          body,
          x,
          cursorY,
          width,
          bodyHeight,
          size: bodySize,
          color: muted,
          maxLines: 4,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.18,
        ),
      );
      cursorY += bodyHeight + .22;
    }

    if (bullets.isEmpty) {
      return elements;
    }

    elements.addAll([
      _line(x, cursorY, width, _rule, width: 1),
      _text(
        'KEY POINTS',
        x,
        cursorY + .18,
        width,
        .13,
        size: 7.4,
        color: _label,
        bold: true,
        spacing: 1.15,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ]);
    cursorY += .48;

    final availableHeight = math.max(.60, y + height - cursorY).toDouble();
    if (bullets.length == 4) {
      elements.addAll(
        _buildFourPointGrid(
          bullets: bullets,
          x: x,
          y: cursorY,
          width: width,
          height: availableHeight,
          rtl: rtl,
        ),
      );
      return elements;
    }

    final rowHeight = availableHeight / bullets.length;
    final bulletSize = rowHeight < .52 ? 10.4 : 11.3;

    for (var index = 0; index < bullets.length; index++) {
      final rowY = cursorY + rowHeight * index;
      final number = '${index + 1}'.padLeft(2, '0');
      final textHeight = math.max(.26, rowHeight - .16).toDouble();

      if (rtl) {
        elements.addAll([
          _text(
            number,
            x + width - .34,
            rowY + .05,
            .34,
            .13,
            size: 7.6,
            color: primaryDark,
            bold: true,
            maxLines: 1,
            align: TextAlign.right,
            lineHeight: 1.0,
          ),
          _line(x + width - .72, rowY + .13, .23, primary, width: 2.2),
          _text(
            bullets[index],
            x,
            rowY,
            width - .86,
            textHeight,
            size: bulletSize,
            color: inkSoft,
            maxLines: 2,
            align: TextAlign.right,
            verticalAlign: 'middle',
            lineHeight: 1.13,
          ),
        ]);
      } else {
        elements.addAll([
          _text(
            number,
            x,
            rowY + .05,
            .34,
            .13,
            size: 7.6,
            color: primaryDark,
            bold: true,
            maxLines: 1,
            lineHeight: 1.0,
          ),
          _line(x + .38, rowY + .13, .23, primary, width: 2.2),
          _text(
            bullets[index],
            x + .74,
            rowY,
            width - .74,
            textHeight,
            size: bulletSize,
            color: inkSoft,
            maxLines: 2,
            verticalAlign: 'middle',
            lineHeight: 1.13,
          ),
        ]);
      }

      if (index < bullets.length - 1) {
        elements.add(
          _line(
            x,
            rowY + rowHeight - .04,
            width,
            _rule,
            width: .8,
          ),
        );
      }
    }

    return elements;
  }

  List<PresentationElement> _buildFourPointGrid({
    required List<String> bullets,
    required double x,
    required double y,
    required double width,
    required double height,
    required bool rtl,
  }) {
    const columnGap = .34;
    final cellWidth = (width - columnGap) / 2;
    final rowHeight = height / 2;
    final elements = <PresentationElement>[];

    for (var index = 0; index < bullets.length; index++) {
      final column = index % 2;
      final row = index ~/ 2;
      final cellX = x + column * (cellWidth + columnGap);
      final cellY = y + row * rowHeight;
      final number = '${index + 1}'.padLeft(2, '0');

      elements.addAll([
        _text(
          number,
          rtl ? cellX + cellWidth - .34 : cellX,
          cellY + .03,
          .34,
          .13,
          size: 7.4,
          color: primaryDark,
          bold: true,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
        _line(
          rtl ? cellX + cellWidth - .73 : cellX + .39,
          cellY + .11,
          .24,
          primary,
          width: 2.2,
        ),
        _text(
          bullets[index],
          cellX,
          cellY + .28,
          cellWidth,
          math.max(.30, rowHeight - .39).toDouble(),
          size: rowHeight < .74 ? 9.8 : 10.7,
          color: inkSoft,
          maxLines: 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.12,
        ),
      ]);

      if (row == 0) {
        elements.add(
          _line(
            cellX,
            cellY + rowHeight - .05,
            cellWidth,
            _rule,
            width: .8,
          ),
        );
      }
    }

    return elements;
  }
}
