part of 'question_bank_tab.dart';

enum _SetupAlertTone { info, danger }

class _ExamSetupHeader extends StatelessWidget {
  final String courseTitle;
  final int totalQuestions;
  final VoidCallback? onClose;

  const _ExamSetupHeader({
    required this.courseTitle,
    required this.totalQuestions,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.borderGray)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
            ),
            child: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Create Exam',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 21,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SetupChip(label: '$totalQuestions in bank'),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  courseTitle.trim().isEmpty
                      ? 'Configure the source, template, and section difficulty before generating.'
                      : '$courseTitle • Configure the source, template, and section difficulty before generating.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogNoticeStack extends StatelessWidget {
  final List<Widget> children;

  const _DialogNoticeStack({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SetupStepIndicator extends StatelessWidget {
  final int currentStep;
  final bool vertical;

  const _SetupStepIndicator({required this.currentStep, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _SetupStepData(
        index: 1,
        title: 'Topics & settings',
        subtitle: 'Exam details and source',
        icon: Icons.tune_rounded,
      ),
      _SetupStepData(
        index: 2,
        title: 'Section difficulty',
        subtitle: 'Difficulty per template section',
        icon: Icons.equalizer_rounded,
      ),
    ];

    if (vertical) {
      return Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _SetupStepTile(
              data: steps[i],
              active: currentStep == i,
              completed: currentStep > i,
            ),
            if (i != steps.length - 1)
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.only(left: 20),
                color: AppColors.borderGray,
              ),
          ],
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _SetupStepTile(
                data: steps[i],
                active: currentStep == i,
                completed: currentStep > i,
                compact: true,
              ),
            ),
            if (i != steps.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

class _SetupStepData {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;

  const _SetupStepData({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _SetupStepTile extends StatelessWidget {
  final _SetupStepData data;
  final bool active;
  final bool completed;
  final bool compact;

  const _SetupStepTile({
    required this.data,
    required this.active,
    required this.completed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active || completed ? AppColors.primary : AppColors.textMuted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 0, vertical: compact ? 10 : 0),
      decoration: BoxDecoration(
        color: active && compact ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: active && compact ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.primary : completed ? AppColors.primarySoft : AppColors.cardBg,
              border: Border.all(color: active || completed ? AppColors.primary.withValues(alpha: 0.35) : AppColors.borderGray),
            ),
            child: completed
                ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                : Icon(data.icon, color: active ? Colors.white : color, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? AppColors.textTitle : color,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
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

class _SetupAlert extends StatelessWidget {
  final String message;
  final _SetupAlertTone tone;

  const _SetupAlert({required this.message, required this.tone});

  @override
  Widget build(BuildContext context) {
    final danger = tone == _SetupAlertTone.danger;
    final bg = danger ? AppColors.dangerBg : AppColors.infoBg;
    final border = danger ? AppColors.dangerBorder : AppColors.infoBorder;
    final color = danger ? AppColors.dangerText : AppColors.infoText;
    final icon = danger ? Icons.error_outline_rounded : Icons.info_outline_rounded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12.3, height: 1.35, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupPageTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SetupPageTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textTitle,
            fontSize: 19,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.45, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SetupPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SetupPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.4, height: 1.35, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _GenerationDifficultyDraft {
  final String sectionLabel;
  final int questionCount;
  final TextEditingController easyCtrl;
  final TextEditingController mediumCtrl;
  final TextEditingController hardCtrl;

  _GenerationDifficultyDraft({required this.sectionLabel, required this.questionCount})
      : easyCtrl = TextEditingController(text: '30'),
        mediumCtrl = TextEditingController(text: '50'),
        hardCtrl = TextEditingController(text: '20');

  int get easyPercent => int.tryParse(easyCtrl.text.trim()) ?? 0;
  int get mediumPercent => int.tryParse(mediumCtrl.text.trim()) ?? 0;
  int get hardPercent => int.tryParse(hardCtrl.text.trim()) ?? 0;
  int get totalPercent => easyPercent + mediumPercent + hardPercent;

  void setEasy(int value) => easyCtrl.text = _boundedPercent(value).toString();
  void setMedium(int value) => mediumCtrl.text = _boundedPercent(value).toString();
  void setHard(int value) => hardCtrl.text = _boundedPercent(value).toString();

  void setMix({required int easy, required int medium, required int hard}) {
    easyCtrl.text = _boundedPercent(easy).toString();
    mediumCtrl.text = _boundedPercent(medium).toString();
    hardCtrl.text = _boundedPercent(hard).toString();
  }

  int _boundedPercent(int value) => value.clamp(0, 100).toInt();

  bool get hasNegativeValue {
    return _isNegativeNumber(easyCtrl.text) || _isNegativeNumber(mediumCtrl.text) || _isNegativeNumber(hardCtrl.text);
  }

  Map<String, int> get percentages {
    return <String, int>{
      'easy': easyPercent,
      'medium': mediumPercent,
      'hard': hardPercent,
    };
  }

  void dispose() {
    easyCtrl.dispose();
    mediumCtrl.dispose();
    hardCtrl.dispose();
  }
}

class _GenerationDifficultyPanel extends StatelessWidget {
  final List<ExamTemplateSectionModel> sections;
  final Map<String, _GenerationDifficultyDraft> drafts;
  final bool enabled;
  final VoidCallback onChanged;

  const _GenerationDifficultyPanel({
    required this.sections,
    required this.drafts,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    void applyPreset(int easy, int medium, int hard) {
      for (final draft in drafts.values) {
        draft.setMix(easy: easy, medium: medium, hard: hard);
      }
      onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 720;
              final leading = Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.percent_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Difficulty presets',
                          style: TextStyle(color: AppColors.textTitle, fontSize: 13.5, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Apply a starting mix to all sections, then fine tune each section if needed.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11.8, height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final presets = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  _DifficultyPresetChip(
                    label: 'Easy 70/20/10',
                    enabled: enabled,
                    onPressed: () => applyPreset(70, 20, 10),
                  ),
                  _DifficultyPresetChip(
                    label: 'Balanced 30/50/20',
                    enabled: enabled,
                    onPressed: () => applyPreset(30, 50, 20),
                  ),
                  _DifficultyPresetChip(
                    label: 'Hard 10/30/60',
                    enabled: enabled,
                    onPressed: () => applyPreset(10, 30, 60),
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leading,
                    const SizedBox(height: 12),
                    presets,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: leading),
                  const SizedBox(width: 12),
                  presets,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            children: [
              _DifficultyTableHeader(),
              Divider(height: 1, color: AppColors.borderGray),
              for (var index = 0; index < sections.length; index++) ...[
                _GenerationDifficultyRow(
                  section: sections[index],
                  draft: drafts['${sections[index].orderIndex > 0 ? sections[index].orderIndex : index + 1}'],
                  enabled: enabled,
                  onChanged: onChanged,
                ),
                if (index != sections.length - 1) Divider(height: 1, color: AppColors.borderGray),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DifficultyTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('Section', style: _difficultyHeaderStyle()),
          ),
          Expanded(child: Text('Easy', textAlign: TextAlign.center, style: _difficultyHeaderStyle())),
          const SizedBox(width: 10),
          Expanded(child: Text('Medium', textAlign: TextAlign.center, style: _difficultyHeaderStyle())),
          const SizedBox(width: 10),
          Expanded(child: Text('Hard', textAlign: TextAlign.center, style: _difficultyHeaderStyle())),
          const SizedBox(width: 10),
          SizedBox(width: 68, child: Text('Total', textAlign: TextAlign.center, style: _difficultyHeaderStyle())),
        ],
      ),
    );
  }

  TextStyle _difficultyHeaderStyle() {
    return TextStyle(
      color: AppColors.textMuted,
      fontSize: 10.7,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.25,
    );
  }
}

class _GenerationDifficultyRow extends StatelessWidget {
  final ExamTemplateSectionModel section;
  final _GenerationDifficultyDraft? draft;
  final bool enabled;
  final VoidCallback onChanged;

  const _GenerationDifficultyRow({
    required this.section,
    required this.draft,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final item = draft;
    if (item == null) return const SizedBox.shrink();
    final totalOk = item.totalPercent == 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DifficultySectionLabel(section: section, draft: item),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _DifficultyPercentField(label: 'Easy', controller: item.easyCtrl, enabled: enabled, onChanged: onChanged)),
                    const SizedBox(width: 8),
                    Expanded(child: _DifficultyPercentField(label: 'Medium', controller: item.mediumCtrl, enabled: enabled, onChanged: onChanged)),
                    const SizedBox(width: 8),
                    Expanded(child: _DifficultyPercentField(label: 'Hard', controller: item.hardCtrl, enabled: enabled, onChanged: onChanged)),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _DifficultyTotalBadge(total: item.totalPercent, ok: totalOk),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Expanded(flex: 5, child: _DifficultySectionLabel(section: section, draft: item)),
              Expanded(child: _DifficultyPercentField(label: 'Easy', controller: item.easyCtrl, enabled: enabled, onChanged: onChanged, hideLabel: true)),
              const SizedBox(width: 10),
              Expanded(child: _DifficultyPercentField(label: 'Medium', controller: item.mediumCtrl, enabled: enabled, onChanged: onChanged, hideLabel: true)),
              const SizedBox(width: 10),
              Expanded(child: _DifficultyPercentField(label: 'Hard', controller: item.hardCtrl, enabled: enabled, onChanged: onChanged, hideLabel: true)),
              const SizedBox(width: 10),
              SizedBox(width: 68, child: Center(child: _DifficultyTotalBadge(total: item.totalPercent, ok: totalOk))),
            ],
          ),
        );
      },
    );
  }
}

class _DifficultySectionLabel extends StatelessWidget {
  final ExamTemplateSectionModel section;
  final _GenerationDifficultyDraft draft;

  const _DifficultySectionLabel({required this.section, required this.draft});

  @override
  Widget build(BuildContext context) {
    final orderIndex = section.orderIndex > 0 ? section.orderIndex : 1;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Text(
            '$orderIndex',
            style: TextStyle(color: AppColors.textTitle, fontSize: 12.3, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                draft.sectionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textTitle, fontSize: 13.2, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                '${section.questionCount} question${section.questionCount == 1 ? '' : 's'} • order index $orderIndex',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.4, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DifficultyTotalBadge extends StatelessWidget {
  final int total;
  final bool ok;

  const _DifficultyTotalBadge({required this.total, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.successText : AppColors.dangerText;
    final bg = ok ? AppColors.successBg : AppColors.dangerBg;
    final border = ok ? AppColors.greenBorder : AppColors.dangerBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        '$total%',
        style: TextStyle(color: color, fontSize: 11.6, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _DifficultyPresetChip extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _DifficultyPresetChip({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        foregroundColor: AppColors.primary,
        side: BorderSide(color: enabled ? AppColors.primary.withValues(alpha: 0.25) : AppColors.borderGray),
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w900)),
    );
  }
}

class _DifficultyPercentField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final bool hideLabel;

  const _DifficultyPercentField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.hideLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      onChanged: (_) => onChanged(),
      style: TextStyle(color: AppColors.textTitle, fontWeight: FontWeight.w900, fontSize: 12.6),
      decoration: InputDecoration(
        isDense: true,
        suffixText: '%',
        suffixStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 11.5),
        filled: true,
        fillColor: enabled ? AppColors.fieldBg : AppColors.fieldDisabledBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderGray)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderGray)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderGray)),
      ),
    );

    if (hideLabel) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10.6, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        field,
      ],
    );
  }
}

class _ExamSetupSummaryPanel extends StatelessWidget {
  final int currentStep;
  final bool showWorkflow;
  final bool titleReady;
  final _ExamScopeMode scopeMode;
  final int selectedScopeCount;
  final int matchingCount;
  final int eligibleCount;
  final int targetCount;
  final int durationMinutes;
  final bool publishAfterSave;
  final ExamTemplateModel template;
  final List<_TemplateRequirementGap> gaps;
  final bool canGenerate;
  final bool canBuildManually;
  final bool templateWillBeSaved;
  final String backendMessage;

  const _ExamSetupSummaryPanel({
    required this.currentStep,
    this.showWorkflow = true,
    required this.titleReady,
    required this.scopeMode,
    required this.selectedScopeCount,
    required this.matchingCount,
    required this.eligibleCount,
    required this.targetCount,
    required this.durationMinutes,
    required this.publishAfterSave,
    required this.template,
    required this.gaps,
    required this.canGenerate,
    required this.canBuildManually,
    required this.templateWillBeSaved,
    required this.backendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final ready = currentStep == 0 ? canBuildManually : canGenerate;
    final sourceLabel = scopeMode == _ExamScopeMode.topics ? 'Topics' : 'Outcomes';
    final sourceValue = scopeMode == _ExamScopeMode.topics && selectedScopeCount == 0
        ? 'All course topics'
        : '$selectedScopeCount selected';
    final statusLabel = ready ? 'Ready' : 'Needs attention';
    final statusColor = ready ? AppColors.successText : AppColors.warningText;
    final statusBg = ready ? AppColors.successBg : AppColors.warningSoftBg;
    final statusBorder = ready ? AppColors.greenBorder : AppColors.warningBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showWorkflow) ...[
            Text(
              'Workflow',
              style: TextStyle(color: AppColors.textTitle, fontSize: 15.5, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _SetupStepIndicator(currentStep: currentStep, vertical: true),
            const SizedBox(height: 18),
            Divider(height: 1, color: AppColors.borderGray),
            const SizedBox(height: 16),
          ],
          Text(
            'Summary',
            style: TextStyle(color: AppColors.textTitle, fontSize: 14.2, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _ExamSummaryRow(label: 'Title', value: titleReady ? 'Ready' : 'Missing', ok: titleReady),
          _ExamSummaryRow(label: sourceLabel, value: sourceValue, ok: scopeMode == _ExamScopeMode.topics || selectedScopeCount > 0),
          _ExamSummaryRow(label: 'Template', value: '$targetCount questions', ok: targetCount > 0),
          _ExamSummaryRow(label: 'Duration', value: '$durationMinutes min', ok: durationMinutes > 0),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _SetupChip(label: publishAfterSave ? 'Publish after save' : 'Draft first'),
              _SetupChip(label: template.backendId == null ? 'Will sync template' : 'Backend template'),
              _SetupChip(label: template.shuffleQuestions ? 'Shuffle' : 'Fixed order'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: statusBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(ready ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: statusColor, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 12.2, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        templateWillBeSaved && currentStep == 1 && canGenerate
                            ? '$backendMessage Template will be synced first.'
                            : backendMessage,
                        style: TextStyle(color: statusColor, fontSize: 11.4, height: 1.35, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (currentStep == 0 && matchingCount > 0) ...[
            const SizedBox(height: 10),
            _SummaryNote(
              icon: Icons.inventory_2_outlined,
              text: '$matchingCount cached questions match the current source. $eligibleCount fit the selected template filters.',
              color: AppColors.textMuted,
              bg: AppColors.surfaceMuted,
              border: AppColors.borderGray,
            ),
          ],
          if (gaps.isNotEmpty && currentStep == 1) ...[
            const SizedBox(height: 10),
            _SummaryNote(
              icon: Icons.warning_amber_rounded,
              text: gaps.map((gap) => '${gap.label} ${gap.availableCount}/${gap.requiredCount}').join(' • '),
              color: AppColors.warningText,
              bg: AppColors.warningSoftBg,
              border: AppColors.warningBorder,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExamSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;

  const _ExamSummaryRow({required this.label, required this.value, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: ok ? AppColors.successText : AppColors.textMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.6, fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: ok ? AppColors.textTitle : AppColors.textMuted, fontSize: 11.6, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;
  final Color border;

  const _SummaryNote({
    required this.icon,
    required this.text,
    required this.color,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 11.1, height: 1.35, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _SetupTextField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          textInputAction: TextInputAction.done,
          style: TextStyle(color: AppColors.textTitle, fontWeight: FontWeight.w800, fontSize: 13.3),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.fieldBg : AppColors.fieldDisabledBg,
            hintText: 'e.g. Java Midterm - Chapter 1',
            hintStyle: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w600, fontSize: 13),
            prefixIcon: Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: AppColors.borderGray),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: AppColors.borderGray),
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupChip extends StatelessWidget {
  final String label;

  const _SetupChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Text(
        label,
        style: TextStyle(color: AppColors.textMuted, fontSize: 10.2, fontWeight: FontWeight.w900, letterSpacing: 0.2),
      ),
    );
  }
}