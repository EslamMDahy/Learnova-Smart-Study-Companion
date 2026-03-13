import 'package:flutter/material.dart';
import '../widgets/app_ui_components.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _search = TextEditingController();
  int _topChipIndex = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chips = const [
      "All",
      "High Priority",
      "Assignments",
      "Grades",
      "Mentions",
    ];

    return Container(
      color: AppColors.pageBg,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: AppSpacing.notificationsPage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (title + button)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Notifications", style: AppText.h1),
                          SizedBox(height: 8),
                          Text(
                            "Stay updated with your courses and system alerts",
                            style: AppText.subtitle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    AppPrimarySoftButton(
                      label: "Mark all as read",
                      onTap: () {
                        // TODO: hook logic
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search
                AppSearchField(
                  controller: _search,
                  hintText: "Search notifications by keyword, professor, or date...",
                ),

                const SizedBox(height: 12),

                // Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(chips.length, (i) {
                      return Padding(
                        padding: EdgeInsets.only(right: i == chips.length - 1 ? 0 : 8),
                        child: AppFilterChip(
                          label: chips[i],
                          selected: i == _topChipIndex,
                          onTap: () => setState(() => _topChipIndex = i),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // List (مثال)
                const AppNotificationCard(
                  title: "Assignment Due Soon: Neural Networks",
                  subtitle:
                      'Reminder: The project "Backpropagation Implementation" is due tomorrow at 11:59 PM.',
                  rightTag: "Yesterday",
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    "End of notifications",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
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
