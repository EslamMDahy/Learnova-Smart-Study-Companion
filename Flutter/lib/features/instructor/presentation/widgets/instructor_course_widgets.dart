import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learnova/core/routing/routes.dart';

/// Courses Management page content – مطابق لمواصفات الـ CSS المقدمة.
class InstructorCourseContent extends StatelessWidget {
  final VoidCallback? onCreateNewCourse;

  const InstructorCourseContent({super.key, this.onCreateNewCourse});

  @override
  Widget build(BuildContext context) {
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
                      _HeaderRow(onCreateNewCourse: onCreateNewCourse),
                      const SizedBox(height: 18),
                      const _StatsRow(),
                      const SizedBox(height: 16),
                      const _SearchAndFiltersRow(),
                      const SizedBox(height: 18),
                      _CoursesGrid(columns: columns),
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

double _clamp(double v, double min, double max) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}

// ----------------------------
// ثوابت التصميم
// ----------------------------
class _CourseTokens {
  static const pageBg = Color(0xFFF6F7F8);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFF0F2F4);

  static const textPrimary = Color(0xFF111418);
  static const textMuted = Color(0xFF617589);
  static const textHint = Color(0xFF94A3B8);

  static const blue = Color(0xFF137FEC);

  static const radiusCard = 12.0;
  static const statCardHeight = 88.0;
  static const courseCardHeight = 322.0;
  static const heroHeight = 128.0;

  static const shadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
  static const hoverShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 26,
      offset: Offset(0, 14),
    ),
  ];
}

// ----------------------------
// Breadcrumb + Header
// ----------------------------
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.home_rounded, size: 14, color: _CourseTokens.textHint),
        SizedBox(width: 8),
        Text(
          "Home",
          style: TextStyle(
            color: _CourseTokens.textHint,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCBD5E1)),
        SizedBox(width: 8),
        Text(
          "Courses Management",
          style: TextStyle(
            color: _CourseTokens.textHint,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final VoidCallback? onCreateNewCourse;

  const _HeaderRow({this.onCreateNewCourse});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 820;

        final left = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Courses",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: _CourseTokens.textPrimary,
                height: 1.05,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Manage your curriculum, AI assessments, and student cohorts.",
              style: TextStyle(
                color: _CourseTokens.textMuted,
                fontSize: 13.2,
                fontWeight: FontWeight.w600,
              ),
            ),
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

        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            btn,
          ],
        );
      },
    );
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
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: hover ? _CourseTokens.hoverShadow : const [],
        ),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text(
            "Create New Course",
            style: TextStyle(fontSize: 12.6, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _CourseTokens.blue,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

// ----------------------------
// Stats Row
// ----------------------------
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wrap = c.maxWidth < 900;

        if (!wrap) {
          return const Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: _CourseTokens.statCardHeight,
                  child: _MiniStatCard.fromPreset(preset: _StatPreset.totalCourses),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: _CourseTokens.statCardHeight,
                  child: _MiniStatCard.fromPreset(preset: _StatPreset.activeStudents),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: _CourseTokens.statCardHeight,
                  child: _MiniStatCard.fromPreset(preset: _StatPreset.pendingGrading),
                ),
              ),
            ],
          );
        }

        const cards = [
          _MiniStatCard.fromPreset(preset: _StatPreset.totalCourses),
          _MiniStatCard.fromPreset(preset: _StatPreset.activeStudents),
          _MiniStatCard.fromPreset(preset: _StatPreset.pendingGrading),
        ];

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((w) => SizedBox(width: (c.maxWidth - 16) / 2, height: _CourseTokens.statCardHeight, child: w)).toList(),
        );
      },
    );
  }
}

enum _StatPreset { totalCourses, activeStudents, pendingGrading }

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

  const _MiniStatCard.fromPreset({required _StatPreset preset})
      : title = preset == _StatPreset.totalCourses
            ? "TOTAL COURSES"
            : preset == _StatPreset.activeStudents
                ? "ACTIVE STUDENTS"
                : "PENDING GRADING",
        value = preset == _StatPreset.totalCourses
            ? "12"
            : preset == _StatPreset.activeStudents
                ? "345"
                : "28",
        icon = preset == _StatPreset.totalCourses
            ? Icons.folder_outlined
            : preset == _StatPreset.activeStudents
                ? Icons.people_outline_rounded
                : Icons.assignment_outlined,
        iconBg = preset == _StatPreset.totalCourses
            ? const Color(0xFFEAF2FF)
            : preset == _StatPreset.activeStudents
                ? const Color(0xFFE9FBF1)
                : const Color(0xFFFFF4DB),
        iconColor = preset == _StatPreset.totalCourses
            ? const Color(0xFF2563EB)
            : preset == _StatPreset.activeStudents
                ? const Color(0xFF16A34A)
                : const Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _CourseTokens.textHint,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: _CourseTokens.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ],
      ),
    );
  }
}

// ----------------------------
// Search + Filters
// ----------------------------
class _SearchAndFiltersRow extends StatelessWidget {
  const _SearchAndFiltersRow();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: const [
          Expanded(child: _SearchField()),
          SizedBox(width: 12),
          _FilterPill(label: "All Semesters"),
          SizedBox(width: 10),
          _FilterPill(label: "All Statuses"),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 18, color: _CourseTokens.textHint),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Search by course name or code...",
              style: TextStyle(
                color: _CourseTokens.textHint,
                fontSize: 12.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatefulWidget {
  final String label;
  const _FilterPill({required this.label});

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: hover ? const Color(0xFFEAF2FF) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: _CourseTokens.textMuted,
                fontSize: 12.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _CourseTokens.textMuted),
          ],
        ),
      ),
    );
  }
}

// ----------------------------
// Courses Grid
// ----------------------------
class _CoursesGrid extends StatelessWidget {
  final int columns;
  const _CoursesGrid({required this.columns});

  @override
  Widget build(BuildContext context) {
    final items = _demoCourses();

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 16.0;
        final totalWidth = constraints.maxWidth;
        final columnWidth = (totalWidth - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.map((course) {
            return SizedBox(
              width: columnWidth,
              child: _CourseCard(model: course),
            );
          }).toList(),
        );
      },
    );
  }
}

enum _CourseStatus { active, draft, archived }

class _CourseModel {
  final String code;
  final _CourseStatus status;
  final String title;
  final String meta;
  final int students;
  final int modules;
  final String memberCountText;
  final String? note;
  final String coverUrl;

  const _CourseModel({
    required this.code,
    required this.status,
    required this.title,
    required this.meta,
    required this.students,
    required this.modules,
    required this.coverUrl,
    this.memberCountText = "",
    this.note,
  });
}

List<_CourseModel> _demoCourses() => const [
      _CourseModel(
        code: "CS-405",
        status: _CourseStatus.active,
        title: "Advanced Machine Learning",
        meta: "Fall 2023 • Computer Science Dept.",
        students: 45,
        modules: 8,
        memberCountText: "+42",
        coverUrl: "https://images.unsplash.com/photo-1526378722484-bd91ca387e72?auto=format&fit=crop&w=1400&q=80",
      ),
      _CourseModel(
        code: "ENG-201",
        status: _CourseStatus.draft,
        title: "Introduction to Robotics",
        meta: "Spring 2024 • Engineering Dept.",
        students: 0,
        modules: 2,
        note: "Setup in progress...",
        coverUrl: "https://images.unsplash.com/photo-1527443154391-507e9dc6c5cc?auto=format&fit=crop&w=1400&q=80",
      ),
      _CourseModel(
        code: "CS-101",
        status: _CourseStatus.active,
        title: "Algorithms & Data Structures",
        meta: "Fall 2023 • Computer Science Dept.",
        students: 120,
        modules: 14,
        memberCountText: "+118",
        coverUrl: "https://images.unsplash.com/photo-1518779578993-ec3579fee39f?auto=format&fit=crop&w=1400&q=80",
      ),
      _CourseModel(
        code: "CS-202",
        status: _CourseStatus.archived,
        title: "Database Systems",
        meta: "Spring 2022 • Computer Science Dept.",
        students: 89,
        modules: 10,
        note: "Course ended",
        coverUrl: "https://images.unsplash.com/photo-1528460033278-a6ba57020470?auto=format&fit=crop&w=1400&q=80",
      ),
    ];

// ==================== بطاقة الكورس (FIXED - no scroll, no overflow) ====================
class _CourseCard extends StatefulWidget {
  final _CourseModel model;

  const _CourseCard({required this.model});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.model;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_CourseTokens.radiusCard),
          boxShadow: hover ? _CourseTokens.hoverShadow : _CourseTokens.shadow,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go('${Routes.instructorCourses}/${Uri.encodeComponent(m.title)}'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_CourseTokens.radiusCard),
            child: Container(
              height: _CourseTokens.courseCardHeight,
              decoration: BoxDecoration(
                color: _CourseTokens.cardBg,
                borderRadius: BorderRadius.circular(_CourseTokens.radiusCard),
                border: Border.all(color: _CourseTokens.border),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: _CourseTokens.heroHeight,
                    child: _CourseHero(
                      status: m.status,
                      code: m.code,
                      imageUrl: m.coverUrl,
                    ),
                  ),
                  // ✅ باقي الكارت ياخد المساحة المتاحة بدقة
                  Expanded(
                    child: _CourseContent(model: m),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== Hero (Rounded image + OLD status style) ====================
class _CourseHero extends StatelessWidget {
  final _CourseStatus status;
  final String code;
  final String imageUrl;

  const _CourseHero({
    required this.status,
    required this.code,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = status == _CourseStatus.active
        ? "Active"
        : status == _CourseStatus.draft
            ? "Draft"
            : "Archived";

    final statusColor = status == _CourseStatus.active
        ? const Color(0xFF16A34A)
        : status == _CourseStatus.draft
            ? const Color(0xFFF59E0B)
            : const Color(0xFF64748B);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(_CourseTokens.radiusCard),
        topRight: Radius.circular(_CourseTokens.radiusCard),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEFF2F6)),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.10))),

          // code
          Positioned(
            right: 12,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _CourseTokens.border),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: _CourseTokens.textPrimary,
                ),
              ),
            ),
          ),

          // ✅ status (SAME AS OLD: filled + white)
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.90),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: statusColor.withOpacity(0.32)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == _CourseStatus.active
                        ? Icons.check_circle_rounded
                        : status == _CourseStatus.draft
                            ? Icons.edit_rounded
                            : Icons.archive_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Bottom content (NO SCROLL + NO OVERFLOW) ====================
class _CourseContent extends StatelessWidget {
  final _CourseModel model;
  const _CourseContent({required this.model});

  @override
  Widget build(BuildContext context) {
    final m = model;
    final showPeople = m.students > 0 || m.memberCountText.isNotEmpty;
    final note = (m.note ?? "").trim();

    return LayoutBuilder(
      builder: (context, c) {
        // ✅ لما الكارت يبقى ضيق (زي 287px) نقلل البادينج والخطوط
        final tight = c.maxWidth < 320;

        final pad = tight ? 14.0 : 18.0;
        final titleSize = tight ? 15.5 : 16.5;
        final metaSize = tight ? 11.5 : 12.5;
        final rowTextSize = tight ? 11.5 : 12.5;

        return Padding(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                m.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: titleSize,
                  height: 1.15,
                  color: _CourseTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Meta
              Text(
                m.meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w400,
                  fontSize: metaSize,
                  color: _CourseTokens.textMuted,
                ),
              ),

              const SizedBox(height: 10),

              // ✅ Students + Modules row: fits even when narrow
              SizedBox(
                height: 18,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: _CourseTokens.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        "${m.students} Students",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w400,
                          fontSize: rowTextSize,
                          color: _CourseTokens.textMuted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.menu_book_outlined, size: 16, color: _CourseTokens.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        "${m.modules} Modules",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w400,
                          fontSize: rowTextSize,
                          color: _CourseTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              const Divider(height: 1, thickness: 1, color: _CourseTokens.divider),
              const SizedBox(height: 10),

              // ✅ Footer ثابت (مش هيكسر)
              SizedBox(
                height: 34,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: showPeople
                            ? _PeopleFooter(memberCountText: m.memberCountText)
                            : _NoteFooter(text: note.isEmpty ? "Course ended" : note),
                      ),
                    ),
                    _IconActionButton(icon: Icons.work_outline_rounded, onTap: () {}),
                    const SizedBox(width: 6),
                    _IconActionButton(icon: Icons.more_vert_rounded, onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PeopleFooter extends StatelessWidget {
  final String memberCountText;
  const _PeopleFooter({required this.memberCountText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _AvatarStackSmall(),
        if (memberCountText.trim().isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F4),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _CourseTokens.border),
            ),
            child: Text(
              memberCountText,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: _CourseTokens.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NoteFooter extends StatelessWidget {
  final String text;
  const _NoteFooter({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: _CourseTokens.textMuted,
      ),
    );
  }
}

// ✅ نسخة أصغر (أقرب لفigma + تضمن مفيش overflow)
class _AvatarStackSmall extends StatelessWidget {
  const _AvatarStackSmall();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      width: 52,
      child: Stack(
        children: [
          _a(0, const Color(0xFFE2E8F0)),
          _a(16, const Color(0xFFDBEAFE)),
        ],
      ),
    );
  }

  Widget _a(double left, Color bg) {
    return Positioned(
      left: left,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          color: bg,
        ),
        child: const Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
      ),
    );
  }
}

// ==================== Action Buttons (no overflow) ====================
class _IconActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconActionButton({required this.icon, required this.onTap});

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: hover ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: widget.icon == Icons.work_outline_rounded ? _CourseTokens.blue : _CourseTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

// ==================== Card Shell ====================
class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _CardShell({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _CourseTokens.cardBg,
        borderRadius: BorderRadius.circular(_CourseTokens.radiusCard),
        border: Border.all(color: _CourseTokens.border),
      ),
      child: child,
    );
  }
}