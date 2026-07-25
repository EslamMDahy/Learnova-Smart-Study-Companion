part of '../instructor_presentation_page.dart';

class QuoteTemplate extends SlideTemplateBuilder {
  const QuoteTemplate();

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final quoteRaw = slide.semanticData['quote'];
    final quoteMap = quoteRaw is Map ? quoteRaw : const {};
    final quote = _string(quoteRaw is String ? quoteRaw : quoteMap['text'] ?? slide.semanticData['text']);
    final author = _string(quoteMap['author'] ?? slide.semanticData['author']);
    final role = _string(quoteMap['role'] ?? quoteMap['source'] ?? slide.semanticData['source']);
    return [
      _oval(10.0, -1.70, 4.80, primary, opacity: .22),
      _oval(-1.15, 5.65, 3.10, violet, opacity: .14),
      _image('assets/logo.webp', .72, .55, .44, .44, fit: 'contain'),
      _text('Learnova', 1.30, .62, 1.6, .28,
          size: 15, color: white, bold: true, maxLines: 1),
      _text('“', .82, 1.35, 1.20, 1.20,
          size: 78, color: cyan, bold: true, maxLines: 1),
      _text(quote, 1.55, 1.68, 10.25, 3.22,
          size: quote.length > 220
              ? 26
              : quote.length > 150
                  ? 30
                  : quote.length > 95
                      ? 34
                      : 40,
          color: white,
          bold: true,
          italic: true,
          maxLines: 7,
          align: TextAlign.center,
          verticalAlign: 'middle',
          lineHeight: 1.04),
      _line(5.76, 5.25, 1.82, primary, width: 4),
      if (author.isNotEmpty)
        _text(author, 3.65, 5.70, 6.05, .34,
            size: 15, color: white, bold: true, maxLines: 1, align: TextAlign.center),
      if (role.isNotEmpty)
        _text(role, 3.65, 6.12, 6.05, .28,
            size: 11, color: '9FB2CA', maxLines: 1, align: TextAlign.center),
      _text('learnova.ai', 11.05, 6.96, 1.55, .18,
          size: 8, color: '6F86A5', bold: true, maxLines: 1, align: TextAlign.right),
    ];
  }
}
