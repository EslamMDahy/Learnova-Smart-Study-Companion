import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/student_courses_models.dart';


String? _normalizeNetworkImageUrl(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;
  final lower = raw.toLowerCase();
  if (lower == 'null' || lower == 'none' || lower == 'undefined') return null;
  if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('data:image/')) {
    return raw;
  }
  return null;
}

class StudentCoursesSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const StudentCoursesSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTitle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StudentCourseGrid extends StatelessWidget {
  final List<StudentCourse> courses;
  final Set<int> enrollingIds;
  final ValueChanged<StudentCourse> onCourseTap;
  final Future<void> Function(StudentCourse course)? onEnroll;

  const StudentCourseGrid({
    super.key,
    required this.courses,
    required this.enrollingIds,
    required this.onCourseTap,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 3;
        if (constraints.maxWidth < 900) columns = 2;
        if (constraints.maxWidth < 620) columns = 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 22,
            mainAxisSpacing: 20,
            mainAxisExtent: 292,
          ),
          itemBuilder: (context, index) {
            final course = courses[index];
            return StudentCourseCard(
              course: course,
              isEnrolling: enrollingIds.contains(course.id),
              onTap: () => onCourseTap(course),
              onEnroll: onEnroll == null ? null : () => onEnroll!(course),
            );
          },
        );
      },
    );
  }
}

class StudentCourseCard extends StatelessWidget {
  final StudentCourse course;
  final bool isEnrolling;
  final VoidCallback onTap;
  final Future<void> Function()? onEnroll;

  const StudentCourseCard({
    super.key,
    required this.course,
    required this.isEnrolling,
    required this.onTap,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _CourseVisual.fromCourse(course);
    final status = _courseUiStatusFromCourse(course);
    final meta = _CoursePresentationMeta.fromCourse(course);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CourseCover(
                  course: course,
                  visual: visual,
                  status: status,
                  badgeLabel: meta.badgeLabel,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _InstructorAvatar(seed: course.id, name: meta.instructorName, avatarUrl: meta.instructorAvatarUrl),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meta.instructorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textTitle,
                                      fontSize: 12.5,
                                      height: 1.05,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    meta.department,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10.5,
                                      height: 1.05,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Expanded(
                              child: _SmallMetaItem(
                                icon: Icons.calendar_today_outlined,
                                label: meta.primaryMeta,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SmallMetaItem(
                                icon: meta.secondaryIcon,
                                label: meta.secondaryMeta,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Text(
                            course.safeDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.2,
                              height: 1.42,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(height: 1, color: AppColors.divider),
                        const SizedBox(height: 9),
                        _CourseActionButton(
                          status: status,
                          loading: isEnrolling,
                          canEnroll: course.canEnroll && onEnroll != null,
                          onEnroll: onEnroll,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCover extends StatelessWidget {
  final StudentCourse course;
  final _CourseVisual visual;
  final _CourseUiStatus status;
  final String badgeLabel;

  const _CourseCover({
    required this.course,
    required this.visual,
    required this.status,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = _normalizeNetworkImageUrl(course.coverImageUrl);
    final hasCover = coverUrl != null;

    return SizedBox(
      height: 102,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCover)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: visual.colors,
                    ),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: visual.colors,
                  ),
                ),
              ),
            )
          else ...[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: visual.colors,
                ),
              ),
            ),
            CustomPaint(painter: _CourseCoverPainter(visual: visual)),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.58),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(status: status),
                    const SizedBox(width: 7),
                    _CourseMetaBadge(label: badgeLabel),
                    const Spacer(),
                    if (status == _CourseUiStatus.enrolled)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2087EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  course.safeCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.8,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  course.safeTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.7,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.25,
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

class _CourseActionButton extends StatelessWidget {
  final _CourseUiStatus status;
  final bool loading;
  final bool canEnroll;
  final Future<void> Function()? onEnroll;

  const _CourseActionButton({
    required this.status,
    required this.loading,
    required this.canEnroll,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _CourseUiStatus.enrolled:
        return _DisabledActionButton(label: 'Enrolled');
      case _CourseUiStatus.closed:
        return _DisabledActionButton(label: 'Closed');
      case _CourseUiStatus.waitlist:
        return SizedBox(
          width: double.infinity,
          height: 32,
          child: OutlinedButton.icon(
            onPressed: loading || !canEnroll ? null : onEnroll,
            icon: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.hourglass_bottom_rounded, size: 15),
            label: Text(loading ? 'Joining...' : 'Join Waitlist'),
            style: OutlinedButton.styleFrom(
              elevation: 0,
              foregroundColor: AppColors.primary,
              disabledForegroundColor: AppColors.textMuted,
              side: BorderSide(color: AppColors.primary, width: 1.2),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      case _CourseUiStatus.open:
        return SizedBox(
          width: double.infinity,
          height: 32,
          child: ElevatedButton.icon(
            onPressed: loading || !canEnroll ? null : onEnroll,
            icon: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_circle_outline_rounded, size: 15),
            label: Text(loading ? 'Enrolling...' : 'Enroll'),
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
        );
    }
  }
}

class _DisabledActionButton extends StatelessWidget {
  final String label;

  const _DisabledActionButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.fieldDisabledBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class StudentCourseDetailsDialog extends StatelessWidget {
  final StudentCourse course;
  final bool isEnrolling;
  final Future<void> Function()? onEnroll;

  const StudentCourseDetailsDialog({
    super.key,
    required this.course,
    required this.isEnrolling,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _CourseVisual.fromCourse(course);
    final status = _courseUiStatusFromCourse(course);
    final meta = _CoursePresentationMeta.fromCourse(course);
    final coverUrl = _normalizeNetworkImageUrl(course.coverImageUrl);
    final hasCover = coverUrl != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCover)
                    Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: visual.colors,
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: visual.colors,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: visual.colors,
                        ),
                      ),
                    ),
                    CustomPaint(painter: _CourseCoverPainter(visual: visual)),
                  ],
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.68),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StatusBadge(status: status),
                            const SizedBox(width: 8),
                            _CourseMetaBadge(label: meta.badgeLabel),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          course.safeCode,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          course.safeTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _InstructorAvatar(seed: course.id, name: meta.instructorName, avatarUrl: meta.instructorAvatarUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta.instructorName,
                              style: TextStyle(
                                color: AppColors.textTitle,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              meta.department,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Course overview',
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.safeDescription,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      height: 1.55,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: meta.primaryMeta,
                      ),
                      _InfoChip(
                        icon: meta.secondaryIcon,
                        label: meta.secondaryMeta,
                      ),
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: meta.badgeLabel,
                      ),
                      if (course.enrollmentCount != null)
                        _InfoChip(
                          icon: Icons.groups_2_outlined,
                          label: '${course.enrollmentCount} enrolled students',
                        ),
                      if (course.averageRating != null)
                        _InfoChip(
                          icon: Icons.star_rate_rounded,
                          label: '${course.averageRating!.toStringAsFixed(1)} rating',
                        ),
                      _InfoChip(
                        icon: Icons.public_rounded,
                        label: course.visibilityLevel,
                      ),
                    ],
                  ),
                  if (course.tags.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: course.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: AppColors.headerBg,
                              side: BorderSide(color: AppColors.border),
                              labelStyle: TextStyle(
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      if (!course.isEnrolled) ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: isEnrolling || onEnroll == null
                              ? null
                              : () {
                                  onEnroll!();
                                },
                          icon: isEnrolling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  course.requiresEnrollmentApproval
                                      ? Icons.hourglass_bottom_rounded
                                      : Icons.add_circle_outline_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            course.requiresEnrollmentApproval
                                ? 'Join Waitlist'
                                : 'Enroll Now',
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentCoursesLoadingPanel extends StatelessWidget {
  final String message;

  const StudentCoursesLoadingPanel({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 3;
        if (constraints.maxWidth < 900) columns = 2;
        if (constraints.maxWidth < 620) columns = 1;

        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 22,
                mainAxisSpacing: 20,
                mainAxisExtent: 292,
              ),
              itemBuilder: (context, index) => const _CourseSkeletonCard(),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class StudentCoursesErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const StudentCoursesErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.dangerText, size: 34),
          const SizedBox(height: 10),
          Text(
            'Could not load courses',
            style: TextStyle(
              color: AppColors.dangerTitle,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.dangerText),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class StudentCoursesEmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StudentCoursesEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTitle,
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallMetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _CourseUiStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final palette = status.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: palette.foreground,
          fontSize: 10.2,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CourseMetaBadge extends StatelessWidget {
  final String label;

  const _CourseMetaBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 132),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.2,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _InstructorAvatar extends StatelessWidget {
  final int seed;
  final String name;
  final String? avatarUrl;

  const _InstructorAvatar({
    required this.seed,
    required this.name,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _normalizeNetworkImageUrl(avatarUrl);
    final colors = [
      const Color(0xFFD9F99D),
      const Color(0xFFBAE6FD),
      const Color(0xFFFDE68A),
      const Color(0xFFFBCFE8),
      const Color(0xFFCCFBF1),
      const Color(0xFFE9D5FF),
    ];
    final bg = colors[seed.abs() % colors.length];
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty && !part.endsWith('.'))
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: imageUrl == null
          ? Text(
              initials.isEmpty ? 'L' : initials,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            )
          : Image.network(
              imageUrl,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                initials.isEmpty ? 'L' : initials,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textGray,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseSkeletonCard extends StatelessWidget {
  const _CourseSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 102,
            decoration: BoxDecoration(
              color: AppColors.headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.headerBg,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _SkeletonLine(widthFactor: 0.55)),
                  ],
                ),
                const SizedBox(height: 18),
                const _SkeletonLine(widthFactor: 0.9),
                const SizedBox(height: 8),
                const _SkeletonLine(widthFactor: 0.72),
                const SizedBox(height: 24),
                const _SkeletonLine(widthFactor: 1, height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _SkeletonLine({required this.widthFactor, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.headerBg,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CourseVisual {
  final List<Color> colors;
  final _CourseCoverKind kind;

  const _CourseVisual({required this.colors, required this.kind});

  factory _CourseVisual.fromCourse(StudentCourse course) {
    final key = '${course.safeCategory} ${course.safeTitle}'.toLowerCase();

    if (key.contains('art') || key.contains('design') || key.contains('media')) {
      return const _CourseVisual(
        colors: [Color(0xFF0F766E), Color(0xFF0EA5E9), Color(0xFFEA580C)],
        kind: _CourseCoverKind.art,
      );
    }
    if (key.contains('ethic') || key.contains('human')) {
      return const _CourseVisual(
        colors: [Color(0xFF6B7280), Color(0xFF111827)],
        kind: _CourseCoverKind.soft,
      );
    }
    if (key.contains('algorithm') || key.contains('advanced')) {
      return const _CourseVisual(
        colors: [Color(0xFF020617), Color(0xFF111827), Color(0xFF0F766E)],
        kind: _CourseCoverKind.code,
      );
    }
    if (key.contains('data')) {
      return const _CourseVisual(
        colors: [Color(0xFF0B1120), Color(0xFF111827), Color(0xFF0F172A)],
        kind: _CourseCoverKind.data,
      );
    }
    if (key.contains('web') || key.contains('stack') || key.contains('development')) {
      return const _CourseVisual(
        colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF0F766E)],
        kind: _CourseCoverKind.code,
      );
    }
    if (key.contains('machine') || key.contains('learning') || key.contains('ai')) {
      return const _CourseVisual(
        colors: [Color(0xFF011B20), Color(0xFF0F172A), Color(0xFF064E3B)],
        kind: _CourseCoverKind.machine,
      );
    }

    final palette = course.id % 4;
    switch (palette) {
      case 1:
        return const _CourseVisual(
          colors: [Color(0xFF172554), Color(0xFF0F766E)],
          kind: _CourseCoverKind.machine,
        );
      case 2:
        return const _CourseVisual(
          colors: [Color(0xFF111827), Color(0xFF1E3A8A)],
          kind: _CourseCoverKind.data,
        );
      case 3:
        return const _CourseVisual(
          colors: [Color(0xFF431407), Color(0xFF0F172A)],
          kind: _CourseCoverKind.art,
        );
      default:
        return const _CourseVisual(
          colors: [Color(0xFF020617), Color(0xFF0F172A)],
          kind: _CourseCoverKind.code,
        );
    }
  }
}

enum _CourseCoverKind { code, data, machine, art, soft }

class _CourseCoverPainter extends CustomPainter {
  final _CourseVisual visual;

  const _CourseCoverPainter({required this.visual});

  @override
  void paint(Canvas canvas, Size size) {
    switch (visual.kind) {
      case _CourseCoverKind.code:
        _paintCode(canvas, size);
        return;
      case _CourseCoverKind.data:
        _paintData(canvas, size);
        return;
      case _CourseCoverKind.machine:
        _paintMachine(canvas, size);
        return;
      case _CourseCoverKind.art:
        _paintArt(canvas, size);
        return;
      case _CourseCoverKind.soft:
        _paintSoft(canvas, size);
        return;
    }
  }

  void _paintCode(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF67E8F9).withValues(alpha: 0.18)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final textPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = 2;

    for (var i = 0; i < 13; i++) {
      final y = 12.0 + i * 7.0;
      final start = size.width * (0.32 + (i % 3) * 0.05);
      final end = math.min(size.width - 16, start + 60 + (i % 4) * 19);
      canvas.drawLine(Offset(start, y), Offset(end, y), paint);
      if (i % 2 == 0) {
        canvas.drawCircle(Offset(end + 9, y), 1.7, textPaint);
      }
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x + 50, size.height), gridPaint);
    }
  }

  void _paintData(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF14B8A6).withValues(alpha: 0.28)
      ..strokeWidth = 1.3;
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), axisPaint);
    }
    for (var y = 0.0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    final path = Path()..moveTo(size.width * .45, size.height * .74);
    for (var i = 0; i < 9; i++) {
      path.lineTo(
        size.width * (.45 + i * .07),
        size.height * (.72 - math.sin(i * .8) * .22),
      );
    }
    canvas.drawPath(path, linePaint);
  }

  void _paintMachine(Canvas canvas, Size size) {
    final glow = Paint()..color = const Color(0xFF22D3EE).withValues(alpha: 0.18);
    final node = Paint()..color = const Color(0xFF14B8A6).withValues(alpha: 0.44);
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.2;

    final points = <Offset>[
      Offset(size.width * .62, size.height * .28),
      Offset(size.width * .78, size.height * .22),
      Offset(size.width * .84, size.height * .52),
      Offset(size.width * .68, size.height * .66),
      Offset(size.width * .53, size.height * .52),
    ];
    for (final p in points) {
      for (final q in points) {
        if (p != q && (p - q).distance < 80) canvas.drawLine(p, q, stroke);
      }
      canvas.drawCircle(p, 11, glow);
      canvas.drawCircle(p, 2.6, node);
    }

    canvas.drawCircle(
      Offset(size.width * .78, size.height * .92),
      3,
      Paint()..color = const Color(0xFF0891B2).withValues(alpha: 0.55),
    );
  }

  void _paintArt(Canvas canvas, Size size) {
    for (var i = 0; i < 9; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 + (i % 3) * 2
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(
          const Color(0xFF14B8A6),
          const Color(0xFFF97316),
          i / 8,
        )!
            .withValues(alpha: 0.34);
      final path = Path()
        ..moveTo(-20, size.height * (.15 + i * .08))
        ..cubicTo(
          size.width * .25,
          size.height * (.02 + i * .03),
          size.width * .48,
          size.height * (.88 - i * .04),
          size.width + 30,
          size.height * (.18 + i * .07),
        );
      canvas.drawPath(path, paint);
    }
  }

  void _paintSoft(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.11);
    canvas.drawCircle(Offset(size.width * .72, size.height * .82), 58, paint);
    canvas.drawCircle(
      Offset(size.width * .45, size.height * .52),
      22,
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(covariant _CourseCoverPainter oldDelegate) {
    return oldDelegate.visual.kind != visual.kind ||
        oldDelegate.visual.colors != visual.colors;
  }
}

enum _CourseUiStatus { open, waitlist, enrolled, closed }

extension _CourseUiStatusX on _CourseUiStatus {
  String get label {
    switch (this) {
      case _CourseUiStatus.open:
        return 'Open';
      case _CourseUiStatus.waitlist:
        return 'Waitlist';
      case _CourseUiStatus.enrolled:
        return 'Enrolled';
      case _CourseUiStatus.closed:
        return 'Closed';
    }
  }

  _StatusPalette get palette {
    switch (this) {
      case _CourseUiStatus.open:
        return const _StatusPalette(
          background: Color(0xFF16A34A),
          foreground: Colors.white,
        );
      case _CourseUiStatus.waitlist:
        return const _StatusPalette(
          background: Color(0xFFEAB308),
          foreground: Colors.white,
        );
      case _CourseUiStatus.enrolled:
        return const _StatusPalette(
          background: Color(0xFF137FEC),
          foreground: Colors.white,
        );
      case _CourseUiStatus.closed:
        return const _StatusPalette(
          background: Color(0xFFEF4444),
          foreground: Colors.white,
        );
    }
  }

}


_CourseUiStatus _courseUiStatusFromCourse(StudentCourse course) {
  if (course.isEnrolled && !course.isPendingEnrollment) {
    return _CourseUiStatus.enrolled;
  }
  if (!course.isOpenForEnrollment || course.status.toLowerCase() == 'archived') {
    return _CourseUiStatus.closed;
  }
  if (course.requiresEnrollmentApproval || course.isPendingEnrollment) {
    return _CourseUiStatus.waitlist;
  }
  return _CourseUiStatus.open;
}

class _StatusPalette {
  final Color background;
  final Color foreground;

  const _StatusPalette({required this.background, required this.foreground});
}

class _CoursePresentationMeta {
  final String instructorName;
  final String? instructorAvatarUrl;
  final String department;
  final String primaryMeta;
  final String secondaryMeta;
  final IconData secondaryIcon;
  final String badgeLabel;

  const _CoursePresentationMeta({
    required this.instructorName,
    required this.instructorAvatarUrl,
    required this.department,
    required this.primaryMeta,
    required this.secondaryMeta,
    required this.secondaryIcon,
    required this.badgeLabel,
  });

  factory _CoursePresentationMeta.fromCourse(StudentCourse course) {
    return _CoursePresentationMeta(
      instructorName: _instructorLabel(course),
      instructorAvatarUrl: course.instructorAvatarUrl,
      department: _departmentLabel(course),
      primaryMeta: course.isEnrolled
          ? _createdAtLabel(course.createdAt)
          : _enrollmentLabel(course.enrollmentCount),
      secondaryMeta: course.isEnrolled
          ? _visibilityLabel(course.visibilityLevel)
          : _ratingOrApprovalLabel(course),
      secondaryIcon: course.isEnrolled
          ? _visibilityIcon(course.visibilityLevel)
          : _ratingOrApprovalIcon(course),
      badgeLabel: _badgeLabel(course),
    );
  }

  static String _instructorLabel(StudentCourse course) {
    return course.safeInstructorName;
  }

  static String _departmentLabel(StudentCourse course) {
    final category = course.safeCategory.trim();
    if (category.isNotEmpty && category.toLowerCase() != 'general') {
      return category;
    }
    return _titleCase(course.courseType.replaceAll('_', ' '));
  }

  static String _badgeLabel(StudentCourse course) {
    final category = course.safeCategory.trim();
    if (category.isNotEmpty && category.toLowerCase() != 'general') {
      return category;
    }
    return _titleCase(course.courseType.replaceAll('_', ' '));
  }


  static String _enrollmentLabel(int? count) {
    if (count == null) return 'Enrollment not available';
    if (count == 1) return '1 enrolled student';
    return '$count enrolled students';
  }

  static String _ratingOrApprovalLabel(StudentCourse course) {
    final rating = course.averageRating;
    if (rating != null && rating > 0) {
      return '${rating.toStringAsFixed(1)} rating';
    }
    if (course.requiresEnrollmentApproval) return 'Approval required';
    if (course.isOpenForEnrollment) return 'Open enrollment';
    return 'Enrollment closed';
  }

  static IconData _ratingOrApprovalIcon(StudentCourse course) {
    final rating = course.averageRating;
    if (rating != null && rating > 0) return Icons.star_rate_rounded;
    if (course.requiresEnrollmentApproval) return Icons.hourglass_bottom_rounded;
    if (course.isOpenForEnrollment) return Icons.how_to_reg_rounded;
    return Icons.lock_outline_rounded;
  }

  static String _visibilityLabel(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Visibility not set';
    return _titleCase(value.replaceAll('_', ' '));
  }

  static IconData _visibilityIcon(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'public':
        return Icons.public_rounded;
      case 'private':
        return Icons.lock_outline_rounded;
      case 'unlisted':
        return Icons.link_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  static String _createdAtLabel(DateTime? value) {
    if (value == null) return 'Created date unavailable';
    final local = value.toLocal();
    final month = _monthName(local.month);
    return 'Created $month ${local.day}, ${local.year}';
  }

  static String _monthName(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return 'Date';
    return months[month - 1];
  }

  static String _titleCase(String raw) {
    final words = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 'General';
    return words
        .map((word) => word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }
}
