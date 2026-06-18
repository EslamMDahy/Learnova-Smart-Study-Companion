import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnova/core/routing/routes.dart';
import 'package:learnova/core/theme/app_theme.dart';
import 'package:learnova/features/student/data/student_exam_history_providers.dart';

class StudentQuizHistoryPage extends ConsumerStatefulWidget {
  const StudentQuizHistoryPage({super.key});

  @override
  ConsumerState<StudentQuizHistoryPage> createState() => _StudentQuizHistoryPageState();
}

class _StudentQuizHistoryPageState extends ConsumerState<StudentQuizHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _selectedCourseId = 0;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(studentExamHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _HistoryErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(studentExamHistoryProvider),
      ),
      data: (history) {
        final filteredRows = _filterRows(history.rows);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentExamHistoryProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Exam History',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textGray,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'View your submitted exams, scores, grading status, and retakes across enrolled courses.',
                            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Refresh exam history',
                      onPressed: () => ref.invalidate(studentExamHistoryProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _StatsRow(history: history),
                const SizedBox(height: 32),
                _buildFilters(history),
                const SizedBox(height: 24),
                _buildTable(filteredRows, history.rows.length),
              ],
            ),
          ),
        );
      },
    );
  }

  List<StudentExamHistoryRow> _filterRows(List<StudentExamHistoryRow> rows) {
    return rows.where((row) {
      final matchesCourse = _selectedCourseId == 0 || row.courseId == _selectedCourseId;
      final matchesStatus = _selectedStatus == 'all' || _statusKey(row) == _selectedStatus;
      final searchable = [
        row.exam.safeTitle,
        row.exam.safeType,
        row.course.title,
        row.course.courseCode ?? '',
        row.statusLabel,
      ].join(' ').toLowerCase();
      final matchesQuery = _query.isEmpty || searchable.contains(_query);
      return matchesCourse && matchesStatus && matchesQuery;
    }).toList(growable: false);
  }

  String _statusKey(StudentExamHistoryRow row) {
    if (row.isInProgress) return 'in_progress';
    if (row.isPending) return 'pending';
    if (row.isPassed) return 'passed';
    if (row.isFailed) return 'failed';
    return 'completed';
  }

  Widget _buildFilters(StudentExamHistoryData history) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.headerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search by exam, course, or status...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textHint),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
                        onPressed: _searchController.clear,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _CourseFilterButton(
          courses: history.courses,
          selectedCourseId: _selectedCourseId,
          onChanged: (value) => setState(() => _selectedCourseId = value),
        ),
        const SizedBox(width: 12),
        _StatusFilterButton(
          selectedStatus: _selectedStatus,
          onChanged: (value) => setState(() => _selectedStatus = value),
        ),
      ],
    );
  }

  Widget _buildTable(List<StudentExamHistoryRow> rows, int totalCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('EXAM DETAILS', style: _headerStyle)),
                Expanded(flex: 2, child: Text('DATE TAKEN', style: _headerStyle)),
                Expanded(flex: 2, child: Text('DURATION', style: _headerStyle)),
                Expanded(flex: 2, child: Text('SCORE', style: _headerStyle)),
                Expanded(flex: 2, child: Text('STATUS', style: _headerStyle)),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('ACTIONS', style: _headerStyle),
                  ),
                ),
              ],
            ),
          ),
          if (rows.isEmpty)
            _EmptyHistoryState(hasFilters: _query.isNotEmpty || _selectedCourseId != 0 || _selectedStatus != 'all')
          else
            ...rows.asMap().entries.map((entry) {
              return _ExamHistoryRowWidget(
                row: entry.value,
                isLast: entry.key == rows.length - 1,
                onView: () {
                  context.go(
                    Routes.studentExamResultFor(
                      courseId: entry.value.courseId,
                      examId: entry.value.examId,
                      attemptId: entry.value.attemptId,
                    ),
                  );
                },
                onRetake: () {
                  context.go(
                    Routes.studentExamAttemptFor(
                      courseId: entry.value.courseId,
                      examId: entry.value.examId,
                    ),
                  );
                },
              );
            }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Text(
                  'Showing ${rows.length} of $totalCount attempts',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => ref.invalidate(studentExamHistoryProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle get _headerStyle => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      );
}

class _StatsRow extends StatelessWidget {
  final StudentExamHistoryData history;

  const _StatsRow({required this.history});

  @override
  Widget build(BuildContext context) {
    final average = history.averageScore;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Attempts',
            value: history.totalAttempts.toString(),
            subText: '${history.gradedCount} graded attempts',
            icon: Icons.assignment_turned_in_outlined,
            iconColor: AppColors.primary,
            subTextColor: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            title: 'Average Score',
            value: average == null ? '—' : '${average.round()}%',
            subText: average == null ? 'No graded exams yet' : 'Based on graded attempts',
            icon: Icons.bar_chart_rounded,
            iconColor: AppColors.successDot,
            subTextColor: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            title: 'Pending Grading',
            value: history.pendingCount.toString(),
            subText: '${history.retakeAvailableCount} retakes available',
            icon: Icons.pending_actions_outlined,
            iconColor: AppColors.warningText,
            subTextColor: AppColors.warningText,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subText;
  final IconData icon;
  final Color iconColor;
  final Color subTextColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subText,
    required this.icon,
    required this.iconColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textTitle),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ExamHistoryRowWidget extends StatelessWidget {
  final StudentExamHistoryRow row;
  final bool isLast;
  final VoidCallback onView;
  final VoidCallback onRetake;

  const _ExamHistoryRowWidget({
    required this.row,
    required this.isLast,
    required this.onView,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = row.percentageScore;
    final progress = percentage == null ? 0.0 : (percentage / 100).clamp(0.0, 1.0).toDouble();
    final statusColor = _statusColor(row);
    final courseCode = (row.course.courseCode ?? '').trim().isEmpty ? 'COURSE' : row.course.courseCode!.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.exam.safeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textTitle),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.badgeIndigoBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        courseCode,
                        style: TextStyle(color: AppColors.badgeIndigoFg, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${row.course.title} • Attempt ${row.attempt.attemptNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(row.displayDate),
                  style: TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(row.displayDate),
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDuration(row.duration),
              style: TextStyle(
                fontSize: 13,
                color: row.duration == null ? AppColors.textHint : AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  percentage == null ? 'Not graded' : '${percentage.round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: percentage == null ? AppColors.textHint : AppColors.textTitle,
                  ),
                ),
                if (percentage != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.headerBg,
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      row.statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (row.canViewResult)
                  IconButton(
                    tooltip: 'View result',
                    onPressed: onView,
                    icon: Icon(Icons.visibility_outlined, size: 18, color: AppColors.textMuted),
                  ),
                if (row.isInProgress)
                  _SmallActionButton(
                    label: 'Continue',
                    icon: Icons.play_arrow_rounded,
                    onPressed: onRetake,
                  )
                else if (row.canRetake)
                  _SmallActionButton(
                    label: 'Retake',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetake,
                  ),
                if (!row.canViewResult && !row.isInProgress && !row.canRetake)
                  Icon(Icons.info_outline, size: 18, color: AppColors.textHint),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(StudentExamHistoryRow row) {
    if (row.isPassed) return AppColors.successDot;
    if (row.isFailed) return AppColors.errorDot;
    if (row.isPending || row.isInProgress) return AppColors.warningText;
    return AppColors.primary;
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    final hour12 = local.hour == 0 ? 12 : local.hour > 12 ? local.hour - 12 : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  static String _formatDuration(Duration? value) {
    if (value == null) return '—';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.infoBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseFilterButton extends StatelessWidget {
  final List<dynamic> courses;
  final int selectedCourseId;
  final ValueChanged<int> onChanged;

  const _CourseFilterButton({
    required this.courses,
    required this.selectedCourseId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    dynamic selectedCourse;
    if (selectedCourseId != 0) {
      for (final course in courses) {
        if (course.id == selectedCourseId) {
          selectedCourse = course;
          break;
        }
      }
    }
    final label = selectedCourse == null ? 'All Courses' : selectedCourse.title.toString();

    return PopupMenuButton<int>(
      tooltip: 'Filter by course',
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<int>(value: 0, child: Text('All Courses')),
        ...courses.map(
          (course) => PopupMenuItem<int>(
            value: course.id as int,
            child: Text(course.title.toString()),
          ),
        ),
      ],
      child: _FilterChip(label: label),
    );
  }
}

class _StatusFilterButton extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  const _StatusFilterButton({
    required this.selectedStatus,
    required this.onChanged,
  });

  static const _labels = <String, String>{
    'all': 'Status: All',
    'passed': 'Passed',
    'failed': 'Failed',
    'pending': 'Pending',
    'in_progress': 'In progress',
    'completed': 'Completed',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Filter by status',
      onSelected: onChanged,
      itemBuilder: (context) => _labels.entries
          .map((entry) => PopupMenuItem<String>(value: entry.key, child: Text(entry.value)))
          .toList(growable: false),
      child: _FilterChip(label: _labels[selectedStatus] ?? 'Status: All'),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  final bool hasFilters;

  const _EmptyHistoryState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 42, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              hasFilters ? 'No exams match your filters' : 'No exam attempts yet',
              style: TextStyle(color: AppColors.textTitle, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try changing the search, course, or status filter.'
                  : 'Submitted and in-progress exam attempts will appear here.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HistoryErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 42, color: AppColors.dangerText),
            const SizedBox(height: 12),
            Text(
              'Could not load exam history',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textTitle),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
