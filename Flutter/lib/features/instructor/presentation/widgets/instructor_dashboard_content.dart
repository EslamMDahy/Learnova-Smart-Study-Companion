import 'package:flutter/material.dart';

class InstructorDashboardContent extends StatelessWidget {
  const InstructorDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final screenW = c.maxWidth;

        // ✅ 1) خلي المحتوى يكبر مع الشاشة بدل ما يتثبت على 1180
        // - لحد 1560 كحد أقصى عشان ما يبقاش "مفروش" قوي.
        // - وعلى الشاشات المتوسطة يفضل قريب من التصميم.
        final maxContentWidth = _clamp(screenW - 220, 1180, 1560);

        // ✅ 2) padding ديناميكي:
        // على الشاشات الكبيرة نقلله (عشان الفراغ الخارجي يقل)
        final horizontalPadding = screenW >= 1600
            ? 24.0
            : screenW >= 1400
                ? 32.0
                : screenW >= 1100
                    ? 48.0
                    : 20.0;

        final topPadding = screenW < 900 ? 18.0 : 26.0;

        final isCompact = screenW < 980;

        return Container(
          color: _T.pageBg,
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Breadcrumb(),
                      const SizedBox(height: 10),
                      const _TitleBlock(),
                      const SizedBox(height: 22),
                      const _StatsRow(),
                      const SizedBox(height: 22),

                      if (isCompact) ...[
                        const _SectionHeaderRowCompact(),
                        const SizedBox(height: 12),
                        const _RecentActivityCard(),
                        const SizedBox(height: 16),
                        const _QuickActionsBlock(compact: true),
                        const SizedBox(height: 16),
                        const _SystemUsageBlock(),
                      ] else ...[
                        const _SectionHeaderRowDesktop(),
                        const SizedBox(height: 12),

                        // ✅ 3) توزيع الأعمدة أحسن على الشاشات الكبيرة
                        // بدل 2:1 ثابتة، نخليها 7:4 بحيث يقل الفراغ ويكبر المحتوى.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(flex: 7, child: _RecentActivityCard()),
                            SizedBox(width: 22),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _QuickActionsBlock(compact: false),
                                  SizedBox(height: 18),
                                  _SystemUsageBlock(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

double _clamp(double v, double min, double max) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}

class _T {
  static const pageBg = Color(0xFFF6F7F8);

  static const cardBg = Colors.white;
  static const border = Color(0xFFE6EAF2);
  static const divider = Color(0xFFEEF2F6);

  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const hint = Color(0xFF94A3B8);

  static const link = Color(0xFF2563EB);

  static const shadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const radius = 12.0;
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          "Home",
          style: TextStyle(
            color: _T.hint,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 6),
        Icon(Icons.chevron_right, size: 16, color: Color(0xFFCBD5E1)),
        SizedBox(width: 6),
        Text(
          "Instructor Dashboard",
          style: TextStyle(
            color: _T.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back, Professor Anderson",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _T.text,
            height: 1.15,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Here's what's happening with your AI study assistant today.",
          style: TextStyle(
            color: _T.muted,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wrap = c.maxWidth < 980;

        const presets = [
          _StatPreset.uploadedMaterials,
          _StatPreset.extractedTopics,
          _StatPreset.generatedQuestions,
          _StatPreset.activeStudents,
        ];

        if (!wrap) {
          return const Row(
            children: [
              Expanded(child: _StatCard(preset: _StatPreset.uploadedMaterials)),
              SizedBox(width: 16),
              Expanded(child: _StatCard(preset: _StatPreset.extractedTopics)),
              SizedBox(width: 16),
              Expanded(child: _StatCard(preset: _StatPreset.generatedQuestions)),
              SizedBox(width: 16),
              Expanded(child: _StatCard(preset: _StatPreset.activeStudents)),
            ],
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: presets
              .map((p) => SizedBox(
                    width: (c.maxWidth - 16) / 2,
                    child: _StatCard(preset: p),
                  ))
              .toList(),
        );
      },
    );
  }
}

enum _StatPreset { uploadedMaterials, extractedTopics, generatedQuestions, activeStudents }

class _StatCard extends StatelessWidget {
  final _StatPreset preset;
  const _StatCard({required this.preset});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color iconColor, Color iconBg, String title, String value, String trend) =
        switch (preset) {
      _StatPreset.uploadedMaterials => (
          Icons.folder_open_rounded,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
          "Uploaded Materials",
          "12 Files",
          "+2",
        ),
      _StatPreset.extractedTopics => (
          Icons.lightbulb_outline_rounded,
          const Color(0xFF9333EA),
          const Color(0xFFF3E8FF),
          "Extracted Topics",
          "45 Concepts",
          "+5",
        ),
      _StatPreset.generatedQuestions => (
          Icons.format_list_bulleted_rounded,
          const Color(0xFFF97316),
          const Color(0xFFFFEDD5),
          "Generated Questions",
          "120 Items",
          "+20",
        ),
      _StatPreset.activeStudents => (
          Icons.people_outline_rounded,
          const Color(0xFF10B981),
          const Color(0xFFD1FAE5),
          "Active Students",
          "85 Enrolled",
          "+3",
        ),
    };

    return _Card(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: SizedBox(
        height: 92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const Spacer(),
                _TrendPill(value: trend),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: _T.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: _T.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  final String value;
  const _TrendPill({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, size: 14, color: Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF16A34A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderRowDesktop extends StatelessWidget {
  const _SectionHeaderRowDesktop();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          flex: 7,
          child: Row(
            children: [
              Text(
                "Recent Activity",
                style: TextStyle(
                  color: _T.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              _ViewAllLink(),
            ],
          ),
        ),
        SizedBox(width: 22),
        Expanded(
          flex: 4,
          child: Text(
            "Quick Actions",
            style: TextStyle(
              color: _T.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderRowCompact extends StatelessWidget {
  const _SectionHeaderRowCompact();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          "Recent Activity",
          style: TextStyle(
            color: _T.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Spacer(),
        _ViewAllLink(),
      ],
    );
  }
}

class _ViewAllLink extends StatelessWidget {
  const _ViewAllLink();

  @override
  Widget build(BuildContext context) {
    return Text(
      "View All",
      style: const TextStyle(
        color: _T.link,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Column(
        children: [
          _ActivityRow(
            icon: Icons.auto_awesome_rounded,
            iconBg: Color(0xFFF3E8FF),
            iconColor: Color(0xFF9333EA),
            title: "AI Processing Complete",
            subtitle:
                "The system successfully extracted 15 topics from \"Intro_to_Algorithms_Lec3.pdf\".",
            time: "2 mins ago",
          ),
          _Line(),
          _ActivityRow(
            icon: Icons.check_circle_rounded,
            iconBg: Color(0xFFDBEAFE),
            iconColor: Color(0xFF2563EB),
            title: "Quiz Published",
            subtitle: "\"Midterm Practice Quiz\" is now available to 85 students.",
            time: "1 hour ago",
          ),
          _Line(),
          _ActivityRow(
            icon: Icons.warning_amber_rounded,
            iconBg: Color(0xFFFFEDD5),
            iconColor: Color(0xFFF97316),
            title: "Review Needed",
            subtitle:
                "3 generated questions for \"Neural Networks\" have been flagged for ambiguity.",
            time: "3 hours ago",
          ),
          _Line(),
          _ActivityRow(
            icon: Icons.person_add_alt_1_rounded,
            iconBg: Color(0xFFD1FAE5),
            iconColor: Color(0xFF10B981),
            title: "New Enrollment",
            subtitle: "Student Sarah Jenkins joined the course.",
            time: "5 hours ago",
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _T.text,
                    fontSize: 12.6,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _T.muted,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w500,
                    height: 1.30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              time,
              style: const TextStyle(
                color: _T.hint,
                fontSize: 10.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Divider(height: 1, thickness: 1, color: _T.divider),
    );
  }
}

class _QuickActionsBlock extends StatelessWidget {
  final bool compact;
  const _QuickActionsBlock({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              color: _T.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const _QuickActionsCard(),
        ],
      );
    }
    return const _QuickActionsCard();
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(14),
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(child: _QuickTile(icon: Icons.upload_file_rounded, label: "Upload Material")),
              SizedBox(width: 12),
              Expanded(child: _QuickTile(icon: Icons.auto_awesome_outlined, label: "Generate Quiz")),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _QuickTile(icon: Icons.rule_folder_outlined, label: "Review Bank")),
              SizedBox(width: 12),
              Expanded(child: _QuickTile(icon: Icons.insert_chart_outlined_rounded, label: "View Reports")),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F172A)),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: _T.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemUsageBlock extends StatelessWidget {
  const _SystemUsageBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "System Usage",
          style: TextStyle(
            color: _T.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12),
        _SystemUsageCard(),
      ],
    );
  }
}

class _SystemUsageCard extends StatelessWidget {
  const _SystemUsageCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Weekly Token Usage",
                  style: TextStyle(
                    color: _T.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _LimitPill(),
            ],
          ),
          SizedBox(height: 6),
          Text(
            "12,450",
            style: TextStyle(
              color: _T.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 14),
          _UsageChart(),
        ],
      ),
    );
  }
}

class _LimitPill extends StatelessWidget {
  const _LimitPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Text(
        "85% Limit",
        style: TextStyle(
          color: _T.link,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UsageChart extends StatelessWidget {
  const _UsageChart();

  @override
  Widget build(BuildContext context) {
    const labels = ["MON", "TUE", "WED", "THU", "FRI"];
    const values = [0.20, 0.30, 0.95, 0.40, 0.28];

    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              children: List.generate(labels.length, (i) {
                final h = switch (labels[i]) {
                  "MON" => 28.0,
                  "TUE" => 38.0,
                  "WED" => 52.0,
                  "THU" => 38.0,
                  _ => 28.0,
                };
                return Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 56,
                      height: h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(labels.length, (i) {
                final isActive = labels[i] == "WED";
                return Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 56,
                      height: 92 * values[i],
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF1682E6) : const Color(0x00000000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: List.generate(labels.length, (i) {
                  final isActive = labels[i] == "WED";
                  return Expanded(
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: isActive ? _T.link : _T.hint,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Card({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _T.cardBg,
        borderRadius: BorderRadius.circular(_T.radius),
        border: Border.all(color: _T.border),
        boxShadow: _T.shadow,
      ),
      child: child,
    );
  }
}
