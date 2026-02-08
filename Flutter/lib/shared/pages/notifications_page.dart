import 'package:flutter/material.dart';

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
    // ألوان قريبة من اللي باينة في التصميم
    const bg = Color(0xFFF6F7F8);
    const textDark = Color(0xFF0F172A);
    const textMuted = Color(0xFF64748B);
    const hint = Color(0xFF94A3B8);
    const border = Color(0xFFE2E8F0);

    final chips = const [
      "All",
      "High Priority",
      "Assignments",
      "Grades",
      "Mentions",
    ];

    return Container(
      color: bg,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
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
                          Text(
                            "Notifications",
                            style: TextStyle(
                              fontFamily: "Manrope",
                              fontSize: 35.6,
                              fontWeight: FontWeight.w800,
                              height: 40 / 35.6,
                              letterSpacing: -1.188,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Stay updated with your courses and system alerts",
                            style: TextStyle(
                              fontFamily: "Manrope",
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: textMuted,
                              height: 24 / 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _PrimarySoftButton(
                      label: "Mark all as read",
                      onTap: () {
                        // TODO: hook logic
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ✅ Search (مطابق لفigma)
                _SearchField(
                  controller: _search,
                  hintText:
                      "Search notifications by keyword, professor, or date...",
                  hintColor: hint,
                  borderColor: border,
                ),

                const SizedBox(height: 12),

                // Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(chips.length, (i) {
                      final selected = i == _topChipIndex;
                      return Padding(
                        padding: EdgeInsets.only(right: i == chips.length - 1 ? 0 : 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => setState(() => _topChipIndex = i),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: selected ? textDark : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? textDark : border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              chips[i],
                              style: TextStyle(
                                fontFamily: "Manrope",
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? Colors.white : const Color(0xFF334155),
                                height: 20 / 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // List
                const _NotificationCard(
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
                      fontFamily: "Manrope",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hint,
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color hintColor;
  final Color borderColor;

  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.hintColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // ✅ في الفيجما 48
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // ✅ في الفيجما 12
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // قريب من rgba(0,0,0,0.05)
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
        border: Border.all(color: borderColor), // لو حابب تشيلها امسح السطر ده
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontFamily: "Manrope",
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 22 / 16,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: "Manrope",
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 22 / 16,
            color: hintColor,
          ),

          // ✅ icon جوه الـ field زي الفيجما + padding مظبوط (40px قبل النص تقريباً)
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 48),

          // ✅ padding الداخلي بتاع النص
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

class _PrimarySoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimarySoftButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE2E8F0);
    const textDark = Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8), // الفيجما 8
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              blurRadius: 2,
              offset: Offset(0, 1),
              color: Color(0x0D000000),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textDark,
            height: 20 / 14,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String rightTag;

  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.rightTag,
  });

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE2E8F0);
    const textDark = Color(0xFF334155);
    const textMuted = Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: "Manrope",
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          height: 28 / 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Yesterday",
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: "Manrope",
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: textMuted,
                    height: 23 / 14,
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
