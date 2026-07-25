part of '../instructor_presentation_page.dart';

class TitleSlideTemplate extends SlideTemplateBuilder {
  const TitleSlideTemplate();

  static const String _panel = '0B1B35';
  static const String _panelSoft = '102746';
  static const String _panelBorder = '27466D';
  static const String _textSoft = 'B8C7DA';
  static const String _textFaint = '7890AE';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final data = slide.semanticData;
    final subtitle = _string(data['subtitle'] ?? _map(data['content'])['lead']);
    final course = _string(data['course'] ?? data['course_name']);
    final instructor = _string(data['instructor'] ?? data['presenter']);
    final term = _string(data['term'] ?? data['semester'] ?? data['date']);
    final kicker = _string(slide.kicker).isEmpty
        ? 'ACADEMIC PRESENTATION'
        : _string(slide.kicker).toUpperCase();
    final slideNumber = (slide.slideNumber ?? 1).toString().padLeft(2, '0');
    final rtl = _rtl('${slide.title} $subtitle');

    const contentX = .78;
    const contentWidth = 7.62;
    const titleY = 1.82;
    final titleSize = _fitTitle(slide.title, large: true);
    final titleLines = _wrappedLineCount(
      slide.title,
      width: contentWidth,
      fontSize: titleSize,
      maxLines: 3,
    );
    final titleHeight = math.max(
      1.18,
      _textBlockHeight(titleLines, titleSize, 1.02, padding: .10),
    );
    final subtitleY = titleY + titleHeight + .18;
    final subtitleLines = subtitle.isEmpty
        ? 0
        : _wrappedLineCount(
            subtitle,
            width: 7.18,
            fontSize: 18,
            maxLines: 3,
          );
    final subtitleHeight = subtitle.isEmpty
        ? 0.0
        : math.max(
            .48,
            _textBlockHeight(subtitleLines, 18, 1.16, padding: .06),
          );

    final elements = <PresentationElement>[
      // Editorial split: a quiet content field and a structured visual rail.
      _rect(8.93, 0, 4.40, 7.50, _panel),
      _rect(8.93, 0, .055, 7.50, primary),
      _line(.78, 1.22, 7.62, '29415F', width: 1),

      // Brand header.
      _image('assets/logo.webp', .78, .48, .42, .42, fit: 'contain'),
      _text('LEARNOVA', 1.32, .53, 1.68, .22,
          size: 13.5, color: white, bold: true, spacing: 1.05, maxLines: 1),
      _text('ACADEMIC AI', 1.32, .78, 1.65, .15,
          size: 7.5, color: _textFaint, bold: true, spacing: 1.45, maxLines: 1),
      _text(slideNumber, 7.78, .54, .62, .25,
          size: 13, color: _textFaint, bold: true, maxLines: 1, align: TextAlign.right),

      // Main title hierarchy.
      _rect(contentX, 1.48, .34, .035, primary),
      _text(kicker, 1.24, 1.39, 6.82, .22,
          size: 10.5, color: '76B8FA', bold: true, spacing: 1.45, maxLines: 1),
      _text(
        slide.title,
        contentX,
        titleY,
        contentWidth,
        titleHeight,
        size: titleSize,
        color: white,
        bold: true,
        maxLines: 3,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.02,
      ),
      if (subtitle.isNotEmpty)
        _text(
          subtitle,
          contentX,
          subtitleY,
          7.18,
          subtitleHeight,
          size: 18,
          color: _textSoft,
          maxLines: 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.16,
        ),

      // Reserved bottom band keeps all metadata aligned and export-safe.
      _line(.78, 5.72, 7.62, '29415F', width: 1),
      ..._metadataRow(
        course: course,
        instructor: instructor,
        term: term,
      ),

      // Formal rail header and footer.
      _text('LEARNOVA / PRESENTATION', 9.42, .58, 3.26, .18,
          size: 8, color: _textFaint, bold: true, spacing: 1.25, maxLines: 1),
      _line(9.42, .94, 3.18, _panelBorder, width: 1),
      _text('STRUCTURED LEARNING', 9.42, 6.78, 2.18, .16,
          size: 7.5, color: _textFaint, bold: true, spacing: 1.2, maxLines: 1),
      _text('learnova.ai', 11.48, 6.78, 1.12, .16,
          size: 7.5, color: _textFaint, bold: true, maxLines: 1, align: TextAlign.right),
      _line(9.42, 6.50, 3.18, _panelBorder, width: 1),
    ];

    if (slide.visual != null && slide.visual!.src.isNotEmpty) {
      elements.addAll(_visualRail(slide.visual!));
    } else {
      elements.addAll(_editorialRail(slideNumber));
    }

    return elements;
  }

  List<PresentationElement> _metadataRow({
    required String course,
    required String instructor,
    required String term,
  }) {
    final items = <MapEntry<String, String>>[
      if (course.isNotEmpty) MapEntry('COURSE', course),
      if (instructor.isNotEmpty) MapEntry('PRESENTER', instructor),
      if (term.isNotEmpty) MapEntry('TERM', term),
    ];

    if (items.isEmpty) {
      return [
        _text('LEARNOVA ACADEMIC PRESENTATION', .78, 6.15, 4.25, .18,
            size: 8, color: _textFaint, bold: true, spacing: 1.15, maxLines: 1),
      ];
    }

    const rowX = .78;
    const rowY = 5.94;
    const rowWidth = 7.62;
    const gap = .28;
    final cellWidth = (rowWidth - gap * (items.length - 1)) / items.length;
    final elements = <PresentationElement>[];

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final x = rowX + index * (cellWidth + gap);
      final valueRtl = _rtl(item.value);
      elements.add(
        _text(item.key, x, rowY, cellWidth, .15,
            size: 7.5, color: _textFaint, bold: true, spacing: 1.2, maxLines: 1),
      );
      elements.add(
        _text(
          item.value,
          x,
          rowY + .27,
          cellWidth,
          .36,
          size: 11.5,
          color: 'E1EAF5',
          bold: true,
          maxLines: 2,
          align: valueRtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.08,
        ),
      );
      if (index < items.length - 1) {
        elements.add(
          _line(
            x + cellWidth + gap / 2,
            rowY,
            .01,
            '29415F',
            width: 1,
            verticalHeight: .70,
          ),
        );
      }
    }

    return elements;
  }

  List<PresentationElement> _visualRail(PresentationVisualContent visual) {
    final caption = _string(visual.caption);
    return [
      _rect(9.42, 1.24, 3.18, 4.82, _panelSoft,
          radius: 18, line: _panelBorder, lineWidth: 1, shadow: true),
      _image(
        visual.src,
        9.58,
        1.40,
        2.86,
        caption.isEmpty ? 4.50 : 3.94,
        fit: visual.fit,
        radius: 14,
      ),
      if (caption.isNotEmpty)
        _text(caption, 9.62, 5.53, 2.78, .34,
            size: 9, color: _textSoft, maxLines: 2, lineHeight: 1.12),
    ];
  }

  List<PresentationElement> _editorialRail(String slideNumber) {
    return [
      _text(slideNumber, 9.34, 1.22, 3.30, 1.36,
          size: 88, color: '1B3C66', bold: true, maxLines: 1, align: TextAlign.right),
      _text('TITLE SLIDE', 9.45, 2.72, 1.48, .17,
          size: 8, color: '76B8FA', bold: true, spacing: 1.45, maxLines: 1),
      _line(9.45, 3.10, 3.10, _panelBorder, width: 1),
      _rect(9.45, 3.42, 3.10, 1.58, '0D213F', radius: 14, line: _panelBorder),
      _rect(9.70, 3.72, 1.62, .055, primary),
      _line(9.70, 4.06, 2.26, '355578', width: 1),
      _line(9.70, 4.32, 1.86, '355578', width: 1),
      _line(9.70, 4.58, 2.34, '355578', width: 1),
      _rect(11.91, 3.69, .38, .38, '173A66', radius: 8, line: '355578'),
      _text('16:9', 11.94, 3.83, .32, .10,
          size: 6.5, color: _textSoft, bold: true, maxLines: 1, align: TextAlign.center),
      _text('ACADEMIC DECK', 9.45, 5.40, 1.65, .16,
          size: 7.5, color: _textFaint, bold: true, spacing: 1.15, maxLines: 1),
      _text('LEARNOVA AI', 11.16, 5.40, 1.39, .16,
          size: 7.5, color: _textFaint, bold: true, spacing: 1.05, maxLines: 1, align: TextAlign.right),
    ];
  }
}
