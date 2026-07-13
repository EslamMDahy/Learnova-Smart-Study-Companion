part of 'instructor_presentation_page.dart';

const int _maxPresentationSectionsPerRequest = 4;

extension _PresentationWorkspace on _InstructorPresentationPageState {
  Future<void> _loadWorkspaceContext() async {
    final courseId = widget.courseId;
    final moduleId = widget.moduleId;
    final materialId = widget.materialId;
    if (courseId == null || moduleId == null || materialId == null) {
      if (!mounted) return;
      setState(() {
        _workspaceLoading = false;
        _workspaceError =
            'The presentation link is missing its course or material context.';
        _generationStatus = 'Invalid presentation context';
      });
      return;
    }

    setState(() {
      _workspaceLoading = true;
      _workspaceError = null;
      _workspaceTopics = const <TopicItem>[];
      _workspaceSections = const <PresentationTargetSection>[];
      _generationBatchIndex = 0;
      _generationBatchCount = 0;
      _generationStatus = 'Loading selected content…';
    });

    try {
      final topicsApi = ref.read(topicsApiProvider);
      final response = await topicsApi.listTopics(
        courseId: courseId,
        moduleId: moduleId,
        materialId: materialId,
      );
      if (!mounted) return;

      final listedTopicsById = <int, TopicItem>{
        for (final TopicItem topic in response.topics) topic.id: topic,
      };
      final requestedIds = widget.selectedTopicIds;
      final requestedTopics = response.topics.where((TopicItem topic) {
        return requestedIds.isEmpty || requestedIds.contains(topic.id);
      }).toList();

      if (requestedTopics.isEmpty) {
        throw const FormatException(
          'The selected topics are no longer available in this material.',
        );
      }

      final hydratedTopicsById = <int, TopicItem>{};

      Future<TopicItem?> loadTopicDetails(int topicId) async {
        final cached = hydratedTopicsById[topicId];
        if (cached != null) return cached;

        final listed = listedTopicsById[topicId];
        if (listed == null) return null;

        try {
          final detail = await topicsApi.getTopic(
            courseId: courseId,
            moduleId: moduleId,
            materialId: materialId,
            topicId: topicId,
          );
          final hydrated = detail.topic.copyWith(
            moduleId: moduleId,
            materialId: materialId,
            pageStart: detail.topic.pageStart ?? listed.pageStart,
            pageEnd: detail.topic.pageEnd ?? listed.pageEnd,
          );
          hydratedTopicsById[topicId] = hydrated;
          return hydrated;
        } catch (_) {
          final normalized = listed.copyWith(
            moduleId: moduleId,
            materialId: materialId,
          );
          hydratedTopicsById[topicId] = normalized;
          return normalized;
        }
      }

      final selectedTopics = <TopicItem>[];
      for (final TopicItem listed in requestedTopics) {
        selectedTopics.add(await loadTopicDetails(listed.id) ?? listed);
      }

      selectedTopics.sort((TopicItem a, TopicItem b) {
        final startCompare = (a.pageStart ?? (1 << 30))
            .compareTo(b.pageStart ?? (1 << 30));
        if (startCompare != 0) return startCompare;
        return a.orderIndex.compareTo(b.orderIndex);
      });

      int? materialPageCount = widget.materialPageCount;
      if (materialPageCount == null || materialPageCount <= 0) {
        try {
          final materialsResponse =
              await ref.read(materialsApiProvider).listMaterials(
                    courseId: courseId,
                    moduleId: moduleId,
                  );
          for (final material in materialsResponse.materials) {
            if (material.id == materialId) {
              materialPageCount = material.pageCount;
              break;
            }
          }
        } catch (_) {
          // Topic ranges remain the primary source.
        }
      }

      final sections = <PresentationTargetSection>[];
      for (final TopicItem topic in selectedTopics) {
        TopicItem? rangeSource = topic;
        final visitedTopicIds = <int>{topic.id};

        while (rangeSource != null &&
            rangeSource.pageStart == null &&
            rangeSource.pageEnd == null &&
            rangeSource.parentTopicId != null) {
          final parentId = rangeSource.parentTopicId!;
          if (!visitedTopicIds.add(parentId)) break;
          rangeSource = await loadTopicDetails(parentId);
        }

        int? pageStart = rangeSource?.pageStart;
        int? pageEnd = rangeSource?.pageEnd;
        if (pageStart == null && pageEnd != null) pageStart = pageEnd;
        if (pageEnd == null && pageStart != null) pageEnd = pageStart;

        if (pageStart == null || pageEnd == null) {
          final pageCount = materialPageCount;
          if (pageCount != null && pageCount > 0) {
            pageStart = 1;
            pageEnd = pageCount;
          }
        }

        if (pageStart == null || pageEnd == null) continue;
        sections.add(
          PresentationTargetSection(
            topicId: topic.id,
            topicTitle: topic.title,
            pageStart: math.min(pageStart, pageEnd),
            pageEnd: math.max(pageStart, pageEnd),
          ),
        );
      }

      if (sections.isEmpty) {
        throw const FormatException(
          'The selected topics have no page ranges and the material has no page count. Add page ranges to the topics before generating a presentation.',
        );
      }

      final batchCount =
          (sections.length + _maxPresentationSectionsPerRequest - 1) ~/
              _maxPresentationSectionsPerRequest;

      if (!mounted) return;
      setState(() {
        _workspaceTopics = selectedTopics;
        _workspaceSections = sections;
        _slideCount = math.max(6, sections.length + 2).clamp(4, 30).toInt();
        _workspaceLoading = false;
        _generationBatchCount = batchCount;
        _generationStatus = batchCount > 1
            ? 'Ready — content will be generated in $batchCount batches'
            : 'Ready to generate';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _workspaceLoading = false;
        _workspaceError = _presentationErrorMessage(error);
        _generationStatus = 'Content could not be loaded';
      });
    }
  }

  List<List<PresentationTargetSection>> _presentationSectionBatches() {
    final batches = <List<PresentationTargetSection>>[];
    for (var start = 0;
        start < _workspaceSections.length;
        start += _maxPresentationSectionsPerRequest) {
      final end = math.min(
        start + _maxPresentationSectionsPerRequest,
        _workspaceSections.length,
      );
      batches.add(_workspaceSections.sublist(start, end));
    }
    return batches;
  }

  List<int> _slidesPerPresentationBatch(int batchCount) {
    if (batchCount <= 0) return const <int>[];
    if (batchCount == 1) return <int>[_slideCount];

    const minimumSlidesPerBatch = 4;
    final cleanupAllowance = math.max(0, batchCount - 1) * 2;
    final effectiveTotal = math.max(
      _slideCount + cleanupAllowance,
      batchCount * minimumSlidesPerBatch,
    );
    final base = effectiveTotal ~/ batchCount;
    final remainder = effectiveTotal % batchCount;

    return <int>[
      for (var index = 0; index < batchCount; index++)
        base + (index < remainder ? 1 : 0),
    ];
  }

  Future<void> _generatePresentationFromWorkspace() async {
    final courseId = widget.courseId;
    final materialId = widget.materialId;
    if (courseId == null || materialId == null || _workspaceSections.isEmpty) {
      return;
    }
    if (_isGenerating) return;

    final batches = _presentationSectionBatches();
    final slidesPerBatch = _slidesPerPresentationBatch(batches.length);

    _generationCancelToken?.cancel('Starting a new presentation request.');
    _streamCancelToken?.cancel('Starting a new presentation request.');
    _generationCancelToken = CancelToken();
    _streamCancelToken = null;

    setState(() {
      _isGenerating = true;
      _workspaceError = null;
      _generationBatchIndex = 0;
      _generationBatchCount = batches.length;
      _generationStatus = batches.length == 1
          ? 'Generating presentation slides…'
          : 'Preparing ${batches.length} presentation batches…';
      _deck = null;
      _selectedSlide = 0;
    });

    try {
      final generatedDecks = <PresentationDeck>[];
      for (var batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        if (_generationCancelToken?.isCancelled == true) return;

        if (mounted) {
          setState(() {
            _generationBatchIndex = batchIndex + 1;
            _generationStatus = batches.length == 1
                ? 'Generating presentation slides…'
                : 'Generating batch ${batchIndex + 1} of ${batches.length}…';
          });
        }

        final result = await _generatePresentationBatch(
          courseId: courseId,
          materialId: materialId,
          sections: batches[batchIndex],
          slideCount: slidesPerBatch[batchIndex],
        );

        final parsedDeck =
            PresentationCodeParser.parse(jsonEncode(result.deckJson));
        if (parsedDeck.slides.isEmpty) {
          throw FormatException(
            'Batch ${batchIndex + 1} returned an empty presentation.',
          );
        }
        generatedDecks.add(parsedDeck);
      }

      if (!mounted) return;
      setState(() {
        _generationStatus = 'Combining generated slides…';
      });

      final deck = _mergePresentationBatches(generatedDecks);
      if (deck.slides.isEmpty) {
        throw const FormatException('The AI returned an empty presentation.');
      }

      if (!mounted) return;
      setState(() {
        _deck = deck;
        _selectedSlide = 0;
        _generationBatchIndex = batches.length;
        _generationStatus = 'Presentation ready';
        _isGenerating = false;
      });
    } catch (error) {
      if (!mounted) return;
      final prefix = _generationBatchIndex > 0 && _generationBatchCount > 1
          ? 'Batch $_generationBatchIndex of $_generationBatchCount failed. '
          : '';
      setState(() {
        _isGenerating = false;
        _workspaceError = '$prefix${_presentationErrorMessage(error)}';
        _generationStatus = 'Generation failed';
      });
    }
  }

  Future<PresentationGenerationResult> _generatePresentationBatch({
    required int courseId,
    required int materialId,
    required List<PresentationTargetSection> sections,
    required int slideCount,
  }) async {
    final api = ref.read(presentationApiProvider);
    String? previousResultSignature;

    try {
      final previous = await api.getPresentationResult(
        courseId: courseId,
        materialId: materialId,
        cancelToken: _generationCancelToken,
      );
      previousResultSignature = _presentationResultSignature(previous);
    } catch (_) {
      previousResultSignature = null;
    }

    final response = await api.generatePresentation(
      courseId: courseId,
      materialId: materialId,
      payload: GeneratePresentationRequest(
        slideCount: slideCount,
        targetSections: sections,
      ),
      cancelToken: _generationCancelToken,
    );

    if (!response.isProcessing) {
      throw FormatException(
        response.status.trim().isEmpty
            ? 'The presentation request was not accepted.'
            : 'Unexpected generation status: ${response.status}',
      );
    }

    return _loadPresentationResultWithRetry(
      courseId: courseId,
      materialId: materialId,
      previousResultSignature: previousResultSignature,
    );
  }

  Future<PresentationGenerationResult> _loadPresentationResultWithRetry({
    required int courseId,
    required int materialId,
    String? previousResultSignature,
  }) async {
    Object? lastError;
    const maxAttempts = 305;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final result = await ref.read(presentationApiProvider).getPresentationResult(
              courseId: courseId,
              materialId: materialId,
              cancelToken: _generationCancelToken,
            );
        final signature = _presentationResultSignature(result);
        if (previousResultSignature == null ||
            signature != previousResultSignature) {
          return result;
        }
      } catch (error) {
        lastError = error;
      }

      if (attempt == maxAttempts - 1) break;
      await Future<void>.delayed(
        attempt < 10 ? const Duration(seconds: 1) : const Duration(seconds: 2),
      );
    }

    if (lastError != null) throw lastError;
    throw const FormatException(
      'The generated presentation did not become available in time.',
    );
  }

  String _presentationResultSignature(PresentationGenerationResult result) {
    return jsonEncode(result.deckJson);
  }

  PresentationDeck _mergePresentationBatches(
    List<PresentationDeck> decks,
  ) {
    if (decks.length == 1) return _renumberPresentationDeck(decks.first);

    final combinedSlides = <PresentationSlide>[];
    for (var deckIndex = 0; deckIndex < decks.length; deckIndex++) {
      final originalSlides = decks[deckIndex].slides;
      var slides = List<PresentationSlide>.from(originalSlides);

      if (deckIndex > 0) {
        while (slides.isNotEmpty &&
            const <String>{'title_slide', 'lecture_objectives'}
                .contains(slides.first.layoutType)) {
          slides.removeAt(0);
        }
      }

      if (deckIndex < decks.length - 1) {
        while (slides.isNotEmpty &&
            const <String>{'summary', 'references'}
                .contains(slides.last.layoutType)) {
          slides.removeLast();
        }
      }

      if (slides.isEmpty) {
        slides = List<PresentationSlide>.from(originalSlides);
      }
      combinedSlides.addAll(slides);
    }

    final first = decks.first;
    return _renumberPresentationDeck(
      first.copyWith(
        sourceLabel: '${decks.length} AI content batches',
        slides: combinedSlides,
      ),
    );
  }

  PresentationDeck _renumberPresentationDeck(PresentationDeck deck) {
    final normalized = <PresentationSlide>[
      for (var index = 0; index < deck.slides.length; index++)
        deck.slides[index].usesDefaultTemplate
            ? PresentationTemplateEngine.rebuildSlide(
                deck.slides[index],
                slideNumber: index + 1,
              )
            : deck.slides[index].copyWith(slideNumber: index + 1),
    ];
    return deck.copyWith(slides: normalized);
  }

  String _presentationErrorMessage(Object error) {
    if (error is FormatException) {
      final message = error.message.toString().trim();
      if (message.isNotEmpty) return message;
    }
    return mapApiError(error);
  }

  void _goBackToCourseMaterials() {
    final slug = widget.courseSlug;
    if (slug == null || slug.trim().isEmpty) {
      context.go(Routes.instructorCourses);
      return;
    }
    context.go(Routes.courseMaterials(slug));
  }

  int _workspacePageCount() {
    final pages = <int>{};
    for (final section in _workspaceSections) {
      for (var page = section.pageStart; page <= section.pageEnd; page++) {
        pages.add(page);
      }
    }
    return pages.length;
  }

  Widget _buildPresentationWorkspace(BuildContext context) {
    final deck = _deck;
    final selectedSlide = deck == null || deck.slides.isEmpty
        ? null
        : deck.slides[_selectedSlide.clamp(0, deck.slides.length - 1).toInt()];
    final batchCount = _workspaceSections.isEmpty
        ? 0
        : (_workspaceSections.length +
                _maxPresentationSectionsPerRequest -
                1) ~/
            _maxPresentationSectionsPerRequest;

    final preview = _DeckPreviewPanel(
      deck: deck,
      selectedSlide: _selectedSlide,
      showExtractedText: _showExtractedText,
      onShowExtractedTextChanged: (bool value) {
        setState(() => _showExtractedText = value);
      },
      onSlideSelected: (int index) {
        setState(() => _selectedSlide = index);
      },
      onDownload: _downloadDeck,
      isDownloading: _isExportingPptx,
      onEditSlide:
          selectedSlide?.usesCardEditor == true ? _editSelectedSlide : null,
      onDuplicateSlide: deck == null ? null : _duplicateSelectedSlide,
      onDeleteSlide:
          deck != null && deck.slides.length > 1 ? _deleteSelectedSlide : null,
      emptyState: _PresentationWorkspaceEmptyPreview(
        loading: _workspaceLoading,
        generating: _isGenerating,
        error: _workspaceError,
        status: _generationStatus,
        batchIndex: _generationBatchIndex,
        batchCount: _generationBatchCount,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final compact = constraints.maxWidth < 900;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 24,
                compact ? 14 : 22,
                compact ? 14 : 24,
                80,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _PresentationWorkspaceHero(
                        compact: compact,
                        courseTitle: widget.courseTitle,
                        materialTitle: widget.materialTitle,
                        sectionCount: _workspaceSections.length,
                        pageCount: _workspacePageCount(),
                        requestedSlideCount: _slideCount,
                        generatedSlideCount: deck?.slides.length,
                        batchCount: batchCount,
                        loading: _workspaceLoading,
                        generating: _isGenerating,
                        canGenerate: !_workspaceLoading &&
                            !_isGenerating &&
                            _workspaceSections.isNotEmpty,
                        onBack: _goBackToCourseMaterials,
                        onGenerate: _generatePresentationFromWorkspace,
                      ),
                      const SizedBox(height: 12),
                      _PresentationWorkspaceControls(
                        compact: compact,
                        topics: _workspaceTopics,
                        sections: _workspaceSections,
                        slideCount: _slideCount,
                        loading: _workspaceLoading,
                        generating: _isGenerating,
                        status: _generationStatus,
                        error: _workspaceError,
                        batchIndex: _generationBatchIndex,
                        batchCount: batchCount,
                        onSlideCountChanged: (int value) {
                          setState(() => _slideCount = value);
                        },
                        onRetryLoad: _loadWorkspaceContext,
                      ),
                      const SizedBox(height: 12),
                      preview,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PresentationWorkspaceHero extends StatelessWidget {
  final bool compact;
  final String? courseTitle;
  final String? materialTitle;
  final int sectionCount;
  final int pageCount;
  final int requestedSlideCount;
  final int? generatedSlideCount;
  final int batchCount;
  final bool loading;
  final bool generating;
  final bool canGenerate;
  final VoidCallback onBack;
  final VoidCallback onGenerate;

  const _PresentationWorkspaceHero({
    required this.compact,
    required this.courseTitle,
    required this.materialTitle,
    required this.sectionCount,
    required this.pageCount,
    required this.requestedSlideCount,
    required this.generatedSlideCount,
    required this.batchCount,
    required this.loading,
    required this.generating,
    required this.canGenerate,
    required this.onBack,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _PresentationBackButton(onPressed: onBack),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _PresentationHeaderChip(
              icon: Icons.school_outlined,
              label: (courseTitle ?? 'Current course').trim(),
            ),
            _PresentationHeaderChip(
              icon: Icons.picture_as_pdf_outlined,
              label: (materialTitle ?? 'Selected material').trim(),
            ),
            if (batchCount > 1)
              _PresentationHeaderChip(
                icon: Icons.layers_outlined,
                label: '$batchCount safe batches',
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'AI Presentation Workspace',
          style: TextStyle(
            fontSize: compact ? 27 : 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.05,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            'Review the selected content, choose the deck length, then generate, edit, reorder and download the presentation from one workspace.',
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
        ),
      ],
    );

    final right = SizedBox(
      width: compact ? double.infinity : 470,
      child: Column(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: <Widget>[
          Wrap(
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _PresentationHeroStat('$sectionCount', 'Sections'),
              _PresentationHeroStat('$pageCount', 'Pages'),
              _PresentationHeroStat(
                '${generatedSlideCount ?? requestedSlideCount}',
                generatedSlideCount == null ? 'Planned slides' : 'Slides',
              ),
            ],
          ),
          SizedBox(height: compact ? 18 : 54),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: canGenerate ? onGenerate : null,
              icon: generating
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      generatedSlideCount == null
                          ? Icons.auto_awesome_rounded
                          : Icons.refresh_rounded,
                      size: 18,
                    ),
              label: Text(
                generating
                    ? 'Generating…'
                    : generatedSlideCount == null
                        ? 'Generate presentation'
                        : 'Regenerate presentation',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.22),
                foregroundColor: AppColors.primary,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.55),
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 198),
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Color(0xFF137FEC),
            Color(0xFF1D6FE8),
            Color(0xFF25A7E8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowBlue.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -80,
            bottom: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    left,
                    const SizedBox(height: 18),
                    right,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: left),
                    const SizedBox(width: 24),
                    right,
                  ],
                ),
        ],
      ),
    );
  }
}

class _PresentationBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PresentationBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded, size: 17),
        label: const Text('Back to materials'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PresentationHeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PresentationHeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresentationHeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _PresentationHeroStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.19)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresentationWorkspaceControls extends StatelessWidget {
  final bool compact;
  final List<TopicItem> topics;
  final List<PresentationTargetSection> sections;
  final int slideCount;
  final bool loading;
  final bool generating;
  final String status;
  final String? error;
  final int batchIndex;
  final int batchCount;
  final ValueChanged<int> onSlideCountChanged;
  final VoidCallback onRetryLoad;

  const _PresentationWorkspaceControls({
    required this.compact,
    required this.topics,
    required this.sections,
    required this.slideCount,
    required this.loading,
    required this.generating,
    required this.status,
    required this.error,
    required this.batchIndex,
    required this.batchCount,
    required this.onSlideCountChanged,
    required this.onRetryLoad,
  });

  @override
  Widget build(BuildContext context) {
    final contentPanel = _PresentationSelectedContent(
      topics: topics,
      sections: sections,
      loading: loading,
      error: error,
      batchCount: batchCount,
      onRetryLoad: onRetryLoad,
    );
    final lengthPanel = _PresentationLengthPanel(
      slideCount: slideCount,
      generating: generating,
      onChanged: onSlideCountChanged,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          compact
              ? Column(
                  children: <Widget>[
                    contentPanel,
                    const SizedBox(height: 16),
                    lengthPanel,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: contentPanel),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: lengthPanel),
                  ],
                ),
          const SizedBox(height: 16),
          _PresentationStatusStrip(
            status: status,
            error: error,
            active: generating || loading,
            batchIndex: batchIndex,
            batchCount: batchCount,
          ),
        ],
      ),
    );
  }
}

class _PresentationSelectedContent extends StatelessWidget {
  final List<TopicItem> topics;
  final List<PresentationTargetSection> sections;
  final bool loading;
  final String? error;
  final int batchCount;
  final VoidCallback onRetryLoad;

  const _PresentationSelectedContent({
    required this.topics,
    required this.sections,
    required this.loading,
    required this.error,
    required this.batchCount,
    required this.onRetryLoad,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _PresentationStepBadge(number: 1),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Selected content', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(
                    'The AI only receives the topic ranges selected from Materials.',
                    style: AppTextStyles.mutedSmall,
                  ),
                ],
              ),
            ),
            if (sections.isNotEmpty)
              _PresentationCountPill('${sections.length} sections'),
          ],
        ),
        const SizedBox(height: 14),
        if (loading)
          const _PresentationLoadingBlock()
        else if (sections.isEmpty)
          _PresentationInlineError(
            message: error ?? 'No valid topic sections were found.',
            onRetry: onRetryLoad,
          )
        else ...<Widget>[
          if (batchCount > 1) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.infoBorder),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.layers_outlined,
                      size: 17, color: AppColors.infoText),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${sections.length} sections will be processed in $batchCount requests, with a maximum of $_maxPresentationSectionsPerRequest sections per request, then merged into one deck.',
                      style: AppTextStyles.mutedSmall.copyWith(
                        color: AppColors.infoText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 210),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final section in sections)
                    _PresentationSectionChip(
                      section: section,
                      isSubtopic: topics.any(
                        (TopicItem topic) =>
                            topic.id == section.topicId &&
                            topic.parentTopicId != null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PresentationLengthPanel extends StatelessWidget {
  final int slideCount;
  final bool generating;
  final ValueChanged<int> onChanged;

  const _PresentationLengthPanel({
    required this.slideCount,
    required this.generating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _PresentationStepBadge(number: 2),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Deck length', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(
                    'Choose how detailed the generated lesson should be.',
                    style: AppTextStyles.mutedSmall,
                  ),
                ],
              ),
            ),
            _PresentationCountPill('$slideCount slides'),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final value in const <int>[6, 10, 15, 20])
              ChoiceChip(
                label: Text('$value slides'),
                selected: slideCount == value,
                onSelected: generating ? null : (_) => onChanged(value),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceMuted,
                side: BorderSide(
                  color: slideCount == value
                      ? AppColors.primary
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  color: slideCount == value
                      ? Colors.white
                      : AppColors.textTitle,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Slider(
          min: 4,
          max: 30,
          divisions: 26,
          value: slideCount.toDouble().clamp(4.0, 30.0).toDouble(),
          label: '$slideCount',
          onChanged: generating
              ? null
              : (double value) => onChanged(value.round()),
        ),
        Text(
          'The final slide count can vary slightly when multiple AI batches are combined and duplicate title slides are removed.',
          style: AppTextStyles.mutedSmall.copyWith(height: 1.4),
        ),
      ],
    );
  }
}

class _PresentationStepBadge extends StatelessWidget {
  final int number;

  const _PresentationStepBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PresentationCountPill extends StatelessWidget {
  final String label;

  const _PresentationCountPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.mutedSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PresentationSectionChip extends StatelessWidget {
  final PresentationTargetSection section;
  final bool isSubtopic;

  const _PresentationSectionChip({
    required this.section,
    required this.isSubtopic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isSubtopic
                ? Icons.subdirectory_arrow_right_rounded
                : Icons.topic_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              section.topicTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.mutedSmall.copyWith(
                color: AppColors.textTitle,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${section.pageStart}–${section.pageEnd}',
            style: AppTextStyles.mutedSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresentationStatusStrip extends StatelessWidget {
  final String status;
  final String? error;
  final bool active;
  final int batchIndex;
  final int batchCount;

  const _PresentationStatusStrip({
    required this.status,
    required this.error,
    required this.active,
    required this.batchIndex,
    required this.batchCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.trim().isNotEmpty;
    final background = hasError
        ? AppColors.dangerBg
        : active
            ? AppColors.infoBg
            : AppColors.successBg;
    final border = hasError
        ? AppColors.dangerBorder
        : active
            ? AppColors.infoBorder
            : AppColors.greenBorder;
    final foreground = hasError
        ? AppColors.dangerText
        : active
            ? AppColors.infoText
            : AppColors.successText;
    final progress = active && batchCount > 0
        ? (batchIndex / batchCount).clamp(0.0, 1.0).toDouble()
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              if (active)
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                Icon(
                  hasError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: foreground,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasError ? error! : status,
                  style: AppTextStyles.mutedSmall.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (active && batchCount > 1 && batchIndex > 0)
                Text(
                  '$batchIndex/$batchCount',
                  style: AppTextStyles.mutedSmall.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          if (progress != null && batchCount > 1) ...<Widget>[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: foreground.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresentationInlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PresentationInlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.dangerText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.mutedSmall.copyWith(
                color: AppColors.dangerText,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reload'),
          ),
        ],
      ),
    );
  }
}

class _PresentationLoadingBlock extends StatelessWidget {
  const _PresentationLoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _PresentationWorkspaceEmptyPreview extends StatelessWidget {
  final bool loading;
  final bool generating;
  final String? error;
  final String status;
  final int batchIndex;
  final int batchCount;

  const _PresentationWorkspaceEmptyPreview({
    required this.loading,
    required this.generating,
    required this.error,
    required this.status,
    required this.batchIndex,
    required this.batchCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.trim().isNotEmpty;
    final active = loading || generating;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 540),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: hasError ? AppColors.dangerBg : AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: active
                    ? Padding(
                        padding: const EdgeInsets.all(26),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        hasError
                            ? Icons.error_outline_rounded
                            : Icons.co_present_rounded,
                        color: hasError
                            ? AppColors.dangerText
                            : AppColors.primary,
                        size: 36,
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                generating
                    ? batchCount > 1
                        ? 'Building batch $batchIndex of $batchCount'
                        : 'Building your presentation'
                    : hasError
                        ? 'Presentation generation stopped'
                        : 'Your presentation will appear here',
                textAlign: TextAlign.center,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: 520,
                child: Text(
                  hasError
                      ? error!
                      : active
                          ? status
                          : 'The generated slides will open here with editing, duplicate, delete, navigation and editable PowerPoint download controls.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.muted,
                ),
              ),
              if (generating && batchCount > 1) ...<Widget>[
                const SizedBox(height: 20),
                SizedBox(
                  width: 320,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: batchCount == 0
                          ? null
                          : (batchIndex / batchCount)
                              .clamp(0.0, 1.0)
                              .toDouble(),
                      minHeight: 7,
                      backgroundColor: AppColors.primarySoft,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
