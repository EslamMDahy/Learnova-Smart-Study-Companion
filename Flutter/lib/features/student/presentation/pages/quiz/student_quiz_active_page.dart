import 'package:flutter/material.dart';
// استدعاء صفحة النتيجة لإعادة بناء حالتها عند التسليم
import 'student_quiz_result_page.dart';

class StudentQuizActivePage extends StatefulWidget {
  const StudentQuizActivePage({super.key});

  @override
  State<StudentQuizActivePage> createState() => _StudentQuizActivePageState();
}

class _StudentQuizActivePageState extends State<StudentQuizActivePage> {
  int _selectedOptionIndex =
      1; // تحديد الاختيار الثاني (Merge Sort) كافتراضي مثل الصورة
  int _currentQuestion = 5; // رقم السؤال الحالي لمتابعة التنقل بالأزرار

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: Column(
        children: [
          /// 1. الشريط العلوي (العنوان والتايمر)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
            ),
            child: Row(
              children: [
                const Text(
                  "Mid-Term Assessment: Computer Science 101",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xff0F172A),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.timer_outlined,
                    size: 18, color: Color(0xff64748B)),
                const SizedBox(width: 8),
                const Text(
                  "00:45:12",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xff0F172A),
                  ),
                ),
              ],
            ),
          ),

          /// 2. محتوى الصفحة الرئيسي المقسم إلى جزأين
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// [الجانب الأيسر] لوحة الأسئلة وبأسفلها زر الـ Submit الأخضر
                Container(
                  width: 280,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Color(0xffE2E8F0))),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Question Palette",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xff0F172A),
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// شبكة أرقام الأسئلة
                      Expanded(
                        child: GridView.builder(
                          itemCount: 20,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            // محاكاة الألوان: أول 4 أسئلة تم حلهم بالأزرق، الباقي أبيض
                            bool isAnswered = index < 4;
                            // تلوين السؤال الحالي بلون خفيف لتمييزه
                            bool isCurrent = (index + 1) == _currentQuestion;

                            return Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isAnswered
                                    ? const Color(0xff1D8CF8)
                                    : (isCurrent
                                        ? const Color(0xffEFF6FF)
                                        : Colors.white),
                                border: Border.all(
                                  color: isCurrent
                                      ? const Color(0xff1D8CF8)
                                      : (isAnswered
                                          ? const Color(0xff1D8CF8)
                                          : const Color(0xffE2E8F0)),
                                  width: isCurrent ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isAnswered
                                      ? Colors.white
                                      : (isCurrent
                                          ? const Color(0xff1D8CF8)
                                          : const Color(0xff475569)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// زر الـ Submit Assessment الأخضر في أسفل الـ Palette
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            // الانتقال لصفحة النتيجة وتفعيل سيكشن الـ Question Review
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const StudentQuizResultPage(
                                        isSubmitted: true),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                                0xff10B981), // اللون الأخضر التفاعلي
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Submit Assessment",
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// [الجانب الأيمن] السؤال، الاختيارات، وأزرار التنقل السفلية (Previous / Next)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Question $_currentQuestion",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(
                                        0xff1D8CF8), // تمييز تايتل السؤال بالأزرق
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Which of the following sorting algorithms has a time complexity of O(n log n) in the average case?",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff0F172A),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                /// قائمة الاختيارات الأربعة
                                _buildOption(0, "Bubble Sort"),
                                _buildOption(1, "Merge Sort"),
                                _buildOption(2, "Selection Sort"),
                                _buildOption(3, "Insertion Sort"),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(color: Color(0xffE2E8F0)),
                        const SizedBox(height: 16),

                        /// 🚀 أزرار التنقل (Previous و Next Question) في أسفل الصفحة كما طلبت
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _currentQuestion > 1
                                  ? () => setState(() => _currentQuestion--)
                                  : null, // يتعطل لو في أول سؤال
                              icon: const Icon(Icons.chevron_left_rounded,
                                  size: 18),
                              label: const Text("Previous",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xff475569),
                                side:
                                    const BorderSide(color: Color(0xffE2E8F0)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _currentQuestion < 20
                                  ? () => setState(() => _currentQuestion++)
                                  : null, // يتعطل لو في آخر سؤال
                              icon: const Text("Next Question",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              label: const Icon(Icons.chevron_right_rounded,
                                  size: 18),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1D8CF8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// ويدجت بناء خيارات الأسئلة التفاعلية بشكل الراديو بوتون
  Widget _buildOption(int index, String text) {
    bool isSelected = _selectedOptionIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedOptionIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected ? const Color(0xff1D8CF8) : const Color(0xffE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected
                  ? const Color(0xff1D8CF8)
                  : const Color(0xff94A3B8),
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xff1D8CF8)
                    : const Color(0xff334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
