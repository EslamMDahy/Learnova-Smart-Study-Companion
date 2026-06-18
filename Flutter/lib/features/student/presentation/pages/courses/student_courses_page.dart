import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/student_courses_models.dart';
import '../../../data/student_courses_providers.dart';
import 'student_course_widgets.dart';

class StudentCoursesPage extends ConsumerStatefulWidget {
  const StudentCoursesPage({super.key});

  @override
  ConsumerState<StudentCoursesPage> createState() => _StudentCoursesPageState();
}

class _StudentCoursesPageState extends ConsumerState<StudentCoursesPage> {
  static const int _pageSize = 6;

  int _pageIndex = 0;
  _StudentCoursesViewMode _viewMode = _StudentCoursesViewMode.grid;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(studentCoursesControllerProvider.notifier).loadEnrolled();
    });
  }

  Future<void> _refresh() async {
    await ref
        .read(studentCoursesControllerProvider.notifier)
        .loadEnrolled(force: true);
  }

  void _openCourseWorkspace(StudentCourse course) {
    context.go('${Routes.studentCourseDetails}?courseId=${course.id}');
  }

  void _goToPage(int index) {
    if (index == _pageIndex) return;
    setState(() => _pageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentCoursesControllerProvider);
    final courses = state.enrolledCourses;
    final totalPages = courses.isEmpty ? 1 : (courses.length / _pageSize).ceil();
    final safePageIndex = _pageIndex.clamp(0, totalPages - 1).toInt();
    final visibleCourses = courses
        .skip(safePageIndex * _pageSize)
        .take(_pageSize)
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 720 ? 20.0 : 32.0;
          final verticalPadding = constraints.maxWidth < 720 ? 28.0 : 56.0;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MyCoursesTitleBlock(),
                    const SizedBox(height: 30),
                    _CoursesToolbar(
                      count: courses.length,
                      viewMode: _viewMode,
                      onViewModeChanged: (mode) {
                        setState(() => _viewMode = mode);
                      },
                    ),
                    const SizedBox(height: 24),
                    _EnrolledCoursesArea(
                      state: state,
                      courses: visibleCourses,
                      viewMode: _viewMode,
                      onRetry: _refresh,
                      onDiscover: () => context.go(Routes.studentDiscoverCourses),
                      onCourseTap: _openCourseWorkspace,
                    ),
                    if (courses.length > _pageSize) ...[
                      const SizedBox(height: 48),
                      Center(
                        child: _CoursesPagination(
                          pageIndex: safePageIndex,
                          totalPages: totalPages,
                          onPageSelected: _goToPage,
                        ),
                      ),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MyCoursesTitleBlock extends StatelessWidget {
  const _MyCoursesTitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Courses',
          style: TextStyle(
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: AppColors.textTitle,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage your curriculum, AI assessments, and student cohorts.',
          style: TextStyle(
            fontSize: 14.5,
            height: 1.35,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CoursesToolbar extends StatelessWidget {
  final int count;
  final _StudentCoursesViewMode viewMode;
  final ValueChanged<_StudentCoursesViewMode> onViewModeChanged;

  const _CoursesToolbar({
    required this.count,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $count course${count == 1 ? '' : 's'}',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            height: 1,
          ),
        ),
        Row(
          children: [
            _TopIconButton(
              icon: Icons.grid_view_rounded,
              active: viewMode == _StudentCoursesViewMode.grid,
              onTap: () => onViewModeChanged(_StudentCoursesViewMode.grid),
            ),
            const SizedBox(width: 8),
            _TopIconButton(
              icon: Icons.view_list_rounded,
              active: viewMode == _StudentCoursesViewMode.list,
              onTap: () => onViewModeChanged(_StudentCoursesViewMode.list),
            ),
          ],
        ),
      ],
    );
  }
}

class _EnrolledCoursesArea extends StatelessWidget {
  final StudentCoursesState state;
  final List<StudentCourse> courses;
  final _StudentCoursesViewMode viewMode;
  final VoidCallback onRetry;
  final VoidCallback onDiscover;
  final ValueChanged<StudentCourse> onCourseTap;

  const _EnrolledCoursesArea({
    required this.state,
    required this.courses,
    required this.viewMode,
    required this.onRetry,
    required this.onDiscover,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const StudentCoursesLoadingPanel(
        message: 'Loading your courses...',
      );
    }

    if (state.enrolledError != null && state.enrolledCourses.isEmpty) {
      return StudentCoursesErrorPanel(
        message: state.enrolledError!,
        onRetry: onRetry,
      );
    }

    if (state.enrolledCourses.isEmpty) {
      return StudentCoursesEmptyPanel(
        icon: Icons.menu_book_outlined,
        title: 'No courses yet',
        description:
            'Accept an instructor invitation or discover public courses to start building your course list.',
        actionLabel: 'Discover Courses',
        onAction: onDiscover,
      );
    }

    if (viewMode == _StudentCoursesViewMode.list) {
      return _StudentCoursesList(
        courses: courses,
        onCourseTap: onCourseTap,
      );
    }

    return StudentCourseGrid(
      courses: courses,
      enrollingIds: state.enrollingCourseIds,
      onCourseTap: onCourseTap,
      onEnroll: null,
    );
  }
}

class _StudentCoursesList extends StatelessWidget {
  final List<StudentCourse> courses;
  final ValueChanged<StudentCourse> onCourseTap;

  const _StudentCoursesList({
    required this.courses,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < courses.length; i++) ...[
          _StudentCourseListTile(
            course: courses[i],
            onTap: () => onCourseTap(courses[i]),
          ),
          if (i != courses.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _StudentCourseListTile extends StatelessWidget {
  final StudentCourse course;
  final VoidCallback onTap;

  const _StudentCourseListTile({
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withOpacity(0.72)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowThin,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: (course.coverImageUrl ?? '').trim().isNotEmpty
                      ? Image.network(
                          course.coverImageUrl!.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CourseThumbFallback(),
                        )
                      : _CourseThumbFallback(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.safeCode,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.safeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.safeDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.fieldDisabledBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Enrolled',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? AppColors.primarySoft : AppColors.cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? AppColors.primary.withOpacity(0.14) : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _CoursesPagination extends StatelessWidget {
  final int pageIndex;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  const _CoursesPagination({
    required this.pageIndex,
    required this.totalPages,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PaginationArrow(
          icon: Icons.chevron_left_rounded,
          enabled: pageIndex > 0,
          onTap: () => onPageSelected(pageIndex - 1),
        ),
        const SizedBox(width: 8),
        for (final page in pages) ...[
          if (page == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Text(
                '...',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            _PaginationNumber(
              label: '${page + 1}',
              active: page == pageIndex,
              onTap: () => onPageSelected(page),
            ),
          const SizedBox(width: 8),
        ],
        _PaginationArrow(
          icon: Icons.chevron_right_rounded,
          enabled: pageIndex < totalPages - 1,
          onTap: () => onPageSelected(pageIndex + 1),
        ),
      ],
    );
  }

  List<int?> _visiblePages() {
    if (totalPages <= 4) {
      return List<int>.generate(totalPages, (index) => index);
    }

    if (pageIndex <= 2) {
      return [0, 1, 2, null, totalPages - 1];
    }

    if (pageIndex >= totalPages - 3) {
      return [0, null, totalPages - 3, totalPages - 2, totalPages - 1];
    }

    return [0, null, pageIndex, null, totalPages - 1];
  }
}

class _PaginationNumber extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PaginationNumber({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            color: enabled ? AppColors.textMuted : AppColors.textHint,
            size: 20,
          ),
        ),
      ),
    );
  }
}


class _CourseThumbFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: AppColors.primarySoft,
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}

enum _StudentCoursesViewMode { grid, list }
