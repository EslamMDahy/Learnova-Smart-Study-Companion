part of 'materials_tab.dart';

class _TopicsSidebarWidget extends StatelessWidget {
  final List<TopicItem> topics; final bool loading;
  final void Function(TopicItem) onTopicTap;
  final VoidCallback onAddManual, onGenerateAI;
  const _TopicsSidebarWidget({required this.topics, required this.loading,
      required this.onTopicTap, required this.onAddManual, required this.onGenerateAI,});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _K.div))),
        child: Row(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(7)),
            alignment: Alignment.center,
            child: const Icon(Icons.tag_rounded, size: 13, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text('Topics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
          if (!loading && topics.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: Text('${topics.length}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ],
          const Spacer(),
          if (loading) const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 1.5)),
        ],),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _K.div))),
        child: SizedBox(
          width: double.infinity,
          child: _AddTopicBtnW(
            icon: Icons.edit_rounded,
            label: 'Add Topic',
            onTap: onAddManual,
            color: AppColors.primary,
            bg: _K.blueSoft,
          ),
        ),
      ),
      Expanded(
        child: loading
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(height: 8),
                  Text('Loading topics…', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],),
              )
            : topics.isEmpty
                ? _TopicsEmptyW(onAddManual: onAddManual)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: topics.length,
                    itemBuilder: (_, i) => _TopicItemW(topic: topics[i], index: i, onTap: () => onTopicTap(topics[i])),
                  ),
      ),
    ],);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Unified "Add Topic" button
// ─────────────────────────────────────────────────────────────────────────────
class _AddTopicUnifiedBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTopicUnifiedBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              const BoxShadow(
                color: Color(0x1A137FEC),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'Add Topic',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;
  const _GhostActionButton({required this.icon, required this.label, required this.fg, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
          ],),
        ),
      ),
    );
  }
}


enum _TopicCreateMode { manual, ai }

class _TopicDialogResult {
  final String title;
  final _TopicCreateMode mode;
  final List<int> learningOutcomeIds;

  const _TopicDialogResult.manual(this.title, {this.learningOutcomeIds = const []})
      : mode = _TopicCreateMode.manual;
  const _TopicDialogResult.ai()
      : mode = _TopicCreateMode.ai,
        title = '',
        learningOutcomeIds = const [];
}

class _AddTopicDialogV2 extends StatefulWidget {
  final List<LearningOutcome> outcomes;
  final bool isSubtopic;
  const _AddTopicDialogV2({super.key, this.outcomes = const [], this.isSubtopic = false});

  @override
  State<_AddTopicDialogV2> createState() => _AddTopicDialogV2State();
}

class _AddTopicDialogV2State extends State<_AddTopicDialogV2>
    {
  final TextEditingController _titleCtrl = TextEditingController();
  bool _submitted = false;
  final Set<int> _selectedOutcomeIds = {};

  bool get _requiresOutcome => widget.isSubtopic && widget.outcomes.isNotEmpty;

  String? get _titleError {
    if (!_submitted) return null;
    if (_titleCtrl.text.trim().isEmpty) return widget.isSubtopic ? 'Subtopic name is required' : 'Topic name is required';
    return null;
  }

  String? get _outcomeError {
    if (!_submitted || !_requiresOutcome) return null;
    if (_selectedOutcomeIds.isEmpty) return 'Choose one learning outcome for this subtopic';
    return null;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _outcomeError != null) return;
    final ids = _selectedOutcomeIds.toList()..sort();
    Navigator.pop(
      context,
      _TopicDialogResult.manual(
        title,
        learningOutcomeIds: widget.isSubtopic && ids.isNotEmpty ? <int>[ids.first] : const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 42,
                  spreadRadius: 2,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogHeader(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _manualBody(),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _K.div)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),),
                          side: const BorderSide(color: _K.div),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(widget.isSubtopic ? 'Create Subtopic' : 'Create Topic'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),),
                        ),
                      ),
                    ),
                  ],),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _K.div)),),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tag_rounded, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.isSubtopic ? 'Add Subtopic' : 'Add Topic', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textTitle,),),
            const SizedBox(height: 2),
            Text(widget.isSubtopic
                ? 'Create a final learning unit and map it to learning outcomes.'
                : 'Create a parent topic. Outcome mapping belongs to subtopics.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),),
          ],),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, size: 18),
          splashRadius: 20,
        ),
      ],),
    );
  }

  Widget _manualBody() {
    final outcomes = widget.isSubtopic ? widget.outcomes : const <LearningOutcome>[];
    return Column(
      key: const ValueKey('manual'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.isSubtopic ? 'Subtopic name' : 'Topic name', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted,),),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          autofocus: true,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: widget.isSubtopic ? 'e.g. Variables and data types' : 'e.g. Introduction to Robotics',
            errorText: _titleError,
            prefixIcon: const Icon(Icons.tag_rounded, size: 16, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surfaceBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _K.div),),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _K.div),),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.4),),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        if (outcomes.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(children: [
            Text('Link to one Learning Outcome',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted),),
            const SizedBox(width: 6),
            Text('(required)',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted.withOpacity(0.7)),),
          ],),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _K.div),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: outcomes.length,
                itemBuilder: (_, i) {
                  final lo = outcomes[i];
                  final selected = _selectedOutcomeIds.contains(lo.id);
                  Color dotColor;
                  switch (lo.difficulty) {
                    case OutcomeDifficulty.intermediate: dotColor = AppColors.warningText; break;
                    case OutcomeDifficulty.advanced: dotColor = AppColors.dangerText; break;
                    default: dotColor = AppColors.successText;
                  }
                  return InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), 
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedOutcomeIds.clear();
                      } else {
                        _selectedOutcomeIds
                          ..clear()
                          ..add(lo.id);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
                        border: i < outcomes.length - 1
                            ? Border(bottom: BorderSide(color: AppColors.divider))
                            : null,
                      ),
                      child: Row(children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.borderSoft,
                              width: 1.5,
                            ),
                          ),
                          child: selected
                              ? Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.badgeBlueBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(lo.code,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.badgeBlueFg),),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(lo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: selected ? AppColors.textTitle : AppColors.textMuted,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),),),
                      ],),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _outcomeError ?? (_selectedOutcomeIds.isEmpty ? 'Select one outcome.' : '1 learning outcome linked'),
              style: TextStyle(
                fontSize: 11.5,
                color: _outcomeError == null ? AppColors.primary : AppColors.dangerText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _K.blueSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _K.blueMid),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.isSubtopic
                  ? 'Subtopics map to exactly one learning outcome. Pick it here before creating the item.'
                  : 'This creates a parent topic only. Add subtopics underneath it to map learning outcomes cleanly.',
              style: const TextStyle(fontSize: 13, height: 1.5,
                  color: AppColors.primary, fontWeight: FontWeight.w500,),
            ),),
          ],),
        ),
      ],
    );
  }

}



bool _isDangerActionColor(Color color) => color.red >= 180 && color.green <= 120;


