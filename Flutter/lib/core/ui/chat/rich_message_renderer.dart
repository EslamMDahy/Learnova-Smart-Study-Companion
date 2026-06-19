import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

const String _plantUmlServerBaseUrl = 'https://www.plantuml.com/plantuml';

class RichMessageRenderer extends StatelessWidget {
  final String text;
  final bool scrollable;
  final double? maxHeight;

  const RichMessageRenderer({
    super.key,
    required this.text,
    this.scrollable = false,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final segments = _splitRichMessage(text);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < segments.length; index++) ...[
          _RichMessageSegmentView(segment: segments[index]),
          if (index != segments.length - 1) const SizedBox(height: 12),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: content,
    );
  }
}

class _RichMessageSegmentView extends StatelessWidget {
  final _RichMessageSegment segment;

  const _RichMessageSegmentView({required this.segment});

  @override
  Widget build(BuildContext context) {
    switch (segment.type) {
      case _RichMessageSegmentType.markdown:
        return _MarkdownMessageBody(text: segment.content);
      case _RichMessageSegmentType.displayMath:
        return _DisplayMathBlock(latex: segment.content);
      case _RichMessageSegmentType.plantUml:
        return _PlantUmlDiagramCard(source: segment.content);
    }
  }
}

class _MarkdownMessageBody extends StatelessWidget {
  final String text;

  const _MarkdownMessageBody({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return MarkdownBody(
      data: text.trim(),
      selectable: true,
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        <md.InlineSyntax>[
          _InlineLatexSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
      builders: {
        'latex': _InlineLatexElementBuilder(),
      },
      onTapLink: (_, href, __) => _openLink(href),
      styleSheet: _messageMarkdownStyleSheet(context),
    );
  }
}

class _DisplayMathBlock extends StatelessWidget {
  final String latex;

  const _DisplayMathBlock({required this.latex});

  @override
  Widget build(BuildContext context) {
    final equation = latex.trim();
    if (equation.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final math = Math.tex(
            equation,
            mathStyle: MathStyle.display,
            textStyle: TextStyle(
              color: AppColors.textTitle,
              fontSize: 15,
              height: 1.45,
            ),
            onErrorFallback: (error) => SelectableText(
              equation,
              style: TextStyle(
                color: AppColors.warningText,
                fontSize: 12.5,
                height: 1.45,
                fontFamily: 'monospace',
              ),
            ),
          );

          if (!constraints.hasBoundedWidth) return math;
          return Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: math,
            ),
          );
        },
      ),
    );
  }
}

class _InlineLatexElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final equation = element.textContent.trim();
    if (equation.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Math.tex(
        equation,
        mathStyle: MathStyle.text,
        textStyle: (preferredStyle ?? const TextStyle()).copyWith(
          color: preferredStyle?.color ?? AppColors.textTitle,
          fontSize: preferredStyle?.fontSize ?? 13,
        ),
        onErrorFallback: (error) => Text(
          equation,
          style: (preferredStyle ?? const TextStyle()).copyWith(
            color: AppColors.warningText,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _InlineLatexSyntax extends md.InlineSyntax {
  _InlineLatexSyntax() : super(r'\\\((.+?)\\\)|\$([^\$\n]+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final equation = (match.group(1) ?? match.group(2) ?? '').trim();
    if (equation.isEmpty) return false;

    parser.addNode(md.Element.text('latex', equation));
    return true;
  }
}

class _PlantUmlDiagramCard extends StatelessWidget {
  final String source;

  const _PlantUmlDiagramCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final normalizedSource = _normalizePlantUmlSource(source);
    final imageUrl = _plantUmlPngUrl(normalizedSource);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 17, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PlantUML diagram',
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Rendered from PlantUML code',
                  child: Icon(Icons.auto_awesome_outlined, size: 15, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : 320.0;

                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 420,
                  ),
                  child: InteractiveViewer(
                    minScale: 0.75,
                    maxScale: 4,
                    child: Image.network(
                      imageUrl,
                      width: width,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => _PlantUmlErrorFallback(
                        source: normalizedSource,
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          width: width,
                          height: 140,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Text(
                'View PlantUML source',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    normalizedSource,
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontSize: 11.5,
                      height: 1.35,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantUmlErrorFallback extends StatelessWidget {
  final String source;

  const _PlantUmlErrorFallback({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoftBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Could not render PlantUML diagram.',
            style: TextStyle(
              color: AppColors.warningText,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            source,
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 11.5,
              height: 1.35,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

MarkdownStyleSheet _messageMarkdownStyleSheet(BuildContext context) {
  final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
  final paragraph = TextStyle(
    color: AppColors.textGray,
    fontSize: 12.7,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  return base.copyWith(
    p: paragraph,
    pPadding: const EdgeInsets.only(bottom: 6),
    strong: paragraph.copyWith(
      color: AppColors.textTitle,
      fontWeight: FontWeight.w900,
    ),
    em: paragraph.copyWith(fontStyle: FontStyle.italic),
    a: paragraph.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
    ),
    h1: paragraph.copyWith(
      color: AppColors.textTitle,
      fontSize: 18,
      fontWeight: FontWeight.w900,
    ),
    h2: paragraph.copyWith(
      color: AppColors.textTitle,
      fontSize: 16,
      fontWeight: FontWeight.w900,
    ),
    h3: paragraph.copyWith(
      color: AppColors.textTitle,
      fontSize: 14.5,
      fontWeight: FontWeight.w900,
    ),
    h1Padding: const EdgeInsets.only(bottom: 8),
    h2Padding: const EdgeInsets.only(top: 4, bottom: 8),
    h3Padding: const EdgeInsets.only(top: 4, bottom: 6),
    listBullet: paragraph.copyWith(
      color: AppColors.textTitle,
      fontWeight: FontWeight.w900,
    ),
    listIndent: 22,
    blockSpacing: 8,
    blockquote: paragraph.copyWith(color: AppColors.textMuted),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    blockquoteDecoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      borderRadius: BorderRadius.circular(8),
    ),
    code: paragraph.copyWith(
      color: AppColors.textTitle,
      fontFamily: 'monospace',
      fontSize: 12,
      fontWeight: FontWeight.w700,
      backgroundColor: AppColors.headerBg,
    ),
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: AppColors.headerBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    tableHead: paragraph.copyWith(
      color: AppColors.textTitle,
      fontWeight: FontWeight.w900,
      fontSize: 12.2,
    ),
    tableBody: paragraph.copyWith(fontSize: 12),
    tableHeadAlign: TextAlign.left,
    tablePadding: const EdgeInsets.symmetric(vertical: 8),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    tableBorder: TableBorder.all(color: AppColors.border, width: 1),
    tableColumnWidth: const FlexColumnWidth(),
    tableVerticalAlignment: TableCellVerticalAlignment.middle,
    tableScrollbarThumbVisibility: false,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
  );
}

List<_RichMessageSegment> _splitRichMessage(String input) {
  if (input.trim().isEmpty) {
    return const [_RichMessageSegment(_RichMessageSegmentType.markdown, '')];
  }

  final pattern = RegExp(
    r'```\s*(?:plantuml|puml|uml)\s*\n([\s\S]*?)```|\$\$\s*\n?([\s\S]*?)\n?\$\$|\\\[\s*([\s\S]*?)\s*\\\]',
    caseSensitive: false,
    multiLine: true,
  );

  final segments = <_RichMessageSegment>[];
  var cursor = 0;

  for (final match in pattern.allMatches(input)) {
    if (match.start > cursor) {
      _addMarkdownSegment(segments, input.substring(cursor, match.start));
    }

    final plantUml = match.group(1);
    final dollarMath = match.group(2);
    final bracketMath = match.group(3);

    if (plantUml != null) {
      segments.add(_RichMessageSegment(_RichMessageSegmentType.plantUml, plantUml.trim()));
    } else {
      final equation = dollarMath ?? bracketMath ?? '';
      segments.add(_RichMessageSegment(_RichMessageSegmentType.displayMath, equation.trim()));
    }

    cursor = match.end;
  }

  if (cursor < input.length) {
    _addMarkdownSegment(segments, input.substring(cursor));
  }

  return segments.isEmpty
      ? [_RichMessageSegment(_RichMessageSegmentType.markdown, input)]
      : segments;
}

void _addMarkdownSegment(List<_RichMessageSegment> segments, String value) {
  if (value.trim().isEmpty) return;
  segments.add(_RichMessageSegment(_RichMessageSegmentType.markdown, value));
}

String _normalizePlantUmlSource(String source) {
  final trimmed = source.trim();
  if (RegExp(r'^@start\w+', caseSensitive: false).hasMatch(trimmed)) {
    return trimmed;
  }
  return '@startuml\n$trimmed\n@enduml';
}

String _plantUmlPngUrl(String source) {
  final encoded = _toHex(utf8.encode(source));
  return '$_plantUmlServerBaseUrl/png/~h$encoded';
}

String _toHex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

Future<void> _openLink(String? href) async {
  if (href == null || href.trim().isEmpty) return;
  final uri = Uri.tryParse(href.trim());
  if (uri == null) return;
  await launchUrl(uri, webOnlyWindowName: '_blank');
}

enum _RichMessageSegmentType { markdown, displayMath, plantUml }

class _RichMessageSegment {
  final _RichMessageSegmentType type;
  final String content;

  const _RichMessageSegment(this.type, this.content);
}
