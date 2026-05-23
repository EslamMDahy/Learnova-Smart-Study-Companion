import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learnova/core/network/error_mapper.dart';
import 'package:learnova/core/theme/app_theme.dart';
import 'package:learnova/core/ui/toast.dart';
import 'package:learnova/features/instructor/data/exam_models.dart';
import 'package:learnova/features/instructor/data/question_models.dart';
import 'package:learnova/features/instructor/data/modules_materials_providers.dart';
import 'package:learnova/features/instructor/presentation/controllers/selected_course_provider.dart';

class InstructorQuizzesScreen extends ConsumerStatefulWidget {
  final int? courseId;
  final String? courseTitle;

  const InstructorQuizzesScreen({super.key, this.courseId, this.courseTitle});

  @override
  ConsumerState<InstructorQuizzesScreen> createState() =>
      _InstructorQuizzesScreenState();
}

class _InstructorQuizzesScreenState extends ConsumerState<InstructorQuizzesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _query = '';
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  List<ExamModel> _exams = [];
  ExamModel? _selectedExam;
  ExamDetailsModel? _selectedDetails;
  bool _detailsLoading = false;
  String? _detailsError;

  int? get _courseId => widget.courseId ?? SelectedCourseCache.cachedCourseId;

  String get _courseTitle {
    final explicit = widget.courseTitle?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final cached = SelectedCourseCache.value?.title.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return 'selected course';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExams());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    final courseId = _courseId;
    if (courseId == null || courseId <= 0) {
      setState(() {
        _loading = false;
        _error = 'Open a course first to view its quizzes.';
        _exams = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ref.read(examsApiProvider).listExams(courseId: courseId);
      if (!mounted) return;
      setState(() {
        _exams = response.exams;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mapApiFailure(e).message;
        _loading = false;
      });
    }
  }

  List<ExamModel> get _filteredExams {
    final q = _query.trim().toLowerCase();
    return _exams.where((exam) {
      final matchesText = q.isEmpty ||
          exam.title.toLowerCase().contains(q) ||
          (exam.description ?? '').toLowerCase().contains(q) ||
          exam.examType.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'published' && exam.isPublished) ||
          (_statusFilter == 'draft' && !exam.isPublished);
      final matchesType = _typeFilter == 'all' ||
          exam.examType.toLowerCase() == _typeFilter;
      return matchesText && matchesStatus && matchesType;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (_selectedExam != null || _detailsLoading) {
      return _ExamAnalyticsPage(
        exam: _selectedDetails?.exam ?? _selectedExam,
        details: _selectedDetails,
        loading: _detailsLoading,
        error: _detailsError,
        onBack: _backToQuizList,
        onRetry: () {
          final exam = _selectedExam;
          if (exam != null) unawaited(_openExamDetails(exam));
        },
      );
    }

    final filtered = _filteredExams;
    return Container(
      color: AppColors.pageBg,
      child: RefreshIndicator(
        onRefresh: _loadExams,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(courseTitle: _courseTitle, onCreate: () {
                      AppToast.info(
                        context,
                        title: 'Create from Question Bank',
                        message: 'Open the course Question Bank tab to create a quiz from saved questions.',
                      );
                    }),
                    SizedBox(height: 22),
                    _StatsSection(exams: _exams),
                    SizedBox(height: 22),
                    _FiltersBar(
                      controller: _searchController,
                      status: _statusFilter,
                      type: _typeFilter,
                      onSearchChanged: (value) => setState(() => _query = value),
                      onStatusChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                      onTypeChanged: (value) => setState(() => _typeFilter = value ?? 'all'),
                    ),
                    SizedBox(height: 14),
                    _ExamTable(
                      loading: _loading,
                      error: _error,
                      exams: filtered,
                      onRetry: _loadExams,
                      onOpen: _openExamDetails,
                    ),
                    SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${filtered.length} of ${_exams.length} quizzes',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
  }

  Future<void> _openExamDetails(ExamModel exam) async {
    final courseId = _courseId;
    if (courseId == null) return;

    setState(() {
      _selectedExam = exam;
      _selectedDetails = null;
      _detailsLoading = true;
      _detailsError = null;
    });

    try {
      final details = await ref.read(examsApiProvider).getExam(
            courseId: courseId,
            examId: exam.id,
          );
      if (!mounted) return;
      setState(() {
        _selectedDetails = details;
        _selectedExam = details.exam;
        _detailsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailsError = mapApiFailure(e).message;
        _detailsLoading = false;
      });
    }
  }

  void _backToQuizList() {
    setState(() {
      _selectedExam = null;
      _selectedDetails = null;
      _detailsLoading = false;
      _detailsError = null;
    });
  }
}

class _Header extends StatelessWidget {
  final String courseTitle;
  final VoidCallback onCreate;
  const _Header({required this.courseTitle, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.textTitle,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage created exams and quizzes for $courseTitle.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: Icon(Icons.add_rounded, size: 18),
          label: Text('Create New Quiz'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final List<ExamModel> exams;
  const _StatsSection({required this.exams});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final active = exams.where((exam) => exam.isPublished).length;
    final draft = exams.length - active;
    final totalQuestions = exams.fold<int>(0, (sum, exam) => sum + exam.totalQuestions);
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Active Quizzes', value: '$active', subtitle: '${exams.length} total created', icon: Icons.assignment_rounded, color: AppColors.primary)),
        SizedBox(width: 16),
        Expanded(child: _StatCard(title: 'Draft Quizzes', value: '$draft', subtitle: 'not published yet', icon: Icons.edit_note_rounded, color: AppColors.warningText)),
        SizedBox(width: 16),
        Expanded(child: _StatCard(title: 'Bank Questions Used', value: '$totalQuestions', subtitle: 'questions across quizzes', icon: Icons.fact_check_rounded, color: AppColors.successDot)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
                SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final TextEditingController controller;
  final String status;
  final String type;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onTypeChanged;
  const _FiltersBar({required this.controller, required this.status, required this.type, required this.onSearchChanged, required this.onStatusChanged, required this.onTypeChanged});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search quizzes by title, description, or type...',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          _DropdownShell(
            width: 150,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: status,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All status')),
                  DropdownMenuItem(value: 'published', child: Text('Published')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                ],
                onChanged: onStatusChanged,
              ),
            ),
          ),
          SizedBox(width: 12),
          _DropdownShell(
            width: 140,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: type,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All types')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                  DropdownMenuItem(value: 'exam', child: Text('Exam')),
                ],
                onChanged: onTypeChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownShell extends StatelessWidget {
  final double width;
  final Widget child;
  const _DropdownShell({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: width,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: DefaultTextStyle(
        style: TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w700),
        child: child,
      ),
    );
  }
}

class _ExamTable extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<ExamModel> exams;
  final VoidCallback onRetry;
  final ValueChanged<ExamModel> onOpen;
  const _ExamTable({required this.loading, required this.error, required this.exams, required this.onRetry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowThin, blurRadius: 20, offset: Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _ExamTableHeader(),
          if (loading)
            Padding(padding: EdgeInsets.symmetric(vertical: 44), child: CircularProgressIndicator())
          else if (error != null)
            _TableMessage(icon: Icons.error_outline_rounded, title: 'Could not load quizzes', message: error!, actionLabel: 'Retry', onAction: onRetry)
          else if (exams.isEmpty)
            _TableMessage(icon: Icons.assignment_outlined, title: 'No quizzes found', message: 'Created exams will appear here after they are saved from the Question Bank.')
          else
            ...exams.map((exam) => _ExamRow(exam: exam, onTap: () => onOpen(exam))),
        ],
      ),
    );
  }
}

class _ExamTableHeader extends StatelessWidget {
  const _ExamTableHeader();

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      color: AppColors.surfaceBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 5, child: _HeaderText('QUIZ TITLE')),
          Expanded(flex: 2, child: _HeaderText('STATUS')),
          Expanded(flex: 2, child: _HeaderText('QUESTIONS')),
          Expanded(flex: 2, child: _HeaderText('TIME LIMIT')),
          Expanded(flex: 2, child: _HeaderText('UPDATED')),
          SizedBox(width: 82, child: _HeaderText('ACTIONS')),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.5));
  }
}

class _ExamRow extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback onTap;
  const _ExamRow({required this.exam, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final statusColor = exam.isPublished ? AppColors.successText : AppColors.textMuted;
    final statusLabel = exam.isPublished ? 'Published' : 'Draft';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.headerBg))),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exam.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textTitle)),
                        SizedBox(height: 4),
                        Text(_subtitle(exam), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _Badge(label: statusLabel, color: statusColor))),
            Expanded(flex: 2, child: Text('${exam.totalQuestions} question${exam.totalQuestions == 1 ? '' : 's'}', style: TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w700))),
            Expanded(flex: 2, child: Text(exam.durationMinutes == null ? 'No limit' : '${exam.durationMinutes} min', style: TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w700))),
            Expanded(flex: 2, child: Text(_formatDate(exam.updatedAt), style: TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w700))),
            SizedBox(width: 82, child: TextButton(onPressed: onTap, child: Text('View'))),
          ],
        ),
      ),
    );
  }

  static String _subtitle(ExamModel exam) {
    final type = exam.examType.trim().isEmpty ? 'Quiz' : _titleCase(exam.examType);
    final score = exam.totalScore == exam.totalScore.roundToDouble() ? exam.totalScore.toInt().toString() : exam.totalScore.toStringAsFixed(1);
    return '$type • $score total points • ${exam.maxAttempts} attempt${exam.maxAttempts == 1 ? '' : 's'}';
  }

  static String _titleCase(String value) {
    final normalized = value.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return 'Quiz';
    return normalized.split(RegExp(r'\s+')).map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}').join(' ');
  }

  static String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '-';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class _TableMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _TableMessage({required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textTitle)),
          SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}


class _ExamAnalyticsPage extends StatelessWidget {
  final ExamModel? exam;
  final ExamDetailsModel? details;
  final bool loading;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _ExamAnalyticsPage({
    required this.exam,
    required this.details,
    required this.loading,
    required this.error,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final resolvedExam = details?.exam ?? exam;
    final questions = details?.questions ?? const <ExamQuestionDetail>[];
    final totalQuestions = questions.isNotEmpty
        ? questions.length
        : resolvedExam?.totalQuestions ?? 0;
    final totalPoints = resolvedExam == null
        ? 0.0
        : resolvedExam.totalScore;

    return Container(
      color: AppColors.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ExamDetailsHeader(
                    exam: resolvedExam,
                    questionsCount: totalQuestions,
                    onBack: onBack,
                  ),
                  SizedBox(height: 22),
                  _ExamDetailsStats(
                    exam: resolvedExam,
                    questionsCount: totalQuestions,
                    totalPoints: totalPoints,
                  ),
                  SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            _ScoreDistributionCard(
                              loading: loading,
                              hasSubmissions: false,
                            ),
                            SizedBox(height: 18),
                            _QuestionBreakdownCard(
                              loading: loading,
                              error: error,
                              questions: questions,
                              onRetry: onRetry,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 18),
                      SizedBox(
                        width: 300,
                        child: _StudentResultsCard(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamDetailsHeader extends StatelessWidget {
  final ExamModel? exam;
  final int questionsCount;
  final VoidCallback onBack;

  const _ExamDetailsHeader({
    required this.exam,
    required this.questionsCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final title = exam?.title.trim().isNotEmpty == true
        ? exam!.title
        : 'Exam details';
    final updated = exam == null ? '-' : _ExamRow._formatDate(exam!.updatedAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Updated $updated • $questionsCount question${questionsCount == 1 ? '' : 's'}',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onBack,
          icon: Icon(Icons.arrow_back_rounded, size: 18),
          label: Text('Back to quizzes'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textGray,
            side: BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizedBox(width: 10),
        FilledButton.icon(
          onPressed: null,
          icon: Icon(Icons.rocket_launch_outlined, size: 18),
          label: Text('Release Grades'),
          style: FilledButton.styleFrom(
            disabledBackgroundColor: AppColors.border,
            disabledForegroundColor: AppColors.textHint,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

class _ExamDetailsStats extends StatelessWidget {
  final ExamModel? exam;
  final int questionsCount;
  final double totalPoints;

  const _ExamDetailsStats({
    required this.exam,
    required this.questionsCount,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Questions',
            value: '$questionsCount',
            subtitle: 'saved in this quiz',
            icon: Icons.quiz_outlined,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Total Points',
            value: _points(totalPoints),
            subtitle: 'from selected questions',
            icon: Icons.stacked_line_chart_rounded,
            color: AppColors.successDot,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Time Limit',
            value: exam?.durationMinutes == null
                ? 'No limit'
                : '${exam!.durationMinutes}m',
            subtitle: 'student attempt time',
            icon: Icons.timer_outlined,
            color: AppColors.warningText,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Status',
            value: exam?.isPublished == true ? 'Published' : 'Draft',
            subtitle: exam?.isPublished == true ? 'visible to students' : 'not visible yet',
            icon: Icons.verified_outlined,
            color: exam?.isPublished == true
                ? AppColors.successDot
                : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  static String _points(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      height: 118,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Spacer(),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ],
      ),
    );
  }
}

class _ScoreDistributionCard extends StatelessWidget {
  final bool loading;
  final bool hasSubmissions;

  const _ScoreDistributionCard({
    required this.loading,
    required this.hasSubmissions,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _PanelCard(
      title: 'Score Distribution',
      trailing: _TinyLegend(label: 'Students'),
      child: SizedBox(
        height: 165,
        child: Center(
          child: loading
              ? CircularProgressIndicator()
              : hasSubmissions
                  ? Text('Distribution will appear here.')
                  : Text(
                      'No student submissions yet.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
        ),
      ),
    );
  }
}

class _QuestionBreakdownCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<ExamQuestionDetail> questions;
  final VoidCallback onRetry;

  const _QuestionBreakdownCard({
    required this.loading,
    required this.error,
    required this.questions,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    Widget body;
    if (loading) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: 42),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (error != null) {
      body = _TableMessage(
        icon: Icons.error_outline_rounded,
        title: 'Could not load exam details',
        message: error!,
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    } else if (questions.isEmpty) {
      body = _TableMessage(
        icon: Icons.quiz_outlined,
        title: 'No questions attached',
        message: 'This quiz was created but no questions were returned by the backend.',
      );
    } else {
      body = Column(
        children: [
          const _QuestionBreakdownHeader(),
          ...questions.asMap().entries.map((entry) {
            return _QuestionBreakdownRow(
              index: entry.key + 1,
              question: entry.value.question,
            );
          }),
        ],
      );
    }

    return _PanelCard(
      title: 'Question Breakdown',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_rounded, size: 18, color: AppColors.textMuted),
          SizedBox(width: 12),
          Icon(Icons.download_outlined, size: 18, color: AppColors.textMuted),
        ],
      ),
      child: body,
    );
  }
}

class _QuestionBreakdownHeader extends StatelessWidget {
  const _QuestionBreakdownHeader();

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      height: 42,
      color: AppColors.surfaceBg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 48, child: _HeaderText('#')),
          Expanded(flex: 5, child: _HeaderText('QUESTION')),
          Expanded(flex: 2, child: _HeaderText('TYPE')),
          Expanded(flex: 2, child: _HeaderText('DIFFICULTY')),
          Expanded(flex: 2, child: _HeaderText('CORRECT RATE')),
        ],
      ),
    );
  }
}

class _QuestionBreakdownRow extends StatelessWidget {
  final int index;
  final QuestionModel question;

  const _QuestionBreakdownRow({
    required this.index,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final rate = question.successRate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.headerBg)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              question.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              question.typeLabel,
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _DifficultyPill(question.difficultyLabel),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              rate == null ? '-' : '${rate.toStringAsFixed(0)}%',
              style: TextStyle(
                color: rate == null ? AppColors.textHint : AppColors.successText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentResultsCard extends StatelessWidget {
  const _StudentResultsCard();

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _PanelCard(
      title: 'Student Results',
      trailing: Text(
        'TOP 5',
        style: TextStyle(
          color: AppColors.textHint,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 48),
        child: Column(
          children: [
            Icon(Icons.people_alt_outlined, color: AppColors.textHint, size: 34),
            SizedBox(height: 12),
            Text(
              'No submissions yet',
              style: TextStyle(
                color: AppColors.textTitle,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Student scores will appear here after learners attempt this quiz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final Widget trailing;
  final Widget child;

  const _PanelCard({
    required this.title,
    required this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textTitle,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                trailing,
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}

class _TinyLegend extends StatelessWidget {
  final String label;

  const _TinyLegend({required this.label});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  final String label;

  const _DifficultyPill(this.label);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final normalized = label.toLowerCase();
    final color = normalized == 'easy'
        ? AppColors.successText
        : normalized == 'hard'
            ? AppColors.errorDot
            : Color(0xFFF97316);
    return _Badge(label: label, color: color);
  }
}

String _points(double value) {
  return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
}


class _ExamDetailsDialog extends StatelessWidget {
  final ExamModel exam;
  final int questionsCount;
  const _ExamDetailsDialog({required this.exam, required this.questionsCount});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(exam.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textTitle))),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close_rounded)),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(label: exam.isPublished ? 'Published' : 'Draft', color: exam.isPublished ? AppColors.successText : AppColors.textMuted),
                  _Badge(label: _ExamRow._titleCase(exam.examType), color: AppColors.primary),
                ],
              ),
              if ((exam.description ?? '').trim().isNotEmpty) ...[
                SizedBox(height: 18),
                Text('Description', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textGray)),
                SizedBox(height: 6),
                Text(exam.description!, style: TextStyle(color: AppColors.textGray, height: 1.45)),
              ],
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _DetailTile(label: 'Questions', value: '$questionsCount')),
                  SizedBox(width: 12),
                  Expanded(child: _DetailTile(label: 'Total Points', value: _points(exam.totalScore))),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _DetailTile(label: 'Time Limit', value: exam.durationMinutes == null ? 'No limit' : '${exam.durationMinutes} min')),
                  SizedBox(width: 12),
                  Expanded(child: _DetailTile(label: 'Attempts', value: '${exam.maxAttempts}')),
                ],
              ),
              SizedBox(height: 20),
              Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text('Done'))),
            ],
          ),
        ),
      ),
    );
  }

  static String _points(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  const _DetailTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(value, style: TextStyle(color: AppColors.textTitle, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
