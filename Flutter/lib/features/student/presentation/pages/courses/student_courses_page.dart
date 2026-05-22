import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learnova/core/routing/routes.dart';

class StudentCoursesPage extends StatelessWidget {
  const StudentCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // تحديث تدرجات الألوان (Gradients) لتصبح أكثر حيوية وجاذبية وعصرية
    final courses = [
      {
        "title": "Intro to Machine Learning",
        "code": "CS-204",
        "credits": "3 Credits",
        "teacher": "Dr. Sarah Chen",
        "department": "Computer Science Dept.",
        "schedule": "Mon/Wed 10:00 AM",
        "location": "Building A, 302",
        "description":
            "A comprehensive introduction to machine learning concepts, algorithms, and applications.",
        "status": "Open",
        "button": "Enroll",
        "gradient1": const Color(0xff4F46E5), // Indigo
        "gradient2": const Color(0xff06B6D4), // Cyan
      },
      {
        "title": "Advanced Algorithms",
        "code": "CS-301",
        "credits": "4 Credits",
        "teacher": "Prof. Alan Smith",
        "department": "Computer Science Dept.",
        "schedule": "Tue/Thu 2:00 PM",
        "location": "Remote",
        "description":
            "Deep dive into graph algorithms, dynamic programming, and NP-completeness.",
        "status": "Waitlist",
        "button": "Join Waitlist",
        "gradient1": const Color(0xff7C3AED), // Purple
        "gradient2": const Color(0xffEC4899), // Pink
      },
      {
        "title": "Data Structures",
        "code": "DS-101",
        "credits": "3 Credits",
        "teacher": "Dr. Emily White",
        "department": "Data Science Dept.",
        "schedule": "Fri 9:00 AM",
        "location": "Lab 404",
        "description":
            "Fundamental data structures including arrays, linked lists, stacks, queues, trees, and graphs.",
        "status": "Enrolled",
        "button": "Enrolled",
        "gradient1": const Color(0xff1E3A8A), // Royal Blue
        "gradient2": const Color(0xff3B82F6), // Light Blue
      },
      {
        "title": "Full Stack Development",
        "code": "WEB-200",
        "credits": "3 Credits",
        "teacher": "Michael Torres",
        "department": "Engineering Dept.",
        "schedule": "Mon/Wed 3:00 PM",
        "location": "Building B, 101",
        "description": "Modern web development with React, Node.js, and SQL.",
        "status": "Open",
        "button": "Enroll",
        "gradient1": const Color(0xff0F766E), // Teal
        "gradient2": const Color(0xff10B981), // Emerald
      },
      {
        "title": "Engineering Ethics",
        "code": "ETH-101",
        "credits": "2 Credits",
        "teacher": "Dr. James Wilson",
        "department": "Humanities Dept.",
        "schedule": "Fri 2:00 PM",
        "location": "Hall C",
        "description":
            "Ethical considerations in engineering practice and sustainability.",
        "status": "Closed",
        "button": "Closed",
        "gradient1": const Color(0xff374151), // Cool Gray
        "gradient2": const Color(0xff6B7280), // Slate
      },
      {
        "title": "Digital Media Arts",
        "code": "ART-220",
        "credits": "3 Credits",
        "teacher": "Lisa Ray",
        "department": "Arts Dept.",
        "schedule": "Tue/Thu 10:00 AM",
        "location": "Studio 5",
        "description":
            "Exploration of digital tools for creative expression and graphic design.",
        "status": "Open",
        "button": "Enroll",
        "gradient1": const Color(0xffF59E0B), // Amber
        "gradient2": const Color(0xffEF4444), // Red
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            const Text(
              "My Courses",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xff0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Manage your curriculum, AI assessments, and student cohorts.",
              style: TextStyle(
                fontSize: 15,
                color: Color(0xff64748B),
              ),
            ),
            const SizedBox(height: 32),

            /// TOP BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Showing 24 courses",
                  style: TextStyle(
                    color: Color(0xff475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    _topIconButton(Icons.grid_view_rounded, true),
                    const SizedBox(width: 8),
                    _topIconButton(Icons.view_agenda_outlined, false),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// GRID
            LayoutBuilder(
              builder: (context, constraints) {
                int count = 3;
                if (constraints.maxWidth < 1150) count = 2;
                if (constraints.maxWidth < 750) count = 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    mainAxisExtent:
                        370, // تصغير طول الكارت الإجمالي ليكون أكثر تماسكاً
                  ),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final status = course['status'].toString();
                    final isClosed = status == "Closed";
                    final isWaitlist = status == "Waitlist";
                    final isEnrolled = status == "Enrolled";

                    return GestureDetector(
                      onTap: () {
                        context.go(Routes.studentCourseDetails);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// TOP COVER
                            Container(
                              height: 130, // تصغير بسيط لغطاء الكارت
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    course['gradient1'] as Color,
                                    course['gradient2'] as Color,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// BADGES
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isClosed
                                              ? const Color(0xffEF4444)
                                              : isWaitlist
                                                  ? const Color(0xffF59E0B)
                                                  : const Color(0xff10B981),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          course['credits'].toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isEnrolled)
                                        const CircleAvatar(
                                          radius: 11,
                                          backgroundColor: Color(0xff1D8CF8),
                                          child: Icon(
                                            Icons.check,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    course['code'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    course['title'].toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// CONTENT - تغليفه بـ Expanded واستخدام Spacer لدفع المكونات للأسفل
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// TEACHER
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Color(0xffEFF6FF),
                                          child: Icon(
                                            Icons.person,
                                            color: Color(0xff1D8CF8),
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                course['teacher'].toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: Color(0xff0F172A),
                                                ),
                                              ),
                                              Text(
                                                course['department'].toString(),
                                                style: const TextStyle(
                                                  color: Color(0xff64748B),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    /// SCHEDULE & LOCATION
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded,
                                            size: 14, color: Color(0xff94A3B8)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            course['schedule'].toString(),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xff475569)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 14, color: Color(0xff94A3B8)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            course['location'].toString(),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xff475569)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    /// DESCRIPTION (تم تحديد حد أقصى سطرين للملائمة مع الطول الجديد)
                                    Text(
                                      course['description'].toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        height: 1.4,
                                        fontSize: 12,
                                        color: Color(0xff64748B),
                                      ),
                                    ),

                                    // السبيسر السحري الذي يقوم بحجز المساحة ودفع زر Enroll ونهاية المحتوى إلى الأسفل تماماً لتوحيد الطول
                                    const Spacer(),

                                    /// BUTTON (Enroll)
                                    SizedBox(
                                      width: double.infinity,
                                      height: 40,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          backgroundColor: isClosed
                                              ? const Color(0xffF1F5F9)
                                              : isWaitlist
                                                  ? Colors.white
                                                  : isEnrolled
                                                      ? const Color(0xffF1F5F9)
                                                      : const Color(0xff1D8CF8),
                                          foregroundColor: isClosed
                                              ? const Color(0xff94A3B8)
                                              : isWaitlist
                                                  ? const Color(0xff1D8CF8)
                                                  : isEnrolled
                                                      ? const Color(0xff475569)
                                                      : Colors.white,
                                          side: isWaitlist
                                              ? const BorderSide(
                                                  color: Color(0xff1D8CF8),
                                                  width: 1.5,
                                                )
                                              : null,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          course['button'].toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 48),

            /// PAGINATION
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _paginationButton(Icons.chevron_left, false),
                const SizedBox(width: 8),
                _pageNumber("1", true),
                _pageNumber("2", false),
                _pageNumber("3", false),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child:
                      Text("...", style: TextStyle(color: Color(0xff94A3B8))),
                ),
                _pageNumber("8", false),
                const SizedBox(width: 8),
                _paginationButton(Icons.chevron_right, true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _topIconButton(IconData icon, bool active) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: active ? const Color(0xff1D8CF8) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: active ? Colors.transparent : const Color(0xffE2E8F0)),
      ),
      child: Icon(
        icon,
        size: 18,
        color: active ? Colors.white : const Color(0xff64748B),
      ),
    );
  }

  Widget _paginationButton(IconData icon, bool active) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Icon(
        icon,
        size: 18,
        color: const Color(0xff64748B),
      ),
    );
  }

  Widget _pageNumber(String number, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: active ? const Color(0xff1D8CF8) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xff64748B),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
