part of 'student_course_details_page.dart';

class _CourseLearningWorkspace extends StatelessWidget {
  final int courseId;
  final StudentCourseContent content;
  final TextEditingController searchController;
  final TextEditingController assistantController;
  final int? selectedModuleId;
  final int? selectedMaterialId;
  final int? selectedExamId;
  final StudentCourseAssistantState assistantState;
  final VoidCallback onBackToDashboard;
  final VoidCallback onBackToCourses;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettings;
  final Future<void> Function() onLogout;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseModule> onSelectModule;
  final void Function(StudentCourseModule module, StudentCourseMaterial material)
      onSelectMaterial;
  final ValueChanged<StudentCourseExam> onSelectExam;
  final ValueChanged<StudentCourseExam> onStartExam;
  final void Function(
    String message,
    StudentCourseModule? module,
    StudentCourseMaterial? material,
  ) onAssistantSend;
  final VoidCallback onAssistantClear;

  const _CourseLearningWorkspace({
    required this.courseId,
    required this.content,
    required this.searchController,
    required this.assistantController,
    required this.selectedModuleId,
    required this.selectedMaterialId,
    required this.selectedExamId,
    required this.assistantState,
    required this.onBackToDashboard,
    required this.onBackToCourses,
    required this.onNotificationsTap,
    required this.onSettings,
    required this.onLogout,
    required this.onRefresh,
    required this.onSelectModule,
    required this.onSelectMaterial,
    required this.onSelectExam,
    required this.onStartExam,
    required this.onAssistantSend,
    required this.onAssistantClear,
  });

  @override
  Widget build(BuildContext context) {
    final selectedExam = _resolveSelectedExam(content.exams);
    final selectedModule = _resolveSelectedModule(content.modules);
    final selectedMaterial = selectedExam == null
        ? _resolveSelectedMaterial(selectedModule)
        : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 980) {
            return _CompactCourseLearningWorkspace(
              courseId: courseId,
              course: content.course,
              modules: content.modules,
              exams: content.exams,
              examsLoadError: content.examsLoadError,
              selectedModule: selectedModule,
              selectedMaterial: selectedMaterial,
              selectedExam: selectedExam,
              onBackToCourses: onBackToCourses,
              onRefresh: onRefresh,
              onSelectModule: onSelectModule,
              onSelectMaterial: onSelectMaterial,
              onSelectExam: onSelectExam,
              onStartExam: onStartExam,
            );
          }

          return Row(
            children: [
              _CourseContentRail(
                courseId: courseId,
                course: content.course,
                modules: content.modules,
                exams: content.exams,
                examsLoadError: content.examsLoadError,
                selectedModuleId: selectedModule?.id,
                selectedMaterialId: selectedMaterial?.id,
                selectedExamId: selectedExam?.id,
                onBackToDashboard: onBackToDashboard,
                onRefresh: onRefresh,
                onSelectModule: onSelectModule,
                onSelectMaterial: onSelectMaterial,
                onSelectExam: onSelectExam,
              ),
              Expanded(
                child: Column(
                  children: [
                    _CourseWorkspaceHeader(
                      searchController: searchController,
                      onNotificationsTap: onNotificationsTap,
                      onSettings: onSettings,
                      onLogout: onLogout,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _LessonContentArea(
                              courseId: courseId,
                              course: content.course,
                              selectedModule: selectedModule,
                              selectedMaterial: selectedMaterial,
                              selectedExam: selectedExam,
                              onRefresh: onRefresh,
                              onStartExam: onStartExam,
                            ),
                          ),
                          _StudyAssistantPanel(
                            courseTitle: content.course?.safeTitle ?? 'Course',
                            controller: assistantController,
                            assistantState: assistantState,
                            selectedModule: selectedModule,
                            selectedMaterial: selectedMaterial,
                            onSend: (message) => onAssistantSend(
                              message,
                              selectedModule,
                              selectedMaterial,
                            ),
                            onClear: onAssistantClear,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  StudentCourseModule? _resolveSelectedModule(List<StudentCourseModule> modules) {
    if (modules.isEmpty) return null;

    for (final module in modules) {
      if (module.id == selectedModuleId) return module;
    }

    if (selectedMaterialId != null) {
      for (final module in modules) {
        final hasSelectedMaterial = module.materials.any(
          (material) => material.id == selectedMaterialId,
        );
        if (hasSelectedMaterial) return module;
      }
    }

    final firstWithMaterial = modules.where((module) => module.materials.isNotEmpty);
    if (firstWithMaterial.isNotEmpty) return firstWithMaterial.first;

    return modules.first;
  }

  StudentCourseExam? _resolveSelectedExam(List<StudentCourseExam> exams) {
    if (selectedExamId == null || exams.isEmpty) return null;
    for (final exam in exams) {
      if (exam.id == selectedExamId) return exam;
    }
    return null;
  }

  StudentCourseMaterial? _resolveSelectedMaterial(StudentCourseModule? module) {
    if (module == null || module.materials.isEmpty) return null;

    for (final material in module.materials) {
      if (material.id == selectedMaterialId) return material;
    }

    return module.materials.first;
  }
}

class _CompactCourseLearningWorkspace extends StatelessWidget {
  final int courseId;
  final StudentCourse? course;
  final List<StudentCourseModule> modules;
  final List<StudentCourseExam> exams;
  final String? examsLoadError;
  final StudentCourseModule? selectedModule;
  final StudentCourseMaterial? selectedMaterial;
  final StudentCourseExam? selectedExam;
  final VoidCallback onBackToCourses;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseModule> onSelectModule;
  final void Function(StudentCourseModule module, StudentCourseMaterial material)
      onSelectMaterial;
  final ValueChanged<StudentCourseExam> onSelectExam;
  final ValueChanged<StudentCourseExam> onStartExam;

  const _CompactCourseLearningWorkspace({
    required this.courseId,
    required this.course,
    required this.modules,
    required this.exams,
    required this.examsLoadError,
    required this.selectedModule,
    required this.selectedMaterial,
    required this.selectedExam,
    required this.onBackToCourses,
    required this.onRefresh,
    required this.onSelectModule,
    required this.onSelectMaterial,
    required this.onSelectExam,
    required this.onStartExam,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onBackToCourses,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to My Courses'),
                ),
                _SoftBadge(label: course?.safeCode ?? 'COURSE-$courseId'),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _MobileModuleSelector(
              modules: modules,
              exams: exams,
              examsLoadError: examsLoadError,
              selectedModuleId: selectedModule?.id,
              selectedMaterialId: selectedMaterial?.id,
              selectedExamId: selectedExam?.id,
              onSelectModule: onSelectModule,
              onSelectMaterial: onSelectMaterial,
              onSelectExam: onSelectExam,
              onRetryExams: onRefresh,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            child: _LessonBody(
              courseId: courseId,
              course: course,
              selectedModule: selectedModule,
              selectedMaterial: selectedMaterial,
              selectedExam: selectedExam,
              onRefresh: onRefresh,
              onStartExam: onStartExam,
            ),
          ),
        ),
      ],
    );
  }
}


class _CourseContentRail extends StatefulWidget {
  final int courseId;
  final StudentCourse? course;
  final List<StudentCourseModule> modules;
  final List<StudentCourseExam> exams;
  final String? examsLoadError;
  final int? selectedModuleId;
  final int? selectedMaterialId;
  final int? selectedExamId;
  final VoidCallback onBackToDashboard;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseModule> onSelectModule;
  final void Function(StudentCourseModule module, StudentCourseMaterial material)
      onSelectMaterial;
  final ValueChanged<StudentCourseExam> onSelectExam;

  const _CourseContentRail({
    required this.courseId,
    required this.course,
    required this.modules,
    required this.exams,
    required this.examsLoadError,
    required this.selectedModuleId,
    required this.selectedMaterialId,
    required this.selectedExamId,
    required this.onBackToDashboard,
    required this.onRefresh,
    required this.onSelectModule,
    required this.onSelectMaterial,
    required this.onSelectExam,
  });

  @override
  State<_CourseContentRail> createState() => _CourseContentRailState();
}

class _CourseContentRailState extends State<_CourseContentRail> {
  static const double _minWidth = 252;
  static const double _defaultWidth = 292;
  static const double _maxWidth = 440;

  double _width = _defaultWidth;
  bool _resizing = false;
  final Set<int> _collapsedModuleIds = <int>{};
  bool _examsExpanded = true;

  @override
  void didUpdateWidget(covariant _CourseContentRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentModuleIds = widget.modules.map((module) => module.id).toSet();
    _collapsedModuleIds.removeWhere((id) => !currentModuleIds.contains(id));
    if (widget.selectedExamId != null &&
        widget.selectedExamId != oldWidget.selectedExamId) {
      _examsExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.course?.safeCode ?? 'COURSE-${widget.courseId}';
    final courseTitle = widget.course?.safeTitle ?? code;

    return _StudentResizableSidebarHost(
      width: _width,
      minWidth: _minWidth,
      maxWidth: _maxWidth,
      isResizing: _resizing,
      onResizeStart: () => setState(() => _resizing = true),
      onResize: _resize,
      onResizeEnd: () => setState(() => _resizing = false),
      child: Container(
        width: _width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border(right: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowThin,
              blurRadius: 18,
              offset: const Offset(8, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WorkspaceBrandHeader(),
            _CourseSidebarHeader(title: courseTitle),
            Expanded(
              child: widget.modules.isEmpty &&
                      widget.exams.isEmpty &&
                      widget.examsLoadError == null
                  ? const _EmptySidebarState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      children: [
                        for (var index = 0; index < widget.modules.length; index++) ...[
                          Builder(
                            builder: (_) {
                              final module = widget.modules[index];
                              final expanded = !_collapsedModuleIds.contains(module.id);
                              return _CourseModuleCard(
                                module: module,
                                moduleNumber: index + 1,
                                expanded: expanded,
                                selected: module.id == widget.selectedModuleId &&
                                    widget.selectedExamId == null,
                                selectedMaterialId: widget.selectedExamId == null
                                    ? widget.selectedMaterialId
                                    : null,
                                onSelectModule: () => _toggleModule(module),
                                onSelectMaterial: (material) => _selectMaterial(module, material),
                              );
                            },
                          ),
                          if (index != widget.modules.length - 1) const SizedBox(height: 12),
                        ],
                        if (widget.modules.isNotEmpty ||
                            widget.exams.isNotEmpty ||
                            widget.examsLoadError != null) ...[
                          if (widget.modules.isNotEmpty) const SizedBox(height: 16),
                          _CourseExamsTreeCard(
                            exams: widget.exams,
                            loadError: widget.examsLoadError,
                            expanded: _examsExpanded,
                            selectedExamId: widget.selectedExamId,
                            onToggle: () => setState(() => _examsExpanded = !_examsExpanded),
                            onSelectExam: _selectExam,
                            onRetry: widget.onRefresh,
                          ),
                        ],
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: widget.onBackToDashboard,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resize(double delta) {
    setState(() {
      _width = (_width + delta).clamp(_minWidth, _maxWidth).toDouble();
    });
  }

  void _toggleModule(StudentCourseModule module) {
    setState(() {
      if (_collapsedModuleIds.contains(module.id)) {
        _collapsedModuleIds.remove(module.id);
      } else {
        _collapsedModuleIds.add(module.id);
      }
    });
    widget.onSelectModule(module);
  }

  void _selectMaterial(
    StudentCourseModule module,
    StudentCourseMaterial material,
  ) {
    setState(() => _collapsedModuleIds.remove(module.id));
    widget.onSelectMaterial(module, material);
  }

  void _selectExam(StudentCourseExam exam) {
    setState(() => _examsExpanded = true);
    widget.onSelectExam(exam);
  }
}

class _StudentResizableSidebarHost extends StatelessWidget {
  static const double _handleWidth = 10.0;

  final double width;
  final double minWidth;
  final double maxWidth;
  final bool isResizing;
  final Widget child;
  final VoidCallback onResizeStart;
  final void Function(double delta) onResize;
  final VoidCallback onResizeEnd;

  const _StudentResizableSidebarHost({
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.isResizing,
    required this.child,
    required this.onResizeStart,
    required this.onResize,
    required this.onResizeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + _handleWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: width, child: child),
          MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => onResizeStart(),
              onHorizontalDragUpdate: (details) => onResize(details.delta.dx),
              onHorizontalDragEnd: (_) => onResizeEnd(),
              onHorizontalDragCancel: onResizeEnd,
              child: Container(
                width: _handleWidth,
                color: isResizing
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.bg,
                child: Center(
                  child: Container(
                    width: 3,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isResizing
                          ? AppColors.primary.withValues(alpha: 0.65)
                          : AppColors.textHint.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceBrandHeader extends StatelessWidget {
  const _WorkspaceBrandHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo.webp',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learnova',
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'STUDENT PORTAL',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseWorkspaceHeader extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettings;
  final Future<void> Function() onLogout;

  const _CourseWorkspaceHeader({
    required this.searchController,
    required this.onNotificationsTap,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: UserStorage.listenable as ValueNotifier<int>,
      builder: (context, _, __) {
        return TopHeaderWidget(
          searchController: searchController,
          searchHint: 'Search topics, questions, or student',
          userName: _displayName(),
          userSubtitle: _displaySubtitle(),
          avatarUrl: UserStorage.avatarUrl,
          onNotificationsTap: onNotificationsTap,
          onSettings: onSettings,
          onLogout: () async => onLogout(),
        );
      },
    );
  }
}

class _LessonContentArea extends StatelessWidget {
  final int courseId;
  final StudentCourse? course;
  final StudentCourseModule? selectedModule;
  final StudentCourseMaterial? selectedMaterial;
  final StudentCourseExam? selectedExam;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseExam> onStartExam;

  const _LessonContentArea({
    required this.courseId,
    required this.course,
    required this.selectedModule,
    required this.selectedMaterial,
    required this.selectedExam,
    required this.onRefresh,
    required this.onStartExam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 34,
              compact ? 20 : 30,
              compact ? 16 : 34,
              42,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: selectedExam != null ? 980 : 860),
                child: _LessonBody(
                  courseId: courseId,
                  course: course,
                  selectedModule: selectedModule,
                  selectedMaterial: selectedMaterial,
                  selectedExam: selectedExam,
                  onRefresh: onRefresh,
                  onStartExam: onStartExam,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LessonBody extends StatelessWidget {
  final int courseId;
  final StudentCourse? course;
  final StudentCourseModule? selectedModule;
  final StudentCourseMaterial? selectedMaterial;
  final StudentCourseExam? selectedExam;
  final VoidCallback onRefresh;
  final ValueChanged<StudentCourseExam> onStartExam;

  const _LessonBody({
    required this.courseId,
    required this.course,
    required this.selectedModule,
    required this.selectedMaterial,
    required this.selectedExam,
    required this.onRefresh,
    required this.onStartExam,
  });

  @override
  Widget build(BuildContext context) {
    final exam = selectedExam;
    if (exam != null) {
      return _ExamOverviewBody(
        course: course,
        exam: exam,
        onStart: exam.isAvailable ? () => onStartExam(exam) : null,
      );
    }

    if (selectedModule == null) {
      return _EmptyLessonState(courseId: courseId, onRefresh: onRefresh);
    }

    final material = selectedMaterial;
    final title = material?.safeTitle ?? selectedModule!.safeTitle;
    final subtitle = material?.safeDescription ?? selectedModule!.safeDescription;
    final lessonTitle = _lessonTitle(selectedModule!, material);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lessonTitle,
          style: TextStyle(
            color: AppColors.textTitle,
            fontSize: 26,
            height: 1.16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.55,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        _MaterialPreviewStage(
          courseId: courseId,
          module: selectedModule!,
          material: material,
          title: title,
          onRefresh: onRefresh,
        ),
        const SizedBox(height: 18),
        _MaterialTopicsCard(
          courseId: courseId,
          course: course,
          module: selectedModule!,
          material: material,
        ),
      ],
    );
  }
}

class _MaterialPreviewStage extends ConsumerStatefulWidget {
  final int courseId;
  final StudentCourseModule module;
  final StudentCourseMaterial? material;
  final String title;
  final VoidCallback onRefresh;

  const _MaterialPreviewStage({
    required this.courseId,
    required this.module,
    required this.material,
    required this.title,
    required this.onRefresh,
  });

  @override
  ConsumerState<_MaterialPreviewStage> createState() => _MaterialPreviewStageState();
}

class _MaterialPreviewStageState extends ConsumerState<_MaterialPreviewStage> {
  Future<String?>? _urlFuture;
  int? _loadedMaterialId;

  Future<String?> _loadUrl(StudentCourseMaterial material) async {
    final inlineUrl = (material.downloadUrl ?? '').trim();
    if (inlineUrl.isNotEmpty) return inlineUrl;

    return ref.read(studentCoursesApiProvider).materialDownloadUrl(
          courseId: widget.courseId,
          moduleId: widget.module.id,
          materialId: material.id,
        );
  }

  Future<String?>? _ensureUrlFuture() {
    final material = widget.material;
    if (material == null) {
      _loadedMaterialId = null;
      _urlFuture = null;
      return null;
    }

    if (_loadedMaterialId != material.id || _urlFuture == null) {
      _loadedMaterialId = material.id;
      _urlFuture = _loadUrl(material);
    }

    return _urlFuture;
  }

  @override
  Widget build(BuildContext context) {
    final material = widget.material;
    if (material == null) {
      return _PdfPlaceholderCard(
        height: 430,
        icon: Icons.picture_as_pdf_outlined,
        title: 'Choose a PDF material',
        message: 'Select one of the published PDF files from the course content list.',
        actionLabel: 'Refresh',
        onAction: widget.onRefresh,
      );
    }

    if (!_isPdfMaterial(material)) {
      return _PdfPlaceholderCard(
        height: 430,
        icon: _materialIcon(material),
        title: widget.title,
        message: 'This student workspace previews PDF files only.',
      );
    }

    final future = _ensureUrlFuture();
    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _PdfPlaceholderCard(
            height: 720,
            icon: Icons.picture_as_pdf_outlined,
            title: 'Loading PDF preview...',
            message: 'Preparing the secured viewer for this material.',
            loading: true,
          );
        }

        final url = (snapshot.data ?? '').trim();
        if (snapshot.hasError || url.isEmpty) {
          return _PdfPlaceholderCard(
            height: 430,
            icon: Icons.link_off_rounded,
            title: 'PDF preview unavailable',
            message: 'Could not load the secured PDF URL. Please try again.',
            actionLabel: 'Retry',
            onAction: () {
              setState(() {
                _loadedMaterialId = null;
                _urlFuture = null;
              });
            },
          );
        }

        return _StudentPdfViewer(
          materialId: material.id,
          url: url,
        );
      },
    );
  }
}

class _StudentPdfViewer extends StatefulWidget {
  final int materialId;
  final String url;

  const _StudentPdfViewer({
    required this.materialId,
    required this.url,
  });

  @override
  State<_StudentPdfViewer> createState() => _StudentPdfViewerState();
}

class _StudentPdfViewerState extends State<_StudentPdfViewer> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(covariant _StudentPdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.materialId != widget.materialId) {
      _register();
    }
  }

  void _register() {
    _viewType = 'student-pdf-${widget.materialId}-${widget.url.hashCode}';
    registerPdfPreviewView(
      viewType: _viewType,
      url: widget.url,
      interactive: true,
    );
    updatePdfPreviewInteractivity(viewType: _viewType, interactive: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 720,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: HtmlElementView(viewType: _viewType),
    );
  }
}

class _PdfPlaceholderCard extends StatelessWidget {
  final double height;
  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PdfPlaceholderCard({
    required this.height,
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(icon, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _MaterialTopicsCard extends ConsumerWidget {
  final int courseId;
  final StudentCourse? course;
  final StudentCourseModule module;
  final StudentCourseMaterial? material;

  const _MaterialTopicsCard({
    required this.courseId,
    required this.course,
    required this.module,
    required this.material,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inlineTopics = material?.topics ?? const <StudentCourseTopic>[];
    final materialTopicsAsync = material == null || inlineTopics.isNotEmpty
        ? null
        : ref.watch(studentMaterialTopicsProvider(StudentMaterialTopicsArgs(
            courseId: courseId,
            moduleId: module.id,
            materialId: material!.id,
          )));

    final topics = inlineTopics.isNotEmpty
        ? inlineTopics
        : materialTopicsAsync?.maybeWhen(
              data: (value) => value,
              orElse: () => const <StudentCourseTopic>[],
            ) ??
            const <StudentCourseTopic>[];
    final roots = _rootCourseTopics(topics);
    final title = material == null ? 'Module Topics' : 'File Topics';
    final isLoadingTopics = materialTopicsAsync?.isLoading ?? false;
    final topicsLoadError = materialTopicsAsync?.hasError ?? false;
    final subtitle = material == null
        ? 'Select a PDF file from the course tree to see its extracted topics.'
        : isLoadingTopics
            ? '${material!.safeTitle} • loading topics...'
            : topicsLoadError
                ? '${material!.safeTitle} • topics could not be loaded'
                : '${material!.safeTitle} • ${topics.length} topic${topics.length == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textTitle,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: _SoftBadge(label: module.safeTitle),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: isLoadingTopics
                ? const _TopicsLoadingBox()
                : topicsLoadError
                    ? _TopicsLoadErrorBox(
                        onRetry: material == null
                            ? null
                            : () => ref.invalidate(
                                  studentMaterialTopicsProvider(
                                    StudentMaterialTopicsArgs(
                                      courseId: courseId,
                                      moduleId: module.id,
                                      materialId: material!.id,
                                    ),
                                  ),
                                ),
                      )
                    : topics.isEmpty
                        ? _NoTopicsBox(material: material)
                        : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < roots.length; i++) ...[
                        _TopicOutlineCard(
                          topic: roots[i],
                          allTopics: topics,
                          indexLabel: '${i + 1}'.padLeft(2, '0'),
                        ),
                        if (i != roots.length - 1) const SizedBox(height: 12),
                      ],
                      if (course != null) ...[
                        const SizedBox(height: 22),
                        Divider(color: AppColors.border),
                        const SizedBox(height: 14),
                        Text(
                          '${course!.safeCode} • ${course!.safeTitle}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopicsLoadingBox extends StatelessWidget {
  const _TopicsLoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading topics for this material...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicsLoadErrorBox extends StatelessWidget {
  final VoidCallback? onRetry;

  const _TopicsLoadErrorBox({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.dangerText,
            size: 26,
          ),
          const SizedBox(height: 10),
          Text(
            'Could not load topics for this material.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoTopicsBox extends StatelessWidget {
  final StudentCourseMaterial? material;

  const _NoTopicsBox({required this.material});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.topic_outlined,
            color: AppColors.textHint,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material == null ? 'No file selected' : 'No topics available yet',
                  style: TextStyle(
                    color: AppColors.textTitle,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  material == null
                      ? 'Choose a PDF from the course structure to preview its topics.'
                      : 'When the instructor-generated topics are ready, they will appear here for reading only.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
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

class _TopicOutlineCard extends StatelessWidget {
  final StudentCourseTopic topic;
  final List<StudentCourseTopic> allTopics;
  final String indexLabel;

  const _TopicOutlineCard({
    required this.topic,
    required this.allTopics,
    required this.indexLabel,
  });

  @override
  Widget build(BuildContext context) {
    final children = _childCourseTopics(allTopics, topic.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.infoBorder),
                ),
                child: Text(
                  indexLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.safeTitle,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((topic.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        topic.safeDescription,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (children.isNotEmpty)
                _SoftBadge(label: '${children.length} subtopic${children.length == 1 ? '' : 's'}'),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                children: [
                  for (final child in children)
                    _SubTopicOutlineRow(
                      topic: child,
                      allTopics: allTopics,
                      depth: 0,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubTopicOutlineRow extends StatelessWidget {
  final StudentCourseTopic topic;
  final List<StudentCourseTopic> allTopics;
  final int depth;

  const _SubTopicOutlineRow({
    required this.topic,
    required this.allTopics,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final children = _childCourseTopics(allTopics, topic.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0),
          child: Stack(
            children: [
              Positioned(
                left: 6,
                top: 0,
                bottom: children.isEmpty ? 13 : -2,
                child: Container(width: 1, color: AppColors.border),
              ),
              Positioned(
                left: 6,
                top: 13,
                child: Container(width: 12, height: 1, color: AppColors.border),
              ),
              Container(
                margin: const EdgeInsets.only(left: 20),
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.safeTitle,
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if ((topic.description ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              topic.safeDescription,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final child in children)
          _SubTopicOutlineRow(
            topic: child,
            allTopics: allTopics,
            depth: depth + 1,
          ),
      ],
    );
  }
}

