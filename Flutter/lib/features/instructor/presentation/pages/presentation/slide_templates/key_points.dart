part of '../instructor_presentation_page.dart';

class KeyPointsTemplate extends SlideTemplateBuilder {
  const KeyPointsTemplate();

  static const String _rail = '0B1B35';
  static const String _railBorder = '27466D';
  static const String _railText = 'C6D3E3';
  static const String _railMuted = '7890AE';
  static const String _rowRule = 'D8E5F2';

  @override
  List<PresentationElement> build(PresentationSlide slide) {
    final data = slide.semanticData;
    final content = _map(data['content']);
    final summary = _string(
      data['summary'] ??
          data['lead'] ??
          content['lead'] ??
          content['summary'],
    );

    final sourceItems = slide.cards.isNotEmpty
        ? slide.cards
        : _itemMaps(data['points'] ?? content['bullets'])
            .map((item) {
              final heading = _string(
                item['heading'] ?? item['title'] ?? item['text'],
              );
              final body = _string(item['body'] ?? item['description']);
              return PresentationCardContent(
                icon: _string(item['icon']),
                heading: heading.isEmpty ? body : heading,
                body: heading.isEmpty ? '' : body,
              );
            })
            .toList();

    final visible = sourceItems
        .where((item) =>
            item.heading.trim().isNotEmpty || item.body.trim().isNotEmpty)
        .take(5)
        .toList();
    final elements = _lightMaster(slide);
    if (visible.isEmpty) return elements;

    final top = _contentTopFor(slide);
    final height = contentBottom - top;
    const railWidth = 3.12;
    const columnGap = .42;
    final listX = safeX + railWidth + columnGap;
    final listWidth = safeWidth - railWidth - columnGap;
    final countLabel = visible.length.toString().padLeft(2, '0');
    final rtl = _rtl(
      '${slide.title} $summary ${visible.map((item) => '${item.heading} ${item.body}').join(' ')}',
    );

    elements.addAll([
      // One continuous editorial rail. Accents remain horizontal and inside it,
      // so web and PowerPoint scaling cannot create detached blue columns.
      _rect(
        safeX,
        top,
        railWidth,
        height,
        _rail,
        radius: panelRadius,
        line: _railBorder,
        lineWidth: 1,
        shadow: true,
      ),
      _rect(safeX + .34, top + .34, .62, .045, primary, radius: 5),
      _text(
        'KEY TAKEAWAYS',
        safeX + .34,
        top + .56,
        railWidth - .68,
        .16,
        size: 8,
        color: '76B8FA',
        bold: true,
        spacing: 1.25,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _text(
        countLabel,
        safeX + .31,
        top + .86,
        railWidth - .62,
        .72,
        size: 45,
        color: white,
        bold: true,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: .95,
      ),
      _text(
        visible.length == 1 ? 'ESSENTIAL IDEA' : 'ESSENTIAL IDEAS',
        safeX + .34,
        top + 1.57,
        railWidth - .68,
        .15,
        size: 7.5,
        color: _railMuted,
        bold: true,
        spacing: 1.12,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
      _line(safeX + .34, top + 1.92, railWidth - .68, _railBorder, width: 1),
      _text(
        summary.isEmpty
            ? 'The ideas on this slide are the concepts learners should retain, connect, and apply.'
            : summary,
        safeX + .34,
        top + 2.20,
        railWidth - .68,
        math.max(.78, height - 3.20),
        size: 11.4,
        color: _railText,
        maxLines: 7,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.20,
      ),
      _line(
        safeX + .34,
        contentBottom - .69,
        railWidth - .68,
        _railBorder,
        width: 1,
      ),
      _text(
        'RETAIN  /  CONNECT  /  APPLY',
        safeX + .34,
        contentBottom - .40,
        railWidth - .68,
        .13,
        size: 6.8,
        color: _railMuted,
        bold: true,
        spacing: .82,
        maxLines: 1,
        align: rtl ? TextAlign.right : TextAlign.left,
        lineHeight: 1.0,
      ),
    ]);

    final count = visible.length;
    final rowGap = count <= 2 ? .28 : (count == 3 ? .16 : .10);
    final rowHeight = count == 1
        ? 1.86
        : count == 2
            ? 1.52
            : (height - rowGap * (count - 1)) / count;
    final groupHeight = rowHeight * count + rowGap * (count - 1);
    final startY = count <= 2 ? top + (height - groupHeight) / 2 : top;

    for (var index = 0; index < count; index++) {
      final item = visible[index];
      final y = startY + index * (rowHeight + rowGap);
      final numberX = rtl ? listX + listWidth - .48 : listX;
      final textX = rtl ? listX : listX + .70;
      final textWidth = listWidth - .70;
      final hasBody = item.body.trim().isNotEmpty;
      final headingSize = count == 1
          ? 21.0
          : count == 2
              ? 17.5
              : count == 3
                  ? 16.0
                  : count == 4
                      ? 14.7
                      : 13.6;
      final bodySize = count == 1
          ? 14.0
          : count == 2
              ? 12.6
              : count == 3
                  ? 11.8
                  : count == 4
                      ? 10.9
                      : 10.1;

      elements.addAll([
        _text(
          '${index + 1}'.padLeft(2, '0'),
          numberX,
          y + .08,
          .48,
          .14,
          size: 8.6,
          color: primaryDark,
          bold: true,
          spacing: .55,
          maxLines: 1,
          align: rtl ? TextAlign.right : TextAlign.left,
          lineHeight: 1.0,
        ),
        _line(
          rtl ? numberX + .20 : numberX,
          y + .36,
          .28,
          primary,
          width: 2.2,
        ),
        _text(
          item.heading,
          textX,
          hasBody ? y + .04 : y + .08,
          textWidth,
          hasBody ? math.min(.46, rowHeight * .42) : rowHeight - .16,
          size: headingSize,
          color: ink,
          bold: true,
          maxLines: hasBody ? 2 : 3,
          align: rtl ? TextAlign.right : TextAlign.left,
          verticalAlign: hasBody ? 'top' : 'middle',
          lineHeight: 1.06,
        ),
        if (hasBody)
          _text(
            item.body,
            textX,
            y + math.min(.54, rowHeight * .47),
            textWidth,
            math.max(.20, rowHeight - math.min(.61, rowHeight * .54)),
            size: bodySize,
            color: muted,
            maxLines: count >= 4 ? 2 : 3,
            align: rtl ? TextAlign.right : TextAlign.left,
            lineHeight: 1.14,
          ),
        if (index < count - 1)
          _line(
            listX,
            y + rowHeight + rowGap / 2,
            listWidth,
            _rowRule,
            width: 1,
          ),
      ]);
    }

    return elements;
  }
}
