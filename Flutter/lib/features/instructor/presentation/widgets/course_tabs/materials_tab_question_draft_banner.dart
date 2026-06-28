part of 'materials_tab.dart';

class _QuestionDraftBanner extends StatelessWidget {
  final _QuestionDraftInfo info;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _QuestionDraftBanner({
    required this.info,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warningText.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.edit_note_rounded, size: 19, color: AppColors.warningText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Unsaved question draft',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTitle,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${info.questionCount} question${info.questionCount == 1 ? '' : 's'} • ${info.targetCount} target${info.targetCount == 1 ? '' : 's'} saved in this browser.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onDiscard,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.dangerText,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Discard'),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow_rounded, size: 17),
            label: const Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
          ),
        ],
      ),
    );
  }
}
