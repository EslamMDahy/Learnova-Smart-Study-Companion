import 'package:flutter/material.dart';
import 'package:learnova/features/student/presentation/pages/quiz/student_quiz_result_page.dart';
// 1. إضافة الـ import الصحيح لصفحة الكويز (تأكد من تعديل المسار لو كان مختلفاً في مجلدات مشروعك)

class StudentCourseDetailsPage extends StatelessWidget {
  const StudentCourseDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
          0xffF8FAFC), // خلفية الصفحة الأساسية الفاتحة المطابقة للنظام
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 1. LEFT SIDEBAR (Course Content - الموديولات القابلة للتمدد)
          Container(
            width: 320,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xffE2E8F0))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Course Content",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xff0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xffEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "CS-101",
                          style: TextStyle(
                            color: Color(0xff1D8CF8),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                /// نظام Modules (Accordion)
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ListView(
                      children: [
                        /// Module 1
                        _buildModuleExpansionTile(
                          title: "Module 1: Core Fundamentals",
                          isInitiallyExpanded: true,
                          children: [
                            _buildContentItem(
                                "1.1 Course Introduction", "12:45",
                                isCompleted: true, isCurrent: false),
                            _buildContentItem(
                                "1.2 Setting Up Environment", "18:20",
                                isCompleted: true, isCurrent: true),
                            _buildContentItem(
                                "1.3 First Code Architecture", "25:10",
                                isCompleted: false, isCurrent: false),
                          ],
                        ),
                        const SizedBox(height: 12),

                        /// Module 2
                        _buildModuleExpansionTile(
                          title: "Module 2: Advanced Data Flow",
                          isInitiallyExpanded: true,
                          children: [
                            _buildContentItem(
                                "2.1 Understanding State", "20:15",
                                isCompleted: false, isCurrent: false),
                            _buildContentItem(
                                "2.2 Async Operations & APIs", "32:40",
                                isCompleted: false, isCurrent: false),
                            _buildContentItem(
                                "2.3 Streams and Observers", "15:10",
                                isCompleted: false, isCurrent: false),
                            // 2. تمرير الـ context هنا كأول متغير لتفعيل التوجيه والربط
                            _buildQuizItem(context, "2.4 Module Quiz", "10 Qs",
                                isLocked: false),
                          ],
                        ),
                        const SizedBox(height: 12),

                        /// Module 3
                        _buildModuleExpansionTile(
                          title: "Module 3: Production Deployment",
                          isInitiallyExpanded: false,
                          children: [
                            _buildContentItem("3.1 CI/CD Pipelines", "45:00",
                                isCompleted: false, isCurrent: false),
                            _buildContentItem(
                                "3.2 Cloud Orchestration", "28:15",
                                isCompleted: false, isCurrent: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 2. MAIN CENTER CONTENT (Video Player & Lesson Tabs)
          Expanded(
            child: SizedBox(
              height: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// VIDEO COVER PLACEHOLDER
                    Container(
                      height: 400,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xff1E1B4B), Color(0xff312E81)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 44,
                            color: Color(0xff1D8CF8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// TITLE & INSTRUCTOR INFO
                    const Text(
                      "1.2 Setting Up Your Production Environment",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "In this lesson, we will explore the industrial standards for setting up scalable architectures.",
                      style: TextStyle(color: Color(0xff64748B), fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    /// NAVIGATION TABS
                    Row(
                      children: [
                        _buildTabItem("Overview", false),
                        _buildTabItem("Notes & Code", true),
                        _buildTabItem("Discussions", false),
                        _buildTabItem("AI Resources", false),
                      ],
                    ),
                    const Divider(color: Color(0xffE2E8F0), height: 1),
                    const SizedBox(height: 28),

                    /// TIMELINE / LESSON OBJECTIVES
                    const Text(
                      "Lesson Timeline",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A)),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineItem("02:15",
                        "Introduction and setup overview of required SDKs."),
                    _buildTimelineItem("08:45",
                        "Configuration of terminal variables and global paths.",
                        isSelected: true),
                    _buildTimelineItem("14:20",
                        "Testing the environment with dummy server compilation."),
                  ],
                ),
              ),
            ),
          ),

          /// 3. RIGHT SIDEBAR (AI Tutor Chat)
          Container(
            width: 340,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Color(0xffE2E8F0))),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Color(0xff1D8CF8), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "AI Learning Tutor",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xff0F172A),
                      ),
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: Colors.green.shade500,
                    ),
                    const SizedBox(width: 6),
                    const Text("Online",
                        style:
                            TextStyle(fontSize: 12, color: Color(0xff64748B))),
                  ],
                ),
                const SizedBox(height: 20),

                /// CHAT MESSAGES AREA
                Expanded(
                  child: ListView(
                    children: [
                      _buildChatMessage(false,
                          "Hello Alex! I am your AI assistant. Ask me anything about the current lesson on Environment Setup."),
                      _buildChatMessage(true,
                          "What is the purpose of configuring global paths at 08:45?"),
                      _buildChatMessage(false,
                          "Configuring global paths ensures that your terminal can call the compiled binaries from any working directory instantly."),
                    ],
                  ),
                ),

                /// INPUT BAR
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Ask AI a question...",
                            hintStyle: TextStyle(
                                color: Color(0xff94A3B8), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.send_rounded,
                            color: Color(0xff1D8CF8), size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
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

  // --- WIDGET HELPER FUNCTIONS FOR CLEAN CODE ---

  /// موديول القائمة المنسدلة (ExpansionTile)
  Widget _buildModuleExpansionTile({
    required String title,
    required List<Widget> children,
    bool isInitiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: ExpansionTile(
        initiallyExpanded: isInitiallyExpanded,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xff1E293B),
          ),
        ),
        trailing: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xff64748B),
          size: 20,
        ),
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        children: children,
      ),
    );
  }

  /// عناصر الدروس العادية
  Widget _buildContentItem(String title, String duration,
      {required bool isCompleted, required bool isCurrent}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xffEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? const Color(0xffBFDBFE)
              : const Color(0xffE2E8F0).withOpacity(0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.play_circle_outline_rounded,
            color: isCompleted
                ? const Color(0xff10B981)
                : (isCurrent
                    ? const Color(0xff1D8CF8)
                    : const Color(0xff94A3B8)),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? const Color(0xff1D8CF8)
                    : const Color(0xff334155),
              ),
            ),
          ),
          Text(
            duration,
            style: TextStyle(
              fontSize: 11,
              color: isCurrent
                  ? const Color(0xff1D8CF8).withOpacity(0.7)
                  : const Color(0xff94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. دالة الـ Module Quiz المحدثة بالكامل لتقوم بالربط والانتقال بنجاح لصفحة الـ QuizResult
  Widget _buildQuizItem(
      BuildContext context, String title, String questionsCount,
      {bool isLocked = false}) {
    return GestureDetector(
      onTap: () {
        if (!isLocked) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const StudentQuizResultPage()),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffE2E8F0).withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(
              isLocked ? Icons.lock_outline_rounded : Icons.assignment_outlined,
              color:
                  isLocked ? const Color(0xff94A3B8) : const Color(0xffF59E0B),
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isLocked
                      ? const Color(0xff94A3B8)
                      : const Color(0xff334155),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xffFEF3C7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                questionsCount,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xffB45309),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? const Color(0xff1D8CF8) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? const Color(0xff1D8CF8) : const Color(0xff64748B),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String time, String text,
      {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xffEFF6FF).withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0xff1D8CF8),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xff475569),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(bool isUser, String message) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xff1D8CF8) : const Color(0xffF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xff334155),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
