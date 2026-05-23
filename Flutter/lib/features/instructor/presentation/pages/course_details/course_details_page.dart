import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/network/error_mapper.dart';
import '../../../../../core/routing/routes.dart';
import '../../../data/courses_models.dart';
import '../../../data/courses_providers.dart';
import '../../controllers/course_details_controller.dart';
import '../../widgets/course_tabs/overview_tab.dart';
import '../../widgets/course_tabs/materials_tab.dart';
import '../../widgets/course_tabs/outcomes_tab.dart';
import '../../widgets/course_tabs/question_bank_tab.dart';
import '../../widgets/course_tabs/students_tab.dart';
import '../../controllers/selected_course_provider.dart';
import '../../course_route_identity.dart';

enum CourseDetailsTab { overview, materials, outcomes, questionBank, students }

class CourseDetailsPage extends ConsumerStatefulWidget {
  final String courseSlug;

  /// Provide this when the course is already in memory (normal navigation).
  /// When null the page self-loads via [selectedCourseByIdProvider].
  final MyCourseItem? cachedCourse;

  /// Numeric course id used as the fallback key for the API fetch when
  /// [cachedCourse] is null (e.g. after a browser refresh).
  final int? cachedCourseId;

  /// Route-backed active tab. Each tab has its own URL and lazy load boundary.
  final CourseDetailsTab initialTab;

  const CourseDetailsPage({
    super.key,
    required this.courseSlug,
    this.cachedCourse,
    this.cachedCourseId,
    this.initialTab = CourseDetailsTab.overview,
  });

  @override
  ConsumerState<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends ConsumerState<CourseDetailsPage> {
  int _currentIndex = 0;
  final Set<String> _loadedTabKeys = <String>{};

  Widget _buildActivePage(MyCourseItem course) {
    switch (widget.initialTab) {
      case CourseDetailsTab.overview:
        return CourseOverviewTab(
          key: PageStorageKey('course-overview-tab'),
          course: course,
        );
      case CourseDetailsTab.materials:
        return CourseMaterialsTab(
          key: PageStorageKey('course-materials-tab'),
          course: course,
        );
      case CourseDetailsTab.outcomes:
        return CourseOutcomesTab(
          key: PageStorageKey('course-outcomes-tab'),
          course: course,
        );
      case CourseDetailsTab.questionBank:
        return CourseQuestionBankTab(
          key: PageStorageKey('course-question-bank-tab'),
          course: course,
        );
      case CourseDetailsTab.students:
        return CourseStudentsTab(
          key: PageStorageKey('course-students-tab'),
          course: course,
        );
    }
  }

  static const _tabs = [
    _TabDef(icon: Icons.dashboard_outlined, label: 'Overview'),
    _TabDef(icon: Icons.folder_open_outlined, label: 'Materials'),
    _TabDef(icon: Icons.flag_outlined, label: 'Outcomes'),
    _TabDef(icon: Icons.quiz_outlined, label: 'Question Bank'),
    _TabDef(icon: Icons.people_outline_rounded, label: 'Students'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab.index;
    final course = widget.cachedCourse;
    if (course != null) _loadActiveTabData(course);
  }

  @override
  void didUpdateWidget(covariant CourseDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _currentIndex = widget.initialTab.index;
    }

    final course = widget.cachedCourse;
    if (course != null &&
        (oldWidget.initialTab != widget.initialTab ||
            oldWidget.cachedCourse?.id != course.id)) {
      _loadActiveTabData(course);
    }
  }

  void _loadActiveTabData(MyCourseItem course) {
    final tab = widget.initialTab;
    final key = '${course.id}:${tab.name}';
    if (!_loadedTabKeys.add(key)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notifier = ref.read(courseDetailsControllerProvider(course.id).notifier);

      switch (tab) {
        case CourseDetailsTab.overview:
          // Overview only needs the course structure. Do not preload materials,
          // topics, questions, outcomes, or invitations from here.
          await notifier.loadModules();
          break;
        case CourseDetailsTab.materials:
          // Materials tab starts with modules; each module/material branch loads
          // its own materials/topics only when opened by the user.
          await notifier.loadModules();
          break;
        case CourseDetailsTab.outcomes:
        case CourseDetailsTab.questionBank:
        case CourseDetailsTab.students:
          // These tabs own their loading in their own widgets.
          break;
      }
    });
  }

  String _routeForTab(MyCourseItem course, int index) {
    final slug = buildCourseRouteSlug(course);
    final tab = CourseDetailsTab.values[index];
    switch (tab) {
      case CourseDetailsTab.overview:
        return Routes.courseDetails(slug);
      case CourseDetailsTab.materials:
        return Routes.courseMaterials(slug);
      case CourseDetailsTab.outcomes:
        return Routes.courseOutcomes(slug);
      case CourseDetailsTab.questionBank:
        return Routes.courseQuestionBank(slug);
      case CourseDetailsTab.students:
        return Routes.courseStudents(slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (widget.cachedCourse != null) {
      return _buildContent(widget.cachedCourse!);
    }

    if (widget.cachedCourseId != null) {
      final asyncCourse =
          ref.watch(selectedCourseByIdProvider(widget.cachedCourseId!));
      return asyncCourse.when(
        loading: () => _buildLoadingShell(),
        error: (e, _) => _buildErrorShell(mapApiFailure(e).message),
        data: (course) => _buildContent(course),
      );
    }

    return _buildErrorShell(
      'Course could not be loaded. Please go back and reopen it.',
    );
  }

  // ── Loading shell ───────────────────────────────────────────────────────────

  Widget _buildLoadingShell() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Center(
          child: SizedBox(
            height: 36,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    ]);
  }

  // ── Error shell ─────────────────────────────────────────────────────────────

  Widget _buildErrorShell(String message) {
    return Column(children: [
      Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    color: AppColors.dangerText, size: 40),
                SizedBox(height: 12),
                Text(
                  'Could not load course',
                  style: AppTextStyles.sectionTitle,
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  style: AppTextStyles.muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  // ── Main content ────────────────────────────────────────────────────────────

  Widget _buildContent(MyCourseItem course) {
    _loadActiveTabData(course);
    return Column(children: [
      // ── Tab header — centered, does NOT stretch to full width ─────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Center(
          child: _PillTabBar(
            tabs: _tabs,
            currentIndex: _currentIndex,
            onTap: (i) {
              if (i == _currentIndex) return;
              SelectedCourseCache.set(course);
              context.go(_routeForTab(course, i));
            },
          ),
        ),
      ),
      Expanded(
        child: KeyedSubtree(
          key: ValueKey('course-${course.id}-${widget.initialTab.name}'),
          child: _buildActivePage(course),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pill tab bar — wraps its content, centered in the header
// ─────────────────────────────────────────────────────────────────────────────
class _PillTabBar extends StatelessWidget {
  final List<_TabDef> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PillTabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(tabs.length, (i) {
            return _PillTab(
              icon: tabs[i].icon,
              label: tabs[i].label,
              selected: i == currentIndex,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Individual pill tab
// ─────────────────────────────────────────────────────────────────────────────
class _PillTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PillTab> createState() => _PillTabState();
}

class _PillTabState extends State<_PillTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.cardBg
                : _hovered
                    ? AppColors.hoverBg
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.selected
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
              SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: widget.selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: widget.selected
                      ? AppColors.textTitle
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
class _TabDef {
  final IconData icon;
  final String label;
  const _TabDef({required this.icon, required this.label});
}
