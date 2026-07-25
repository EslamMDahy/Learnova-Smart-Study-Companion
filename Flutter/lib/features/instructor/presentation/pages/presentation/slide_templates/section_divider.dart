part of '../instructor_presentation_page.dart';

class SectionDividerTemplate extends SlideTemplateBuilder {
  const SectionDividerTemplate();

  static const String _rail = '0B1B35';
  static const String _railBorder = '27466D';
  static const String _number = '1B3C66';
  static const String _textSoft = 'B8C7DA';
  static const String _textFaint = '7890AE';
  static const String _accentText = '76B8FA';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final data = slide.semanticData;
    final subtitle = _string(
      data['subtitle'] ?? _map(data['content'])['lead'],
    );
    final sectionNumber = _string(data['section_number']).isNotEmpty
        ? _string(data['section_number']).padLeft(2, '0')
        : '${slide.slideNumber ?? 1}'.padLeft(2, '0');
    final kicker = _string(slide.kicker).isEmpty
        ? 'SECTION'
        : _string(slide.kicker).toUpperCase();
    final descriptor = _string(
      data['descriptor'] ?? data['section_label'] ?? data['chapter'],
    );
    final slideNumber = '${slide.slideNumber ?? 1}'.padLeft(2, '0');
    final rtl = _rtl('${slide.title} $subtitle');

    const railWidth = 3.42;
    const contentX = 4.18;
    const contentWidth = 8.12;
    const titleY = 2.16;

    final titleSize = _fitTitle(slide.title, large: true);
    final titleLines = _wrappedLineCount(
      slide.title,
      width: contentWidth,
      fontSize: titleSize,
      maxLines: 3,
    );
    final titleHeight = math.max(
      1.14,
      _textBlockHeight(titleLines, titleSize, 1.01, padding: .08),
    );
    final subtitleY = titleY + titleHeight + .24;
    final subtitleLines = subtitle.isEmpty
        ? 0
        : _wrappedLineCount(
            subtitle,
            width: 7.54,
            fontSize: 17.5,
            maxLines: 3,
          );
    final subtitleHeight = subtitle.isEmpty
        ? 0.0
        : math.max(
            .48,
            _textBlockHeight(subtitleLines, 17.5, 1.17, padding: .06),
          );

    return [
      // A restrained editorial split keeps the divider related to the title
      // slide without repeating its exact composition.
      _rect(0, 0, railWidth, 7.50, _rail),
      _rect(railWidth - .055, 0, .055, 7.50, primary),

      // Brand block.
      _image('assets/logo.webp', .72, .48, .42, .42, fit: 'contain'),
      _text('LEARNOVA', 1.27, .53, 1.55, .22,
          size: 13.2,
          color: white,
          bold: true,
          spacing: 1.0,
          maxLines: 1),
      _text('ACADEMIC AI', 1.27, .78, 1.52, .15,
          size: 7.3,
          color: _textFaint,
          bold: true,
          spacing: 1.40,
          maxLines: 1),
      _line(.72, 1.20, 2.00, _railBorder, width: 1),

      // Section index rail.
      _text('SECTION', .72, 1.58, 1.40, .18,
          size: 8,
          color: _accentText,
          bold: true,
          spacing: 1.35,
          maxLines: 1),
      _text(sectionNumber, .60, 1.88, 2.28, 1.44,
          size: 86,
          color: _number,
          bold: true,
          maxLines: 1,
          lineHeight: 1.0),
      _rect(.72, 3.44, .64, .045, primary, radius: 4),
      if (descriptor.isNotEmpty)
        _text(descriptor.toUpperCase(), .72, 3.78, 2.08, .34,
            size: 8.2,
            color: _textSoft,
            bold: true,
            spacing: .90,
            maxLines: 2,
            lineHeight: 1.10),

      // Quiet navigation detail at the bottom of the rail.
      _line(.72, 6.18, 2.00, _railBorder, width: 1),
      _text('LECTURE SECTION', .72, 6.47, 1.48, .14,
          size: 7.1,
          color: _textFaint,
          bold: true,
          spacing: 1.10,
          maxLines: 1),
      _text(slideNumber, 2.20, 6.45, .52, .18,
          size: 9,
          color: _textSoft,
          bold: true,
          maxLines: 1,
          align: TextAlign.right),

      // Main editorial field.
      _rect(contentX, 1.42, .34, .035, primary),
      _text('$kicker  /  $sectionNumber', contentX + .46, 1.34, 4.20, .20,
          size: 9.4,
          color: _accentText,
          bold: true,
          spacing: 1.10,
          maxLines: 1),
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
        lineHeight: 1.01,
      ),
      if (subtitle.isNotEmpty)
        _text(
          subtitle,
          contentX,
          subtitleY,
          7.54,
          subtitleHeight,
          size: 17.5,
          color: _textSoft,
          maxLines: 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.17,
        ),

      // Footer rhythm mirrors the title slide and remains PowerPoint-safe.
      _line(contentX, 6.18, contentWidth, _railBorder, width: 1),
      _text('SECTION TRANSITION', contentX, 6.47, 2.05, .14,
          size: 7.3,
          color: _textFaint,
          bold: true,
          spacing: 1.20,
          maxLines: 1),
      _text('LEARNOVA / PRESENTATION', 9.72, 6.47, 2.58, .14,
          size: 7.3,
          color: _textFaint,
          bold: true,
          spacing: 1.05,
          maxLines: 1,
          align: TextAlign.right),
      _text('learnova.ai', 11.17, 6.82, 1.13, .14,
          size: 7.2,
          color: _textFaint,
          bold: true,
          maxLines: 1,
          align: TextAlign.right),
    ];
  }
}
