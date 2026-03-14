import 'package:flutter/material.dart';
import 'package:learnova/shared/widgets/design_tokens.dart';

/// Instructor Dashboard content (matches provided HTML prototype).
class InstructorDashboardContent extends StatelessWidget {
  final String userName;
  const InstructorDashboardContent({
    super.key,
    this.userName = 'Professor Anderson',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;

      // Match HTML breakpoints: 1000 => 2 stats cols, 600 => 1 col.
      final statsCols = w <= 600 ? 1 : (w <= 1000 ? 2 : 4);
      final isTwoColStacked = w <= 980;

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: w < 600 ? 16 : 32,
          vertical: w < 600 ? 16 : 24,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Breadcrumb(items: [
                  'Home',
                  'Instructor Dashboard',
                ]),
                const SizedBox(height: 10),
                Text(
                  'Welcome back, $userName',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: AppColors.text,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Here's what's happening with your AI study assistant today.",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 20),

                // Stats grid
                _StatsGrid(
                  columns: statsCols,
                  children: const [
                    _StatCard(
                      iconBg: Color(0xFFEFF6FF),
                      iconColor: AppColors.primary,
                      icon: Icons.folder_open_rounded,
                      trendText: '+2',
                      label: 'Uploaded Materials',
                      value: '12 Files',
                    ),
                    _StatCard(
                      iconBg: Color(0xFFF3E8FF),
                      iconColor: Color(0xFF9333EA),
                      icon: Icons.info_outline_rounded,
                      trendText: '+5',
                      label: 'Extracted Topics',
                      value: '45 Concepts',
                    ),
                    _StatCard(
                      iconBg: Color(0xFFFFEDD5),
                      iconColor: Color(0xFFF97316),
                      icon: Icons.format_list_bulleted_rounded,
                      trendText: '+20',
                      label: 'Generated Questions',
                      value: '120 Items',
                    ),
                    _StatCard(
                      iconBg: Color(0xFFD1FAE5),
                      iconColor: Color(0xFF10B981),
                      icon: Icons.groups_rounded,
                      trendText: '+3',
                      label: 'Active Students',
                      value: '85 Enrolled',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Two columns
                Flex(
                  direction: isTwoColStacked ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(title: 'Recent Activity', actionText: 'View All'),
                          _ActivityCard(),
                        ],
                      ),
                    ),
                    SizedBox(width: isTwoColStacked ? 0 : 20, height: isTwoColStacked ? 20 : 0),
                    const Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 12),
                          _QuickActionsCard(),
                          SizedBox(height: 18),
                          Text(
                            'System Usage',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 12),
                          _UsageCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/* ------------------------------- Breadcrumb ------------------------------- */

class _Breadcrumb extends StatelessWidget {
  final List<String> items;
  const _Breadcrumb({required this.items});

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final isLast = i == items.length - 1;
      widgets.add(Text(
        items[i],
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: isLast ? AppColors.text : AppColors.hint,
        ),
      ));
      if (!isLast) {
        widgets.add(const SizedBox(width: 6));
        widgets.add(const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFCBD5E1)));
        widgets.add(const SizedBox(width: 6));
      }
    }

    return Row(children: widgets);
  }
}

/* --------------------------------- Stats --------------------------------- */

class _StatsGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;
  const _StatsGrid({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final colW = (w - gap * (columns - 1)) / columns;

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children
            .map((e) => SizedBox(width: colW, child: e))
            .toList(),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String trendText;
  final String label;
  final String value;

  const _StatCard({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.trendText,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
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
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFDF4),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 12, color: Color(0xFF16A34A)),
                    const SizedBox(width: 5),
                    Text(
                      trendText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ Activity Card ----------------------------- */

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  const _SectionHeader({required this.title, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const Spacer(),
        Text(
          actionText,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: const Column(
        children: [
          _ActivityRow(
            iconBg: Color(0xFFF3E8FF),
            iconColor: Color(0xFF9333EA),
            icon: Icons.layers_rounded,
            title: 'AI Processing Complete',
            sub: 'The system successfully extracted 15 topics from "Intro_to_Algorithms_Lec3.pdf".',
            time: '2 mins ago',
          ),
          _Divider(),
          _ActivityRow(
            iconBg: Color(0xFFDBEAFE),
            iconColor: AppColors.primary,
            icon: Icons.check_circle_outline_rounded,
            title: 'Quiz Published',
            sub: '"Midterm Practice Quiz" is now available to 85 students.',
            time: '1 hour ago',
          ),
          _Divider(),
          _ActivityRow(
            iconBg: Color(0xFFFFEDD5),
            iconColor: Color(0xFFF97316),
            icon: Icons.warning_amber_rounded,
            title: 'Review Needed',
            sub: '3 generated questions for "Neural Networks" have been flagged for ambiguity.',
            time: '3 hours ago',
          ),
          _Divider(),
          _ActivityRow(
            iconBg: Color(0xFFD1FAE5),
            iconColor: Color(0xFF10B981),
            icon: Icons.person_add_alt_1_rounded,
            title: 'New Enrollment',
            sub: 'Student Sarah Jenkins joined the course.',
            time: '5 hours ago',
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}

class _ActivityRow extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String sub;
  final String time;

  const _ActivityRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.sub,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.hint,
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Quick Actions ------------------------------ */

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final cols = w < 300 ? 1 : 2;
        final tileW = (w - (cols - 1) * 10) / cols;

        const tileH = 78.0;

        const tiles = [
          _QuickTile(icon: Icons.cloud_upload_outlined, label: 'Upload Material'),
          _QuickTile(icon: Icons.auto_awesome_rounded, label: 'Generate Quiz'),
          _QuickTile(icon: Icons.fact_check_outlined, label: 'Review Bank'),
          _QuickTile(icon: Icons.bar_chart_rounded, label: 'View Reports'),
        ];

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tiles
              .map((t) => SizedBox(width: tileW, height: tileH, child: t))
              .toList(),
        );
      }),
    );
  }
}

class _QuickTile extends StatefulWidget {
  final IconData icon;
  final String label;
  const _QuickTile({required this.icon, required this.label});

  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = hover ? const Color(0xFFEFF6FF) : const Color(0xFFF1F3F5);
    final border = hover ? const Color(0xFFDBEAFE) : AppColors.border;
    final iconColor = hover ? AppColors.primary : AppColors.text;
    final textColor = hover ? AppColors.primary : AppColors.text;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18, color: iconColor),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ Usage Card -------------------------------- */

class _UsageCard extends StatelessWidget {
  const _UsageCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Weekly Token Usage',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Text(
                    '85% Limit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '12,450',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 14),
            _MiniBarChart(),
          ],
        ),
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Match the "WED active" chart. Heights roughly: 28,38,82,38,28
    const values = [28.0, 38.0, 82.0, 38.0, 28.0];
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    const activeIndex = 2;

    return SizedBox(
      height: 110,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final v = values[i];
                final isActive = i == activeIndex;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 44,
                        height: v,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: isActive ? AppColors.primary : AppColors.hint,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
