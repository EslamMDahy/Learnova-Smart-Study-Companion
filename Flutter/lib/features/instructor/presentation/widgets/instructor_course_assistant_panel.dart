import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  static const double _minPanelWidth = 320;
  static const double _defaultPanelWidth = 430;
  static const double _maxPanelWidth = 760;

  double _panelWidth = _defaultPanelWidth;

  @override
  Widget build(BuildContext context) {
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
                      ? 'Ask a question about this course...'
                      : 'Loading chat...',
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
                final canSend = enabled &&
                    !sending &&
                    value.text.trim().isNotEmpty;
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
        constraints: const BoxConstraints(maxWidth: 330),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? AppColors.primary : AppColors.headerBg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowThin,
                blurRadius: 12,
                offset: const Offset(0, 6),
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
