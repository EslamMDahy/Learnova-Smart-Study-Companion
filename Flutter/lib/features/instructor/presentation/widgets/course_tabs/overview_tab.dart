import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../data/courses_models.dart';
import '../../controllers/course_details_controller.dart';
import '../course_outcomes_panel.dart';
import '../generate_questions_dialog.dart';

class CourseOverviewTab extends ConsumerWidget {
  final MyCourseItem course;
  const CourseOverviewTab({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state         = ref.watch(courseDetailsControllerProvider(course.id));
    final moduleCount   = state.modules.length;
    final materialCount = state.materials.values.fold<int>(0, (s, l) => s + l.length);
    final questionCount = state.questions.length;
    final studentCount  = course.enrollmentCount ?? 0;

    int filled = 0;
    if (moduleCount > 0)   filled++;
    if (materialCount > 0) filled++;
    if (questionCount > 0) filled++;
    if (studentCount > 0)  filled++;
    final completionPct = filled / 4.0;

    return Container(
      color: AppColors.pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Hero banner ──────────────────────────────────────────────────
          _HeroBanner(course: course),
          const SizedBox(height: 16),

          // ── Stat row ─────────────────────────────────────────────────────
          Row(children: [
            _StatCard(
              icon: Icons.view_module_rounded,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFEFF6FF),
              label: 'Modules',
              value: '$moduleCount',
              loading: state.modulesLoading,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.folder_rounded,
              iconColor: const Color(0xFF9333EA),
              iconBg: const Color(0xFFF3E8FF),
              label: 'Materials',
              value: '$materialCount',
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.quiz_rounded,
              iconColor: const Color(0xFFEA580C),
              iconBg: const Color(0xFFFFEDD5),
              label: 'Questions',
              value: '$questionCount',
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.people_rounded,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFDCFCE7),
              label: 'Students',
              value: '$studentCount',
            ),
          ]),
          const SizedBox(height: 16),

          // ── Two-column body ──────────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Left: Setup + Health
            Expanded(
              flex: 4,
              child: Column(children: [
                _SectionCard(
                  title: 'Course Setup',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: completionPct == 1.0
                      ? const Color(0xFF16A34A)
                      : AppColors.primary,
                  child: _SetupChecklist(
                    moduleCount: moduleCount,
                    materialCount: materialCount,
                    questionCount: questionCount,
                    studentCount: studentCount,
                    completionPct: completionPct,
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Course Health',
                  icon: Icons.bar_chart_rounded,
                  iconColor: const Color(0xFF9333EA),
                  child: _CourseHealth(
                    moduleCount: moduleCount,
                    materialCount: materialCount,
                    questionCount: questionCount,
                    studentCount: studentCount,
                  ),
                ),
              ]),
            ),

            const SizedBox(width: 12),

            // Right: Modules + Quick Actions
            Expanded(
              flex: 6,
              child: Column(children: [
                _SectionCard(
                  title: 'Modules',
                  icon: Icons.view_module_rounded,
                  iconColor: AppColors.primary,
                  trailing: state.modulesLoading
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                  child: state.modules.isEmpty
                      ? const _EmptyHint(
                          'No modules yet.\nGo to the Materials tab to create your first module.')
                      : Column(
                          children: state.modules.map((m) => _ModuleTile(
                            title: m.title,
                            materialCount: state.materials[m.id]?.length ?? 0,
                            isPublished: m.isPublished,
                          )).toList(),
                        ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Quick Actions',
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFD97706),
                  child: _QuickActions(courseId: course.id),
                ),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero banner
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final MyCourseItem course;
  const _HeroBanner({required this.course});

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final status   = course.status.toLowerCase();
    final isActive = status == 'published' || status == 'active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A6FD4), Color(0xFF137FEC), Color(0xFF38BDF8)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _HeroBadge(
                isActive ? '● Active' : _cap(course.status),
                isActive ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
              ),
              const SizedBox(width: 8),
              _HeroBadge(course.safeCourseCode, Colors.white70),
              const SizedBox(width: 8),
              _HeroBadge(_cap(course.courseType), Colors.white70),
              const SizedBox(width: 8),
              _HeroBadge(
                course.isPrivate ? '🔒 Private' : '🌐 Public',
                Colors.white70,
              ),
            ]),
            const SizedBox(height: 10),
            Text(course.safeTitle,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2)),
            if (course.category != null) ...[
              const SizedBox(height: 5),
              Text(course.category!,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7))),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(children: [
            Text('Created',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              '${course.createdAt.day}/${course.createdAt.month}/${course.createdAt.year}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _HeroBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stat card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, value;
  final bool loading;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05000000),
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: iconColor),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          loading
              ? const SizedBox(
                  width: 28,
                  height: 22,
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ))
              : Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textTitle,
                      height: 1)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ]),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTitle)),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      Padding(padding: const EdgeInsets.all(16), child: child),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Setup checklist
// ─────────────────────────────────────────────────────────────────────────────
class _SetupChecklist extends StatelessWidget {
  final int moduleCount, materialCount, questionCount, studentCount;
  final double completionPct;

  const _SetupChecklist({
    required this.moduleCount,
    required this.materialCount,
    required this.questionCount,
    required this.studentCount,
    required this.completionPct,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      (moduleCount > 0,   Icons.view_module_rounded, 'Create modules',   'Organise your content'),
      (materialCount > 0, Icons.folder_rounded,       'Upload materials', 'Add videos, PDFs, docs'),
      (questionCount > 0, Icons.quiz_rounded,          'Add questions',   'Build your question bank'),
      (studentCount > 0,  Icons.people_rounded,        'Invite students', 'Enroll learners'),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completionPct,
              minHeight: 6,
              backgroundColor: AppColors.pageBg,
              color: completionPct == 1.0
                  ? const Color(0xFF16A34A)
                  : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${(completionPct * 100).round()}%',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted)),
      ]),
      const SizedBox(height: 14),
      ...steps.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: s.$1 ? const Color(0xFFDCFCE7) : AppColors.pageBg,
              shape: BoxShape.circle,
              border: Border.all(
                  color:
                      s.$1 ? const Color(0xFF16A34A) : AppColors.border),
            ),
            child: Icon(
              s.$1 ? Icons.check_rounded : s.$2,
              size: 12,
              color: s.$1 ? const Color(0xFF16A34A) : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.$3,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color:
                          s.$1 ? AppColors.textTitle : AppColors.textMuted,
                      decoration:
                          s.$1 ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textMuted)),
              Text(s.$4,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ]),
          ),
        ]),
      )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Course health
// ─────────────────────────────────────────────────────────────────────────────
class _CourseHealth extends StatelessWidget {
  final int moduleCount, materialCount, questionCount, studentCount;

  const _CourseHealth({
    required this.moduleCount,
    required this.materialCount,
    required this.questionCount,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (Icons.view_module_rounded, AppColors.primary,       'Content Depth', moduleCount,   10,  'modules'),
      (Icons.folder_rounded,      const Color(0xFF9333EA), 'Materials',     materialCount, 20,  'files'),
      (Icons.quiz_rounded,        const Color(0xFFEA580C), 'Question Bank', questionCount, 50,  'questions'),
      (Icons.people_rounded,      const Color(0xFF16A34A), 'Student Reach', studentCount,  100, 'enrolled'),
    ];

    return Column(
      children: List.generate(metrics.length, (i) {
        final m = metrics[i];
        final pct = (m.$4 / m.$5).clamp(0.0, 1.0);
        final isLast = i == metrics.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: m.$2.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Icon(m.$1, size: 13, color: m.$2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(m.$3,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTitle)),
                  ),
                  Text('${m.$4} ${m.$6}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct == 0 ? 0 : pct.clamp(0.04, 1.0),
                    minHeight: 5,
                    backgroundColor: AppColors.pageBg,
                    color: m.$2,
                  ),
                ),
              ]),
            ),
          ]),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Module tile
// ─────────────────────────────────────────────────────────────────────────────
class _ModuleTile extends StatelessWidget {
  final String title;
  final int materialCount;
  final bool isPublished;

  const _ModuleTile({
    required this.title,
    required this.materialCount,
    required this.isPublished,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPublished
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFFEF9C3),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.folder_rounded,
            size: 15,
            color: isPublished
                ? AppColors.primary
                : const Color(0xFFD97706)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textTitle)),
      ),
      const SizedBox(width: 8),
      Text('$materialCount files',
          style: const TextStyle(
              fontSize: 11.5, color: AppColors.textMuted)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: isPublished
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isPublished ? 'Published' : 'Draft',
          style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isPublished
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD97706)),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Quick actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends ConsumerWidget {
  final int courseId;
  const _QuickActions({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseDetailsControllerProvider(courseId));
    final materialCount = state.materials.values.fold<int>(0, (sum, list) => sum + list.length);
    final canGenerate = materialCount > 0;

    final actions = [
      (Icons.add_box_outlined,     AppColors.primary,       const Color(0xFFEFF6FF), 'Create Module',        'Add a new content module',        () {}, true),
      (Icons.upload_file_outlined, const Color(0xFF9333EA), const Color(0xFFF3E8FF), 'Upload Material',      'Add videos, PDFs, or docs',       () {}, true),
      (Icons.flag_outlined,        const Color(0xFF16A34A), const Color(0xFFDCFCE7), 'Learning Outcomes',    'Manage course learning goals',    () => showCourseOutcomesDialog(context, ref, courseId), true),
      (Icons.auto_awesome_rounded, const Color(0xFF7C3AED), const Color(0xFFF3E8FF), 'Generate Questions',   canGenerate ? 'Select mixed course content scope' : 'Add materials before generating questions', () {
        if (!canGenerate) return;
        showDialog(
          context: context,
          builder: (_) => GenerateQuestionsDialog(courseId: courseId),
        );
      }, canGenerate),
      (Icons.quiz_outlined,        const Color(0xFFEA580C), const Color(0xFFFFEDD5), 'Add Question',         'Grow your question bank',         () {}, true),
      (Icons.person_add_outlined,  const Color(0xFF0EA5E9), const Color(0xFFE0F2FE), 'Invite Students',      'Send course invitations',         () {}, true),
    ];

    return Column(
      children: List.generate(actions.length, (i) {
        final a = actions[i];
        final isLast = i == actions.length - 1;
        final enabled = a.$7;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: enabled ? 1 : 0.55,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: enabled ? a.$6 : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: a.$3,
                          borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Icon(a.$1, size: 15, color: a.$2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(a.$4,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTitle)),
                        Text(a.$5,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted)),
                      ]),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 11, color: enabled ? AppColors.textHint : AppColors.border),
                  ]),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty hint
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint(this.message);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(
      child: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.6)),
    ),
  );
}
