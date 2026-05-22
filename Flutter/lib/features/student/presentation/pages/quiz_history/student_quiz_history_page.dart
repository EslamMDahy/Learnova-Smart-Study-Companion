import 'package:flutter/material.dart';

class StudentQuizHistoryPage extends StatelessWidget {
  const StudentQuizHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // تم استخدام Padding خارجي مريح (64 من اليمين والشمال، و 40 من فوق وتحت) 
    // ليعطي نفس إحساس الفراغ والابتعاد عن الـ Sidebar والـ Header الموجود في الصورة.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE SECTION
          const Text(
            'My Quiz History',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xff1e293b),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'View your past results, scores, and performance metrics across all courses.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff64748b),
            ),
          ),
          const SizedBox(height: 32),

          /// STATS CARDS
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Total Quizzes Taken',
                  value: '24',
                  subText: '↑ +2 this week',
                  icon: Icons.assignment_turned_in_outlined,
                  iconColor: const Color(0xff3b82f6),
                  subTextColor: const Color(0xff22c55e),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _statCard(
                  title: 'Average Score',
                  value: '82%',
                  subText: 'Top 15% of class average',
                  icon: Icons.bar_chart_rounded,
                  iconColor: const Color(0xff22c55e),
                  subTextColor: const Color(0xff64748b),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _statCard(
                  title: 'Pending Retakes',
                  value: '2',
                  subText: 'Due within 3 days',
                  icon: Icons.assignment_late_outlined,
                  iconColor: const Color(0xfff97316),
                  subTextColor: const Color(0xfff97316),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          /// SEARCH & FILTER BAR
          Row(
            children: [
              // شريط البحث الممتد
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xfff1f5f9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TextField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search by quiz name, topic...',
                      hintStyle: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
                      prefixIcon: Icon(Icons.search, size: 18, color: Color(0xff94a3b8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _filterButton('All Courses'),
              const SizedBox(width: 12),
              _filterButton('Status: All'),
              const SizedBox(width: 12),
              // زر More Filters المتناسق مع الصورة
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tune, size: 16, color: Color(0xff64748b)),
                    SizedBox(width: 8),
                    Text(
                      'More Filters',
                      style: TextStyle(color: Color(0xff64748b), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          /// DATA TABLE CONTAINER
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffe2e8f0)),
            ),
            child: Column(
              children: [
                /// TABLE HEADER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xfff8fafc),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                    border: Border(bottom: BorderSide(color: const Color(0xffe2e8f0))),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: Text('QUIZ DETAILS', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('DATE TAKEN', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('DURATION', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('SCORE', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('STATUS', style: _headerStyle)),
                      Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('ACTIONS', style: _headerStyle))),
                    ],
                  ),
                ),

                /// TABLE ROWS (بيانات مطابقة للصورة تماماً)
                _quizRow(
                  title: 'Intro to Machine Learning - Midterm',
                  code: 'CS401',
                  subtitle: 'Module 4 Assessment',
                  date: 'Oct 24, 2023',
                  time: '10:30 AM',
                  duration: '45m 12s',
                  score: '88%',
                  progress: 0.88,
                  progressColor: const Color(0xff22c55e),
                  status: 'Passed',
                  statusColor: const Color(0xff22c55e),
                  actions: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.visibility_outlined, size: 18, color: Color(0xff64748b)),
                      SizedBox(width: 12),
                      Icon(Icons.refresh, size: 18, color: Color(0xff64748b)),
                    ],
                  ),
                ),

                _quizRow(
                  title: 'Data Structures Basics',
                  code: 'CS202',
                  subtitle: 'Weekly Quiz 3',
                  date: 'Oct 20, 2023',
                  time: '02:15 PM',
                  duration: '28m 05s',
                  score: '92%',
                  progress: 0.92,
                  progressColor: const Color(0xff22c55e),
                  status: 'Passed',
                  statusColor: const Color(0xff22c55e),
                  actions: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.visibility_outlined, size: 18, color: Color(0xff64748b)),
                    ],
                  ),
                ),

                _quizRow(
                  title: 'Advanced Calculus - Quiz 1',
                  code: 'MATH301',
                  subtitle: '',
                  date: 'Oct 18, 2023',
                  time: '09:00 AM',
                  duration: '55m 00s',
                  score: '45%',
                  progress: 0.45,
                  progressColor: const Color(0xffef4444),
                  status: 'Failed',
                  statusColor: const Color(0xffef4444),
                  actions: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.visibility_outlined, size: 18, color: Color(0xff64748b)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xffeff6ff),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xffbfdbfe)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, size: 14, color: Color(0xff2563eb)),
                            SizedBox(width: 4),
                            Text(
                              'Retake',
                              style: TextStyle(color: Color(0xff2563eb), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _quizRow(
                  title: 'Physics II - Electromagnetism',
                  code: 'PHY102',
                  subtitle: '',
                  date: 'Oct 15, 2023',
                  time: '11:45 AM',
                  duration: '-',
                  score: 'Not graded',
                  progress: 0.0,
                  progressColor: Colors.transparent,
                  status: 'Pending',
                  statusColor: const Color(0xfff59e0b),
                  actions: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Color(0xff64748b)),
                    ],
                  ),
                ),

                _quizRow(
                  title: 'Operating Systems - Final',
                  code: 'CS305',
                  subtitle: '',
                  date: 'Oct 10, 2023',
                  time: '01:00 PM',
                  duration: '1h 12m',
                  score: '76%',
                  progress: 0.76,
                  progressColor: const Color(0xffeab308),
                  status: 'Passed',
                  statusColor: const Color(0xff22c55e),
                  isLast: true, // لإلغاء الخط السفلي لآخر عنصر في الجدول
                  actions: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.visibility_outlined, size: 18, color: Color(0xff64748b)),
                    ],
                  ),
                ),

                /// TABLE FOOTER (PAGINATION)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    children: [
                      const Text(
                        'Showing 1-5 of 24 results',
                        style: TextStyle(color: Color(0xff64748b), fontSize: 13),
                      ),
                      const Spacer(),
                      _pageButton('Previous', disabled: true),
                      const SizedBox(width: 8),
                      _pageButton('Next', disabled: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xff64748b),
    letterSpacing: 0.5,
  );

  static Widget _statCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color iconColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xff64748b), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xff0f172a)),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static Widget _filterButton(String text) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5f9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xff334155), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xff64748b)),
        ],
      ),
    );
  }

  static Widget _quizRow({
    required String title,
    required String code,
    required String subtitle,
    required String date,
    required String time,
    required String duration,
    required String score,
    required double progress,
    required Color progressColor,
    required String status,
    required Color statusColor,
    required Widget actions,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xffe2e8f0))),
      ),
      child: Row(
        children: [
          /// DETAILS Column
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xff0f172a)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffe0e7ff),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(color: Color(0xff4338ca), fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xff94a3b8), fontSize: 12),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),

          /// DATE TAKEN Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontSize: 13, color: Color(0xff334155), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: Color(0xff94a3b8))),
              ],
            ),
          ),

          /// DURATION Column
          Expanded(
            flex: 2,
            child: Text(
              duration,
              style: TextStyle(
                fontSize: 13, 
                color: duration == '-' ? const Color(0xff94a3b8) : const Color(0xff64748b)
              ),
            ),
          ),

          /// SCORE Column
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  score,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: score == 'Not graded' ? const Color(0xff94a3b8) : const Color(0xff0f172a),
                  ),
                ),
                if (progress > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      width: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: const Color(0xfff1f5f9),
                          valueColor: AlwaysStoppedAnimation(progressColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // مسافة تضمن تباعد البروجرس بار عن العمود القادم
                ],
              ],
            ),
          ),

          /// STATUS Column
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// ACTIONS Column
          Expanded(
            flex: 2,
            child: actions,
          ),
        ],
      ),
    );
  }

  static Widget _pageButton(String text, {required bool disabled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: disabled ? const Color(0xfff8fafc) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: disabled ? const Color(0xffcbd5e1) : const Color(0xff334155),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}