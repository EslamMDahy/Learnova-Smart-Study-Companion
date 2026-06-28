import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

const String _plantUmlServerBaseUrl = 'https://www.plantuml.com/plantuml';
const String _mermaidInkBaseUrl = 'https://mermaid.ink';

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

    final padded = Padding(
      padding: const EdgeInsets.all(2),
      child: content,
    );

    if (!scrollable && maxHeight == null) return padded;

    final body = scrollable ? SingleChildScrollView(child: padded) : padded;
    if (maxHeight == null) return body;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight!),
      child: body,
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
      case _RichMessageSegmentType.mermaid:
        return _MermaidDiagramCard(source: segment.content);
      case _RichMessageSegmentType.code:
        return _CodeBlock(
          code: segment.content,
          language: segment.language,
        );
    }
  }
}

class _MarkdownMessageBody extends StatelessWidget {
  final String text;

  const _MarkdownMessageBody({required this.text});

  @override
  Widget build(BuildContext context) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return const SizedBox.shrink();

    return MarkdownBody(
      data: normalizedText,
      selectable: true,
      softLineBreak: true,
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

class _CodeBlock extends StatelessWidget {
  final String code;
  final String? language;

  const _CodeBlock({
    required this.code,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final cleanCode = _normalizeCodeBlock(code);
    final label = _languageLabel(language);
    final isPlainDiagram = _isDiagramLanguage(language) || _isAsciiUmlDiagram(cleanCode);
    final textStyle = TextStyle(
      color: AppColors.textGray,
      fontSize: 12.5,
      height: 1.55,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w600,
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _codeBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.headerBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    await Clipboard.setData(ClipboardData(text: cleanCode));
                    messenger?.showSnackBar(
                      const SnackBar(
                        content: Text('Code copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                  label: Text(
                    'Copy',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          Scrollbar(
            thumbVisibility: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(14),
              child: SelectableText.rich(
                TextSpan(
                  style: textStyle,
                  children: isPlainDiagram
                      ? [TextSpan(text: cleanCode, style: textStyle)]
                      : _highlightCode(
                          cleanCode,
                          language: language,
                          baseStyle: textStyle,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Align(
                alignment: Alignment.center,
                child: math,
              ),
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
                TextButton.icon(
                  onPressed: () => _downloadRemoteImage(
                    imageUrl,
                    _diagramFileName('learnova-uml', normalizedSource),
                  ),
                  icon: Icon(Icons.download_rounded, size: 14, color: AppColors.textMuted),
                  label: Text(
                    'Download PNG',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),
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

class _MermaidDiagramCard extends StatelessWidget {
  final String source;

  const _MermaidDiagramCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final normalizedSource = _normalizeMermaidSource(source);
    final imageUrl = _mermaidPngUrl(normalizedSource);

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
                Icon(Icons.schema_outlined, size: 17, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mermaid diagram',
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _downloadRemoteImage(
                    imageUrl,
                    _diagramFileName('learnova-mermaid', normalizedSource),
                  ),
                  icon: Icon(Icons.download_rounded, size: 14, color: AppColors.textMuted),
                  label: Text(
                    'Download PNG',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Rendered from Mermaid code',
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
                    maxHeight: 480,
                  ),
                  child: InteractiveViewer(
                    minScale: 0.75,
                    maxScale: 4,
                    child: Image.network(
                      imageUrl,
                      width: width,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => _MermaidErrorFallback(
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
                'View Mermaid source',
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

class _MermaidErrorFallback extends StatelessWidget {
  final String source;

  const _MermaidErrorFallback({required this.source});

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
            'Could not render Mermaid diagram.',
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
    fontSize: 13,
    height: 1.58,
    fontWeight: FontWeight.w500,
  );

  return base.copyWith(
    p: paragraph,
    pPadding: const EdgeInsets.only(bottom: 8),
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
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w900,
    ),
    h2: paragraph.copyWith(
      color: AppColors.textTitle,
      fontSize: 17,
      height: 1.35,
      fontWeight: FontWeight.w900,
    ),
    h3: paragraph.copyWith(
      color: AppColors.textTitle,
      fontSize: 15,
      height: 1.4,
      fontWeight: FontWeight.w900,
    ),
    h1Padding: const EdgeInsets.only(top: 4, bottom: 10),
    h2Padding: const EdgeInsets.only(top: 4, bottom: 8),
    h3Padding: const EdgeInsets.only(top: 4, bottom: 6),
    listBullet: paragraph.copyWith(
      color: AppColors.textTitle,
      fontWeight: FontWeight.w900,
    ),
    listIndent: 22,
    blockSpacing: 8,
    blockquote: paragraph.copyWith(color: AppColors.textMuted),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
    blockquoteDecoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      borderRadius: BorderRadius.circular(8),
    ),
    code: paragraph.copyWith(
      color: AppColors.textTitle,
      fontFamily: 'monospace',
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      backgroundColor: AppColors.headerBg,
    ),
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: _codeBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    tableHead: paragraph.copyWith(
      color: AppColors.textTitle,
      fontWeight: FontWeight.w900,
      fontSize: 12.5,
    ),
    tableBody: paragraph.copyWith(fontSize: 12.2),
    tableHeadAlign: TextAlign.left,
    tablePadding: const EdgeInsets.symmetric(vertical: 8),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    tableBorder: TableBorder.all(color: AppColors.border, width: 1),
    tableColumnWidth: const IntrinsicColumnWidth(),
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
    r'```[ \t]*([^\n`]*)\r?\n([\s\S]*?)```|\$\$\s*\n?([\s\S]*?)\n?\$\$|\\\[\s*([\s\S]*?)\s*\\\]',
    caseSensitive: false,
    multiLine: true,
  );

  final segments = <_RichMessageSegment>[];
  var cursor = 0;

  for (final match in pattern.allMatches(input)) {
    if (match.start > cursor) {
      _addMarkdownSegments(segments, input.substring(cursor, match.start));
    }

    final fenceLanguage = match.group(1);
    final fencedCode = match.group(2);
    final dollarMath = match.group(3);
    final bracketMath = match.group(4);

    if (fencedCode != null) {
      final language = _normalizeLanguage(fenceLanguage);
      final cleanFencedCode = _normalizeCodeBlock(fencedCode);
      if (_isMermaidLanguage(language) || _looksLikeMermaidSource(cleanFencedCode)) {
        segments.add(_RichMessageSegment(
          _RichMessageSegmentType.mermaid,
          cleanFencedCode,
          language: language,
        ));
      } else {
        final plantUmlSource = _plantUmlSourceFromCodeBlock(cleanFencedCode, language);
        if (plantUmlSource != null) {
          segments.add(_RichMessageSegment(
            _RichMessageSegmentType.plantUml,
            plantUmlSource,
            language: language,
          ));
        } else {
          segments.add(_RichMessageSegment(
            _RichMessageSegmentType.code,
            cleanFencedCode,
            language: _isAsciiUmlDiagram(cleanFencedCode) ? 'ascii-uml' : language,
          ));
        }
      }
    } else {
      final equation = dollarMath ?? bracketMath ?? '';
      segments.add(_RichMessageSegment(
        _RichMessageSegmentType.displayMath,
        equation.trim(),
      ));
    }

    cursor = match.end;
  }

  if (cursor < input.length) {
    _addMarkdownSegments(segments, input.substring(cursor));
  }

  return segments.isEmpty
      ? [_RichMessageSegment(_RichMessageSegmentType.markdown, input)]
      : segments;
}

void _addMarkdownSegments(List<_RichMessageSegment> segments, String value) {
  if (value.trim().isEmpty) return;

  final lines = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final markdownBuffer = StringBuffer();

  void flushMarkdown() {
    final markdown = markdownBuffer.toString();
    if (markdown.trim().isNotEmpty) {
      segments.add(_RichMessageSegment(
        _RichMessageSegmentType.markdown,
        _prepareMarkdownText(markdown),
      ));
    }
    markdownBuffer.clear();
  }

  var index = 0;
  while (index < lines.length) {
    final matrix = _tryReadAsciiMatrix(lines, index);
    if (matrix != null) {
      flushMarkdown();
      segments.add(_RichMessageSegment(
        _RichMessageSegmentType.displayMath,
        matrix.latex,
      ));
      index += matrix.consumedLines;
      continue;
    }

    final mathLine = _tryConvertStandaloneMathLine(lines[index]);
    if (mathLine != null) {
      flushMarkdown();
      segments.add(_RichMessageSegment(
        _RichMessageSegmentType.displayMath,
        mathLine,
      ));
      index++;
      continue;
    }

    markdownBuffer.writeln(lines[index]);
    index++;
  }

  flushMarkdown();
}

String _prepareMarkdownText(String value) {
  var output = value;

  // Common AI output writes short formulas inside normal prose without LaTeX
  // delimiters. Wrap only very small formula fragments so normal Markdown links
  // and sentences are not affected.
  output = output.replaceAllMapped(
    RegExp(
      r'\b([A-Za-zθΘωŵ]\w*\s*=\s*\[[^\]\n]{1,80}\])(?=\s+(?:is|are|represents|denotes)\b)',
      caseSensitive: false,
    ),
    (match) => r'$' + _toLatexExpression(match.group(1) ?? '') + r'$',
  );

  output = output.replaceAllMapped(
    RegExp(r'\[ŵ\]|\[w\^?\]', caseSensitive: false),
    (_) => r'$[\hat{w}]$',
  );

  return output;
}

_AsciiMatrixRead? _tryReadAsciiMatrix(List<String> lines, int startIndex) {
  if (startIndex >= lines.length) return null;

  final firstLine = lines[startIndex].trimRight();
  if (!firstLine.contains('=') || !firstLine.contains('|')) return null;

  final firstMatch = RegExp(r'^(?:where\s+)?(.+?)\s*=\s*(\|.*\|)\s*$', caseSensitive: false)
      .firstMatch(firstLine.trim());
  if (firstMatch == null) return null;

  final left = firstMatch.group(1)?.trim() ?? '';
  final rows = <List<String>>[];
  final firstRow = _readPipeRow(firstMatch.group(2) ?? '');
  if (firstRow == null) return null;
  rows.add(firstRow);

  var cursor = startIndex + 1;
  while (cursor < lines.length) {
    final row = _readPipeRow(lines[cursor]);
    if (row == null) break;
    rows.add(row);
    cursor++;
  }

  if (rows.length < 2 || rows.any((row) => row.length < 2)) return null;

  final latexRows = rows
      .map((row) => row.map(_toLatexExpression).join(' & '))
      .join(r' \\ ');
  final latex = '${_toLatexExpression(left)} = \\begin{bmatrix} $latexRows \\end{bmatrix}';

  return _AsciiMatrixRead(latex: latex, consumedLines: cursor - startIndex);
}

List<String>? _readPipeRow(String line) {
  final firstPipe = line.indexOf('|');
  final lastPipe = line.lastIndexOf('|');
  if (firstPipe < 0 || lastPipe <= firstPipe) return null;

  final content = line.substring(firstPipe + 1, lastPipe).trim();
  if (content.isEmpty) return null;
  if (RegExp(r'^[-+\s]+$').hasMatch(content)) return null;

  final cells = content
      .split(RegExp(r'[\s,]+'))
      .map((cell) => cell.trim())
      .where((cell) => cell.isNotEmpty)
      .toList();

  if (cells.length < 2) return null;
  return cells;
}

String? _tryConvertStandaloneMathLine(String line) {
  var expression = line.trim();
  if (expression.isEmpty || expression.endsWith(':')) return null;
  if (expression.startsWith('- ') || expression.startsWith('* ') || expression.startsWith('• ')) {
    return null;
  }

  final hasWherePrefix = expression.toLowerCase().startsWith('where ');
  if (expression.toLowerCase().startsWith('where ')) {
    expression = expression.substring(6).trim();
  }

  if (!expression.contains('=')) return null;
  if (!_hasMathSignals(expression)) return null;
  if (_containsProseAfterFormula(expression)) return null;

  final latex = _toLatexExpression(expression);
  return hasWherePrefix ? r'\text{where } ' + latex : latex;
}

bool _hasMathSignals(String expression) {
  return RegExp(r'[=+\-*/^()\[\]θΘωŵ√]|\b(?:sin|cos|tan|sqrt|log|ln)\b')
      .hasMatch(expression);
}

bool _containsProseAfterFormula(String expression) {
  return RegExp(
    r'\b(?:the|this|that|given|used|calculate|matrix|vector|angle|axis|unit|rotation|representing|where)\b',
    caseSensitive: false,
  ).hasMatch(expression);
}

String _toLatexExpression(String expression) {
  var output = expression.trim();
  if (output.isEmpty) return output;

  output = output
      .replaceAll('×', '*')
      .replaceAll('·', '*')
      .replaceAll('θ', r'\theta')
      .replaceAll('Θ', r'\Theta')
      .replaceAll('ω', r'\omega')
      .replaceAll('ŵ', r'\hat{w}')
      .replaceAll('√', r'\sqrt');

  // Function names should be rendered upright in math mode.
  output = output.replaceAllMapped(
    RegExp(r'\b(sin|cos|tan|log|ln)\s*\(', caseSensitive: false),
    (match) => '\\${match.group(1)!.toLowerCase()}(',
  );

  output = output.replaceAllMapped(
    RegExp(r'\bsqrt\s*\(', caseSensitive: false),
    (_) => r'\sqrt(',
  );

  // Convert sqrt(a + b) to \sqrt{a + b}. Keep it conservative: one level is
  // enough for the AI answers we receive here.
  output = output.replaceAllMapped(
    RegExp(r'\\sqrt\s*\(([^()]+)\)', caseSensitive: false),
    (match) => '\\sqrt{${_toLatexExpression(match.group(1) ?? '')}}',
  );

  output = output.replaceAllMapped(
    RegExp(r'\b([A-Za-z])([0-9]+)\b'),
    (match) => '${match.group(1)}_{${match.group(2)}}',
  );

  output = output.replaceAllMapped(
    RegExp(r'\^\s*([A-Za-z0-9]+|\{[^}]+\})'),
    (match) {
      final power = match.group(1) ?? '';
      if (power.startsWith('{') && power.endsWith('}')) return '^$power';
      return '^{$power}';
    },
  );

  output = output.replaceAllMapped(
    RegExp(r'\s*\*\s*'),
    (_) => r' \cdot ',
  );

  return output.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _AsciiMatrixRead {
  final String latex;
  final int consumedLines;

  const _AsciiMatrixRead({
    required this.latex,
    required this.consumedLines,
  });
}

List<TextSpan> _highlightCode(
  String code, {
  required String? language,
  required TextStyle baseStyle,
}) {
  final spans = <TextSpan>[];
  final tokenPattern = RegExp(
    r'''("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|//[^\n]*|#[^\n]*|/\*[\s\S]*?\*/|\b(?:abstract|and|as|async|await|break|case|catch|class|const|continue|def|default|do|elif|else|enum|export|extends|False|false|final|finally|for|from|function|get|if|implements|import|in|interface|is|lambda|let|new|null|None|not|or|override|return|set|static|super|switch|this|throw|throws|true|True|try|typedef|var|void|while|with|yield)\b|\b(?:bool|boolean|char|double|dynamic|float|int|Integer|List|Map|num|Object|String|var|void)\b|\b\d+(?:\.\d+)?\b)''',
    multiLine: true,
  );

  var cursor = 0;
  for (final match in tokenPattern.allMatches(code)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: code.substring(cursor, match.start), style: baseStyle));
    }

    final token = match.group(0) ?? '';
    spans.add(TextSpan(
      text: token,
      style: baseStyle.copyWith(
        color: _tokenColor(token),
        fontWeight: _tokenWeight(token),
      ),
    ));
    cursor = match.end;
  }

  if (cursor < code.length) {
    spans.add(TextSpan(text: code.substring(cursor), style: baseStyle));
  }

  return spans;
}

FontWeight _tokenWeight(String token) {
  if (_keywordPattern.hasMatch(token) || _typePattern.hasMatch(token)) {
    return FontWeight.w900;
  }
  return FontWeight.w600;
}

Color _tokenColor(String token) {
  final trimmed = token.trimLeft();

  if (trimmed.startsWith('//') || trimmed.startsWith('#') || trimmed.startsWith('/*')) {
    return AppColors.textHint;
  }
  if (trimmed.startsWith('"') || trimmed.startsWith("'")) {
    return AppColors.successText;
  }
  if (_numberPattern.hasMatch(trimmed)) {
    return AppColors.purpleText;
  }
  if (_keywordPattern.hasMatch(trimmed)) {
    return AppColors.primary;
  }
  if (_typePattern.hasMatch(trimmed)) {
    return AppColors.badgeIndigoFg;
  }
  return AppColors.textGray;
}

final RegExp _keywordPattern = RegExp(
  r'^\b(?:abstract|and|as|async|await|break|case|catch|class|const|continue|def|default|do|elif|else|enum|export|extends|False|false|final|finally|for|from|function|get|if|implements|import|in|interface|is|lambda|let|new|null|None|not|or|override|return|set|static|super|switch|this|throw|throws|true|True|try|typedef|var|void|while|with|yield)\b$',
);
final RegExp _typePattern = RegExp(
  r'^\b(?:bool|boolean|char|double|dynamic|float|int|Integer|List|Map|num|Object|String|void)\b$',
);
final RegExp _numberPattern = RegExp(r'^\d+(?:\.\d+)?$');

Color get _codeBackground => AppColors.isDark
    ? const Color(0xFF020617)
    : const Color(0xFFF8FAFC);

String _normalizeCodeBlock(String value) {
  var output = value.replaceAll('\r\n', '\n');
  if (output.startsWith('\n')) output = output.substring(1);
  if (output.endsWith('\n')) output = output.substring(0, output.length - 1);
  return output;
}

String? _normalizeLanguage(String? value) {
  final language = (value ?? '').trim().split(RegExp(r'\s+')).first.toLowerCase();
  if (language.isEmpty) return null;
  return language;
}

String _languageLabel(String? language) {
  final normalized = (language ?? '').trim();
  if (normalized.isEmpty) return 'Code';

  const labels = {
    'js': 'JavaScript',
    'javascript': 'JavaScript',
    'ts': 'TypeScript',
    'typescript': 'TypeScript',
    'py': 'Python',
    'python': 'Python',
    'dart': 'Dart',
    'java': 'Java',
    'c': 'C',
    'cpp': 'C++',
    'c++': 'C++',
    'cs': 'C#',
    'csharp': 'C#',
    'html': 'HTML',
    'css': 'CSS',
    'json': 'JSON',
    'yaml': 'YAML',
    'yml': 'YAML',
    'sql': 'SQL',
    'bash': 'Bash',
    'sh': 'Shell',
    'shell': 'Shell',
    'powershell': 'PowerShell',
    'ps1': 'PowerShell',
    'ascii-uml': 'ASCII UML Diagram',
    'ascii-diagram': 'ASCII Diagram',
    'mermaid': 'Mermaid',
    'mmd': 'Mermaid',
    'text': 'Text',
  };

  return labels[normalized.toLowerCase()] ?? normalized.toUpperCase();
}

bool _isMermaidLanguage(String? language) {
  final normalized = (language ?? '').toLowerCase();
  return normalized == 'mermaid' || normalized == 'mmd';
}

bool _looksLikeMermaidSource(String source) {
  final trimmed = source.trimLeft();
  if (trimmed.isEmpty) return false;

  final firstLine = trimmed.split('\n').first.trim();
  return RegExp(
    r'^(?:graph\s+(?:TD|TB|BT|LR|RL)|flowchart\s+(?:TD|TB|BT|LR|RL)|sequenceDiagram|classDiagram|stateDiagram(?:-v2)?|erDiagram|journey|gantt|pie\s+title|mindmap|timeline|gitGraph|quadrantChart|requirementDiagram|C4Context|C4Container|C4Component)\b',
    caseSensitive: false,
  ).hasMatch(firstLine);
}

String _normalizeMermaidSource(String source) {
  return _normalizeCodeBlock(source).trim();
}

String _mermaidPngUrl(String source) {
  final encoded = base64Url.encode(utf8.encode(source)).replaceAll('=', '');
  return '$_mermaidInkBaseUrl/img/$encoded?type=png&bgColor=FFFFFF';
}

bool _isPlantUmlLanguage(String? language) {
  final normalized = (language ?? '').toLowerCase();
  return normalized == 'plantuml' || normalized == 'puml' || normalized == 'uml';
}

bool _isDiagramLanguage(String? language) {
  final normalized = (language ?? '').toLowerCase();
  return normalized == 'ascii-uml' || normalized == 'ascii-diagram' || normalized == 'text';
}

String? _plantUmlSourceFromCodeBlock(String code, String? language) {
  final trimmed = code.trim();
  if (trimmed.isEmpty) return null;

  if (_isPlantUmlLanguage(language) || _looksLikePlantUmlSource(trimmed)) {
    return _normalizePlantUmlSource(trimmed);
  }

  return _asciiUmlToPlantUmlSource(trimmed);
}

bool _looksLikePlantUmlSource(String source) {
  return RegExp(r'^@start\w+', caseSensitive: false).hasMatch(source.trim());
}

bool _isAsciiUmlDiagram(String source) {
  final normalized = source.replaceAll('\r\n', '\n');
  final borderCount = RegExp(r'^\s*\+[-=]{3,}\+\s*$', multiLine: true)
      .allMatches(normalized)
      .length;
  final titleCount = RegExp(r'^\s*\|\s*[^|]{2,}\s*\|\s*$', multiLine: true)
      .allMatches(normalized)
      .length;
  return borderCount >= 2 && titleCount >= 1;
}

String? _asciiUmlToPlantUmlSource(String source) {
  if (!_isAsciiUmlDiagram(source)) return null;

  final lines = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final classes = <_ParsedAsciiClass>[];

  var index = 0;
  while (index < lines.length) {
    if (!_isAsciiBorderLine(lines[index])) {
      index++;
      continue;
    }

    final titleLineIndex = index + 1;
    final separatorIndex = index + 2;
    if (titleLineIndex >= lines.length || separatorIndex >= lines.length) break;

    final className = _readAsciiBoxCell(lines[titleLineIndex]);
    if (className == null || className.isEmpty || !_isAsciiBorderLine(lines[separatorIndex])) {
      index++;
      continue;
    }

    final members = <String>[];
    var cursor = separatorIndex + 1;
    while (cursor < lines.length && !_isAsciiBorderLine(lines[cursor])) {
      final member = _readAsciiBoxCell(lines[cursor]);
      if (member != null && member.trim().isNotEmpty) {
        members.add(_normalizeAsciiUmlMember(member));
      }
      cursor++;
    }

    if (cursor >= lines.length) {
      index++;
      continue;
    }

    classes.add(_ParsedAsciiClass(
      name: className.trim(),
      members: members,
      startLine: index,
      endLine: cursor,
    ));
    index = cursor + 1;
  }

  if (classes.isEmpty) return null;

  final buffer = StringBuffer()
    ..writeln('@startuml')
    ..writeln('skinparam classAttributeIconSize 0')
    ..writeln('skinparam shadowing false')
    ..writeln('skinparam roundcorner 8')
    ..writeln();

  final aliases = <_ParsedAsciiClass, String>{};
  final usedAliases = <String>{};
  for (final parsedClass in classes) {
    final alias = _uniquePlantUmlAlias(parsedClass.name, usedAliases);
    aliases[parsedClass] = alias;
    final escapedName = parsedClass.name.replaceAll('"', r'\"');
    buffer.writeln('class "$escapedName" as $alias {');
    for (final member in parsedClass.members) {
      buffer.writeln('  $member');
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  for (var i = 0; i < classes.length - 1; i++) {
    final from = aliases[classes[i]]!;
    final to = aliases[classes[i + 1]]!;
    final between = lines
        .sublist(classes[i].endLine + 1, classes[i + 1].startLine)
        .join('\n')
        .toLowerCase();
    final label = _relationshipLabelFromAscii(between);
    buffer.writeln(label == null ? '$from --> $to' : '$from --> $to : $label');
  }

  buffer.writeln('@enduml');
  return buffer.toString();
}

bool _isAsciiBorderLine(String line) {
  return RegExp(r'^\s*\+[-=]{3,}\+\s*$').hasMatch(line);
}

String? _readAsciiBoxCell(String line) {
  final firstPipe = line.indexOf('|');
  final lastPipe = line.lastIndexOf('|');
  if (firstPipe < 0 || lastPipe <= firstPipe) return null;
  return line.substring(firstPipe + 1, lastPipe).trim();
}

String _normalizeAsciiUmlMember(String member) {
  final trimmed = member.trim();
  if (trimmed.isEmpty) return trimmed;
  if (RegExp(r'^[+\-#~]').hasMatch(trimmed)) return trimmed;
  return trimmed;
}

String _uniquePlantUmlAlias(String name, Set<String> usedAliases) {
  var alias = name
      .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (alias.isEmpty) alias = 'Class';
  if (RegExp(r'^[0-9]').hasMatch(alias)) alias = 'Class_$alias';

  final baseAlias = alias;
  var counter = 2;
  while (usedAliases.contains(alias)) {
    alias = '${baseAlias}_$counter';
    counter++;
  }
  usedAliases.add(alias);
  return alias;
}

String? _relationshipLabelFromAscii(String text) {
  const candidates = ['has', 'contains', 'uses', 'owns', 'extends', 'inherits'];
  for (final candidate in candidates) {
    if (RegExp('\\b$candidate\\b').hasMatch(text)) return candidate;
  }
  return null;
}

class _ParsedAsciiClass {
  final String name;
  final List<String> members;
  final int startLine;
  final int endLine;

  const _ParsedAsciiClass({
    required this.name,
    required this.members,
    required this.startLine,
    required this.endLine,
  });
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

String _diagramFileName(String prefix, String source) {
  final hex = _toHex(utf8.encode(source));
  final suffix = hex.length <= 12 ? hex : hex.substring(0, 12);
  return '$prefix-$suffix.png';
}

Future<void> _downloadRemoteImage(String imageUrl, String fileName) async {
  final uri = Uri.tryParse(imageUrl.trim());
  if (uri == null) return;

  final opened = await launchUrl(
    uri,
    webOnlyWindowName: '_blank',
  );

  if (!opened) {
    await _openLink(imageUrl);
  }
}

Future<void> _openLink(String? href) async {
  if (href == null || href.trim().isEmpty) return;
  final uri = Uri.tryParse(href.trim());
  if (uri == null) return;
  await launchUrl(uri, webOnlyWindowName: '_blank');
}

enum _RichMessageSegmentType { markdown, displayMath, plantUml, mermaid, code }

class _RichMessageSegment {
  final _RichMessageSegmentType type;
  final String content;
  final String? language;

  const _RichMessageSegment(
    this.type,
    this.content, {
    this.language,
  });
}
