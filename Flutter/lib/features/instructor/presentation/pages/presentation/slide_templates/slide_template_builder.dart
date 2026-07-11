part of '../instructor_presentation_page.dart';

abstract class SlideTemplateBuilder {
  const SlideTemplateBuilder();

  List<PresentationElement> build(PresentationSlide slide);

  double get sw => _LectureLayoutEngine.sw;
  double get sh => _LectureLayoutEngine.sh;
  String get canvas => _LectureLayoutEngine.canvas;
  String get white => _LectureLayoutEngine.white;
  String get ink => _LectureLayoutEngine.ink;
  String get inkSoft => _LectureLayoutEngine.inkSoft;
  String get muted => _LectureLayoutEngine.muted;
  String get footer => _LectureLayoutEngine.footer;
  String get primary => _LectureLayoutEngine.primary;
  String get primaryDark => _LectureLayoutEngine.primaryDark;
  String get primarySoft => _LectureLayoutEngine.primarySoft;
  String get cyan => _LectureLayoutEngine.cyan;
  String get cyanSoft => _LectureLayoutEngine.cyanSoft;
  String get indigo => _LectureLayoutEngine.indigo;
  String get indigoSoft => _LectureLayoutEngine.indigoSoft;
  String get violet => _LectureLayoutEngine.violet;
  String get violetSoft => _LectureLayoutEngine.violetSoft;
  String get border => _LectureLayoutEngine.border;
  String get divider => _LectureLayoutEngine.divider;
  String get success => _LectureLayoutEngine.success;
  String get warning => _LectureLayoutEngine.warning;
  String get danger => _LectureLayoutEngine.danger;
  String get darkBlue => _LectureLayoutEngine.darkBlue;

  double get safeX => _LectureLayoutEngine.safeX;
  double get safeWidth => _LectureLayoutEngine.safeWidth;
  double get contentBottom => _LectureLayoutEngine.contentBottom;
  double get footerRuleY => _LectureLayoutEngine.footerRuleY;
  double get panelRadius => _LectureLayoutEngine.panelRadius;
  double get compactRadius => _LectureLayoutEngine.compactRadius;
  double get panelGap => _LectureLayoutEngine.panelGap;

  PresentationElement _text(
    String value,
    double x,
    double y,
    double w,
    double h, {
    double size = 14,
    String? color,
    bool bold = false,
    bool italic = false,
    int maxLines = 3,
    TextAlign? align,
    double spacing = 0,
    String verticalAlign = 'top',
    double? lineHeight,
  }) {
    return _LectureLayoutEngine._text(
      value,
      x,
      y,
      w,
      h,
      size: size,
      color: color ?? ink,
      bold: bold,
      italic: italic,
      maxLines: maxLines,
      align: align,
      spacing: spacing,
      verticalAlign: verticalAlign,
      lineHeight: lineHeight,
    );
  }

  PresentationElement _rect(
    double x,
    double y,
    double w,
    double h,
    String fill, {
    double radius = 0,
    String? line,
    double lineWidth = 1,
    double opacity = 1,
    bool shadow = false,
  }) {
    return _LectureLayoutEngine._rect(
      x,
      y,
      w,
      h,
      fill,
      radius: radius,
      line: line,
      lineWidth: lineWidth,
      opacity: opacity,
      shadow: shadow,
    );
  }

  PresentationElement _oval(
    double x,
    double y,
    double size,
    String fill, {
    double opacity = 1,
  }) {
    return _LectureLayoutEngine._oval(
      x,
      y,
      size,
      fill,
      opacity: opacity,
    );
  }

  PresentationElement _line(
    double x,
    double y,
    double w,
    String color, {
    double width = 2,
    double verticalHeight = 0,
  }) {
    return _LectureLayoutEngine._line(
      x,
      y,
      w,
      color,
      width: width,
      verticalHeight: verticalHeight,
    );
  }

  PresentationElement _image(
    String path,
    double x,
    double y,
    double w,
    double h, {
    String fit = 'cover',
    double radius = 0,
  }) {
    return _LectureLayoutEngine._image(
      path,
      x,
      y,
      w,
      h,
      fit: fit,
      radius: radius,
    );
  }

  PresentationElement _equationElement(
    PresentationEquationContent equation,
    double x,
    double y,
    double w,
    double h, {
    required String color,
    required double size,
  }) {
    return _LectureLayoutEngine._equationElement(
      equation,
      x,
      y,
      w,
      h,
      color: color,
      size: size,
    );
  }

  _LectureAccentSpec _accent(int index) {
    return _LectureLayoutEngine._accent(index);
  }

  int _wrappedLineCount(
    String value, {
    required double width,
    required double fontSize,
    required int maxLines,
  }) {
    return _LectureLayoutEngine._wrappedLineCount(
      value,
      width: width,
      fontSize: fontSize,
      maxLines: maxLines,
    );
  }

  double _textBlockHeight(
    int lineCount,
    double fontSize,
    double lineHeight, {
    double padding = .06,
  }) {
    return _LectureLayoutEngine._textBlockHeight(
      lineCount,
      fontSize,
      lineHeight,
      padding: padding,
    );
  }

  double _contentTopFor(PresentationSlide slide) {
    return _LectureLayoutEngine._contentTopFor(slide);
  }

  double _fitTitle(
    String title, {
    bool large = false,
    bool compact = false,
  }) {
    return _LectureLayoutEngine._fitTitle(
      title,
      large: large,
      compact: compact,
    );
  }

  String _iconGlyph(String value) {
    return _LectureLayoutEngine._iconGlyph(value);
  }

  bool _rtl(String value) {
    return _LectureLayoutEngine._rtl(value);
  }

  String _string(dynamic value) {
    return _LectureLayoutEngine._string(value);
  }

  int _int(dynamic value, int fallback) {
    return _LectureLayoutEngine._int(value, fallback);
  }

  Map<String, dynamic> _map(dynamic value) {
    return _LectureLayoutEngine._map(value);
  }

  List<String> _stringList(dynamic value) {
    return _LectureLayoutEngine._stringList(value);
  }

  List<Map<String, dynamic>> _itemMaps(dynamic value) {
    return _LectureLayoutEngine._itemMaps(value);
  }

  List<PresentationElement> _lightMaster(
    PresentationSlide slide, {
    double? titleHeight,
  }) {
    final titleSize = _fitTitle(slide.title, compact: true);
    final contentTop = _contentTopFor(slide);
    final resolvedTitleHeight = titleHeight ?? math.max(.58, contentTop - 1.16);
    final kicker = (slide.kicker ?? 'LECTURE').toUpperCase();
    final kickerWidth = math.min(3.05, math.max(1.22, .72 + kicker.length * .052)).toDouble();

    return [
      // Quiet brand decoration. It remains outside the reading area.
      _oval(11.70, -.90, 2.62, primarySoft, opacity: .88),
      _oval(12.23, .55, .44, cyanSoft, opacity: .92),
      _image('assets/logo.webp', .60, .31, .36, .36, fit: 'contain'),
      _text('Learnova', 1.05, .39, 1.26, .20,
          size: 12.5, color: ink, bold: true, maxLines: 1, lineHeight: 1.0),
      _rect(2.48, .30, kickerWidth, .30, primarySoft,
          radius: 12, line: 'CBE2FB', lineWidth: .8),
      _text(kicker, 2.62, .405, kickerWidth - .28, .105,
          size: 7.4,
          color: primaryDark,
          bold: true,
          spacing: .85,
          maxLines: 1,
          align: TextAlign.center,
          lineHeight: 1.0),
      _rect(12.06, .29, .61, .31, darkBlue, radius: 14),
      _text('${slide.slideNumber ?? 1}'.padLeft(2, '0'), 12.16, .395, .41, .105,
          size: 7.4,
          color: white,
          bold: true,
          maxLines: 1,
          align: TextAlign.center,
          lineHeight: 1.0),
      _line(.60, .82, 12.10, divider, width: 1),
      _text(slide.title, safeX, 1.03, 11.42, resolvedTitleHeight,
          size: titleSize,
          color: ink,
          bold: true,
          maxLines: 2,
          lineHeight: 1.02),
      _line(safeX, contentTop - .10, .68, primary, width: 3.5),
      _line(safeX + .76, contentTop - .10, .18, cyan, width: 3.5),
      _line(safeX, footerRuleY, safeWidth, divider, width: 1),
      _text('Learnova • Instructor presentation', .70, 7.15, 4.20, .12,
          size: 7.1,
          color: footer,
          bold: true,
          maxLines: 1,
          lineHeight: 1.0),
      _text('learnova.ai', 11.40, 7.15, 1.23, .12,
          size: 7.1,
          color: footer,
          bold: true,
          maxLines: 1,
          align: TextAlign.right,
          lineHeight: 1.0),
    ];
  }

  List<PresentationElement> _card(
    PresentationCardContent card,
    int index,
    double x,
    double y,
    double w,
    double h, {
    required bool dense,
  }) {
    final accent = _accent(index);
    final pad = dense ? .16 : .24;
    final icon = dense ? .36 : .46;
    final double headingSize = dense ? 12.0 : (w < 3.6 ? 14.2 : 16.2);
    final double bodySize = dense ? 10.0 : (w < 3.6 ? 11.8 : 13.2);
    final body = card.equation?.value ?? card.body;
    final elements = <PresentationElement>[
      _rect(x, y, w, h, white,
          radius: dense ? 12 : compactRadius, line: border, shadow: true),
      _rect(x, y, math.min(.66, w * .22).toDouble(), .05,
          accent.color, radius: 5),
      _rect(x + pad, y + pad, icon, icon, accent.softColor,
          radius: dense ? 8 : 10),
      _text(_iconGlyph(card.icon), x + pad,
          y + pad + icon * .28, icon, icon * .38,
          size: dense ? 10.5 : 12.5, color: accent.color, bold: true,
          maxLines: 1, align: TextAlign.center, lineHeight: 1.0),
      _text('${index + 1}'.padLeft(2, '0'), x + w - pad - .38,
          y + pad + .11, .38, .12,
          size: dense ? 7.2 : 8.0, color: accent.color, bold: true,
          maxLines: 1, align: TextAlign.center, lineHeight: 1.0),
      _text(card.heading, x + pad,
          y + pad + icon + (dense ? .10 : .16),
          w - pad * 2, dense ? .50 : .66,
          size: headingSize, color: ink, bold: true, maxLines: 2,
          lineHeight: 1.07),
    ];
    if (card.equation != null) {
      elements.add(_equationElement(card.equation!, x + pad,
          y + pad + icon + .72, w - pad * 2,
          h - icon - pad * 2 - .84,
          color: inkSoft, size: dense ? 15 : 19));
    } else {
      elements.add(_text(body, x + pad,
          y + pad + icon + (dense ? .66 : .86),
          w - pad * 2,
          h - icon - pad * 2 - (dense ? .74 : .96),
          size: bodySize, color: muted, maxLines: dense ? 4 : 6,
          lineHeight: 1.14));
    }
    return elements;
  }
}
