import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learnova/core/routing/routes.dart';
import 'package:learnova/core/network/error_mapper.dart';
import 'package:learnova/core/ui/toast.dart';
import 'package:learnova/core/utils/image_picker_bytes.dart';
import '../../data/courses_models.dart';
import '../../data/course_vocabulary.dart';
import 'package:learnova/shared/widgets/app_ui_components.dart';
import 'invite_students_dialog.dart';
import '../controllers/selected_course_provider.dart';
import '../course_route_identity.dart';

part 'instructor_course_cards.dart';

typedef CourseUpdateAction = Future<MyCourseItem> Function(
  MyCourseItem course,
  CourseUpdateRequest payload,
);
typedef CoursePublishAction = Future<MyCourseItem> Function(MyCourseItem course);
typedef CourseArchiveAction = Future<MyCourseItem> Function(MyCourseItem course);
typedef CourseDeleteAction = Future<void> Function(MyCourseItem course);
typedef CourseCoverUploadAction = Future<MyCourseItem> Function({
  required MyCourseItem course,
  required List<int> bytes,
  required String? contentType,
  required String filename,
});

class InstructorCourseContent extends StatefulWidget {
  final VoidCallback? onCreateNewCourse;
  final VoidCallback? onRefresh;
  final bool loading;
  final String? errorText;
  final List<MyCourseItem> courses;
  final CourseUpdateAction? onUpdateCourse;
  final CoursePublishAction? onPublishCourse;
  final CourseArchiveAction? onArchiveCourse;
  final CourseDeleteAction? onDeleteCourse;
  final CourseCoverUploadAction? onUploadCover;

  const InstructorCourseContent({
    super.key,
    this.onCreateNewCourse,
    this.onRefresh,
    this.loading = false,
    this.errorText,
    this.courses = const [],
    this.onUpdateCourse,
    this.onPublishCourse,
    this.onArchiveCourse,
    this.onDeleteCourse,
    this.onUploadCover,
  });

  @override
  State<InstructorCourseContent> createState() =>
      _InstructorCourseContentState();
}
class _InstructorCourseContentState extends State<InstructorCourseContent> {
  final _search = TextEditingController();
  Timer? _searchDebounce;

  String _searchText = '';

  String selectedSemester = 'All Semesters';
  String selectedStatus = 'All Statuses';
  String selectedType = 'All Types';

  // ---- Caches (performance)
  List<MyCourseItem> _cachedFiltered = [];
  String _cacheKey = '';

  int _totalCoursesCached = 0;
  int _activeStudentsTotalCached = 0;
  int _pendingInvitesTotalCached = 0;

  @override
  void initState() {
    super.initState();
    _recomputeTotals();
  }

  @override
  void didUpdateWidget(covariant InstructorCourseContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the list changed (e.g. fetched from API), recompute totals and clear the cache key
    if (!identical(oldWidget.courses, widget.courses) ||
        oldWidget.courses.length != widget.courses.length) {
      _recomputeTotals();
      _cacheKey = '';
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _recomputeTotals() {
    _totalCoursesCached = widget.courses.length;

    _activeStudentsTotalCached =
        widget.courses.fold<int>(0, (sum, c) => sum + (c.enrollmentCount ?? 0));

    _pendingInvitesTotalCached =
        widget.courses.fold<int>(0, (sum, c) => sum + (c.pendingInvites ?? 0));
  }

  void _recomputeFiltered() {
    final key =
        '${_searchText.trim().toLowerCase()}|$selectedSemester|$selectedStatus|$selectedType|${widget.courses.length}';
    if (key == _cacheKey) return;
    _cacheKey = key;

    final q = _searchText.trim().toLowerCase();

    bool statusOk(MyCourseItem c) {
      if (selectedStatus == 'All Statuses') return true;
      return c.status.trim().toLowerCase() == selectedStatus.toLowerCase();
    }

    bool semesterOk(MyCourseItem c) {
      if (selectedSemester == 'All Semesters') return true;
      
      return true; 
    }

    bool typeOk(MyCourseItem c) {
      if (selectedType == 'All Types') return true;
      return c.courseType.trim().toLowerCase() == selectedType.toLowerCase();
    }

    bool searchOk(MyCourseItem c) {
      if (q.isEmpty) return true;

      final title = c.title.toLowerCase();
      final code = c.safeCourseCode
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '-')
          .replaceAll(RegExp(r'[^a-z0-9\-]'), '');

      return title.contains(q) || code.contains(q);
    }

    _cachedFiltered = widget.courses.where((c) {
      return statusOk(c) && semesterOk(c) && typeOk(c) && searchOk(c);
    }).toList(growable: false);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _searchText = value;
        _cacheKey = ''; // ensure filter recomputation on next render
      });
    });
  }

  void _clearAll() {
    _search.clear();
    setState(() {
      _searchText = '';
      selectedSemester = 'All Semesters';
      selectedStatus = 'All Statuses';
      selectedType = 'All Types';
      _cacheKey = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    _recomputeFiltered();
    final courses = _cachedFiltered;

    final hasActiveFilters = (_searchText.trim().isNotEmpty) ||
        selectedSemester != 'All Semesters' ||
        selectedStatus != 'All Statuses' ||
        selectedType != 'All Types';

    return Container(
      color: _CourseTokens.pageBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;

          int columns = 4;
          if (screenW < 1200) columns = 3;
          if (screenW < 900) columns = 2;
          if (screenW < 600) columns = 1;

          final maxContentWidth = _clamp(screenW - 220, 1180, 1560);

          final horizontalPadding = screenW >= 1600
              ? 24.0
              : screenW >= 1400
                  ? 32.0
                  : screenW >= 1100
                      ? 48.0
                      : 20.0;

          final topPadding = screenW < 900 ? 18.0 : 26.0;
          final isNarrow = constraints.maxWidth < 1100;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 28),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const _Breadcrumb(),
                      const SizedBox(height: 14),
                      _HeaderRow(
                        onCreateNewCourse: widget.onCreateNewCourse,
                        onRefresh: widget.onRefresh,
                      ),
                      const SizedBox(height: 18),
                      _StatsRow(
                        totalCourses: _totalCoursesCached,
                        activeStudents: _activeStudentsTotalCached,
                        pendingInvites: _pendingInvitesTotalCached,
                      ),
                      const SizedBox(height: 16),
                      _CoursesFiltersBar(
                        controller: _search,
                        isNarrow: isNarrow,
                        selectedSemester: selectedSemester,
                        selectedStatus: selectedStatus,
                        selectedType: selectedType,
                        onSearchChanged: _onSearchChanged,
                        onSemesterChanged: (v) =>
                            setState(() => selectedSemester = v),
                        onStatusChanged: (v) =>
                            setState(() => selectedStatus = v),
                        onTypeChanged: (v) => setState(() => selectedType = v),
                        onMoreFilters: () {},
                        onRefresh: widget.onRefresh ?? () {},
                      ),
                      const SizedBox(height: 12),
                      _ActiveFiltersChips(
                        searchText: _searchText,
                        selectedSemester: selectedSemester,
                        selectedStatus: selectedStatus,
                        selectedType: selectedType,
                        onClearAll: _clearAll,
                        onClearSearch: () {
                          _search.clear();
                          setState(() {
                            _searchText = '';
                            _cacheKey = '';
                          });
                        },
                        onClearSemester: () => setState(() {
                          selectedSemester = 'All Semesters';
                          _cacheKey = '';
                        }),
                        onClearStatus: () => setState(() {
                          selectedStatus = 'All Statuses';
                          _cacheKey = '';
                        }),
                        onClearType: () => setState(() {
                          selectedType = 'All Types';
                          _cacheKey = '';
                        }),
                      ),
                      if ((widget.errorText ?? '').trim().isNotEmpty) ...[
                        _InlineErrorBanner(
                          message: widget.errorText!.trim(),
                          onRetry: widget.onRefresh,
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 18),
                      _CoursesGrid(
                        columns: columns,
                        courses: courses,
                        loading: widget.loading,
                        hasAnyCourses: widget.courses.isNotEmpty,
                        hasActiveFilters: hasActiveFilters,
                        onClearFilters: _clearAll,
                        onCreateFirstCourse: widget.onCreateNewCourse,
                        onUpdateCourse: widget.onUpdateCourse,
                        onPublishCourse: widget.onPublishCourse,
                        onArchiveCourse: widget.onArchiveCourse,
                        onDeleteCourse: widget.onDeleteCourse,
                        onUploadCover: widget.onUploadCover,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
// ==================== Filters Bar ====================

class _CoursesFiltersBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isNarrow;

  final String selectedSemester;
  final String selectedStatus;
  final String selectedType;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSemesterChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onTypeChanged;

  final VoidCallback onMoreFilters;
  final VoidCallback onRefresh;

  const _CoursesFiltersBar({
    required this.controller,
    required this.isNarrow,
    required this.selectedSemester,
    required this.selectedStatus,
    required this.selectedType,
    required this.onSearchChanged,
    required this.onSemesterChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onMoreFilters,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final search = FigmaUmSearch40(
      controller: controller,
      onChanged:  onSearchChanged,
    );

    final semesterDrop = FigmaUmDropdown40(
      width: isNarrow ? 170 : 158,
      value: selectedSemester,
      items: [
        'All Semesters',
        'Fall 2023',
        'Spring 2024',
        'Fall 2024',
        'Spring 2025',
      ],
      onChanged: onSemesterChanged,
    );

    final statusDrop = FigmaUmDropdown40(
      width: isNarrow ? 158 : 146,
      value: selectedStatus,
      items: ['All Statuses', 'active', 'draft', 'archived'],
      onChanged: onStatusChanged,
    );

    final typeDrop = FigmaUmDropdown40(
      width: isNarrow ? 140 : 128,
      value: selectedType,
      items: ['All Types', 'lecture', 'seminar', 'lab'],
      onChanged: onTypeChanged,
    );

    return Container(
      height: isNarrow ? null : 56,
      padding: EdgeInsets.symmetric(
          horizontal: 16, vertical: isNarrow ? 12 : 0,),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.borderGray),
        boxShadow: [
          const BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),),
        ],
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: 12),
                Row(children: [
                  semesterDrop,
                  const SizedBox(width: 10),
                  statusDrop,
                  const SizedBox(width: 10),
                  typeDrop,
                ],),
              ],
            )
          : Row(children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              semesterDrop,
              const SizedBox(width: 10),
              statusDrop,
              const SizedBox(width: 10),
              typeDrop,
            ],),
    );
  }
}

// ==================== Active Filter Chips ====================

class _ActiveFiltersChips extends StatelessWidget {
  final String searchText;
  final String selectedSemester;
  final String selectedStatus;
  final String selectedType;

  final VoidCallback onClearAll;
  final VoidCallback onClearSearch;
  final VoidCallback onClearSemester;
  final VoidCallback onClearStatus;
  final VoidCallback onClearType;

  const _ActiveFiltersChips({
    required this.searchText,
    required this.selectedSemester,
    required this.selectedStatus,
    required this.selectedType,
    required this.onClearAll,
    required this.onClearSearch,
    required this.onClearSemester,
    required this.onClearStatus,
    required this.onClearType,
  });

  bool get _hasAny =>
      (searchText.trim().isNotEmpty) ||
      selectedSemester != 'All Semesters' ||
      selectedStatus   != 'All Statuses'  ||
      selectedType     != 'All Types';

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();

    Widget chip(String label, VoidCallback onDeleted) {
      return InputChip(
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 12,),),
        onDeleted:       onDeleted,
        deleteIcon:      const Icon(Icons.close_rounded, size: 16),
        backgroundColor: AppColors.headerBg,
        side:  BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing:            10,
        runSpacing:         10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (searchText.trim().isNotEmpty)
            chip('Search: "${searchText.trim()}"', onClearSearch),
          if (selectedSemester != 'All Semesters')
            chip('Semester: $selectedSemester', onClearSemester),
          if (selectedStatus != 'All Statuses')
            chip('Status: $selectedStatus', onClearStatus),
          if (selectedType != 'All Types')
            chip('Type: $selectedType', onClearType),
          TextButton.icon(
            onPressed: onClearAll,
            icon:  const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Clear all',
                style: TextStyle(fontWeight: FontWeight.w900),),
            style: TextButton.styleFrom(
                foregroundColor: _CourseTokens.blue,),
          ),
        ],
      ),
    );
  }
}

// ==================== Helpers ====================

double _clamp(double v, double min, double max) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}

// ==================== Design Tokens ====================

class _CourseTokens {
  static Color get pageBg => AppColors.pageBg;
  static Color get cardBg => AppColors.cardBg;
  static Color get border => AppColors.borderGray;
  static Color get divider => AppColors.headerBg;

  static Color get textPrimary => AppColors.textTitle;
  static Color get textMuted => AppColors.textMuted;
  static Color get textHint => AppColors.textHint;

  static Color get blue => AppColors.primary;

  static const radiusCard       = 12.0;
  static const statCardHeight   = 88.0;
  static const courseCardHeight = 322.0;
  static const heroHeight       = 128.0;

  static const hoverShadow = [
    BoxShadow(
        color: Color(0x14000000), blurRadius: 26, offset: Offset(0, 14),),
  ];
}

// ==================== Breadcrumb ====================

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.home_rounded, size: 14, color: _CourseTokens.textHint),
        const SizedBox(width: 8),
        Text('Home',
            style: TextStyle(
                color:      _CourseTokens.textHint,
                fontSize:   12,
                fontWeight: FontWeight.w600,),),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded,
            size: 16, color: Color(0xFFCBD5E1),),
        const SizedBox(width: 8),
        Text('Courses Management',
            style: TextStyle(
                color:      _CourseTokens.textHint,
                fontSize:   12,
                fontWeight: FontWeight.w600,),),
      ],
    );
  }
}

// ==================== Header Row ====================

class _HeaderRow extends StatelessWidget {
  final VoidCallback? onCreateNewCourse;
  final VoidCallback? onRefresh;

  const _HeaderRow({this.onCreateNewCourse, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final compact = c.maxWidth < 820;

      final left = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Courses',
              style: TextStyle(
                  fontSize:   30,
                  fontWeight: FontWeight.w900,
                  color:      _CourseTokens.textPrimary,
                  height:     1.05,),),
          const SizedBox(height: 6),
          Text(
              'Manage your curriculum, AI assessments, and student cohorts.',
              style: TextStyle(
                  color:      _CourseTokens.textMuted,
                  fontSize:   13.2,
                  fontWeight: FontWeight.w600,),),
        ],
      );

      final btn = _PrimaryButton(onPressed: onCreateNewCourse);

      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            left,
            const SizedBox(height: 14),
            Align(alignment: Alignment.centerLeft, child: btn),
          ],
        );
      }

      return Row(children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        btn,
      ],);
    },);
  }
}

class _PrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.onPressed});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit:  (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: hover ? _CourseTokens.hoverShadow : [],
        ),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon:  const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text('Create New Course',
              style: TextStyle(
                  height: 1.0,
                  leadingDistribution: TextLeadingDistribution.even,
                  fontSize:   12.6,
                  fontWeight: FontWeight.w800,
                  color:      Colors.white,),),
          style: ElevatedButton.styleFrom(
            alignment: Alignment.center,
            backgroundColor: _CourseTokens.blue,
            elevation:   0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12,),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),),
          ),
        ),
      ),
    );
  }
}

// ==================== Stats Row ====================

class _StatsRow extends StatelessWidget {
  final int totalCourses;
  final int activeStudents;
  final int pendingInvites;

  const _StatsRow({
    required this.totalCourses,
    required this.activeStudents,
    required this.pendingInvites,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wrap = c.maxWidth < 900;

      final cards = [
        _MiniStatCard(
          title:     'TOTAL COURSES',
          value:     totalCourses.toString(),
          icon:      Icons.folder_outlined,
          iconBg:    const Color(0xFFEAF2FF),
          iconColor: AppColors.primary,
        ),
        _MiniStatCard(
          title:     'ACTIVE STUDENTS',
          value:     activeStudents.toString(),
          icon:      Icons.people_outline_rounded,
          iconBg:    const Color(0xFFE9FBF1),
          iconColor: AppColors.successText,
        ),
        _MiniStatCard(
          title:     'PENDING INVITES',
          value:     pendingInvites.toString(),
          icon:      Icons.mail_outline_rounded,
          iconBg:    const Color(0xFFFFF4DB),
          iconColor: const Color(0xFFF59E0B),
        ),
      ];

      if (!wrap) {
        return Row(children: [
          Expanded(
              child: SizedBox(
                  height: _CourseTokens.statCardHeight,
                  child: cards[0],),),
          const SizedBox(width: 16),
          Expanded(
              child: SizedBox(
                  height: _CourseTokens.statCardHeight,
                  child: cards[1],),),
          const SizedBox(width: 16),
          Expanded(
              child: SizedBox(
                  height: _CourseTokens.statCardHeight,
                  child: cards[2],),),
        ],);
      }

      return Wrap(
        spacing:    16,
        runSpacing: 16,
        children: cards
            .map((w) => SizedBox(
                width:  (c.maxWidth - 16) / 2,
                height: _CourseTokens.statCardHeight,
                child:  w,),)
            .toList(),
      );
    },);
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color:         _CourseTokens.textHint,
                      fontSize:      10.4,
                      fontWeight:    FontWeight.w800,
                      letterSpacing: 0.35,),),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      color:      _CourseTokens.textPrimary,
                      fontSize:   24,
                      fontWeight: FontWeight.w900,
                      height:     1.0,),),
            ],
          ),
        ),
        Container(
          width:  34,
          height: 34,
          decoration: BoxDecoration(
            color:        iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ],),
    );
  }
}


// ==================== Courses Grid ====================

class _CoursesGrid extends StatelessWidget {
  final int columns;
  final List<MyCourseItem> courses;
  final bool loading;
  final bool hasAnyCourses;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onCreateFirstCourse;
  final CourseUpdateAction? onUpdateCourse;
  final CoursePublishAction? onPublishCourse;
  final CourseArchiveAction? onArchiveCourse;
  final CourseDeleteAction? onDeleteCourse;
  final CourseCoverUploadAction? onUploadCover;

  const _CoursesGrid({
    required this.columns,
    required this.courses,
    required this.loading,
    required this.hasAnyCourses,
    required this.hasActiveFilters,
    this.onClearFilters,
    this.onCreateFirstCourse,
    this.onUpdateCourse,
    this.onPublishCourse,
    this.onArchiveCourse,
    this.onDeleteCourse,
    this.onUploadCover,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child:   _CoursesGridSkeleton(),
      );
    }

    if (courses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child:   hasAnyCourses && hasActiveFilters
            ? _NoResultsState(onClear: onClearFilters)
            : _CoursesEmptyState(onCreate: onCreateFirstCourse),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      const gap         = 16.0;
      final totalWidth  = constraints.maxWidth;
      final columnWidth = (totalWidth - (columns - 1) * gap) / columns;

      return Wrap(
        spacing:    gap,
        runSpacing: gap,
        children: courses.map((course) {
          return SizedBox(
            width: columnWidth,
            child: _ApiCourseCard(
              course: course,
              onUpdateCourse: onUpdateCourse,
              onPublishCourse: onPublishCourse,
              onArchiveCourse: onArchiveCourse,
              onDeleteCourse: onDeleteCourse,
              onUploadCover: onUploadCover,
            ),
          );
        }).toList(),
      );
    },);
  }
}

class _CoursesGridSkeleton extends StatelessWidget {
  const _CoursesGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      int columns = 4;
      if (w < 1200) columns = 3;
      if (w < 900)  columns = 2;
      if (w < 600)  columns = 1;

      const gap   = 16.0;
      final cardW = (w - (columns - 1) * gap) / columns;

      return Wrap(
        spacing:    gap,
        runSpacing: gap,
        children: List.generate(8, (_) {
          return SizedBox(
            width:  cardW,
            height: _CourseTokens.courseCardHeight,
            child:  const _SkeletonCard(),
          );
        }),
      );
    },);
  }
}

class _NoResultsState extends StatelessWidget {
  final VoidCallback? onClear;
  const _NoResultsState({this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding:     const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.border),
          boxShadow: [
            const BoxShadow(
                color:      Color(0x0D000000),
                blurRadius: 2,
                offset:     Offset(0, 1),),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off_rounded,
              size: 34, color: AppColors.primary,),
          const SizedBox(height: 10),
          Text('No results match your filters',
              style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w900,
                  color:      AppColors.textTitle,),
              textAlign: TextAlign.center,),
          const SizedBox(height: 8),
          Text(
              'Try clearing filters or searching with a different keyword.',
              style:     TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,),
          const SizedBox(height: 14),
          if (onClear != null)
            ElevatedButton.icon(
              onPressed: onClear,
              icon:  const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Clear filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),),
              ),
            ),
        ],),
      ),
    );
  }
}

class _CoursesEmptyState extends StatelessWidget {
  final VoidCallback? onCreate;
  const _CoursesEmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: _CourseTokens.border),
            boxShadow: [
              const BoxShadow(
                  color:      Color(0x0D000000),
                  blurRadius: 2,
                  offset:     Offset(0, 1),),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width:  54,
              height: 54,
              decoration: BoxDecoration(
                color:        const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.folder_open_rounded,
                  color: _CourseTokens.blue, size: 28,),
            ),
            const SizedBox(height: 12),
            Text('No courses yet',
                style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.w900,
                    color:      _CourseTokens.textPrimary,),),
            const SizedBox(height: 6),
            Text(
                'Create your first course to start uploading materials, generating AI quizzes, and inviting students.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize:   12.8,
                    fontWeight: FontWeight.w600,
                    color:      _CourseTokens.textMuted,
                    height:     1.35,),),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onCreate,
                icon:  const Icon(Icons.add_rounded,
                    size: 18, color: Colors.white,),
                label: const Text('Create course',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color:      Colors.white,),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _CourseTokens.blue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),),
                ),
              ),
            ),
          ],),
        ),
      ),
    );
  }
}

// ==================== Skeleton Card ====================

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync:    this,
        duration: const Duration(milliseconds: 1100),)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final color = Color.lerp(
            AppColors.borderGray,
            AppColors.headerBg,
            _c.value,)!;

        return Container(
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(_CourseTokens.radiusCard),
            border:       Border.all(color: _CourseTokens.border),
          ),
          child: Column(children: [
            Container(
              height: _CourseTokens.heroHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_CourseTokens.radiusCard),),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 18,
                        width:  double.infinity,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),),),
                    const SizedBox(height: 10),
                    Container(
                        height: 14,
                        width:  160,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),),),
                    const SizedBox(height: 18),
                    Row(children: [
                      Container(
                          height: 12,
                          width:  90,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),),),
                      const SizedBox(width: 12),
                      Container(
                          height: 12,
                          width:  90,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),),),
                    ],),
                    const Spacer(),
                    Container(height: 1, color: _CourseTokens.divider),
                    const SizedBox(height: 12),
                    Container(
                        height: 12,
                        width:  140,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),),),
                  ],
                ),
              ),
            ),
          ],),
        );
      },
    );
  }
}