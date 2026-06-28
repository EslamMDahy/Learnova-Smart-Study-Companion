part of 'materials_tab.dart';

class _AddTopicDialogWidget extends StatefulWidget {
  final String moduleTitle;
  final TextEditingController titleCtrl, descCtrl;
  final ValueChanged<TopicDifficulty> onDifficultyChanged;
  const _AddTopicDialogWidget({required this.moduleTitle, required this.titleCtrl,
      required this.descCtrl, required this.onDifficultyChanged});
  @override
  State<_AddTopicDialogWidget> createState() => _AddTopicDialogWidgetState();
}

class _AddTopicDialogWidgetState extends State<_AddTopicDialogWidget> {
  TopicDifficulty _diff = TopicDifficulty.beginner;

  static Map<TopicDifficulty, (Color, Color)> get _diffColors => {
    TopicDifficulty.beginner:     (AppColors.successText, AppColors.successBg),
    TopicDifficulty.intermediate: (AppColors.warningText, AppColors.warningSoftBg),
    TopicDifficulty.advanced:     (AppColors.dangerText, AppColors.dangerBorder),
  };

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.tag_rounded, size: 17, color: AppColors.primary), SizedBox(width: 8),
          Text('Add Topic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
      SizedBox(height: 4),
      Text('in "${widget.moduleTitle}"', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
    ]),
    content: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: widget.titleCtrl, autofocus: true, decoration: InputDecoration(
          hintText: 'e.g. Introduction to Cryptography', labelText: 'Topic Title *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      SizedBox(height: 12),
      TextField(controller: widget.descCtrl, maxLines: 2, decoration: InputDecoration(
          hintText: 'Optional description…', labelText: 'Description',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
      SizedBox(height: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Difficulty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        SizedBox(height: 8),
        Row(children: TopicDifficulty.values.map((d) {
          final (fg, bg) = _diffColors[d]!;
          final sel = _diff == d;
          final isLast = d == TopicDifficulty.advanced;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () { setState(() => _diff = d); widget.onDifficultyChanged(d); },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? bg : AppColors.surfaceBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? fg : AppColors.border, width: sel ? 1.5 : 1),
                ),
                child: Center(child: Text(d.label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: sel ? fg : AppColors.textMuted))),
              ),
            ),
          ));
        }).toList()),
      ]),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
          onPressed: () {
            if (widget.titleCtrl.text.trim().isEmpty) return;
            Navigator.pop(context, {'difficulty': _diff});
          },
          child: Text('Add Topic')),
    ]);
}

class _SimpleDialog extends StatelessWidget {
  final String title, confirm; final TextEditingController ctrl; final Color confirmColor;
  const _SimpleDialog({required this.title, required this.ctrl, required this.confirm, required this.confirmColor});
  @override
  Widget build(BuildContext context) => _PreferencesDialogShell(
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DialogTextField(
          controller: ctrl,
          hintText: 'Enter value',
          autofocus: true,
        ),
        SizedBox(height: 16),
        _DialogActions(
          onCancel: () => Navigator.pop(context, false),
          onConfirm: () => Navigator.pop(context, true),
          confirmLabel: confirm,
          confirmVariant: _isDangerActionColor(confirmColor) ? AppButtonVariant.danger : AppButtonVariant.primary,
        ),
      ],
    ),
  );
}

class _ConfirmDialogWidget extends StatelessWidget {
  final String title, body, confirm; final Color confirmColor;
  const _ConfirmDialogWidget({required this.title, required this.body, required this.confirm, required this.confirmColor});
  @override
  Widget build(BuildContext context) => _PreferencesDialogShell(
    title: title,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(body, style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textMuted)),
        SizedBox(height: 16),
        _DialogActions(
          onCancel: () => Navigator.pop(context, false),
          onConfirm: () => Navigator.pop(context, true),
          confirmLabel: confirm,
          confirmVariant: _isDangerActionColor(confirmColor) ? AppButtonVariant.danger : AppButtonVariant.primary,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
//  Module Actions Grid — replaces the vertical list with a 2-col card grid
// ─────────────────────────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final String status; const _Dot({required this.status});
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final c = switch (status) {
      'ready'       => _K.green,
      'processing'  => _K.amber,
      'uploaded'    => _K.amber,
      'draft_upload'=> AppColors.infoText,
      'error'       => AppColors.dangerText,
      _             => AppColors.textHint,
    };
    return Container(width: 6, height: 6, margin: const EdgeInsets.only(left: 5),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon; final String tooltip; final VoidCallback onTap;
  const _IBtn({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(message: tooltip, child: InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: WidgetStatePropertyAll(Colors.transparent), onTap: onTap,
      borderRadius: BorderRadius.circular(6), child: Padding(padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 14, color: AppColors.textHint))));
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final bool disabled;
  final VoidCallback? onTap;

  const _Btn({
    required this.icon,
    required this.label,
    this.primary = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final fg = disabled
        ? AppColors.textHint
        : (primary ? Colors.white : AppColors.textTitle);
    final bg = disabled
        ? AppColors.borderGray
        : (primary ? AppColors.primary : Colors.transparent);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: WidgetStatePropertyAll(Colors.transparent), 
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: primary || disabled
              ? null
              : BoxDecoration(
                  border: Border.all(color: _K.div),
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
