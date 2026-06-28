import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/chat/rich_message_renderer.dart';
import '../../../student/data/student_course_assistant_models.dart';
import '../../../student/data/student_course_assistant_providers.dart';

class InstructorCourseAssistantPanel extends StatefulWidget {
  final String courseTitle;
  final TextEditingController controller;
  final StudentCourseAssistantState assistantState;
  final ValueChanged<String> onSend;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const InstructorCourseAssistantPanel({
    super.key,
    required this.courseTitle,
    required this.controller,
    required this.assistantState,
    required this.onSend,
    required this.onClear,
    required this.onClose,
  });

  @override
  State<InstructorCourseAssistantPanel> createState() =>
      _InstructorCourseAssistantPanelState();
}

class _InstructorCourseAssistantPanelState
    extends State<InstructorCourseAssistantPanel> {
  static const double _minPanelWidth = 360;
  static const double _defaultPanelWidth = 520;
  static const double _maxPanelWidth = 960;

  final ScrollController _scrollController = ScrollController();
  double _panelWidth = _defaultPanelWidth;

  @override
  void initState() {
    super.initState();
    _scrollToBottom(jump: true);
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _scrollToBottom(jump: true);
    });
  }

  @override
  void didUpdateWidget(covariant InstructorCourseAssistantPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final messageCountChanged =
        oldWidget.assistantState.messages.length != widget.assistantState.messages.length;
    final sendingChanged =
        oldWidget.assistantState.sending != widget.assistantState.sending;
    final historyChanged =
        oldWidget.assistantState.loadingHistory != widget.assistantState.loadingHistory;

    if (messageCountChanged || sendingChanged || historyChanged) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAssistantBusy = widget.assistantState.isBusy;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxAllowedWidth = math.max(
      _minPanelWidth,
      math.min(_maxPanelWidth, screenWidth * 0.68),
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
                          color: isAssistantBusy
                              ? AppColors.textHint
                              : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close assistant',
                        onPressed: widget.onClose,
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
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
                      _AssistantContextCard(courseTitle: widget.courseTitle),
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
                                  'Ask anything about this course. I will create a chat session from your first message, then keep the same session for follow-up questions.',
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
                              label: 'Summarize course',
                              onTap: () => widget.onSend(
                                'Summarize this course in clear bullet points.',
                              ),
                            ),
                            _AssistantChip(
                              label: 'Explain simply',
                              onTap: () => widget.onSend(
                                'Explain the key ideas in this course in simple terms with examples.',
                              ),
                            ),
                            _AssistantChip(
                              label: 'Quiz ideas',
                              onTap: () => widget.onSend(
                                'Suggest quiz questions for this course.',
                              ),
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
                                Expanded(
                                  child: _AssistantBubble(message: message),
                                ),
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
  final String courseTitle;

  const _AssistantContextCard({required this.courseTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selectedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.school_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Course RAG chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _AssistantInputBar extends StatefulWidget {
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
  State<_AssistantInputBar> createState() => _AssistantInputBarState();
}

class _AssistantInputBarState extends State<_AssistantInputBar> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 56, maxHeight: 184),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.text,
                        child: CallbackShortcuts(
                          bindings: <ShortcutActivator, VoidCallback>{
                            const SingleActivator(LogicalKeyboardKey.enter): _submit,
                          },
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: widget.controller,
                                builder: (context, value, _) {
                                  if (value.text.isNotEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return IgnorePointer(
                                    child: Text(
                                      widget.enabled
                                          ? 'Message Learnova AI...'
                                          : 'Loading chat...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 13.2,
                                        height: 1.35,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              EditableText(
                                controller: widget.controller,
                                focusNode: _focusNode,
                                readOnly: !widget.enabled || widget.sending,
                                minLines: 1,
                                maxLines: 7,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                cursorColor: AppColors.primary,
                                backgroundCursorColor: AppColors.border,
                                cursorWidth: 2,
                                style: TextStyle(
                                  color: AppColors.textTitle,
                                  fontSize: 13.2,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                                selectionColor: AppColors.primary.withOpacity(0.18),
                                enableSuggestions: true,
                                autocorrect: true,
                                scrollPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.controller,
                      builder: (context, value, _) {
                        final canSend = widget.enabled &&
                            !widget.sending &&
                            value.text.trim().isNotEmpty;
                        return Tooltip(
                          message: canSend ? 'Send message' : 'Type a message first',
                          waitDuration: const Duration(milliseconds: 500),
                          child: Material(
                            color: canSend ? AppColors.primary : const Color(0xFFE9EFF7),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: canSend ? _submit : null,
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: widget.sending
                                    ? Padding(
                                        padding: const EdgeInsets.all(11),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                          color: canSend
                                              ? Colors.white
                                              : AppColors.textHint,
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_upward_rounded,
                                        color: canSend ? Colors.white : AppColors.textHint,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_return_rounded,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 5),
                  Text(
                    'Enter to send · Shift + Enter for a new line',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || widget.sending || !widget.enabled) return;
    widget.controller.clear();
    widget.onSend(text);
    _focusNode.requestFocus();
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
            RichMessageRenderer(text: message.content),
          if (!message.isUser && message.sources.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final source in message.sources)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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

class _AssistantMessage extends StatelessWidget {
  final bool isUser;
  final Widget child;

  const _AssistantMessage({required this.isUser, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isUser ? 420 : double.infinity,
        ),
        child: Container(
          width: isUser ? null : double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isUser ? 14 : 15,
            vertical: isUser ? 10 : 13,
          ),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primary : AppColors.cardBg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 18),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowThin,
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AssistantBotIcon extends StatelessWidget {
  final double size;

  const _AssistantBotIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.primary,
            AppColors.badgeIndigoFg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

class _AssistantChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AssistantChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? AppColors.headerBg : AppColors.cardBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: onTap == null ? AppColors.border : AppColors.badgeBlueBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: onTap == null ? AppColors.textHint : AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class InstructorCourseAssistantFab extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const InstructorCourseAssistantFab({
    super.key,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.badgeBlueBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AssistantBotIcon(size: 32),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Course AI',
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    busy ? 'Thinking...' : 'Ask about content',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
