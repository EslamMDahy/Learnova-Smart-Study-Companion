import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/student_courses_models.dart';
import '../../../data/student_courses_providers.dart';
import 'student_course_widgets.dart';

class StudentDiscoverCoursesPage extends ConsumerStatefulWidget {
  const StudentDiscoverCoursesPage({super.key});

  @override
  ConsumerState<StudentDiscoverCoursesPage> createState() =>
      _StudentDiscoverCoursesPageState();
}

class _StudentDiscoverCoursesPageState
    extends ConsumerState<StudentDiscoverCoursesPage> {
  static const int _pageSize = 6;

  late final TextEditingController _searchController;
  Timer? _autocompleteDebounce;
  int _pageIndex = 0;
  _StudentCoursesViewMode _viewMode = _StudentCoursesViewMode.grid;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    Future.microtask(() {
      ref.read(studentCoursesControllerProvider.notifier).loadEnrolled();
    });
  }

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final controller = ref.read(studentCoursesControllerProvider.notifier);
    await controller.loadEnrolled(force: true);

    final currentQuery = ref.read(studentCoursesControllerProvider).query;
    if (currentQuery.trim().isNotEmpty) {
      await controller.searchPublic(currentQuery, force: true);
    }
  }

  Future<void> _runSearch([String? query]) async {
    final searchText = (query ?? _searchController.text).trim();
    _autocompleteDebounce?.cancel();

    setState(() => _pageIndex = 0);

    _searchController.text = searchText;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );

    await ref
        .read(studentCoursesControllerProvider.notifier)
        .searchPublic(searchText);
  }

  void _queueAutocomplete(String value) {
    _autocompleteDebounce?.cancel();

    final query = value.trim();
    if (query.isEmpty) {
      ref.read(studentCoursesControllerProvider.notifier).autocompletePublic('');
      return;
    }

    _autocompleteDebounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(studentCoursesControllerProvider.notifier)
          .autocompletePublic(query);
    });
  }

  Future<void> _selectSuggestion(String suggestion) async {
    await _runSearch(suggestion);
  }

  Future<void> _clearSearch() async {
    _autocompleteDebounce?.cancel();
    _searchController.clear();
    setState(() => _pageIndex = 0);

    final controller = ref.read(studentCoursesControllerProvider.notifier);
    await controller.autocompletePublic('');
    await controller.searchPublic('');
  }

  Future<void> _enroll(StudentCourse course) async {
    try {
      final result = await ref
          .read(studentCoursesControllerProvider.notifier)
          .enroll(course);

      if (!mounted) return;
      final message = result.isPending
          ? 'Enrollment request sent. Waiting for instructor approval.'
          : 'You are now enrolled in ${course.safeTitle}.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      final message = ref.read(studentCoursesControllerProvider).searchError ??
          'Could not enroll in this course. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showCourseDetails(StudentCourse course) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final state = ref.read(studentCoursesControllerProvider);
        return StudentCourseDetailsDialog(
          course: course,
          isEnrolling: state.isEnrolling(course.id),
          onEnroll: course.canEnroll
              ? () async {
                  Navigator.of(dialogContext).pop();
                  await _enroll(course);
                }
              : null,
        );
      },
    );
  }

  void _goToPage(int index) {
    if (index == _pageIndex) return;
    setState(() => _pageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentCoursesControllerProvider);
    final courses = state.publicCourses;
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
                    _DiscoverCoursesTitleBlock(
                      enrolledCount: state.enrolledCourses.length,
                      totalMatches: state.publicTotal,
                      searching: state.searching,
                      onRefresh: _refresh,
                    ),
                    const SizedBox(height: 28),
                    _SearchPublicCoursesCard(
                      controller: _searchController,
                      searching: state.searching,
                      loadingSuggestions: state.loadingSuggestions,
                      suggestions: state.autocompleteSuggestions,
                      autocompleteQuery: state.autocompleteQuery,
                      autocompleteError: state.autocompleteError,
                      onChanged: _queueAutocomplete,
                      onSearch: _runSearch,
                      onSuggestionSelected: _selectSuggestion,
                      onClear: _clearSearch,
                    ),
                    const SizedBox(height: 30),
                    _CoursesToolbar(
                      count: courses.length,
                      totalCount: state.publicTotal,
                      hasQuery: state.query.trim().isNotEmpty,
                      viewMode: _viewMode,
                      onViewModeChanged: (mode) {
                        setState(() => _viewMode = mode);
                      },
                    ),
                    const SizedBox(height: 24),
                    _PublicCoursesArea(
                      state: state,
                      courses: visibleCourses,
                      viewMode: _viewMode,
                      onCourseTap: _showCourseDetails,
                      onEnroll: _enroll,
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

class _DiscoverCoursesTitleBlock extends StatelessWidget {
  final int enrolledCount;
  final int totalMatches;
  final bool searching;
  final Future<void> Function() onRefresh;

  const _DiscoverCoursesTitleBlock({
    required this.enrolledCount,
    required this.totalMatches,
    required this.searching,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover Courses',
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
                'Search public courses, view course overviews, and enroll.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricPill(
                    icon: Icons.school_outlined,
                    label: '$enrolledCount enrolled',
                  ),
                  _MetricPill(
                    icon: Icons.public_rounded,
                    label: '$totalMatches total match${totalMatches == 1 ? '' : 'es'}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: searching
              ? null
              : onRefresh,
          icon: searching
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textGray,
            side: BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textGray,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPublicCoursesCard extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final bool loadingSuggestions;
  final List<String> suggestions;
  final String autocompleteQuery;
  final String? autocompleteError;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onSearch;
  final ValueChanged<String> onSuggestionSelected;
  final Future<void> Function() onClear;

  const _SearchPublicCoursesCard({
    required this.controller,
    required this.searching,
    required this.loadingSuggestions,
    required this.suggestions,
    required this.autocompleteQuery,
    required this.autocompleteError,
    required this.onChanged,
    required this.onSearch,
    required this.onSuggestionSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.74)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find public courses',
                          style: TextStyle(
                            color: AppColors.textTitle,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Search is connected to the backend public courses endpoint.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (compact)
                Column(
                  children: [
                    _SearchTextField(
                      controller: controller,
                      onChanged: onChanged,
                      onSearch: onSearch,
                      onClear: onClear,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: _SearchButton(
                        searching: searching,
                        onSearch: onSearch,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _SearchTextField(
                        controller: controller,
                        onChanged: onChanged,
                        onSearch: onSearch,
                        onClear: onClear,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: _SearchButton(
                        searching: searching,
                        onSearch: onSearch,
                      ),
                    ),
                  ],
                ),
              _AutocompleteSuggestionsPanel(
                loading: loadingSuggestions,
                suggestions: suggestions,
                query: autocompleteQuery,
                error: autocompleteError,
                onSuggestionSelected: onSuggestionSelected,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onSearch;
  final Future<void> Function() onClear;

  const _SearchTextField({
    required this.controller,
    required this.onChanged,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: (_) {
        onSearch();
      },
      decoration: InputDecoration(
        hintText: 'Search public courses, e.g. Python',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.textHint,
          size: 20,
        ),
        suffixIcon: IconButton(
          tooltip: 'Clear search',
          onPressed: onClear,
          icon: Icon(
            Icons.close_rounded,
            color: AppColors.textHint,
            size: 18,
          ),
        ),
        filled: true,
        fillColor: AppColors.headerBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final bool searching;
  final Future<void> Function() onSearch;

  const _SearchButton({required this.searching, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: searching
          ? null
          : onSearch,
      icon: searching
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.search_rounded, size: 18),
      label: Text(searching ? 'Searching' : 'Search'),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _AutocompleteSuggestionsPanel extends StatelessWidget {
  final bool loading;
  final List<String> suggestions;
  final String query;
  final String? error;
  final ValueChanged<String> onSuggestionSelected;

  const _AutocompleteSuggestionsPanel({
    required this.loading,
    required this.suggestions,
    required this.query,
    required this.error,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    final shouldShow = hasQuery &&
        (loading || suggestions.isNotEmpty || (error ?? '').trim().isNotEmpty);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: loading
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Loading suggestions from autocomplete...',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : suggestions.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: suggestions.map((suggestion) {
                    return InkWell(
                      onTap: () => onSuggestionSelected(suggestion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.manage_search_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  color: AppColors.textTitle,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(growable: false),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    error ?? 'No suggestions found.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
    );
  }
}

class _CoursesToolbar extends StatelessWidget {
  final int count;
  final int totalCount;
  final bool hasQuery;
  final _StudentCoursesViewMode viewMode;
  final ValueChanged<_StudentCoursesViewMode> onViewModeChanged;

  const _CoursesToolbar({
    required this.count,
    required this.totalCount,
    required this.hasQuery,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = hasQuery
        ? 'Showing $count course${count == 1 ? '' : 's'}'
        : 'Search backend public courses';
    final suffix = hasQuery && totalCount > count ? ' • $totalCount total matches' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '$label$suffix',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 16),
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

class _PublicCoursesArea extends StatelessWidget {
  final StudentCoursesState state;
  final List<StudentCourse> courses;
  final _StudentCoursesViewMode viewMode;
  final ValueChanged<StudentCourse> onCourseTap;
  final Future<void> Function(StudentCourse course) onEnroll;

  const _PublicCoursesArea({
    required this.state,
    required this.courses,
    required this.viewMode,
    required this.onCourseTap,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    if (state.query.trim().isEmpty) {
      return const StudentCoursesEmptyPanel(
        icon: Icons.search_rounded,
        title: 'Search to discover public courses',
        description:
            'Type a keyword like Python, AI, math, or algorithms to load public courses from the backend.',
      );
    }

    if (state.searching && state.publicCourses.isEmpty) {
      return const StudentCoursesLoadingPanel(
        message: 'Searching public courses...',
      );
    }

    if (state.searchError != null && state.publicCourses.isEmpty) {
      return StudentCoursesEmptyPanel(
        icon: Icons.info_outline_rounded,
        title: 'No public courses loaded',
        description: state.searchError!,
      );
    }

    if (state.publicCourses.isEmpty) {
      return StudentCoursesEmptyPanel(
        icon: Icons.public_off_rounded,
        title: 'No available courses found',
        description:
            'No public open courses matched “${state.query}”, or all matching courses are already in your enrolled list.',
      );
    }

    if (viewMode == _StudentCoursesViewMode.list) {
      return _StudentCoursesList(
        courses: courses,
        enrollingIds: state.enrollingCourseIds,
        onCourseTap: onCourseTap,
        onEnroll: onEnroll,
      );
    }

    return StudentCourseGrid(
      courses: courses,
      enrollingIds: state.enrollingCourseIds,
      onCourseTap: onCourseTap,
      onEnroll: onEnroll,
    );
  }
}

class _StudentCoursesList extends StatelessWidget {
  final List<StudentCourse> courses;
  final Set<int> enrollingIds;
  final ValueChanged<StudentCourse> onCourseTap;
  final Future<void> Function(StudentCourse course) onEnroll;

  const _StudentCoursesList({
    required this.courses,
    required this.enrollingIds,
    required this.onCourseTap,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < courses.length; i++) ...[
          _StudentCourseListTile(
            course: courses[i],
            isEnrolling: enrollingIds.contains(courses[i].id),
            onTap: () => onCourseTap(courses[i]),
            onEnroll: () => onEnroll(courses[i]),
          ),
          if (i != courses.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _StudentCourseListTile extends StatelessWidget {
  final StudentCourse course;
  final bool isEnrolling;
  final VoidCallback onTap;
  final Future<void> Function() onEnroll;

  const _StudentCourseListTile({
    required this.course,
    required this.isEnrolling,
    required this.onTap,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final canEnroll = course.canEnroll;
    final actionLabel = course.requiresEnrollmentApproval ? 'Join Waitlist' : 'Enroll';

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
            border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
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
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: isEnrolling || !canEnroll
                      ? null
                      : onEnroll,
                  icon: isEnrolling
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          course.requiresEnrollmentApproval
                              ? Icons.hourglass_bottom_rounded
                              : Icons.add_circle_outline_rounded,
                          size: 15,
                        ),
                  label: Text(isEnrolling ? 'Enrolling...' : actionLabel),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.fieldDisabledBg,
                    disabledForegroundColor: AppColors.textMuted,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
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
              color: active ? AppColors.primary.withValues(alpha: 0.14) : AppColors.border,
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? AppColors.textMuted : AppColors.textHint.withValues(alpha: 0.45),
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
