part of '../instructor_presentation_page.dart';

class FullImageTemplate extends SlideTemplateBuilder {
  const FullImageTemplate();

  static const String _overlay = '061327';
  static const String _panel = '07182E';
  static const String _panelBorder = '29415F';
  static const String _textSoft = 'D5E1F0';
  static const String _textFaint = '8EA4BE';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final visual = slide.visual!;
    final data = slide.semanticData;
    final content = _map(data['content']);
    final subtitle = _string(
      data['subtitle'] ?? content['lead'] ?? content['body'],
    );
    final caption = _string(visual.caption);
    final kicker = _string(slide.kicker).isEmpty
        ? 'VISUAL STUDY'
        : _string(slide.kicker).toUpperCase();
    final slideNumber = (slide.slideNumber ?? 1).toString().padLeft(2, '0');
    final rtl = _rtl('${slide.title} $subtitle');

    const panelX = .68;
    const panelY = 3.76;
    const panelWidth = 8.48;
    const panelHeight = 2.90;
    const innerX = panelX + .38;
    const innerWidth = panelWidth - .76;

    final titleSize = math.min(42.0, _fitTitle(slide.title)).toDouble();
    final titleLines = _wrappedLineCount(
      slide.title,
      width: innerWidth,
      fontSize: titleSize,
      maxLines: 2,
    );
    final titleHeight = math.max(
      .70,
      _textBlockHeight(titleLines, titleSize, 1.02, padding: .06),
    );
    final titleY = panelY + .76;
    final subtitleY = titleY + titleHeight + .13;
    final subtitleHeight = math.max(
      .34,
      panelY + panelHeight - subtitleY - .25,
    );

    final elements = <PresentationElement>[
      // Full-bleed image remains the primary visual. The subtle wash keeps
      // bright and dark source images equally readable in preview and PPT.
      _image(visual.src, 0, 0, sw, sh, fit: visual.fit),
      _rect(0, 0, sw, sh, _overlay, opacity: .22),

      // Quiet masthead. It avoids floating pills and keeps the image visible.
      _rect(0, 0, sw, .94, _overlay, opacity: .68),
      _image('assets/logo.webp', .64, .27, .38, .38, fit: 'contain'),
      _text('LEARNOVA', 1.13, .36, 1.56, .18,
          size: 12.5,
          color: white,
          bold: true,
          spacing: 1.0,
          maxLines: 1,
          lineHeight: 1.0),
      _text('ACADEMIC PRESENTATION', 2.93, .39, 2.42, .13,
          size: 7.4,
          color: _textFaint,
          bold: true,
          spacing: 1.25,
          maxLines: 1,
          lineHeight: 1.0),
      _line(5.58, .47, 5.31, _panelBorder, width: 1),
      _text('FULL IMAGE', 11.08, .39, .94, .13,
          size: 7.4,
          color: _textFaint,
          bold: true,
          spacing: 1.15,
          maxLines: 1,
          align: TextAlign.right,
          lineHeight: 1.0),
      _text(slideNumber, 12.18, .34, .48, .18,
          size: 12.5,
          color: white,
          bold: true,
          maxLines: 1,
          align: TextAlign.right,
          lineHeight: 1.0),

      // One cohesive editorial panel. Accents are horizontal and contained,
      // so they cannot appear as detached blue columns after scaling.
      _rect(
        panelX,
        panelY,
        panelWidth,
        panelHeight,
        _panel,
        radius: 18,
        line: _panelBorder,
        lineWidth: 1,
        opacity: .94,
        shadow: true,
      ),
      _rect(innerX, panelY + .34, .70, .045, primary, radius: 4),
      _rect(innerX + .79, panelY + .34, .18, .045, cyan, radius: 4),
      _text(kicker, innerX, panelY + .50, innerWidth, .15,
          size: 8.3,
          color: '76B8FA',
          bold: true,
          spacing: 1.35,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0),
      _text(
        slide.title,
        innerX,
        titleY,
        innerWidth,
        titleHeight,
        size: titleSize,
        color: white,
        bold: true,
        maxLines: 2,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.02,
      ),
      if (subtitle.isNotEmpty)
        _text(
          subtitle,
          innerX,
          subtitleY,
          innerWidth,
          subtitleHeight,
          size: 15.5,
          color: _textSoft,
          maxLines: 2,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.14,
        ),

      // A restrained source note lives over the image without competing with
      // the title. It disappears completely when no caption is supplied.
      if (caption.isNotEmpty)
        ..._captionPanel(
          caption: caption,
          rtl: _rtl(caption),
        ),
    ];

    return elements;
  }

  List<PresentationElement> _captionPanel({
    required String caption,
    required bool rtl,
  }) {
    const x = 9.55;
    const y = 5.29;
    const width = 3.12;
    const height = 1.37;
    return [
      _rect(
        x,
        y,
        width,
        height,
        _panel,
        radius: 14,
        line: _panelBorder,
        lineWidth: 1,
        opacity: .88,
      ),
      _rect(x + .24, y + .24, .46, .035, primary, radius: 4),
      _text('IMAGE NOTE', x + .24, y + .38, width - .48, .13,
          size: 7.2,
          color: '76B8FA',
          bold: true,
          spacing: 1.15,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0),
      _text(
        caption,
        x + .24,
        y + .64,
        width - .48,
        .52,
        size: 10.4,
        color: _textSoft,
        maxLines: 3,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.13,
      ),
    ];
  }
}
