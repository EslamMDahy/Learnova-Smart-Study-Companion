import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learnova/core/ui/widgets/app_card.dart';

class QuizDetailsScreen extends StatelessWidget {
  const QuizDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // نفس خلفية الـ QBank
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Navigation & Breadcrumbs
            _buildBreadcrumbs(context),
            const SizedBox(height: 24),

            // 2. Header (Title & Main Actions)
            _buildMainHeader(),
            const SizedBox(height: 32),

            // 3. Stats Section (بشكل كروت الـ QBank)
            _buildStatsGrid(),
            const SizedBox(height: 32),

            // 4. Main Content Area (Layout التقسيم الجديد)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اليسار: تحليل الأسئلة (الجزء الأكبر)
                Expanded(flex: 3, child: _buildQuestionsAnalysis()),
                const SizedBox(width: 32),
                // اليمين: قائمة المتفوقين (Sidebar جانبي)
                Expanded(flex: 1, child: _buildLeaderboardSidebar()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    return InkWell(
      onTap: () => context.pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF6366F1)),
          SizedBox(width: 8),
          Text(
            "Back to Quizzes",
            style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMainHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Midterm Exam Analytics",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            SizedBox(height: 8),
            Text(
              "Introduction to Artificial Intelligence • Section A",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderAction(Icons.file_download_outlined, "Download Report", isPrimary: false),
            const SizedBox(width: 12),
            _buildHeaderAction(Icons.ios_share_rounded, "Share Results", isPrimary: true),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF6366F1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPrimary ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        boxShadow: isPrimary ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isPrimary ? Colors.white : const Color(0xFF475569)),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: isPrimary ? Colors.white : const Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _statItem("Avg. Score", "78%", Icons.analytics_outlined, Colors.blue),
        _statItem("Pass Rate", "92%", Icons.check_circle_outline, Colors.green),
        _statItem("Highest", "100%", Icons.emoji_events_outlined, Colors.orange),
        _statItem("Time Avg.", "38m", Icons.timer_outlined, Colors.purple),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: AppCard(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsAnalysis() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Performance by Question", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          _questionAnalysisRow("Q1", "Primary goals of Machine Learning", "95% Correct", 0.95, Colors.green),
          _questionAnalysisRow("Q4", "Neural Network backpropagation", "42% Correct", 0.42, Colors.red),
          _questionAnalysisRow("Q7", "Gradient Descent algorithms", "68% Correct", 0.68, Colors.orange),
          const SizedBox(height: 24),
          _buildAIHint(),
        ],
      ),
    );
  }

  Widget _questionAnalysisRow(String id, String text, String percentage, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$id: $text", style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              Text(percentage, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: val, minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildAIHint() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: const [
          Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "Recommendation: Students found Q4 challenging. You might want to revisit 'Backpropagation' in your next session.",
              style: TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSidebar() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Performers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          _studentItem("Sarah Johnson", "100%", "Rank #1"),
          _studentItem("Michael Chen", "98%", "Rank #2"),
          _studentItem("Omar Khalid", "97%", "Rank #3"),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              child: const Text("View Full Class Results", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _studentItem(String name, String score, String rank) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.person_outline, size: 20, color: Color(0xFF64748B))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(rank, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ]),
          ),
          Text(score, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}