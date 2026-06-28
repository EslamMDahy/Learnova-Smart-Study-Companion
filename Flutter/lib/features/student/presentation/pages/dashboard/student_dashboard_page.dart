import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../../core/storage/user_storage.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/student_dashboard_models.dart';
import '../../../data/student_dashboard_providers.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(studentDashboardProvider);

    return dashboard.when(
      loading: () => const _DashboardLoading(),
      error: (error, _) => _DashboardError(
        message: error.toString(),
        onRetry: () => ref.invalidate(studentDashboardProvider),
      ),
      data: (data) => _DashboardView(
        data: data,
        onRefresh: () => ref.invalidate(studentDashboardProvider),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final StudentDashboardData data;
  final VoidCallback onRefresh;

  const _DashboardView({
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 1180;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 800 ? 20 : 32,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHero(data: data),
                const SizedBox(height: 24),
                isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MainDashboardContent(data: data),
                          const SizedBox(height: 24),
                          _SideDashboardContent(data: data),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _MainDashboardContent(data: data),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: _SideDashboardContent(data: data),
                          ),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final StudentDashboardData data;

  const _DashboardHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName(UserStorage.fullName ?? 'Student');
    final upcomingCount = data.upcomingExams.length;
    final availableCount = data.availableExams.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $firstName',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textTitle,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You have $upcomingCount upcoming assessments and $availableCount available now.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MainDashboardContent extends StatelessWidget {
  final StudentDashboardData data;

  const _MainDashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final shownCourses = data.courses.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatsGrid(data: data),
        const SizedBox(height: 32),
        _SectionHeader(
          title: 'Enrolled Courses',
          actionText: data.courses.isEmpty ? null : 'View All',
          onAction: data.courses.isEmpty
              ? null
              : () => context.go(Routes.studentCourses),
        ),
        const SizedBox(height: 16),
        if (shownCourses.isEmpty)
          _EmptyCard(
            icon: Icons.menu_book_outlined,
            title: 'No enrolled courses yet',
            message: 'When you enroll in a course, it will appear here.',
            actionText: 'Find Courses',
            onAction: () => context.go(Routes.studentCourses),
          )
        else
          _CourseCardsGrid(courses: shownCourses),
        const SizedBox(height: 24),
        _LearningInsightsCard(data: data),
      ],
    );
  }
}

class _SideDashboardContent extends StatelessWidget {
  final StudentDashboardData data;

  const _SideDashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DashboardPanel(
          title: 'Upcoming Deadlines',
          child: _DeadlineList(exams: data.upcomingExams.take(4).toList()),
        ),
        const SizedBox(height: 20),
        _DashboardPanel(
          title: 'Recent Results',
          child: const _RecentResultsList(),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final StudentDashboardData data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        title: 'Enrolled Courses',
        value: data.courses.length.toString(),
        caption: '${data.activeCoursesCount} active',
        icon: Icons.school_outlined,
      ),
      _StatItem(
        title: 'Upcoming Exams',
        value: data.upcomingExams.length.toString(),
        caption: '${data.availableExams.length} available now',
        icon: Icons.event_available_outlined,
      ),
      _StatItem(
        title: 'Question Pool',
        value: data.totalQuestionCount.toString(),
        caption: 'From published exams',
        icon: Icons.quiz_outlined,
      ),
      _StatItem(
        title: 'Assessments',
        value: data.totalPublishedExams.toString(),
        caption: data.failedExamCourseLoads == 0
            ? 'Synced with backend'
            : '${data.failedExamCourseLoads} course sync skipped',
        icon: Icons.trending_up_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 560
            ? 1
            : constraints.maxWidth < 920
                ? 2
                : 4;
        const spacing = 16.0;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _StatCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final String caption;
  final IconData icon;

  const _StatItem({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 102),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(item.icon, color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textTitle,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.successText,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textTitle,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText!,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _CourseCardsGrid extends StatelessWidget {
  final List<StudentDashboardCourse> courses;

  const _CourseCardsGrid({required this.courses});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 620
            ? 1
            : constraints.maxWidth < 960
                ? 2
                : 3;
        const spacing = 16.0;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: courses
              .map(
                (course) => SizedBox(
                  width: width,
                  child: _CourseCard(course: course),
                ),
              )
              .toList(),
        );
      },
    );
  }
}


class _CourseCoverFallback extends StatelessWidget {
  final bool showPulse;

  const _CourseCoverFallback({this.showPulse = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff073B34), Color(0xff0B1D33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: showPulse
          ? Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            )
          : null,
    );
  }
}

class _CourseCard extends StatelessWidget {
  final StudentDashboardCourse course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final coverUrl = _normalizeNetworkImageUrl(course.coverImageUrl);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 128,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (coverUrl != null)
                  Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const _CourseCoverFallback(showPulse: true);
                    },
                    errorBuilder: (_, __, ___) => const _CourseCoverFallback(),
                  )
                else
                  const _CourseCoverFallback(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.42),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: -24,
                  top: -28,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.safeCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.safeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTitle,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${course.safeInstructorName} • ${course.safeCategory}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  _titleCase(course.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => context.go(
                      '${Routes.studentCourseDetails}?courseId=${course.id}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerBg,
                      foregroundColor: AppColors.textGray,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
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

class _LearningInsightsCard extends StatelessWidget {
  final StudentDashboardData data;

  const _LearningInsightsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights(data);
    final highlightCourse = data.courses.isNotEmpty ? data.courses.first.safeTitle : 'your courses';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              Text(
                'AI Learning Insights',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textTitle,
                ),
              ),
              Text(
                'Based on your enrolled courses and assessments in ',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              Text(
                highlightCourse,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < insights.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _InsightRowItem(item: insights[i]),
          ],
        ],
      ),
    );
  }

  List<_InsightItem> _buildInsights(StudentDashboardData data) {
    final available = data.availableExams;
    final upcoming = data.upcomingExams;

    if (data.courses.isEmpty) {
      return const [
        _InsightItem(
          icon: Icons.school_outlined,
          iconColorType: _InsightColorType.info,
          title: 'Start by enrolling in a course',
          subtitle: 'Your dashboard will unlock assessments and recommendations after enrollment.',
          buttonText: 'Browse',
          route: Routes.studentCourses,
          primary: true,
        ),
      ];
    }

    final items = <_InsightItem>[];
    if (available.isNotEmpty) {
      final exam = available.first;
      items.add(
        _InsightItem(
          icon: Icons.bolt_rounded,
          iconColorType: _InsightColorType.danger,
          title: 'Ready now: ${exam.safeTitle}',
          subtitle: '${exam.courseTitle} • ${exam.totalQuestions} questions • due ${_formatShortDateTime(exam.deadline)}',
          buttonText: 'Practice Now',
          route: '${Routes.studentCourseDetails}?courseId=${exam.courseId}&examId=${exam.id}',
          primary: true,
        ),
      );
    }

    if (upcoming.isNotEmpty) {
      final exam = upcoming.first;
      items.add(
        _InsightItem(
          icon: Icons.schedule_rounded,
          iconColorType: _InsightColorType.warning,
          title: 'Upcoming: ${exam.safeTitle}',
          subtitle: '${exam.courseTitle} • ${_relativeDate(exam.deadline)}',
          buttonText: 'Review Course',
          route: '${Routes.studentCourseDetails}?courseId=${exam.courseId}',
          primary: false,
        ),
      );
    }

    if (items.length < 2 && data.courses.isNotEmpty) {
      final course = data.courses.first;
      items.add(
        _InsightItem(
          icon: Icons.menu_book_rounded,
          iconColorType: _InsightColorType.info,
          title: 'Continue learning: ${course.safeTitle}',
          subtitle: '${course.safeCode} • ${course.safeCategory}',
          buttonText: 'Continue',
          route: '${Routes.studentCourseDetails}?courseId=${course.id}',
          primary: items.isEmpty,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _InsightItem(
          icon: Icons.check_circle_outline_rounded,
          iconColorType: _InsightColorType.success,
          title: 'All caught up',
          subtitle: 'No published assessments are due right now.',
          buttonText: 'My Courses',
          route: Routes.studentCourses,
          primary: false,
        ),
      );
    }

    return items.take(2).toList();
  }
}

enum _InsightColorType { danger, warning, info, success }

class _InsightItem {
  final IconData icon;
  final _InsightColorType iconColorType;
  final String title;
  final String subtitle;
  final String buttonText;
  final String route;
  final bool primary;

  const _InsightItem({
    required this.icon,
    required this.iconColorType,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.route,
    required this.primary,
  });
}


class _InsightColors {
  final Color background;
  final Color foreground;

  const _InsightColors(this.background, this.foreground);
}

class _InsightRowItem extends StatelessWidget {
  final _InsightItem item;

  const _InsightRowItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = _insightColors(item.iconColorType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.background,
            child: Icon(item.icon, color: colors.foreground, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () => context.go(item.route),
              style: ElevatedButton.styleFrom(
                backgroundColor: item.primary ? AppColors.primary : AppColors.cardBg,
                foregroundColor: item.primary ? Colors.white : AppColors.textGray,
                elevation: 0,
                side: item.primary ? BorderSide.none : BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                item.buttonText,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _InsightColors _insightColors(_InsightColorType type) {
    switch (type) {
      case _InsightColorType.danger:
        return _InsightColors(AppColors.dangerBorder, AppColors.errorDot);
      case _InsightColorType.warning:
        return _InsightColors(AppColors.warningSoftBg, AppColors.warningText);
      case _InsightColorType.success:
        return _InsightColors(AppColors.successBg, AppColors.successText);
      case _InsightColorType.info:
        return _InsightColors(AppColors.infoBg, AppColors.infoText);
    }
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textTitle,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DeadlineList extends StatelessWidget {
  final List<StudentDashboardExam> exams;

  const _DeadlineList({required this.exams});

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const _CompactEmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No deadlines yet',
        message: 'Published exams will appear here when your instructor schedules them.',
      );
    }

    return Column(
      children: [
        for (final exam in exams) _DeadlineRow(exam: exam),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: OutlinedButton(
            onPressed: () => context.go(Routes.studentCourses),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: Text(
              'View Courses',
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final StudentDashboardExam exam;

  const _DeadlineRow({required this.exam});

  @override
  Widget build(BuildContext context) {
    final date = exam.deadline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _monthAbbr(date),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _dayNumber(date),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.safeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textTitle,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${exam.courseTitle} • ${_formatTime(date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentResultsList extends StatelessWidget {
  const _RecentResultsList();

  @override
  Widget build(BuildContext context) {
    return const _CompactEmptyState(
      icon: Icons.insights_outlined,
      title: 'No graded results yet',
      message: 'Your submitted and graded exams will appear here.',
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.infoBg,
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textTitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          if (actionText != null) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CompactEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textTitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 360, height: 38, radius: 10),
          const SizedBox(height: 10),
          _SkeletonBox(width: 440, height: 16, radius: 8),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 560
                  ? 1
                  : constraints.maxWidth < 920
                      ? 2
                      : 4;
              const spacing = 16.0;
              final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(
                  4,
                  (_) => _SkeletonBox(width: width, height: 102, radius: 14),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          _SkeletonBox(width: double.infinity, height: 220, radius: 16),
          const SizedBox(height: 20),
          _SkeletonBox(width: double.infinity, height: 160, radius: 16),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 520,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.dangerBg,
              child: Icon(Icons.cloud_off_rounded, color: AppColors.dangerText),
            ),
            const SizedBox(height: 14),
            Text(
              'Could not load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textTitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}


String? _normalizeNetworkImageUrl(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;

  final withScheme = raw.startsWith('//') ? 'https:$raw' : raw;
  if (!withScheme.startsWith('http://') && !withScheme.startsWith('https://')) {
    return null;
  }

  final parsed = Uri.tryParse(withScheme);
  if (parsed == null || !parsed.hasAuthority) return null;
  return Uri.encodeFull(withScheme);
}

String _firstName(String name) {
  final clean = name.trim();
  if (clean.isEmpty) return 'Student';
  return clean.split(RegExp(r'\s+')).first;
}

String _titleCase(String value) {
  final clean = value.trim().replaceAll('_', ' ');
  if (clean.isEmpty) return 'Unknown';
  return clean
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _monthAbbr(DateTime? date) {
  if (date == null) return '--';
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return months[date.toLocal().month - 1];
}

String _dayNumber(DateTime? date) {
  if (date == null) return '--';
  return date.toLocal().day.toString().padLeft(2, '0');
}

String _formatTime(DateTime? date) {
  if (date == null) return 'No time';
  final local = date.toLocal();
  final hour12 = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $period';
}

String _formatShortDateTime(DateTime? date) {
  if (date == null) return 'not scheduled';
  return '${_monthAbbr(date)} ${_dayNumber(date)} • ${_formatTime(date)}';
}

String _relativeDate(DateTime? date) {
  if (date == null) return 'Not scheduled';
  final now = DateTime.now();
  final local = date.toLocal();
  final diff = local.difference(now);
  final absolute = diff.abs();

  if (absolute.inMinutes < 60) {
    final minutes = absolute.inMinutes <= 0 ? 1 : absolute.inMinutes;
    return diff.isNegative ? '$minutes min ago' : 'in $minutes min';
  }
  if (absolute.inHours < 24) {
    return diff.isNegative ? '${absolute.inHours} hours ago' : 'in ${absolute.inHours} hours';
  }
  if (absolute.inDays < 7) {
    return diff.isNegative ? '${absolute.inDays} days ago' : 'in ${absolute.inDays} days';
  }
  return _formatShortDateTime(local);
}
