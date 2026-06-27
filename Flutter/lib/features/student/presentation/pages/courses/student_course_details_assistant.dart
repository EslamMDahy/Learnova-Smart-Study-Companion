part of 'student_course_details_page.dart';

class _StudyAssistantPanel extends StatefulWidget {
  final String courseTitle;
  final TextEditingController controller;
  final StudentCourseAssistantState assistantState;
  final StudentCourseModule? selectedModule;
  final StudentCourseMaterial? selectedMaterial;
  final ValueChanged<String> onSend;
  final VoidCallback onClear;

  const _StudyAssistantPanel({
    required this.courseTitle,
    required this.controller,
    required this.assistantState,
    required this.selectedModule,
    required this.selectedMaterial,
    required this.onSend,
    required this.onClear,
  });

  @override
  State<_StudyAssistantPanel> createState() => _StudyAssistantPanelState();
}

class _StudyAssistantPanelState extends State<_StudyAssistantPanel> {
  static const double _minPanelWidth = 320;
  static const double _defaultPanelWidth = 430;
  static const double _maxPanelWidth = 760;

  double _panelWidth = _defaultPanelWidth;

  @override
  Widget build(BuildContext context) {
    final moduleTitle = widget.selectedModule?.safeTitle;
    final materialTitle = widget.selectedMaterial?.safeTitle;
    final hasContext = materialTitle != null && materialTitle.trim().isNotEmpty;
    final isAssistantBusy = widget.assistantState.isBusy;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxAllowedWidth = math.max(
      _minPanelWidth,
      math.min(_maxPanelWidth, screenWidth * 0.58),
    );
    final width = _panelWidth.clamp(_minPanelWidth, maxAllowedWidth).toDouble();

    return SizedBox(
      width: width,
      height: double.infinity,
      child: Stack(
        children: [
          Container(
            width: width,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      _AssistantBotIcon(size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course assistant',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textTitle,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.courseTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Drag the left edge to resize chat',
                        child: Icon(
                          Icons.open_in_full_rounded,
                          color: AppColors.textHint,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'New chat',
                        onPressed: isAssistantBusy ? null : widget.onClear,
                        icon: Icon(
                          Icons.add_comment_outlined,
                          color: isAssistantBusy ? AppColors.textHint : AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.headerBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AssistantContextCard(
                        moduleTitle: moduleTitle,
                        materialTitle: materialTitle,
                      ),
                      const SizedBox(height: 14),
                      if (widget.assistantState.loadingHistory) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AssistantBotIcon(size: 26),
                            const SizedBox(width: 8),
                            const _AssistantHistoryLoadingBubble(),
                          ],
                        ),
                      ] else if (widget.assistantState.messages.isEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AssistantBotIcon(size: 26),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _AssistantMessage(
                                isUser: false,
                                child: Text(
                                  hasContext
                                      ? 'Ask anything about this material. I will create a chat session from your first message, then keep the same session for follow-up questions.'
                                      : 'Ask anything about this course. Select a material first if you want the question to stay focused on one lecture.',
                                  style: TextStyle(
                                    color: AppColors.textGray,
                                    fontSize: 12.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _AssistantChip(
                              label: 'Summarize material',
                              onTap: hasContext
                                  ? () => widget.onSend(
                                        'Summarize "${materialTitle!}" in clear bullet points.',
                                      )
                                  : null,
                            ),
                            _AssistantChip(
                              label: 'Explain simply',
                              onTap: hasContext
                                  ? () => widget.onSend(
                                        'Explain "${materialTitle!}" in simple terms with examples.',
                                      )
                                  : null,
                            ),
                            _AssistantChip(
                              label: 'Quiz me',
                              onTap: hasContext
                                  ? () => widget.onSend(
                                        'Quiz me on "${materialTitle!}", then wait for my answers.',
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ] else ...[
                        for (final message in widget.assistantState.messages) ...[
                          if (!message.isUser)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AssistantBotIcon(size: 26),
                                const SizedBox(width: 8),
                                Expanded(child: _AssistantBubble(message: message)),
                              ],
                            )
                          else
                            _AssistantBubble(message: message),
                          const SizedBox(height: 12),
                        ],
                        if (widget.assistantState.sending)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AssistantBotIcon(size: 26),
                              const SizedBox(width: 8),
                              const _AssistantTypingBubble(),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
                _AssistantInputBar(
                  controller: widget.controller,
                  sending: widget.assistantState.sending,
                  enabled: !widget.assistantState.loadingHistory,
                  onSend: widget.onSend,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _panelWidth = (_panelWidth - details.delta.dx)
                        .clamp(_minPanelWidth, maxAllowedWidth)
                        .toDouble();
                  });
                },
                child: SizedBox(
                  width: 10,
                  child: Center(
                    child: Container(
                      width: 3,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
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

class _AssistantContextCard extends StatelessWidget {
  final String? moduleTitle;
  final String? materialTitle;

  const _AssistantContextCard({
    required this.moduleTitle,
    required this.materialTitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasMaterial = materialTitle != null && materialTitle!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasMaterial ? AppColors.selectedBg : AppColors.headerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasMaterial ? AppColors.primary.withOpacity(0.25) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasMaterial ? Icons.menu_book_rounded : Icons.info_outline_rounded,
            color: hasMaterial ? AppColors.primary : AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasMaterial ? materialTitle! : 'No material selected',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (moduleTitle != null && moduleTitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    moduleTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final ValueChanged<String> onSend;

  const _AssistantInputBar({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowThin,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 5, 7, 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !sending,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Ask a question about this lecture...'
                      : 'Ask a question about this course...',
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend = enabled && !sending && value.text.trim().isNotEmpty;
                return Material(
                  color: canSend ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    onTap: canSend ? _submit : null,
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: canSend ? Colors.white : AppColors.textHint,
                              size: 18,
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final text = controller.text.trim();
    if (text.isEmpty || sending || !enabled) return;
    controller.clear();
    onSend(text);
  }
}

class _AssistantBubble extends StatelessWidget {
  final StudentAssistantMessage message;

  const _AssistantBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return _AssistantMessage(
      isUser: message.isUser,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isUser || message.isError)
            Text(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.white : AppColors.warningText,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: message.isUser ? FontWeight.w700 : FontWeight.w500,
              ),
            )
          else
            RichMessageRenderer(
              text: message.content,
            ),
          if (!message.isUser && message.sources.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final source in message.sources)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.headerBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      source.label,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


class _AssistantMarkdownText extends StatelessWidget {
  final String text;
  const _AssistantMarkdownText({required this.text});
  @override
  Widget build(BuildContext context) {
    return RichMessageRenderer(text: text);
  }
}

class _AssistantMarkdownBullet extends StatelessWidget {
  final String marker;
  final String text;
  final TextStyle baseStyle;

  const _AssistantMarkdownBullet({
    required this.marker,
    required this.text,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: marker == '•' ? 14 : 24,
          child: Text(
            marker,
            style: baseStyle.copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: _AssistantMarkdownLine(text: text, style: baseStyle),
        ),
      ],
    );
  }
}

class _AssistantMarkdownLine extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _AssistantMarkdownLine({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _inlineSpans(text, style)),
      textAlign: TextAlign.start,
      softWrap: true,
    );
  }
}

List<TextSpan> _inlineSpans(String text, TextStyle baseStyle) {
  final spans = <TextSpan>[];
  var cursor = 0;

  while (cursor < text.length) {
    final token = _nextMarkdownToken(text, cursor);
    if (token == null) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
      break;
    }

    if (token.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, token.start), style: baseStyle));
    }

    final content = text.substring(token.contentStart, token.contentEnd);
    var tokenStyle = baseStyle;
    switch (token.type) {
      case _MarkdownInlineTokenType.bold:
        tokenStyle = baseStyle.copyWith(
          color: AppColors.textTitle,
          fontWeight: FontWeight.w900,
        );
        break;
      case _MarkdownInlineTokenType.italic:
        tokenStyle = baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        );
        break;
      case _MarkdownInlineTokenType.code:
        tokenStyle = baseStyle.copyWith(
          color: AppColors.textTitle,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          backgroundColor: AppColors.headerBg,
        );
        break;
      case _MarkdownInlineTokenType.link:
        tokenStyle = baseStyle.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
        );
        break;
    }

    spans.add(TextSpan(text: content, style: tokenStyle));
    cursor = token.end;
  }

  return spans;
}

_MarkdownInlineToken? _nextMarkdownToken(String text, int start) {
  _MarkdownInlineToken? best;

  void consider(_MarkdownInlineToken? token) {
    if (token == null) return;
    if (best == null || token.start < best!.start) best = token;
  }

  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '**',
    type: _MarkdownInlineTokenType.bold,
  ));
  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '__',
    type: _MarkdownInlineTokenType.bold,
  ));
  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '`',
    type: _MarkdownInlineTokenType.code,
  ));
  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '*',
    type: _MarkdownInlineTokenType.italic,
    ignoredPrefixes: const ['**'],
  ));
  consider(_findDelimitedToken(
    text: text,
    start: start,
    delimiter: '_',
    type: _MarkdownInlineTokenType.italic,
    ignoredPrefixes: const ['__'],
  ));
  consider(_findMarkdownLink(text, start));

  return best;
}

_MarkdownInlineToken? _findDelimitedToken({
  required String text,
  required int start,
  required String delimiter,
  required _MarkdownInlineTokenType type,
  List<String> ignoredPrefixes = const [],
}) {
  var open = text.indexOf(delimiter, start);

  while (open != -1) {
    final shouldIgnore = ignoredPrefixes.any(
      (prefix) => text.startsWith(prefix, open),
    );
    if (!shouldIgnore) {
      final contentStart = open + delimiter.length;
      final close = text.indexOf(delimiter, contentStart);
      if (close != -1 && close > contentStart) {
        return _MarkdownInlineToken(
          type: type,
          start: open,
          contentStart: contentStart,
          contentEnd: close,
          end: close + delimiter.length,
        );
      }
    }

    open = text.indexOf(delimiter, open + delimiter.length);
  }

  return null;
}

_MarkdownInlineToken? _findMarkdownLink(String text, int start) {
  final openBracket = text.indexOf('[', start);
  if (openBracket == -1) return null;

  final closeBracket = text.indexOf(']', openBracket + 1);
  if (closeBracket == -1 || closeBracket + 1 >= text.length) return null;
  if (text[closeBracket + 1] != '(') return null;

  final closeParen = text.indexOf(')', closeBracket + 2);
  if (closeParen == -1 || closeBracket == openBracket + 1) return null;

  return _MarkdownInlineToken(
    type: _MarkdownInlineTokenType.link,
    start: openBracket,
    contentStart: openBracket + 1,
    contentEnd: closeBracket,
    end: closeParen + 1,
  );
}

enum _MarkdownInlineTokenType { bold, italic, code, link }

class _MarkdownInlineToken {
  final _MarkdownInlineTokenType type;
  final int start;
  final int contentStart;
  final int contentEnd;
  final int end;

  const _MarkdownInlineToken({
    required this.type,
    required this.start,
    required this.contentStart,
    required this.contentEnd,
    required this.end,
  });
}


class _AssistantHistoryLoadingBubble extends StatelessWidget {
  const _AssistantHistoryLoadingBubble();

  @override
  Widget build(BuildContext context) {
    return _AssistantMessage(
      isUser: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'Loading previous chat...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantTypingBubble extends StatelessWidget {
  const _AssistantTypingBubble();

  @override
  Widget build(BuildContext context) {
    return _AssistantMessage(
      isUser: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'Thinking...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}



