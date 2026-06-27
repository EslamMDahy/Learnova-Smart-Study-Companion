part of 'quiz_screen.dart';

class _ExamStudioStats {
  final int courses;
  final int exams;
  final int published;
  final int draft;
  final int questions;

  const _ExamStudioStats({
    required this.courses,
    required this.exams,
    required this.published,
    required this.draft,
    required this.questions,
  });

  factory _ExamStudioStats.fromGroups(List<_CourseExamGroup> groups) {
    final exams = groups.fold<int>(0, (sum, group) => sum + group.exams.length);
    final published = groups.fold<int>(0, (sum, group) => sum + group.published);
    final questions = groups.fold<int>(0, (sum, group) => sum + group.totalQuestions);
    return _ExamStudioStats(
      courses: groups.length,
      exams: exams,
      published: published,
      draft: exams - published,
      questions: questions,
    );
  }
}

class _ExamStudioHero extends StatelessWidget {
  final _ExamStudioStats stats;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback? onCreateExam;

  const _ExamStudioHero({
    required this.stats,
    required this.refreshing,
    required this.onRefresh,
    required this.onCreateExam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3EA8), Color(0xFF137FEC), Color(0xFF20C6D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.34), blurRadius: 22, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 29),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exams', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.7)),
                const SizedBox(height: 6),
                Text(
                  'Manage generated exams, publish them to students, and export backend-ready paper PDFs.',
                  style: TextStyle(color: Colors.white.withOpacity(0.86), fontSize: 13, fontWeight: FontWeight.w700, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(value: '${stats.courses}', label: 'Courses'),
              _HeroMetric(value: '${stats.exams}', label: 'Exams'),
              _HeroMetric(value: '${stats.published}', label: 'Published'),
              _HeroMetric(value: '${stats.questions}', label: 'Questions'),
            ],
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: refreshing ? null : onRefresh,
                icon: refreshing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(refreshing ? 'Loading...' : 'Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withOpacity(0.55),
                  side: BorderSide(color: Colors.white.withOpacity(0.35)),
                  backgroundColor: Colors.white.withOpacity(0.08),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onCreateExam,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create exam'),
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withOpacity(0.25),
                  disabledForegroundColor: Colors.white.withOpacity(0.65),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HeroMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.76), fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ExamStudioBody extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_CourseExamGroup> groups;
  final List<_CourseExamGroup> allGroups;
  final _CourseExamGroup? activeGroup;
  final _ExamStatusFilter statusFilter;
  final TextEditingController searchController;
  final bool hasActiveFilters;
  final ValueChanged<_ExamStatusFilter> onStatusChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectCourse;
  final void Function(MyCourseItem course, ExamModel exam) onOpenExam;
  final void Function(MyCourseItem course, ExamModel exam) onPublishExam;
  final void Function(MyCourseItem course, ExamModel exam) onExportExam;
  final ValueChanged<MyCourseItem> onOpenQuestionBank;
  final ValueChanged<MyCourseItem> onOpenTemplates;

  const _ExamStudioBody({
    required this.loading,
    required this.error,
    required this.groups,
    required this.allGroups,
    required this.activeGroup,
    required this.statusFilter,
    required this.searchController,
    required this.hasActiveFilters,
    required this.onStatusChanged,
    required this.onClearFilters,
    required this.onRetry,
    required this.onSelectCourse,
    required this.onOpenExam,
    required this.onPublishExam,
    required this.onExportExam,
    required this.onOpenQuestionBank,
    required this.onOpenTemplates,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _StudioShell(
        child: SizedBox(height: 560, child: Center(child: CircularProgressIndicator())),
      );
    }
    if (error != null) {
      return _StudioShell(
        child: _StateMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not load exams',
          message: error!,
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      );
    }
    final noMatches = groups.isEmpty && hasActiveFilters && allGroups.isNotEmpty;
    if (groups.isEmpty && !noMatches) {
      return _StudioShell(
        child: _StateMessage(
          icon: Icons.school_outlined,
          title: 'No courses found',
          message: 'Create a course first. Exams are scoped per course in the backend.',
          actionLabel: 'Refresh',
          onAction: onRetry,
        ),
      );
    }

    final group = noMatches ? allGroups.first : activeGroup ?? groups.first;
    final navigatorGroups = noMatches ? const <_CourseExamGroup>[] : groups;
    final board = noMatches
        ? _NoMatchingExamsPanel(onClearFilters: onClearFilters)
        : _CourseExamBoard(
            group: group,
            onOpenExam: onOpenExam,
            onPublishExam: onPublishExam,
            onExportExam: onExportExam,
            onOpenQuestionBank: onOpenQuestionBank,
            onOpenTemplates: onOpenTemplates,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        if (compact) {
          return Column(
            children: [
              _CourseNavigatorCard(
                groups: navigatorGroups,
                totalCount: noMatches ? allGroups.length : groups.length,
                activeCourseId: group.course.id,
                statusFilter: statusFilter,
                searchController: searchController,
                emptyMessage: noMatches ? 'No courses or exams match the current filters.' : null,
                onStatusChanged: onStatusChanged,
                onSelectCourse: onSelectCourse,
              ),
              const SizedBox(height: 16),
              board,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 420,
              child: _CourseNavigatorCard(
                groups: navigatorGroups,
                totalCount: noMatches ? allGroups.length : groups.length,
                activeCourseId: group.course.id,
                statusFilter: statusFilter,
                searchController: searchController,
                emptyMessage: noMatches ? 'No courses or exams match the current filters.' : null,
                onStatusChanged: onStatusChanged,
                onSelectCourse: onSelectCourse,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(child: board),
          ],
        );
      },
    );
  }
}

class _NoMatchingExamsPanel extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _NoMatchingExamsPanel({required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return _StudioShell(
      child: SizedBox(
        height: 360,
        child: _StateMessage(
          icon: Icons.search_rounded,
          title: 'No matching exams',
          message: 'No course or exam matches the current search/status filters. Clear filters or edit the search box on the left.',
          actionLabel: 'Clear filters',
          onAction: onClearFilters,
        ),
      ),
    );
  }
}

class _InlineEmptyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InlineEmptyMessage({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon, color: AppColors.textMuted, size: 36),
          const SizedBox(height: 12),
          Text(title, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(message, style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w700, height: 1.4)),
        ],
      ),
    );
  }
}

class _StudioShell extends StatelessWidget {
  final Widget child;

  const _StudioShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 24, offset: const Offset(0, 14))],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CourseNavigatorCard extends StatelessWidget {
  final List<_CourseExamGroup> groups;
  final int totalCount;
  final int activeCourseId;
  final _ExamStatusFilter statusFilter;
  final TextEditingController searchController;
  final String? emptyMessage;
  final ValueChanged<_ExamStatusFilter> onStatusChanged;
  final ValueChanged<int> onSelectCourse;

  const _CourseNavigatorCard({
    required this.groups,
    required this.totalCount,
    required this.activeCourseId,
    required this.statusFilter,
    required this.searchController,
    this.emptyMessage,
    required this.onStatusChanged,
    required this.onSelectCourse,
  });

  @override
  Widget build(BuildContext context) {
    return _StudioShell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBox(icon: Icons.folder_open_outlined, color: AppColors.primary, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Course library', style: _textStyle(color: AppColors.textTitle, size: 16, weight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text('Backend exams grouped by course', style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    _MiniBadge(label: '$totalCount', color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 16),
                _SearchField(controller: searchController),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ExamStatusFilter.values.map((filter) {
                    return _FilterChipButton(
                      label: filter.label,
                      selected: filter == statusFilter,
                      onTap: () => onStatusChanged(filter),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          if (groups.isEmpty && emptyMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
              child: _InlineEmptyMessage(
                icon: Icons.manage_search_rounded,
                title: 'No matches',
                message: emptyMessage!,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final group = groups[index];
                return _CourseTile(
                  group: group,
                  active: group.course.id == activeCourseId,
                  onTap: () => onSelectCourse(group.course.id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search course or exam...',
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: AppColors.surfaceBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w700),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: _textStyle(
            color: selected ? Colors.white : AppColors.textMuted,
            size: 12,
            weight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final _CourseExamGroup group;
  final bool active;
  final VoidCallback onTap;

  const _CourseTile({required this.group, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final course = group.course;
    final statusColor = course.isPrivate ? AppColors.warningText : AppColors.successText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.selectedBg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary.withOpacity(0.42) : AppColors.border),
          boxShadow: active ? [BoxShadow(color: AppColors.shadowThin, blurRadius: 14, offset: const Offset(0, 8))] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBox(icon: Icons.school_outlined, color: active ? AppColors.primary : AppColors.textMuted, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.safeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(course.safeCourseCode, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textMuted, size: 11, weight: FontWeight.w800)),
                    ],
                  ),
                ),
                _StatusDot(color: group.error == null ? statusColor : AppColors.errorDot),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CompactStat(value: '${group.exams.length}', label: 'Exams'),
                const SizedBox(width: 8),
                _CompactStat(value: '${group.published}', label: 'Live'),
                const SizedBox(width: 8),
                _CompactStat(value: '${group.draft}', label: 'Draft'),
              ],
            ),
            if (group.error != null) ...[
              const SizedBox(height: 10),
              Text(group.error!, maxLines: 2, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.dangerText, size: 11, weight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String value;
  final String label;

  const _CompactStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: _textStyle(color: AppColors.textTitle, size: 13, weight: FontWeight.w900)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textHint, size: 10, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _CourseExamBoard extends StatelessWidget {
  final _CourseExamGroup group;
  final void Function(MyCourseItem course, ExamModel exam) onOpenExam;
  final void Function(MyCourseItem course, ExamModel exam) onPublishExam;
  final void Function(MyCourseItem course, ExamModel exam) onExportExam;
  final ValueChanged<MyCourseItem> onOpenQuestionBank;
  final ValueChanged<MyCourseItem> onOpenTemplates;

  const _CourseExamBoard({
    required this.group,
    required this.onOpenExam,
    required this.onPublishExam,
    required this.onExportExam,
    required this.onOpenQuestionBank,
    required this.onOpenTemplates,
  });

  @override
  Widget build(BuildContext context) {
    final course = group.course;
    return _StudioShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CourseBoardHeader(
            group: group,
            onOpenTemplates: () => onOpenTemplates(course),
          ),
          if (group.error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: _StateMessage(icon: Icons.error_outline_rounded, title: 'Could not load course exams', message: group.error!),
            )
          else if (group.exams.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
              child: _EmptyCourseExams(course: course, onOpenQuestionBank: () => onOpenQuestionBank(course), onOpenTemplates: () => onOpenTemplates(course)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              itemCount: group.exams.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final exam = group.exams[index];
                return _ExamListCard(
                  index: index + 1,
                  course: course,
                  exam: exam,
                  onOpen: () => onOpenExam(course, exam),
                  onPublish: exam.isPublished ? null : () => onPublishExam(course, exam),
                  onExport: () => onExportExam(course, exam),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CourseBoardHeader extends StatelessWidget {
  final _CourseExamGroup group;
  final VoidCallback onOpenTemplates;

  const _CourseBoardHeader({required this.group, required this.onOpenTemplates});

  @override
  Widget build(BuildContext context) {
    final course = group.course;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
        gradient: LinearGradient(colors: [AppColors.surfaceAlt, AppColors.surfaceBg], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          _IconBox(icon: Icons.menu_book_outlined, color: AppColors.primary, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(course.safeTitle, style: _textStyle(color: AppColors.textTitle, size: 21, weight: FontWeight.w900, letterSpacing: -0.3)),
                    _MiniBadge(label: course.isPrivate ? 'Private' : 'Public', color: course.isPrivate ? AppColors.warningText : AppColors.successText),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${course.safeCourseCode} • ${group.exams.length} exams • ${group.published} published • ${group.draft} draft',
                  style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onOpenTemplates,
            icon: const Icon(Icons.view_module_outlined, size: 18),
            label: const Text('Templates'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCourseExams extends StatelessWidget {
  final MyCourseItem course;
  final VoidCallback onOpenQuestionBank;
  final VoidCallback onOpenTemplates;

  const _EmptyCourseExams({required this.course, required this.onOpenQuestionBank, required this.onOpenTemplates});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBox(icon: Icons.add_task_rounded, color: AppColors.primary, size: 62),
              const SizedBox(height: 18),
              Text('No exams for ${course.safeTitle} yet', textAlign: TextAlign.center, style: _textStyle(color: AppColors.textTitle, size: 20, weight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'Create a manual draft, or generate one automatically from a saved template. The backend stores exams per course.',
                textAlign: TextAlign.center,
                style: _textStyle(color: AppColors.textMuted, size: 13, weight: FontWeight.w700, height: 1.45),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(onPressed: onOpenQuestionBank, icon: const Icon(Icons.add_rounded), label: const Text('Create exam')),
                  OutlinedButton.icon(onPressed: onOpenTemplates, icon: const Icon(Icons.view_module_outlined), label: const Text('Open templates')),
                ],
              ),
            ],
          ),
        ),
    );
  }
}

class _ExamListCard extends StatelessWidget {
  final int index;
  final MyCourseItem course;
  final ExamModel exam;
  final VoidCallback onOpen;
  final VoidCallback? onPublish;
  final VoidCallback onExport;

  const _ExamListCard({
    required this.index,
    required this.course,
    required this.exam,
    required this.onOpen,
    required this.onPublish,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = exam.isPublished ? AppColors.successText : AppColors.warningText;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 16, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.badgeBlueBorder)),
              child: Text(index.toString().padLeft(2, '0'), style: _textStyle(color: AppColors.primary, size: 13, weight: FontWeight.w900)),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(exam.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _textStyle(color: AppColors.textTitle, size: 15, weight: FontWeight.w900))),
                      const SizedBox(width: 8),
                      _MiniBadge(label: exam.isPublished ? 'Published' : 'Draft', color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaPill(icon: Icons.category_outlined, label: _titleCase(exam.examType)),
                      _MetaPill(icon: Icons.quiz_outlined, label: '${exam.totalQuestions} questions'),
                      _MetaPill(icon: Icons.stacked_line_chart_rounded, label: '${_points(exam.totalScore)} points'),
                      _MetaPill(icon: Icons.timer_outlined, label: _duration(exam.durationMinutes)),
                      _MetaPill(icon: Icons.repeat_rounded, label: '${exam.maxAttempts} attempt${exam.maxAttempts == 1 ? '' : 's'}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Updated', style: _textStyle(color: AppColors.textHint, size: 10, weight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(_formatDate(exam.updatedAt), style: _textStyle(color: AppColors.textMuted, size: 12, weight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              tooltip: 'Exam actions',
              onSelected: (value) {
                switch (value) {
                  case 'open':
                    onOpen();
                    return;
                  case 'publish':
                    onPublish?.call();
                    return;
                  case 'export':
                    onExport();
                    return;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'open', child: _MenuItem(icon: Icons.open_in_new_rounded, label: 'Open details')),
                if (!exam.isPublished)
                  const PopupMenuItem(value: 'publish', child: _MenuItem(icon: Icons.publish_rounded, label: 'Publish to students')),
                const PopupMenuItem(value: 'export', child: _MenuItem(icon: Icons.picture_as_pdf_outlined, label: 'Export PDF')),
              ],
            ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

