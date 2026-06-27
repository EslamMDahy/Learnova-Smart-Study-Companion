part of 'materials_tab.dart';

extension _CourseMaterialsTabView on _CourseMaterialsTabState {
  Widget _buildMaterialsScaffold(BuildContext context) {
    final st = ref.watch(courseDetailsControllerProvider(widget.course.id));
    _maybeRestoreUiState(st);

    if (_showQuestionAuthoring) {
      return QuestionBankAuthoringFlow(
        course: widget.course,
        initialModuleIds: _authoringModuleIds,
        initialMaterialIds: _authoringMaterialIds,
        initialTopicIds: _authoringTopicIds,
        embedded: true,
        launchContext: _authoringLaunchContext,
        onClose: _closeQuestionAuthoring,
        onSavedToQuestionBank: _openQuestionBankAfterSave,
      );
    }

    final active = _active ?? _sel;
    final hasTreeSelection = _selectionMode && !_treeSelection.isEmpty;
    final footerCtx = hasTreeSelection ? (_footerCtxFromSelection(st) ?? active) : active;
    final showFooter = hasTreeSelection
        ? footerCtx != null
        : (footerCtx != null && !_hideFooterForActive);
    void refreshModules() => _refreshStructureTree(st);

    void toggleSidebarCollapsed() {
      setState(() {
        _sidebarCollapsed = !_sidebarCollapsed;
        _persistUiState();
      });
    }

    Widget sidebar({required double width}) => _SidebarWidget(
          width: width,
          state: st,
          expanded: _expanded,
          active: _active,
          scroll: _scroll,
          draggingModuleId: _draggingModuleId,
          onModuleTap: (m) => _tapModule(m, st),
          onMaterialTap: _tapMaterial,
          onTopicTap: _tapTopic,
          onAddMaterial: _showUploadSheet,
          onAddModule: _showCreateModuleDialog,
          onModuleReorder: _handleModuleReorder,
          onDragChanged: (moduleId) {
            if (!mounted) return;
            setState(() => _draggingModuleId = moduleId);
          },
          onRefresh: refreshModules,
          onToggleCollapsed: toggleSidebarCollapsed,
          refreshing: _treeRefreshing,
          selectionMode: _selectionMode,
          treeSelection: _treeSelection,
          onToggleSelectionMode: _toggleSelectionMode,
          onClearSelection: _clearTreeSelection,
          onModuleCheckChanged: (module, value) => _setModuleChecked(module, st, value),
          onMaterialCheckChanged: (module, material, value) => _setMaterialChecked(module, material, st, value),
          onTopicCheckChanged: (module, material, topic, value) =>
              _setTopicChecked(module, material, topic, st, value),
          expandedMaterialIds: _expandedMaterialIds,
          expandedTopicIds: _expandedTopicIds,
          onToggleMaterialExpanded: _toggleMaterialExpanded,
          onToggleTopicExpanded: _toggleTopicExpanded,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 820;
        final compact = constraints.maxWidth < 1120;
        final defaultSidebarWidth = compact ? _CourseMaterialsTabState._sidebarCompactWidth : _CourseMaterialsTabState._sidebarDefaultWidth;
        final computedMaxWidth = constraints.maxWidth * 0.38;
        final effectiveMaxWidth = computedMaxWidth < 300
            ? 300.0
            : computedMaxWidth > _CourseMaterialsTabState._sidebarMaxWidth
                ? _CourseMaterialsTabState._sidebarMaxWidth
                : computedMaxWidth;
        final maxSidebarWidth = effectiveMaxWidth < _CourseMaterialsTabState._sidebarMinWidth
            ? _CourseMaterialsTabState._sidebarMinWidth
            : effectiveMaxWidth;
        final sidebarWidth = (_sidebarWidth ?? defaultSidebarWidth)
            .clamp(_CourseMaterialsTabState._sidebarMinWidth, maxSidebarWidth)
            .toDouble();
        final sidebarHeight = constraints.maxHeight < 640 ? 212.0 : 286.0;

        void resizeSidebar(double delta) {
          setState(() {
            final currentWidth = _sidebarWidth ?? sidebarWidth;
            _sidebarWidth = (currentWidth + delta)
                .clamp(_CourseMaterialsTabState._sidebarMinWidth, maxSidebarWidth)
                .toDouble();
            _sidebarCollapsed = false;
          });
        }

        Widget treePane() {
          if (_sidebarCollapsed) {
            return _CollapsedSidebarRail(
              width: _CollapsedSidebarRail.railWidth,
              modulesCount: st.modules.length,
              loading: st.modulesLoading || _treeRefreshing,
              onExpand: toggleSidebarCollapsed,
              onAddModule: _showCreateModuleDialog,
              onRefresh: refreshModules,
            );
          }

          return _ResizableSidebarHost(
            width: sidebarWidth,
            minWidth: _CourseMaterialsTabState._sidebarMinWidth,
            maxWidth: maxSidebarWidth,
            isResizing: _sidebarResizing,
            onResizeStart: () => setState(() => _sidebarResizing = true),
            onResize: resizeSidebar,
            onResizeEnd: () {
              setState(() => _sidebarResizing = false);
              _persistUiState();
            },
            child: RepaintBoundary(child: sidebar(width: sidebarWidth)),
          );
        }

        return Column(children: [
          Expanded(
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_sidebarCollapsed)
                        SizedBox(
                          height: sidebarHeight,
                          child: RepaintBoundary(
                            child: sidebar(width: double.infinity),
                          ),
                        )
                      else
                        _CollapsedSidebarBar(
                          modulesCount: st.modules.length,
                          loading: st.modulesLoading || _treeRefreshing,
                          onExpand: toggleSidebarCollapsed,
                          onAddModule: _showCreateModuleDialog,
                          onRefresh: refreshModules,
                        ),
                      const Divider(height: 1, thickness: 1, color: _K.div),
                      Expanded(
                        child: RepaintBoundary(child: _buildMaterialsBody(st)),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      treePane(),
                      Expanded(
                        child: RepaintBoundary(child: _buildMaterialsBody(st)),
                      ),
                    ],
                  ),
          ),
          if (showFooter)
            _FooterWidget(
              ctx: footerCtx,
              uploading: st.uploading,
              canGenerate: _canGenerate(footerCtx, st),
              selectionCount: hasTreeSelection ? _treeSelection.totalCount : null,
              onUpload: () { final m = footerCtx.module; if (m != null) _showUploadSheet(m); },
              onGenerate: () => _openQuestionAuthoringFromSelection(footerCtx),
              onAskAi: widget.onOpenCourseAssistant,
              assistantBusy: widget.courseAssistantBusy,
              onClose: () => setState(() {
                if (_selectionMode && !_treeSelection.isEmpty) {
                  _treeSelection = _treeSelection.clear();
                  _hideFooterForActive = false;
                } else {
                  _hideFooterForActive = true;
                }
                _persistUiState();
              }),
            ),
        ],);
      },
    );
  }

  Widget _buildMaterialsBody(CourseDetailsState st) {
    final _QuestionDraftInfo? draft = _readQuestionDraftInfo();
    if (draft == null) return _buildPanel(st);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _QuestionDraftBanner(
          info: draft,
          onResume: () => _resumeQuestionDraft(draft),
          onDiscard: _discardQuestionDraft,
        ),
        Expanded(child: _buildPanel(st)),
      ],
    );
  }

  _QuestionDraftInfo? _readQuestionDraftInfo() {
    final String? raw = _questionDraftStore.getString(_questionDraftKey);
    if (raw == _cachedQuestionDraftRaw) return _cachedQuestionDraftInfo;

    _cachedQuestionDraftRaw = raw;
    if (raw == null || raw.trim().isEmpty) {
      _cachedQuestionDraftInfo = null;
      return null;
    }

    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final List<dynamic> questions = (data['questions'] as List?) ?? const <dynamic>[];
      if (questions.isEmpty) {
        _cachedQuestionDraftInfo = null;
        return null;
      }

      final List<Map<String, dynamic>> targets = ((data['targets'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();

      final Set<int> topicIds = <int>{};
      final Set<int> materialIds = <int>{};
      final Set<int> moduleIds = <int>{};
      for (final Map<String, dynamic> target in targets) {
        final int? topicId = (target['topicId'] as num?)?.toInt();
        final int? materialId = (target['materialId'] as num?)?.toInt();
        final int? moduleId = (target['moduleId'] as num?)?.toInt();
        if (topicId != null) topicIds.add(topicId);
        if (materialId != null) materialIds.add(materialId);
        if (moduleId != null) moduleIds.add(moduleId);
      }

      final List<Map<String, dynamic>> questionMaps = questions
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
      for (final Map<String, dynamic> question in questionMaps) {
        final int? topicId = (question['topicId'] as num?)?.toInt();
        final int? materialId = (question['materialId'] as num?)?.toInt();
        final int? moduleId = (question['moduleId'] as num?)?.toInt();
        if (topicId != null) topicIds.add(topicId);
        if (materialId != null) materialIds.add(materialId);
        if (moduleId != null) moduleIds.add(moduleId);
      }

      final List<QuestionAuthoringTarget> targetSnapshots = targets
          .map(_authoringTargetFromJson)
          .whereType<QuestionAuthoringTarget>()
          .toList();
      if (targetSnapshots.isEmpty) {
        final Map<int, QuestionAuthoringTarget> questionTargets = <int, QuestionAuthoringTarget>{};
        for (final Map<String, dynamic> question in questionMaps) {
          final int? topicId = (question['topicId'] as num?)?.toInt();
          final String topicName = (question['topicName']?.toString() ?? '').trim();
          if (topicId == null || topicName.isEmpty) continue;
          questionTargets[topicId] = QuestionAuthoringTarget(
            moduleId: (question['moduleId'] as num?)?.toInt(),
            moduleName: question['moduleName']?.toString(),
            materialId: (question['materialId'] as num?)?.toInt(),
            materialName: question['materialName']?.toString(),
            topicId: topicId,
            topicName: topicName,
            isSubtopic: true,
          );
        }
        targetSnapshots.addAll(questionTargets.values);
      }
      final String title = topicIds.isEmpty
          ? 'Saved question draft'
          : '${topicIds.length} saved target${topicIds.length == 1 ? '' : 's'}';

      _cachedQuestionDraftInfo = _QuestionDraftInfo(
        questionCount: questions.length,
        targetCount: topicIds.isEmpty ? targets.length : topicIds.length,
        moduleIds: moduleIds,
        materialIds: materialIds,
        topicIds: topicIds,
        launchContext: QuestionAuthoringLaunchContext(
          kind: QuestionAuthoringScopeKind.selection,
          title: title,
          subtitle: 'Local draft restored from this browser. Continue editing or save selected questions to backend.',
          selectedModuleIds: moduleIds,
          selectedMaterialIds: materialIds,
          selectedTopicIds: topicIds,
          targetSnapshots: targetSnapshots,
        ),
      );
      return _cachedQuestionDraftInfo;
    } catch (_) {
      _cachedQuestionDraftInfo = null;
      return null;
    }
  }

  void _resumeQuestionDraft(_QuestionDraftInfo draft) {
    setState(() {
      _authoringModuleIds = draft.moduleIds;
      _authoringMaterialIds = draft.materialIds;
      _authoringTopicIds = draft.topicIds;
      _authoringLaunchContext = draft.launchContext;
      _showQuestionAuthoring = true;
      _hideFooterForActive = true;
    });
    _persistUiState();
  }

  void _discardQuestionDraft() {
    _cachedQuestionDraftRaw = null;
    _cachedQuestionDraftInfo = null;
    _questionDraftStore.remove(_questionDraftKey);
    setState(() {});
  }

}
