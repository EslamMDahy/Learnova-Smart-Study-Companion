part of 'student_course_details_page.dart';

class _CourseSidebarHeader extends StatelessWidget {
  final String title;

  const _CourseSidebarHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMetricPill extends StatelessWidget {
  final String value;
  final String label;

  const _SidebarMetricPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9.5,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SidebarSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseExamsTreeCard extends StatelessWidget {
  final List<StudentCourseExam> exams;
  final String? loadError;
  final bool expanded;
  final int? selectedExamId;
  final VoidCallback onToggle;
  final ValueChanged<StudentCourseExam> onSelectExam;
  final VoidCallback? onRetry;

  const _CourseExamsTreeCard({
    required this.exams,
    required this.expanded,
    required this.selectedExamId,
    required this.onToggle,
    required this.onSelectExam,
    this.loadError,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final active = selectedExamId != null && exams.any((exam) => exam.id == selectedExamId);
    final hasLoadError = loadError != null && loadError!.trim().isNotEmpty;
    final examLabel = hasLoadError && exams.isEmpty
        ? 'Could not load exams'
        : exams.isEmpty
            ? 'No published exams'
            : exams.length == 1
                ? '1 published exam'
                : '${exams.length} published exams';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.infoBorder : AppColors.border,
          width: active ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: active ? AppColors.shadowBlue.withOpacity(0.18) : AppColors.shadowThin,
            blurRadius: active ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: active ? AppColors.selectedBg : AppColors.cardBg,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 11, 11),
                child: Row(
                  children: [
                    _ExamsIndexBox(active: active),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exams',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active ? AppColors.primary : AppColors.textTitle,
                              fontSize: 13,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            examLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.chevron_right_rounded,
                      color: active || expanded ? AppColors.primary : AppColors.textHint,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Container(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: hasLoadError && exams.isEmpty
                      ? _ExamsLoadErrorNode(
                          message: loadError!.trim(),
                          onRetry: onRetry,
                        )
                      : exams.isEmpty
                          ? const _NoPublishedExamsNode()
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 2,
                                  height: 22.0 * exams.length.clamp(1, 8).toDouble(),
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoBorder,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    children: [
                                      for (var index = 0; index < exams.length; index++) ...[
                                        _CourseExamTile(
                                          exam: exams[index],
                                          selected: exams[index].id == selectedExamId,
                                          onTap: () => onSelectExam(exams[index]),
                                        ),
                                        if (index != exams.length - 1) const SizedBox(height: 8),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
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

class _ExamsIndexBox extends StatelessWidget {
  final bool active;

  const _ExamsIndexBox({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.headerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Icon(
        Icons.assignment_turned_in_outlined,
        color: active ? Colors.white : AppColors.primary,
        size: 17,
      ),
    );
  }
}

class _NoPublishedExamsNode extends StatelessWidget {
  const _NoPublishedExamsNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No published exams are available for this course yet.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamsLoadErrorNode extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ExamsLoadErrorNode({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 17,
                color: AppColors.warningText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Published exams could not be loaded.',
                  style: TextStyle(
                    color: AppColors.warningText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseExamTile extends StatelessWidget {
  final StudentCourseExam exam;
  final bool selected;
  final VoidCallback onTap;

  const _CourseExamTile({
    required this.exam,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SidebarLeafTile(
      icon: Icons.assignment_turned_in_outlined,
      iconBg: selected ? AppColors.primary : AppColors.infoBg,
      iconColor: selected ? Colors.white : AppColors.primary,
      title: exam.safeTitle,
      subtitle: '${exam.totalQuestions} questions • ${_formatScore(exam.totalScore)} pts',
      selected: selected,
      onTap: onTap,
      badge: _titleCase(exam.safeType),
      trailing: Icon(
        Icons.play_arrow_rounded,
        color: exam.isAvailable ? AppColors.primary : AppColors.textHint,
        size: 18,
      ),
    );
  }
}

List<StudentCourseTopic> _rootCourseTopics(List<StudentCourseTopic> topics) {
  final roots = topics.where((topic) => topic.parentTopicId == null).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return roots;
}

List<StudentCourseTopic> _childCourseTopics(
  List<StudentCourseTopic> topics,
  int parentTopicId,
) {
  final children = topics.where((topic) => topic.parentTopicId == parentTopicId).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return children;
}

class _CourseModuleCard extends StatelessWidget {
  final StudentCourseModule module;
  final int moduleNumber;
  final bool selected;
  final bool expanded;
  final int? selectedMaterialId;
  final VoidCallback onSelectModule;
  final ValueChanged<StudentCourseMaterial> onSelectMaterial;

  const _CourseModuleCard({
    required this.module,
    required this.moduleNumber,
    required this.selected,
    required this.expanded,
    required this.selectedMaterialId,
    required this.onSelectModule,
    required this.onSelectMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected;
    final hasContent = module.materials.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.infoBorder : AppColors.border,
          width: active ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: active ? AppColors.shadowBlue.withOpacity(0.18) : AppColors.shadowThin,
            blurRadius: active ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: active ? AppColors.selectedBg : AppColors.cardBg,
            child: InkWell(
              onTap: onSelectModule,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 11, 11),
                child: Row(
                  children: [
                    _ModuleIndexBox(number: moduleNumber, active: active),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module.safeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active ? AppColors.primary : AppColors.textTitle,
                              fontSize: 13,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _moduleSummary(module),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PublishedDot(active: module.isPublished),
                    const SizedBox(width: 8),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.chevron_right_rounded,
                      color: active || expanded ? AppColors.primary : AppColors.textHint,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Container(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: hasContent
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 2,
                              height: 22.0 * module.materials.length.clamp(1, 8).toDouble(),
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: AppColors.infoBorder,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                children: [
                                  for (var i = 0; i < module.materials.length; i++) ...[
                                    _ContentMaterialNode(
                                      material: module.materials[i],
                                      indexLabel: '${moduleNumber}.${i + 1}',
                                      selected: module.materials[i].id == selectedMaterialId,
                                      onTap: () => onSelectMaterial(module.materials[i]),
                                    ),
                                    if (i != module.materials.length - 1)
                                      const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        )
                      : const _ModuleEmptyContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _moduleSummary(StudentCourseModule module) {
    return module.materials.length == 1
        ? '1 material'
        : '${module.materials.length} materials';
  }
}

class _ModuleIndexBox extends StatelessWidget {
  final int number;
  final bool active;

  const _ModuleIndexBox({required this.number, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.headerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
      ),
      child: active
          ? const Icon(Icons.folder_open_rounded, color: Colors.white, size: 17)
          : Text(
              number.toString().padLeft(2, '0'),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _PublishedDot extends StatelessWidget {
  final bool active;

  const _PublishedDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: active ? 'Published' : 'Not published',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? AppColors.successDot : AppColors.textHint,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ModuleEmptyContent extends StatelessWidget {
  const _ModuleEmptyContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textHint),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'No published materials yet.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentMaterialNode extends StatelessWidget {
  final StudentCourseMaterial material;
  final String indexLabel;
  final bool selected;
  final VoidCallback onTap;

  const _ContentMaterialNode({
    required this.material,
    required this.indexLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _materialIcon(material);
    final isPdf = _isPdfMaterial(material);
    final meta = <String>[
      _titleCase(material.safeType),
      if (material.fileSize != null) _formatBytes(material.fileSize!),
    ];

    return _SidebarLeafTile(
      icon: icon,
      iconBg: isPdf ? AppColors.dangerBg : AppColors.infoBg,
      iconColor: isPdf ? AppColors.dangerText : AppColors.primary,
      title: material.safeTitle,
      subtitle: meta.join(' • '),
      selected: selected,
      onTap: onTap,
      prefix: indexLabel,
      badge: isPdf ? 'PDF' : _titleCase(material.safeType),
      trailing: _NodeStatusDot(status: material.status),
    );
  }
}

class _ModuleExamTile extends StatelessWidget {
  final StudentCourseExam exam;
  final bool selected;
  final VoidCallback onTap;

  const _ModuleExamTile({
    required this.exam,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SidebarLeafTile(
      icon: Icons.assignment_turned_in_outlined,
      iconBg: AppColors.infoBg,
      iconColor: AppColors.primary,
      title: exam.safeTitle,
      subtitle: '${exam.totalQuestions} questions • ${_formatScore(exam.totalScore)} pts',
      selected: selected,
      onTap: onTap,
      badge: _titleCase(exam.safeType),
      trailing: Icon(
        Icons.play_arrow_rounded,
        color: exam.isAvailable ? AppColors.primary : AppColors.textHint,
        size: 18,
      ),
    );
  }
}

class _SidebarLeafTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? prefix;
  final String? badge;
  final Widget? trailing;

  const _SidebarLeafTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.prefix,
    this.badge,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedBg : AppColors.surfaceBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.25 : 1,
            ),
          ),
          child: Row(
            children: [
              if ((prefix ?? '').isNotEmpty) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    prefix!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textHint,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : iconBg,
                  borderRadius: BorderRadius.circular(9),
                  border: selected ? null : Border.all(color: AppColors.border),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if ((badge ?? '').isNotEmpty) ...[
                          _SmallBlueBadge(label: badge!),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected ? AppColors.primary : AppColors.textTitle,
                              fontSize: 12.2,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallBlueBadge extends StatelessWidget {
  final String label;

  const _SmallBlueBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NodeStatusDot extends StatelessWidget {
  final String status;

  const _NodeStatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final available = normalized.contains('published') ||
        normalized.contains('uploaded') ||
        normalized.contains('ready') ||
        normalized.contains('available');

    return Tooltip(
      message: status.trim().isEmpty ? 'Available' : _titleCase(status),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: available ? AppColors.successDot : AppColors.warningDot,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MobileModuleSelector extends StatelessWidget {
  final List<StudentCourseModule> modules;
  final List<StudentCourseExam> exams;
  final String? examsLoadError;
  final int? selectedModuleId;
  final int? selectedMaterialId;
  final int? selectedExamId;
  final ValueChanged<StudentCourseModule> onSelectModule;
  final void Function(StudentCourseModule module, StudentCourseMaterial material)
      onSelectMaterial;
  final ValueChanged<StudentCourseExam> onSelectExam;
  final VoidCallback onRetryExams;

  const _MobileModuleSelector({
    required this.modules,
    required this.exams,
    required this.examsLoadError,
    required this.selectedModuleId,
    required this.selectedMaterialId,
    required this.selectedExamId,
    required this.onSelectModule,
    required this.onSelectMaterial,
    required this.onSelectExam,
    required this.onRetryExams,
  });

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty && exams.isEmpty && examsLoadError == null) {
      return const _EmptySidebarState();
    }

    return Column(
      children: [
        for (var index = 0; index < modules.length; index++) ...[
          Builder(
            builder: (_) {
              final module = modules[index];
              return _CourseModuleCard(
                module: module,
                moduleNumber: index + 1,
                expanded: true,
                selected: module.id == selectedModuleId && selectedExamId == null,
                selectedMaterialId: selectedExamId == null ? selectedMaterialId : null,
                onSelectModule: () => onSelectModule(module),
                onSelectMaterial: (material) => onSelectMaterial(module, material),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        if (modules.isNotEmpty || exams.isNotEmpty || examsLoadError != null) ...[
          const SizedBox(height: 8),
          _CourseExamsTreeCard(
            exams: exams,
            loadError: examsLoadError,
            expanded: true,
            selectedExamId: selectedExamId,
            onToggle: () {},
            onSelectExam: onSelectExam,
            onRetry: onRetryExams,
          ),
        ],
      ],
    );
  }
}

class _ModuleNumberBadge extends StatelessWidget {
  final int number;
  final bool active;
  final bool done;

  const _ModuleNumberBadge({
    required this.number,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    if (done && !active) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.successBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.successDot,
          size: 15,
        ),
      );
    }

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.infoBg : AppColors.headerBg,
        shape: BoxShape.circle,
      ),
      child: active
          ? const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 14)
          : Text(
              number.toString(),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool active;
  final bool alignRight;

  const _TabLabel({
    required this.label,
    required this.active,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: EdgeInsets.only(left: alignRight ? 0 : 20, right: alignRight ? 26 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.primary : AppColors.textMuted,
          fontSize: 12.5,
          fontWeight: active ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    );
  }
}


