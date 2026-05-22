import 'package:flutter/material.dart';
import 'student_quiz_active_page.dart';

class StudentQuizResultPage extends StatefulWidget {
  // متغير لمعرفة هل تم تسليم الاختبار وعرض سيكشن المراجعة أم لا
  final bool isSubmitted;

  const StudentQuizResultPage({super.key, this.isSubmitted = false});

  @override
  State<StudentQuizResultPage> createState() => _StudentQuizResultPageState();
}

class _StudentQuizResultPageState extends State<StudentQuizResultPage> {
  // متغيرات داخلية للتحكم في تبويبات المراجعة والسؤال الحالي داخل السيكشن الجديد
  int _activeTab = 1; // 0: All, 1: Incorrect, 2: Flagged
  int _currentReviewQuestion = 5; // رقم السؤال الحالي المعروض في المراجعة

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 1. LEFT SIDEBAR (Course Content)
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
                            color: Color(0xff0F172A)),
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
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ListView(
                      children: [
                        _buildModuleExpansionTile(
                          title: "Module 1: Intro",
                          isInitiallyExpanded: false,
                          isCompleted: true,
                          children: [
                            _buildContentItem("1.1 Course Introduction",
                                isCompleted: true, isCurrent: false),
                            _buildContentItem("1.2 Setting Up Environment",
                                isCompleted: true, isCurrent: false),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildModuleExpansionTile(
                          title: "Module 2: Neural Nets",
                          isInitiallyExpanded: true,
                          isCurrentModule: true,
                          children: [
                            _buildContentItem("2.1 Perceptrons",
                                isCompleted: true, isCurrent: false),
                            _buildContentItem("2.2 Backpropagation",
                                isCompleted: false, isCurrent: false),
                            _buildContentItem("2.3 Activation Functions",
                                isCompleted: false, isCurrent: false),
                            _buildQuizItem("2.4 Module Quiz",
                                isSelectedQuiz: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildModuleExpansionTile(
                          title: "Module 3: Deep Learning",
                          isInitiallyExpanded: false,
                          leadingNumber: "3",
                          children: [
                            _buildContentItem("3.1 CNN Architecture",
                                isCompleted: false, isCurrent: false),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildModuleExpansionTile(
                          title: "Module 4: Project",
                          isInitiallyExpanded: false,
                          leadingNumber: "4",
                          children: [
                            _buildContentItem("4.1 Final Submission",
                                isCompleted: false, isCurrent: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text("Back to Dashboard",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1D8CF8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 2. MAIN CENTER CONTENT
          Expanded(
            child: SizedBox(
              height: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Mid-Term Assessment: Computer Science 101",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xff0F172A)),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Completed",
                                      style: TextStyle(
                                          color: Color(0xff15803D),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Assessment completed on Oct 24, 2023 • 10:30 AM • ID: #CALC2-2023-MID",
                                style: TextStyle(
                                    color: Color(0xff64748B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon:
                                  const Icon(Icons.download_rounded, size: 15),
                              label: const Text("Export PDF",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xff1E293B),
                                side:
                                    const BorderSide(color: Color(0xffE2E8F0)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffF1F5F9),
                                foregroundColor: const Color(0xff1E293B),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Back to Dashboard",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 32),

                    /// كروت الإحصائيات
                    Row(
                      children: [
                        _buildMetricCard(
                            "OVERALL SCORE",
                            widget.isSubmitted ? "78" : "0",
                            "/100",
                            true,
                            "",
                            const Icon(Icons.emoji_events_outlined,
                                color: Color(0xff94A3B8))),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                            "TIME TAKEN",
                            widget.isSubmitted ? "14m 22s" : "0m 0s",
                            "",
                            false,
                            "Avg. 43s per question",
                            null),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                            "ACCURACY RATE",
                            widget.isSubmitted ? "80%" : "0%",
                            "",
                            false,
                            widget.isSubmitted
                                ? "16 Correct\n4 Incorrect"
                                : "0 Correct\n0 Incorrect",
                            null,
                            showProgressCircle: true),
                        const SizedBox(width: 16),
                        _buildMetricCard(
                            "PERCENTILE",
                            widget.isSubmitted ? "Top 12%" : "Top 0%",
                            "",
                            false,
                            widget.isSubmitted
                                ? "Better than 88% of peers"
                                : "Better than 0% of peers",
                            null),
                      ],
                    ),
                    const SizedBox(height: 32),

                    /// كرت تحليل الذكاء الاصطناعي
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xffEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded,
                                    color: Color(0xff1D8CF8), size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "AI Learning Analysis",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xff0F172A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("IDENTIFIED WEAKNESSES",
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xff64748B),
                                            letterSpacing: 0.5)),
                                    const SizedBox(height: 12),
                                    _buildAnalysisItem(
                                      icon: Icons.warning_amber_rounded,
                                      iconColor: const Color(0xffEF4444),
                                      bgColor: const Color(0xffFEF2F2),
                                      borderColor: const Color(0xffFEE2E2),
                                      title:
                                          "Integrals of Trigonometric Functions",
                                      subtitle:
                                          "You missed 3 questions related to sin²(x) integration.",
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAnalysisItem(
                                      icon: Icons.info_outline_rounded,
                                      iconColor: const Color(0xffF59E0B),
                                      bgColor: const Color(0xffFFFBEB),
                                      borderColor: const Color(0xffFEF3C7),
                                      title: "Integration by Parts",
                                      subtitle:
                                          "Slower response time detected. Review formula structure.",
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("RECOMMENDED STUDY MATERIALS",
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xff64748B),
                                            letterSpacing: 0.5)),
                                    const SizedBox(height: 12),
                                    _buildAnalysisItem(
                                      icon: Icons.menu_book_rounded,
                                      iconColor: const Color(0xffEF4444),
                                      bgColor: const Color(0xffFEF2F2),
                                      borderColor: const Color(0xffFEE2E2),
                                      title: "Chapter 4: Advanced Integration",
                                      subtitle: "PDF • 15 mins read",
                                      hasArrow: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAnalysisItem(
                                      icon: Icons.play_circle_fill_rounded,
                                      iconColor: const Color(0xff1D8CF8),
                                      bgColor: const Color(0xffEFF6FF),
                                      borderColor: const Color(0xffDBEAFE),
                                      title: "Video: Mastering Trig Integrals",
                                      subtitle: "Video • 8 mins watch",
                                      hasArrow: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    /// 🚀 التحكم التلقائي: إما عرض زر البدء أو عرض الـ Question Review Section بالكامل
                    widget.isSubmitted
                        ? _buildQuestionReviewSection() // عرض سيكشن المراجعة والأزرار بالتفصيل
                        : Center(
                            child: SizedBox(
                              width: 160,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const StudentQuizActivePage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff1D8CF8),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text("take Quiezz",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),

          /// 3. RIGHT SIDEBAR (Study Assistant Chat)
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
                    CircleAvatar(
                        radius: 5, backgroundColor: Colors.green.shade500),
                    const SizedBox(width: 8),
                    const Text(
                      "Study Assistant",
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xff0F172A)),
                    ),
                    const SizedBox(width: 6),
                    const Text("• Online & Ready",
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xff10B981),
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.more_horiz,
                        color: Color(0xff64748B), size: 20),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text("Today",
                              style: TextStyle(
                                  color: Color(0xff94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      _buildChatMessage(false,
                          "Hi there! I'm watching this video with you. I can help you summarize key points, generate quiz questions, or explain complex terms like \"Backpropagation\". What do you need?"),
                      Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 16),
                        child: Row(
                          children: [
                            _buildSuggestionChip("Summarize video"),
                            const SizedBox(width: 8),
                            _buildSuggestionChip("Quiz me"),
                          ],
                        ),
                      ),
                      _buildChatMessage(true,
                          "Can you explain the chain rule part mentioned at 04:20?"),
                      _buildChatMessage(false,
                          "Certainly! At 04:20, the instructor explains that the Chain Rule is used to calculate how a change in the network's weights affects the final error.\n\nThink of it like nested gears: turning a small gear (weight) inside turns a larger gear (hidden layer), which turns the final wheel (output). The chain rule tells us exactly how much the final wheel turns if we nudge the small gear."),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            hintText: "Ask a question about this lecture...",
                            hintStyle: TextStyle(
                                color: Color(0xff94A3B8), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xff1D8CF8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 14),
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

  /// 🚀 بناء الـ Question Review Section بالكامل مع التبويبات وأزرار التنقل التفاعلية
  Widget _buildQuestionReviewSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 1. ترويسة السيكشن والتبويبات الفلتر (All, Incorrect, Flagged)
          Row(
            children: [
              const Text(
                "Question Review",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff0F172A)),
              ),
              const SizedBox(width: 24),
              _buildReviewTab(0, "All (20)"),
              const SizedBox(width: 8),
              _buildReviewTab(1, "Incorrect (4)"),
              const SizedBox(width: 8),
              _buildReviewTab(2, "Flagged (1)"),
            ],
          ),
          const SizedBox(height: 24),

          /// 2. تفاصيل السؤال الحالي المختار للمراجعة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question $_currentReviewQuestion",
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff0F172A)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel, color: Color(0xffEF4444), size: 14),
                    SizedBox(width: 4),
                    Text("Incorrect",
                        style: TextStyle(
                            color: Color(0xffEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Which of the following sorting algorithms has a time complexity of O(n log n) in the average case?",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff334155),
                height: 1.4),
          ),
          const SizedBox(height: 20),

          /// 3. عرض الاختيارات وحالتها (الإجابة الخطأ والإجابة الصح)
          _buildReviewOption("Bubble Sort",
              isWrongSelected: true, isCorrectAnswer: false),
          _buildReviewOption("Merge Sort",
              isWrongSelected: false, isCorrectAnswer: true),
          _buildReviewOption("Selection Sort",
              isWrongSelected: false, isCorrectAnswer: false),
          _buildReviewOption("Insertion Sort",
              isWrongSelected: false, isCorrectAnswer: false),

          const SizedBox(height: 20),

          /// 4. صندوق توضيح الذكاء الاصطناعي لسبب الخطأ (AI Explanation)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffBFDBFE)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: Color(0xff1D8CF8), size: 18),
                    SizedBox(width: 8),
                    Text("Explanation",
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xff1D8CF8))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Merge Sort consistently divides the array in half and takes O(n) time to merge, resulting in O(n log n) complexity. Bubble Sort has an average case complexity of O(n²).",
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xff1E40AF),
                      height: 1.4,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xffE2E8F0)),
          const SizedBox(height: 12),

          /// 5. 🚀 أزرار التنقل المضافة (Previous و Next) للتنقل بين مراجعة الأسئلة كما كانت بصفحة الحل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _currentReviewQuestion > 1
                    ? () => setState(() => _currentReviewQuestion--)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: const Text("Previous",
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff475569),
                  side: const BorderSide(color: Color(0xffE2E8F0)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _currentReviewQuestion < 20
                    ? () => setState(() => _currentReviewQuestion++)
                    : null,
                icon: const Text("Next Question",
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                label: const Icon(Icons.chevron_right_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1D8CF8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// ويدجت بناء تبويبات الفلترة لسكشن المراجعة
  Widget _buildReviewTab(int tabIndex, String label) {
    bool isSelected = _activeTab == tabIndex;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabIndex),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1D8CF8) : const Color(0xffF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xff64748B),
          ),
        ),
      ),
    );
  }

  /// ويدجت خيارات الأسئلة المصححة داخل سيكشن المراجعة
  Widget _buildReviewOption(String optionText,
      {required bool isWrongSelected, required bool isCorrectAnswer}) {
    Color cardBg = Colors.white;
    Color borderBg = const Color(0xffE2E8F0);
    IconData icon = Icons.radio_button_off_rounded;
    Color iconColor = const Color(0xff94A3B8);

    if (isWrongSelected) {
      cardBg = const Color(0xffFEF2F2);
      borderBg = const Color(0xffFEE2E2);
      icon = Icons.cancel_rounded;
      iconColor = const Color(0xffEF4444);
    } else if (isCorrectAnswer) {
      cardBg = const Color(0xffDCFCE7);
      borderBg = const Color(0xffBBF7D0);
      icon = Icons.check_circle_rounded;
      iconColor = const Color(0xff10B981);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderBg),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Text(
            optionText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: (isWrongSelected || isCorrectAnswer)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isWrongSelected
                  ? const Color(0xff991B1B)
                  : isCorrectAnswer
                      ? const Color(0xff166534)
                      : const Color(0xff334155),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---

  Widget _buildMetricCard(String title, String value, String total,
      bool showTrendBelow, String footerText, Widget? trailingIcon,
      {bool showProgressCircle = false}) {
    return Expanded(
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff64748B),
                        letterSpacing: 0.5)),
                if (trailingIcon != null) trailingIcon,
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff0F172A))),
                    if (total.isNotEmpty)
                      Text(total,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff94A3B8))),
                    if (showProgressCircle) ...[
                      const Spacer(),
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: widget.isSubmitted ? 0.8 : 0.0,
                          strokeWidth: 3,
                          backgroundColor: const Color(0xffEFF6FF),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade600),
                        ),
                      )
                    ]
                  ],
                ),
                if (showTrendBelow && widget.isSubmitted) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xffDCFCE7),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text("+2% from last attempt",
                        style: TextStyle(
                            color: Color(0xff15803D),
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            const Spacer(),
            if (!showTrendBelow && footerText.isNotEmpty)
              Text(footerText,
                  style: const TextStyle(
                      color: Color(0xff64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(
      {required IconData icon,
      required Color iconColor,
      required Color bgColor,
      required Color borderColor,
      required String title,
      required String subtitle,
      bool hasArrow = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0F172A))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff64748B))),
              ],
            ),
          ),
          if (hasArrow)
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xff94A3B8), size: 20),
        ],
      ),
    );
  }

  Widget _buildModuleExpansionTile(
      {required String title,
      required List<Widget> children,
      bool isInitiallyExpanded = false,
      bool isCompleted = false,
      bool isCurrentModule = false,
      String? leadingNumber}) {
    Widget leadingIcon;
    if (isCompleted) {
      leadingIcon = const Icon(Icons.check_circle_outline_rounded,
          color: Color(0xff10B981), size: 18);
    } else if (isCurrentModule) {
      leadingIcon = const Icon(Icons.incomplete_circle_rounded,
          color: Color(0xff1D8CF8), size: 18);
    } else {
      leadingIcon = CircleAvatar(
        radius: 9,
        backgroundColor: const Color(0xffF1F5F9),
        child: Text(leadingNumber ?? "",
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xff64748B),
                fontWeight: FontWeight.w700)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isCurrentModule
                ? const Color(0xffBFDBFE)
                : const Color(0xffE2E8F0)),
      ),
      child: ExpansionTile(
        initiallyExpanded: isInitiallyExpanded,
        leading: leadingIcon,
        title: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isCurrentModule
                    ? const Color(0xff0F172A)
                    : const Color(0xff475569))),
        trailing: Icon(
            isInitiallyExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: const Color(0xff64748B),
            size: 18),
        childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        children: children,
      ),
    );
  }

  Widget _buildContentItem(String title,
      {required bool isCompleted, required bool isCurrent}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: isCurrent ? const Color(0xffEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.play_circle_outline_rounded,
              color:
                  isCurrent ? const Color(0xff1D8CF8) : const Color(0xff94A3B8),
              size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent
                        ? const Color(0xff1D8CF8)
                        : const Color(0xff64748B))),
          ),
          if (isCompleted)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xff10B981), size: 15)
        ],
      ),
    );
  }

  Widget _buildQuizItem(String title, {bool isSelectedQuiz = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelectedQuiz ? const Color(0xffEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            isSelectedQuiz ? Border.all(color: const Color(0xffBFDBFE)) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_outlined,
              color: isSelectedQuiz
                  ? const Color(0xff1D8CF8)
                  : const Color(0xff94A3B8),
              size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        isSelectedQuiz ? FontWeight.w700 : FontWeight.w500,
                    color: isSelectedQuiz
                        ? const Color(0xff1D8CF8)
                        : const Color(0xff64748B))),
          ),
          if (isSelectedQuiz)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xff10B981), size: 15)
        ],
      ),
    );
  }

  Widget _buildChatMessage(bool isUser, String message) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Text(message,
            style: TextStyle(
                color: isUser ? Colors.white : const Color(0xff334155),
                fontSize: 13,
                height: 1.45)),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff1D8CF8).withOpacity(0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xff1D8CF8),
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}
