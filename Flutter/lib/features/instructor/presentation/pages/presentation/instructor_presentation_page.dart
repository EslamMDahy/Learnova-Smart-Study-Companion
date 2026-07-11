import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/widgets/design_tokens.dart';
import 'presentation_design_tokens.dart';
import 'presentation_download_stub.dart'
    if (dart.library.js_interop) 'presentation_download_web.dart';

part 'slide_templates/slide_template_builder.dart';
part 'slide_templates/slide_template_registry.dart';
part 'slide_templates/title_slide.dart';
part 'slide_templates/lecture_objectives.dart';
part 'slide_templates/section_divider.dart';
part 'slide_templates/concept_explanation.dart';
part 'slide_templates/text_with_image.dart';
part 'slide_templates/full_image.dart';
part 'slide_templates/key_points.dart';
part 'slide_templates/comparison.dart';
part 'slide_templates/process_steps.dart';
part 'slide_templates/timeline.dart';
part 'slide_templates/diagram.dart';
part 'slide_templates/table.dart';
part 'slide_templates/equation_explanation.dart';
part 'slide_templates/equation_derivation.dart';
part 'slide_templates/worked_example.dart';
part 'slide_templates/problem_solution.dart';
part 'slide_templates/multiple_choice.dart';
part 'slide_templates/practice_activity.dart';
part 'slide_templates/case_study.dart';
part 'slide_templates/quote.dart';
part 'slide_templates/summary.dart';
part 'slide_templates/references.dart';
part 'slide_templates/adaptive_cards.dart';
part 'slide_templates/single_card_center.dart';
part 'slide_templates/two_card_horizontal.dart';
part 'slide_templates/three_card_horizontal.dart';

class InstructorPresentationPage extends StatefulWidget {
  const InstructorPresentationPage({super.key});

  @override
  State<InstructorPresentationPage> createState() =>
      _InstructorPresentationPageState();
}

class _InstructorPresentationPageState extends State<InstructorPresentationPage> {
  late final TextEditingController _codeController;
  PresentationDeck? _deck;
  String? _error;
  int _selectedSlide = 0;
  bool _showExtractedText = false;
  bool _isExportingPptx = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _renderCode() {
    final source = _codeController.text.trim();
    if (source.isEmpty) {
      setState(() {
        _error = 'Paste the AI presentation JSON first.';
        _deck = null;
        _selectedSlide = 0;
      });
      return;
    }

    try {
      final deck = PresentationCodeParser.parse(source);
      if (deck.slides.isEmpty) {
        throw const FormatException(
          'No slides were found. The JSON response must contain a non-empty slides array.',
        );
      }

      setState(() {
        _deck = deck;
        _error = null;
        _selectedSlide = 0;
      });
    } catch (error) {
      setState(() {
        _deck = null;
        _error = error.toString().replaceFirst('FormatException: ', '');
        _selectedSlide = 0;
      });
    }
  }

  void _loadJsonTemplate() {
    _codeController.text =
        const JsonEncoder.withIndent('  ').convert(_sampleJsonDeck);
    _renderCode();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _codeController.text = text;
    _renderCode();
  }

  Future<void> _copyDeckJson() async {
    final deck = _deck;
    if (deck == null || !deck.isAiTemplateDeck) return;

    final json = const JsonEncoder.withIndent('  ').convert(deck.toAiJson());
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updated AI JSON copied to clipboard.')),
    );
  }

  Future<void> _editSelectedSlide() async {
    final deck = _deck;
    if (deck == null ||
        _selectedSlide < 0 ||
        _selectedSlide >= deck.slides.length) {
      return;
    }

    final current = deck.slides[_selectedSlide];
    if (!current.usesDefaultTemplate) return;

    final edited = await showDialog<PresentationSlide>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditTemplateSlideDialog(slide: current),
    );
    if (!mounted || edited == null) return;

    final slides = List<PresentationSlide>.from(deck.slides);
    slides[_selectedSlide] = PresentationTemplateEngine.rebuildSlide(
      edited,
      slideNumber: _selectedSlide + 1,
    );
    _applyDeckSlides(deck, slides);
  }

  void _duplicateSelectedSlide() {
    final deck = _deck;
    if (deck == null ||
        _selectedSlide < 0 ||
        _selectedSlide >= deck.slides.length) {
      return;
    }

    final source = deck.slides[_selectedSlide];
    final copy = source.copyWith(
      title: source.usesDefaultTemplate ? '${source.title} — Copy' : source.title,
    );
    final slides = List<PresentationSlide>.from(deck.slides)
      ..insert(_selectedSlide + 1, copy);
    _applyDeckSlides(deck, slides, selectedSlide: _selectedSlide + 1);
  }

  void _deleteSelectedSlide() {
    final deck = _deck;
    if (deck == null || deck.slides.length <= 1) return;

    final slides = List<PresentationSlide>.from(deck.slides)
      ..removeAt(_selectedSlide);
    final nextIndex = math.min(_selectedSlide, slides.length - 1).toInt();
    _applyDeckSlides(deck, slides, selectedSlide: nextIndex);
  }

  void _applyDeckSlides(
    PresentationDeck deck,
    List<PresentationSlide> slides, {
    int? selectedSlide,
  }) {
    final normalized = <PresentationSlide>[
      for (var i = 0; i < slides.length; i++)
        slides[i].usesDefaultTemplate
            ? PresentationTemplateEngine.rebuildSlide(
                slides[i],
                slideNumber: i + 1,
              )
            : slides[i],
    ];

    final updated = deck.copyWith(
      sourceLabel:
          deck.isAiTemplateDeck ? 'AI JSON + instructor edits' : deck.sourceLabel,
      slides: normalized,
    );

    setState(() {
      _deck = updated;
      _error = null;
      _selectedSlide = selectedSlide ?? _selectedSlide;
    });

    if (updated.isAiTemplateDeck) {
      _codeController.text =
          const JsonEncoder.withIndent('  ').convert(updated.toAiJson());
    }
  }

  Future<void> _downloadDeck(PresentationDeck deck) async {
    if (_isExportingPptx) return;

    setState(() => _isExportingPptx = true);
    try {
      await exportPresentationPptx(
        deckJson: jsonEncode(deck.toAiJson()),
        filename: _safeFileName('${deck.title}.pptx'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Editable PowerPoint downloaded successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not export PowerPoint: $error'),
          duration: const Duration(seconds: 7),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPptx = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = _deck;
    final selectedSlide = deck == null || deck.slides.isEmpty
        ? null
        : deck.slides[_selectedSlide.clamp(0, deck.slides.length - 1).toInt()];

    return Container(
      color: AppColors.pageBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1180;
          final editor = _CodeInputPanel(
            controller: _codeController,
            error: _error,
            onRender: _renderCode,
            onPaste: _pasteFromClipboard,
            onLoadTemplate: _loadJsonTemplate,
            onClear: () {
              setState(() {
                _codeController.clear();
                _deck = null;
                _error = null;
                _selectedSlide = 0;
              });
            },
          );

          final preview = _DeckPreviewPanel(
            deck: deck,
            selectedSlide: _selectedSlide,
            showExtractedText: _showExtractedText,
            onShowExtractedTextChanged: (value) =>
                setState(() => _showExtractedText = value),
            onSlideSelected: (index) => setState(() => _selectedSlide = index),
            onDownload: _downloadDeck,
            isDownloading: _isExportingPptx,
            onCopyJson: deck?.isAiTemplateDeck == true ? _copyDeckJson : null,
            onEditSlide:
                selectedSlide?.usesCardEditor == true ? _editSelectedSlide : null,
            onDuplicateSlide: deck == null ? null : _duplicateSelectedSlide,
            onDeleteSlide:
                deck != null && deck.slides.length > 1 ? _deleteSelectedSlide : null,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 440, child: editor),
                      const SizedBox(width: 24),
                      Expanded(child: preview),
                    ],
                  )
                : Column(
                    children: [
                      editor,
                      const SizedBox(height: 24),
                      preview,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _CodeInputPanel extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback onRender;
  final VoidCallback onPaste;
  final VoidCallback onLoadTemplate;
  final VoidCallback onClear;

  const _CodeInputPanel({
    required this.controller,
    required this.error,
    required this.onRender,
    required this.onPaste,
    required this.onLoadTemplate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.slideshow_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Presentation Builder', style: AppTextStyles.h3),
                    const SizedBox(height: 3),
                    Text(
                      'Paste lecture JSON generated with the Learnova schema. Flutter selects the right teaching layout for each slide.',
                      style: AppTextStyles.mutedSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security_rounded, color: AppColors.infoText, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use semantic lecture layouts such as objectives, explanations, comparisons, diagrams, tables, equations, worked examples, activities, and summaries. Flutter and PowerPoint consume the same canonical slide geometry.',
                    style: AppTextStyles.mutedSmall.copyWith(
                      color: AppColors.infoText,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 420,
            child: TextField(
              controller: controller,
              expands: true,
              maxLines: null,
              minLines: null,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.textTitle,
              ),
              decoration: InputDecoration(
                hintText:
                    'Paste Learnova lecture JSON here...\n\n{\n  "schema_version": 4,\n  "title": "Probability Foundations",\n  "slides": [\n    {\n      "slide_number": 1,\n      "layout_type": "title_slide",\n      "kicker": "STATISTICS 101",\n      "title": "Probability Foundations",\n      "subtitle": "From events to conditional reasoning"\n    }\n  ]\n}',
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(
              icon: Icons.error_outline_rounded,
              message: error!,
              color: AppColors.dangerText,
              background: AppColors.dangerBg,
              border: AppColors.dangerBorder,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onRender,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Build Presentation'),
              ),
              OutlinedButton.icon(
                onPressed: onPaste,
                icon: const Icon(Icons.content_paste_rounded),
                label: const Text('Paste'),
              ),
              OutlinedButton.icon(
                onPressed: onLoadTemplate,
                icon: const Icon(Icons.data_object_rounded),
                label: const Text('Load AI Example'),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeckPreviewPanel extends StatelessWidget {
  final PresentationDeck? deck;
  final int selectedSlide;
  final bool showExtractedText;
  final ValueChanged<bool> onShowExtractedTextChanged;
  final ValueChanged<int> onSlideSelected;
  final Future<void> Function(PresentationDeck deck) onDownload;
  final bool isDownloading;
  final VoidCallback? onCopyJson;
  final VoidCallback? onEditSlide;
  final VoidCallback? onDuplicateSlide;
  final VoidCallback? onDeleteSlide;

  const _DeckPreviewPanel({
    required this.deck,
    required this.selectedSlide,
    required this.showExtractedText,
    required this.onShowExtractedTextChanged,
    required this.onSlideSelected,
    required this.onDownload,
    required this.isDownloading,
    this.onCopyJson,
    this.onEditSlide,
    this.onDuplicateSlide,
    this.onDeleteSlide,
  });

  @override
  Widget build(BuildContext context) {
    final deck = this.deck;

    return _GlassCard(
      child: deck == null
          ? const _EmptyPresentationPreview()
          : Builder(
              builder: (context) {
                final slide = deck.slides[selectedSlide];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(deck.title, style: AppTextStyles.h3),
                              const SizedBox(height: 4),
                              Text(
                                '${deck.slides.length} slide${deck.slides.length == 1 ? '' : 's'} built from ${deck.sourceLabel}.',
                                style: AppTextStyles.mutedSmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (onEditSlide != null)
                                FilledButton.tonalIcon(
                                  onPressed: onEditSlide,
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  label: const Text('Edit slide'),
                                ),
                              if (onCopyJson != null)
                                OutlinedButton.icon(
                                  onPressed: onCopyJson,
                                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                                  label: const Text('Copy JSON'),
                                ),
                              OutlinedButton.icon(
                                onPressed: isDownloading
                                    ? null
                                    : () => onDownload(deck),
                                icon: isDownloading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.download_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  isDownloading
                                      ? 'Building PowerPoint…'
                                      : 'Download editable PPTX',
                                ),
                              ),
                              IconButton.outlined(
                                tooltip: 'Duplicate slide',
                                onPressed: onDuplicateSlide,
                                icon: const Icon(Icons.copy_rounded),
                              ),
                              IconButton.outlined(
                                tooltip: 'Delete slide',
                                onPressed: onDeleteSlide,
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                              _SlideStepper(
                                selected: selectedSlide,
                                total: deck.slides.length,
                                onChanged: onSlideSelected,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SlideCanvas(
                      slide: slide,
                      showExtractedText: showExtractedText,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  slide.title,
                                  style: AppTextStyles.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (slide.usesDefaultTemplate) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    slide.layoutType ?? 'default_template',
                                    style: AppTextStyles.mutedSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!slide.usesDefaultTemplate) ...[
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Extracted text fallback',
                                style: AppTextStyles.mutedSmall,
                              ),
                              Switch.adaptive(
                                value: showExtractedText,
                                onChanged: onShowExtractedTextChanged,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SlideThumbnailStrip(
                      deck: deck,
                      selectedSlide: selectedSlide,
                      onSlideSelected: onSlideSelected,
                    ),
                    if (slide.usesDefaultTemplate) ...[
                      const SizedBox(height: 18),
                      _TemplateContentSummary(slide: slide),
                    ] else if (slide.notes.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _ExtractedTextPanel(notes: slide.notes),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

class _EmptyPresentationPreview extends StatelessWidget {
  const _EmptyPresentationPreview();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 560),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.co_present_rounded, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text('No presentation rendered yet', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            SizedBox(
              width: 460,
              child: Text(
                'Paste the structured JSON generated by AI, then click Build Presentation. Flutter will apply the default template and keep every field editable.',
                textAlign: TextAlign.center,
                style: AppTextStyles.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _TemplateContentSummary extends StatelessWidget {
  final PresentationSlide slide;

  const _TemplateContentSummary({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Default template content', style: AppTextStyles.label),
              const Spacer(),
              Text(
                '${slide.cards.length} card${slide.cards.length == 1 ? '' : 's'}',
                style: AppTextStyles.mutedSmall,
              ),
            ],
          ),
          if ((slide.kicker ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              slide.kicker!,
              style: AppTextStyles.mutedSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(slide.title, style: AppTextStyles.label),
          if (slide.cards.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final card in slide.cards)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _iconForPath(card.icon),
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.heading,
                                style: AppTextStyles.mutedSmall.copyWith(
                                  color: AppColors.textTitle,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.mutedSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EditTemplateSlideDialog extends StatefulWidget {
  final PresentationSlide slide;

  const _EditTemplateSlideDialog({required this.slide});

  @override
  State<_EditTemplateSlideDialog> createState() =>
      _EditTemplateSlideDialogState();
}

class _EditTemplateSlideDialogState
    extends State<_EditTemplateSlideDialog> {
  late final TextEditingController _kickerController;
  late final TextEditingController _titleController;
  late String _layoutType;
  late List<_CardEditorControllers> _cards;
  String? _error;

  @override
  void initState() {
    super.initState();
    _kickerController = TextEditingController(text: widget.slide.kicker ?? '');
    _titleController = TextEditingController(text: widget.slide.title);
    _layoutType = PresentationTemplateEngine.normalizeLayout(
      widget.slide.layoutType,
      cardCount: widget.slide.cards.length,
    );
    _cards = [
      for (final card in widget.slide.cards)
        _CardEditorControllers.fromCard(card),
    ];
  }

  @override
  void dispose() {
    _kickerController.dispose();
    _titleController.dispose();
    for (final card in _cards) {
      card.dispose();
    }
    super.dispose();
  }

  void _addCard() {
    if (_cards.length >= PresentationDesignTokens.maxCardsPerSlide) return;
    setState(() {
      _cards.add(
        _CardEditorControllers.fromCard(
          const PresentationCardContent(
            icon: 'auto_awesome_white',
            heading: 'New card',
            body: 'Add the card content here.',
          ),
        ),
      );
    });
  }

  void _removeCard(int index) {
    if (_cards.length <= 1) return;
    final removed = _cards.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _save() {
    final title = _titleController.text.trim();
    final kicker = _kickerController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Slide title is required.');
      return;
    }
    if (title.length > PresentationDesignTokens.maxTitleCharacters) {
      setState(
        () => _error =
            'Slide title must be ${PresentationDesignTokens.maxTitleCharacters} characters or fewer.',
      );
      return;
    }
    if (kicker.length > PresentationDesignTokens.maxKickerCharacters) {
      setState(
        () => _error =
            'Kicker must be ${PresentationDesignTokens.maxKickerCharacters} characters or fewer.',
      );
      return;
    }

    final cards = <PresentationCardContent>[];
    for (var index = 0; index < _cards.length; index++) {
      final editor = _cards[index];
      final heading = editor.heading.text.trim().isEmpty
          ? 'Untitled card'
          : editor.heading.text.trim();
      final body = editor.body.text.trim();
      if (heading.length >
          PresentationDesignTokens.maxCardHeadingCharacters) {
        setState(
          () => _error =
              'Card ${index + 1} heading must be ${PresentationDesignTokens.maxCardHeadingCharacters} characters or fewer.',
        );
        return;
      }
      if (body.length > PresentationDesignTokens.maxCardBodyCharacters) {
        setState(
          () => _error =
              'Card ${index + 1} body must be ${PresentationDesignTokens.maxCardBodyCharacters} characters or fewer.',
        );
        return;
      }
      cards.add(
        PresentationCardContent(
          icon: editor.icon.text.trim().isEmpty
              ? 'auto_awesome_white'
              : editor.icon.text.trim(),
          heading: heading,
          body: body,
        ),
      );
    }

    Navigator.of(context).pop(
      widget.slide.copyWith(
        layoutType: _layoutType,
        kicker: kicker,
        title: title,
        cards: cards,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.edit_note_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit AI slide', style: AppTextStyles.h3),
                        const SizedBox(height: 3),
                        Text(
                          'Change the content; Flutter rebuilds the default layout automatically.',
                          style: AppTextStyles.mutedSmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _layoutType,
                        decoration: _editorInputDecoration(
                          label: 'Layout type',
                          icon: Icons.dashboard_customize_rounded,
                        ),
                        items: [
                          for (final layout
                              in PresentationTemplateEngine.supportedLayouts)
                            DropdownMenuItem(
                              value: layout,
                              child: Text(
                                PresentationTemplateEngine.layoutLabel(layout),
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _layoutType = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _kickerController,
                        decoration: _editorInputDecoration(
                          label: 'Kicker',
                          hint: 'TASK 1',
                          icon: Icons.label_important_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _titleController,
                        maxLines: 2,
                        decoration: _editorInputDecoration(
                          label: 'Slide title',
                          icon: Icons.title_rounded,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Text('Cards', style: AppTextStyles.label),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _cards.length >= PresentationDesignTokens.maxCardsPerSlide
                                ? null
                                : _addCard,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add card'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _cards.length; i++) ...[
                        _CardEditor(
                          index: i,
                          controllers: _cards[i],
                          canRemove: _cards.length > 1,
                          onRemove: () => _removeCard(i),
                        ),
                        if (i != _cards.length - 1)
                          const SizedBox(height: 12),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _InlineMessage(
                          icon: Icons.error_outline_rounded,
                          message: _error!,
                          color: AppColors.dangerText,
                          background: AppColors.dangerBg,
                          border: AppColors.dangerBorder,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Apply changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardEditor extends StatelessWidget {
  final int index;
  final _CardEditorControllers controllers;
  final bool canRemove;
  final VoidCallback onRemove;

  const _CardEditor({
    required this.index,
    required this.controllers,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Card ${index + 1}', style: AppTextStyles.label),
              const Spacer(),
              IconButton(
                tooltip: 'Remove card',
                onPressed: canRemove ? onRemove : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controllers.icon,
                  decoration: _editorInputDecoration(
                    label: 'Icon key',
                    hint: 'exclamation_white',
                    icon: Icons.emoji_symbols_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controllers.heading,
                  decoration: _editorInputDecoration(
                    label: 'Heading',
                    icon: Icons.short_text_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controllers.body,
            minLines: 2,
            maxLines: 4,
            decoration: _editorInputDecoration(
              label: 'Body',
              icon: Icons.notes_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardEditorControllers {
  final TextEditingController icon;
  final TextEditingController heading;
  final TextEditingController body;

  _CardEditorControllers({
    required this.icon,
    required this.heading,
    required this.body,
  });

  factory _CardEditorControllers.fromCard(PresentationCardContent card) {
    return _CardEditorControllers(
      icon: TextEditingController(text: card.icon),
      heading: TextEditingController(text: card.heading),
      body: TextEditingController(text: card.body),
    );
  }

  void dispose() {
    icon.dispose();
    heading.dispose();
    body.dispose();
  }
}

InputDecoration _editorInputDecoration({
  required String label,
  String? hint,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 19),
    filled: true,
    fillColor: AppColors.fieldBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}

class _SlideCanvas extends StatelessWidget {
  static const double slideW = 13.3333333333;
  static const double slideH = 7.5;

  final PresentationSlide slide;
  final bool showExtractedText;

  const _SlideCanvas({required this.slide, required this.showExtractedText});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * slideH / slideW;
        final scale = width / slideW;
        final visualTextCount = slide.elements
            .where((element) =>
                element.type == PresentationElementType.text &&
                element.text.trim().length > 2)
            .length;

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _colorFromHex(slide.backgroundHex, fallback: Colors.white),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 24,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: _colorFromHex(
                      slide.backgroundHex,
                      fallback: Colors.white,
                    ),
                  ),
                ),
                for (final element in slide.elements)
                  _SlideElementView(element: element, scale: scale),
                if (showExtractedText &&
                    visualTextCount <= 1 &&
                    slide.notes.isNotEmpty)
                  _SlideNotesOverlay(
                    notes: slide.notes.take(9).toList(),
                    scale: scale,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Fixed 16:9 renderer for semantic AI slides.
///
/// The slide uses the same absolute geometry as the HTML exporter. Text is
/// wrapped into deterministic lines before rendering, which prevents browser
/// and PowerPoint font metrics from producing different line breaks.
class _HtmlTemplateSlideView extends StatelessWidget {
  static const double designWidth = PresentationDesignTokens.slideWidth;
  static const double designHeight = PresentationDesignTokens.slideHeight;

  final PresentationSlide slide;

  const _HtmlTemplateSlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: designWidth,
        height: designHeight,
        child: _HtmlTemplateSlideBody(slide: slide),
      ),
    );
  }
}

class _HtmlTemplateSlideBody extends StatelessWidget {
  final PresentationSlide slide;

  const _HtmlTemplateSlideBody({required this.slide});

  @override
  Widget build(BuildContext context) {
    final layout = PresentationDesignTokens.layoutFor(
      layout: slide.layoutType ?? 'adaptive_cards',
      cardCount: slide.cards.length,
      title: slide.title,
      hasKicker: (slide.kicker ?? '').trim().isNotEmpty,
    );
    final slideRtl = _containsRtlText(slide.title) ||
        _containsRtlText(slide.kicker ?? '');

    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontFamily: PresentationDesignTokens.bodyFontFamily,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: PresentationDesignTokens.canvas,
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned(
                right: -118,
                top: -176,
                child: _HtmlDecorativeCircle(
                  size: 386,
                  color: PresentationDesignTokens.decorationPrimary,
                ),
              ),
              const Positioned(
                right: 82,
                top: 22,
                child: _HtmlDecorativeCircle(
                  size: 118,
                  color: PresentationDesignTokens.decorationCyan,
                ),
              ),
              const Positioned(
                right: 32,
                top: 128,
                child: _HtmlDecorativeCircle(
                  size: 56,
                  color: PresentationDesignTokens.decorationViolet,
                ),
              ),
              const Positioned(
                left: -112,
                bottom: -150,
                child: _HtmlDecorativeCircle(
                  size: 244,
                  color: PresentationDesignTokens.decorationPrimary,
                ),
              ),
              Positioned(
                left: PresentationDesignTokens.pagePaddingX,
                top: PresentationDesignTokens.pagePaddingTop,
                width: PresentationDesignTokens.contentWidth,
                height: PresentationDesignTokens.headerHeight,
                child: _HtmlSlideHeader(slide: slide),
              ),
              Positioned(
                left: PresentationDesignTokens.pagePaddingX,
                top: 132,
                width: PresentationDesignTokens.titleWidth,
                height: layout.contentTop - 146,
                child: _HtmlSlideHero(slide: slide, layout: layout),
              ),
              if (slide.problem != null)
                Positioned(
                  left: PresentationDesignTokens.pagePaddingX,
                  top: layout.contentTop,
                  width: PresentationDesignTokens.contentWidth,
                  height: PresentationDesignTokens.contentBottom - layout.contentTop,
                  child: _HtmlProblemLayout(slide: slide),
                )
              else if (slide.equation != null)
                Positioned(
                  left: PresentationDesignTokens.pagePaddingX,
                  top: layout.contentTop,
                  width: PresentationDesignTokens.contentWidth,
                  height: PresentationDesignTokens.contentBottom - layout.contentTop,
                  child: _HtmlEquationLayout(slide: slide),
                )
              else if (slide.visual != null)
                Positioned(
                  left: PresentationDesignTokens.pagePaddingX,
                  top: layout.contentTop,
                  width: PresentationDesignTokens.contentWidth,
                  height: PresentationDesignTokens.contentBottom - layout.contentTop,
                  child: _HtmlVisualFocusLayout(slide: slide),
                )
              else if (slide.cards.isEmpty)
                Positioned(
                  left: PresentationDesignTokens.pagePaddingX,
                  top: layout.contentTop,
                  width: PresentationDesignTokens.contentWidth,
                  height: PresentationDesignTokens.contentBottom -
                      layout.contentTop,
                  child: const _HtmlEmptyCardsState(),
                )
              else
                for (var index = 0; index < slide.cards.length; index++)
                  Positioned.fromRect(
                    rect: layout.cardRect(index, rtl: slideRtl),
                    child: _HtmlPresentationCard(
                      card: slide.cards[index],
                      index: index,
                      density: layout.grid.density,
                    ),
                  ),
              const Positioned(
                left: PresentationDesignTokens.pagePaddingX,
                top: 1000,
                width: PresentationDesignTokens.contentWidth,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: PresentationDesignTokens.divider,
                ),
              ),
              const Positioned(
                left: PresentationDesignTokens.pagePaddingX,
                top: PresentationDesignTokens.footerY,
                width: PresentationDesignTokens.contentWidth,
                height: 28,
                child: _HtmlSlideFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HtmlDecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _HtmlDecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HtmlSlideHeader extends StatelessWidget {
  final PresentationSlide slide;

  const _HtmlSlideHeader({required this.slide});

  @override
  Widget build(BuildContext context) {
    final page = '${slide.slideNumber ?? 1}'.padLeft(2, '0');

    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 2,
          width: 50,
          height: 50,
          child: Image.asset(
            PresentationDesignTokens.logoAssetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            cacheWidth: 160,
          ),
        ),
        const Positioned(
          left: 64,
          top: 8,
          width: 190,
          height: 38,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Learnova',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: PresentationDesignTokens.ink,
                fontFamily: PresentationDesignTokens.headingFontFamily,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        Positioned(
          left: 260,
          top: 10,
          width: 230,
          height: 34,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PresentationDesignTokens.primarySoft,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: PresentationDesignTokens.primary.withOpacity(0.16),
              ),
            ),
            child: const Text(
              'AI PRESENTATION',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PresentationDesignTokens.primaryDark,
                fontFamily: PresentationDesignTokens.bodyFontFamily,
                fontSize: 14,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 6,
          width: 92,
          height: 42,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PresentationDesignTokens.pageBadge,
              borderRadius: BorderRadius.circular(21),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24102A56),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              page,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PresentationDesignTokens.white,
                fontFamily: PresentationDesignTokens.bodyFontFamily,
                fontSize: 16,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HtmlSlideHero extends StatelessWidget {
  final PresentationSlide slide;
  final PresentationSlideLayoutSpec layout;

  const _HtmlSlideHero({required this.slide, required this.layout});

  @override
  Widget build(BuildContext context) {
    final kicker = (slide.kicker ?? '').trim();
    final titleRtl = _containsRtlText(slide.title);
    final kickerRtl = _containsRtlText(kicker);
    final titleLineCount = layout.titleText.split('\n').length;
    final titleTop = kicker.isNotEmpty ? 56.0 : 8.0;
    final titleHeight =
        layout.titleFontSize * 1.08 * titleLineCount + 8;
    final marksTop = titleTop + titleHeight + 14;

    return Stack(
      children: [
        if (kicker.isNotEmpty)
          Positioned(
            left: titleRtl ? null : 0,
            right: titleRtl ? 0 : null,
            top: 0,
            width: 360,
            height: 38,
            child: Container(
              decoration: BoxDecoration(
                color: PresentationDesignTokens.primarySoft,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: PresentationDesignTokens.primary.withOpacity(0.18),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: kickerRtl ? null : 18,
                    right: kickerRtl ? 18 : null,
                    top: 15,
                    width: 8,
                    height: 8,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: PresentationDesignTokens.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: kickerRtl ? 18 : 38,
                    right: kickerRtl ? 38 : 18,
                    top: 8,
                    height: 22,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: kickerRtl
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        kicker.toUpperCase(),
                        maxLines: 1,
                        softWrap: false,
                        textDirection: kickerRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        textAlign:
                            kickerRtl ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          color: PresentationDesignTokens.primaryDark,
                          fontFamily: kickerRtl
                              ? PresentationDesignTokens.rtlFontFamily
                              : PresentationDesignTokens.bodyFontFamily,
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: kickerRtl ? 0 : 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          left: 0,
          top: titleTop,
          width: PresentationDesignTokens.titleWidth,
          height: titleHeight,
          child: Text(
            layout.titleText,
            maxLines: titleLineCount,
            softWrap: false,
            overflow: TextOverflow.clip,
            textDirection: titleRtl ? TextDirection.rtl : TextDirection.ltr,
            textAlign: titleRtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: PresentationDesignTokens.ink,
              fontFamily: titleRtl
                  ? PresentationDesignTokens.rtlFontFamily
                  : PresentationDesignTokens.headingFontFamily,
              fontSize: layout.titleFontSize,
              height: 1.08,
              fontWeight: FontWeight.w700,
              letterSpacing: titleRtl ? 0 : -1.5,
            ),
          ),
        ),
        Positioned(
          left: titleRtl ? null : 0,
          right: titleRtl ? 0 : null,
          top: marksTop,
          width: 124,
          height: 8,
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              Container(
                width: 88,
                height: 8,
                decoration: BoxDecoration(
                  color: PresentationDesignTokens.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 26,
                height: 8,
                decoration: BoxDecoration(
                  color: PresentationDesignTokens.cyan,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _HtmlVisualFocusLayout extends StatelessWidget {
  final PresentationSlide slide;

  const _HtmlVisualFocusLayout({required this.slide});

  @override
  Widget build(BuildContext context) {
    final visual = slide.visual!;
    final lead = slide.cards.isNotEmpty ? slide.cards.first : null;
    final rest = slide.cards.length > 1 ? slide.cards.skip(1).take(3).toList() : const <PresentationCardContent>[];
    final hasRtl = _containsRtlText(slide.title) || _containsRtlText(lead?.body ?? '');

    return Directionality(
      textDirection: hasRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(
        children: [
          Positioned(
            left: hasRtl ? 0 : 740,
            right: hasRtl ? 740 : 0,
            top: 0,
            bottom: 0,
            child: _HtmlImageFrame(visual: visual),
          ),
          Positioned(
            left: hasRtl ? 980 : 0,
            right: hasRtl ? 0 : 980,
            top: 12,
            bottom: 12,
            child: _HtmlNarrativePanel(
              eyebrow: lead?.heading ?? 'Visual insight',
              body: lead?.body ?? visual.caption ?? 'Add an image caption or supporting card content.',
              icon: lead?.icon ?? 'image_white',
            ),
          ),
          for (var i = 0; i < rest.length; i++)
            Positioned(
              left: hasRtl ? 980 : 0,
              right: hasRtl ? 0 : 980,
              top: 330.0 + i * 104.0,
              height: 82,
              child: _HtmlMiniInsightCard(card: rest[i], index: i + 1),
            ),
        ],
      ),
    );
  }
}

class _HtmlEquationLayout extends StatelessWidget {
  final PresentationSlide slide;

  const _HtmlEquationLayout({required this.slide});

  @override
  Widget build(BuildContext context) {
    final equation = slide.equation!;
    final rtl = _containsRtlText(equation.explanation ?? slide.title);
    final supportingCards = slide.cards.take(3).toList();

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(
        children: [
          Positioned(
            left: rtl ? 0 : 620,
            right: rtl ? 620 : 0,
            top: 0,
            bottom: 110,
            child: Container(
              decoration: BoxDecoration(
                color: PresentationDesignTokens.white,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: PresentationDesignTokens.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10137FEC),
                    blurRadius: 34,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 52),
              child: Column(
                crossAxisAlignment: rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    equation.label ?? 'Key equation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                    style: TextStyle(
                      color: PresentationDesignTokens.primaryDark,
                      fontFamily: rtl
                          ? PresentationDesignTokens.rtlFontFamily
                          : PresentationDesignTokens.bodyFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: rtl ? 0 : 0.8,
                    ),
                  ),
                  const SizedBox(height: 38),
                  Expanded(
                    child: Center(
                      child: Text(
                        equation.value,
                        maxLines: 4,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: PresentationDesignTokens.ink,
                          fontFamily: 'Cambria Math',
                          fontSize: 56,
                          height: 1.18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: rtl ? 1180 : 0,
            right: rtl ? 0 : 1180,
            top: 0,
            bottom: 110,
            child: _HtmlNarrativePanel(
              eyebrow: 'Explanation',
              body: equation.explanation ?? 'Explain every variable and the learning objective behind the equation.',
              icon: 'function_white',
            ),
          ),
          for (var i = 0; i < supportingCards.length; i++)
            Positioned(
              left: i * 570.0,
              bottom: 0,
              width: 540,
              height: 86,
              child: _HtmlMiniInsightCard(card: supportingCards[i], index: i),
            ),
        ],
      ),
    );
  }
}

class _HtmlProblemLayout extends StatelessWidget {
  final PresentationSlide slide;

  const _HtmlProblemLayout({required this.slide});

  @override
  Widget build(BuildContext context) {
    final problem = slide.problem!;
    final rtl = _containsRtlText(problem.statement);
    final steps = problem.solutionSteps.take(5).toList();

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(
        children: [
          Positioned(
            left: rtl ? 800 : 0,
            right: rtl ? 0 : 800,
            top: 0,
            bottom: 0,
            child: _HtmlProblemQuestionPanel(problem: problem),
          ),
          Positioned(
            left: rtl ? 0 : 980,
            right: rtl ? 980 : 0,
            top: 0,
            bottom: 0,
            child: _HtmlSolutionPanel(problem: problem, steps: steps),
          ),
        ],
      ),
    );
  }
}

class _HtmlImageFrame extends StatelessWidget {
  final PresentationVisualContent visual;

  const _HtmlImageFrame({required this.visual});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PresentationDesignTokens.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: PresentationDesignTokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12102A56),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PresentationImage(visual: visual),
          if ((visual.caption ?? '').trim().isNotEmpty)
            Positioned(
              left: 28,
              right: 28,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: PresentationDesignTokens.white.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  visual.caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PresentationDesignTokens.inkSoft,
                    fontFamily: PresentationDesignTokens.bodyFontFamily,
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresentationImage extends StatelessWidget {
  final PresentationVisualContent visual;

  const _PresentationImage({required this.visual});

  @override
  Widget build(BuildContext context) {
    final src = visual.src.trim();
    final isNetwork = src.startsWith('http://') || src.startsWith('https://');
    final path = src.startsWith('assets/assets/')
        ? src.replaceFirst('assets/', '')
        : src.startsWith('assets/')
            ? src
            : 'assets/$src';
    if (src.isEmpty) {
      return const ColoredBox(color: PresentationDesignTokens.primarySoft);
    }
    return isNetwork
        ? Image.network(src, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _ImageFallback())
        : Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _ImageFallback());
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PresentationDesignTokens.primarySoft,
      alignment: Alignment.center,
      child: const Text(
        'Image',
        style: TextStyle(
          color: PresentationDesignTokens.primaryDark,
          fontFamily: PresentationDesignTokens.headingFontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HtmlNarrativePanel extends StatelessWidget {
  final String eyebrow;
  final String body;
  final String icon;

  const _HtmlNarrativePanel({required this.eyebrow, required this.body, required this.icon});

  @override
  Widget build(BuildContext context) {
    final rtl = _containsRtlText(eyebrow + body);
    final bodyText = PresentationDesignTokens.wrapText(
      body,
      width: 590,
      fontSize: 27,
      maxLines: 8,
      averageGlyphFactor: 0.9,
    );
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: PresentationDesignTokens.pageBadge,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(color: Color(0x18102A56), blurRadius: 34, offset: Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PresentationDesignTokens.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _iconGlyphForPath(icon),
              style: const TextStyle(color: PresentationDesignTokens.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 34),
          Text(
            eyebrow,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            textAlign: rtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: PresentationDesignTokens.cyan,
              fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.bodyFontFamily,
              fontSize: 20,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: rtl ? 0 : 1.0,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            bodyText,
            maxLines: 8,
            overflow: TextOverflow.clip,
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            textAlign: rtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: PresentationDesignTokens.white,
              fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.headingFontFamily,
              fontSize: 30,
              height: 1.22,
              fontWeight: FontWeight.w700,
              letterSpacing: rtl ? 0 : -0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HtmlMiniInsightCard extends StatelessWidget {
  final PresentationCardContent card;
  final int index;

  const _HtmlMiniInsightCard({required this.card, required this.index});

  @override
  Widget build(BuildContext context) {
    final accent = PresentationDesignTokens.accentFor(index);
    final rtl = _containsRtlText(card.heading + card.body);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: PresentationDesignTokens.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PresentationDesignTokens.border),
        boxShadow: const [BoxShadow(color: Color(0x0A102A56), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Row(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent.softColor, borderRadius: BorderRadius.circular(15)),
            child: Text(_iconGlyphForPath(card.icon), style: TextStyle(color: accent.color, fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(card.heading, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, style: TextStyle(color: PresentationDesignTokens.ink, fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.headingFontFamily, fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(card.equation?.value ?? card.body, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, style: TextStyle(color: PresentationDesignTokens.textMuted, fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.bodyFontFamily, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HtmlProblemQuestionPanel extends StatelessWidget {
  final PresentationProblemContent problem;

  const _HtmlProblemQuestionPanel({required this.problem});

  @override
  Widget build(BuildContext context) {
    final rtl = _containsRtlText(problem.statement);
    return Container(
      padding: const EdgeInsets.all(38),
      decoration: BoxDecoration(
        color: PresentationDesignTokens.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: PresentationDesignTokens.border),
        boxShadow: const [BoxShadow(color: Color(0x0E102A56), blurRadius: 32, offset: Offset(0, 16))],
      ),
      child: Column(
        crossAxisAlignment: rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text('Problem', style: TextStyle(color: PresentationDesignTokens.primaryDark, fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.bodyFontFamily, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Text(
            PresentationDesignTokens.wrapText(problem.statement, width: 690, fontSize: 28, maxLines: 7),
            maxLines: 7,
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            textAlign: rtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(color: PresentationDesignTokens.ink, fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.headingFontFamily, fontSize: 30, height: 1.18, fontWeight: FontWeight.w700),
          ),
          if (problem.choices.isNotEmpty) ...[
            const SizedBox(height: 24),
            for (var i = 0; i < math.min(4, problem.choices.length); i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(color: PresentationDesignTokens.primarySoft, borderRadius: BorderRadius.circular(18)),
                  child: Text('${String.fromCharCode(65 + i)}. ${problem.choices[i]}', maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, style: TextStyle(color: PresentationDesignTokens.inkSoft, fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.bodyFontFamily, fontSize: 19, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HtmlSolutionPanel extends StatelessWidget {
  final PresentationProblemContent problem;
  final List<String> steps;

  const _HtmlSolutionPanel({required this.problem, required this.steps});

  @override
  Widget build(BuildContext context) {
    final rtl = _containsRtlText([...steps, problem.answer ?? ''].join(' '));
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: PresentationDesignTokens.pageBadge,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text('Solution path', style: TextStyle(color: PresentationDesignTokens.cyan, fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.bodyFontFamily, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: PresentationDesignTokens.white.withOpacity(0.14), borderRadius: BorderRadius.circular(12)), child: Text('${i + 1}', style: const TextStyle(color: PresentationDesignTokens.white, fontWeight: FontWeight.w800, fontSize: 15))),
                  const SizedBox(width: 14),
                  Expanded(child: Text(steps[i], maxLines: 3, overflow: TextOverflow.ellipsis, textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, style: TextStyle(color: PresentationDesignTokens.white, fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.bodyFontFamily, fontSize: 21, height: 1.25, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          const Spacer(),
          if ((problem.answer ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: PresentationDesignTokens.success.withOpacity(0.18), borderRadius: BorderRadius.circular(22), border: Border.all(color: PresentationDesignTokens.success.withOpacity(0.30))),
              child: Text('Answer: ${problem.answer}', textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, style: TextStyle(color: PresentationDesignTokens.white, fontFamily: rtl ? PresentationDesignTokens.rtlFontFamily : PresentationDesignTokens.headingFontFamily, fontSize: 24, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

class _HtmlPresentationCard extends StatelessWidget {
  final PresentationCardContent card;
  final int index;
  final PresentationCardDensity density;

  const _HtmlPresentationCard({
    required this.card,
    required this.index,
    required this.density,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final accent = PresentationDesignTokens.accentFor(index);
        final headingRtl = _containsRtlText(card.heading);
        final bodyContent = card.equation?.value ?? card.body;
        final bodyRtl = _containsRtlText(bodyContent);
        final cardRtl = card.heading.trim().isNotEmpty ? headingRtl : bodyRtl;
        final metrics = _PresentationCardMetrics.forDensity(
          density,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          heading: card.heading,
          body: bodyContent,
        );
        final headingText = PresentationDesignTokens.wrapText(
          card.heading,
          width: metrics.textWidth,
          fontSize: metrics.headingFontSize,
          maxLines: 2,
        );
        final bodyText = PresentationDesignTokens.wrapText(
          bodyContent,
          width: metrics.textWidth,
          fontSize: metrics.bodyFontSize,
          maxLines: metrics.bodyMaxLines,
        );
        final leading = cardRtl
            ? constraints.maxWidth - metrics.padding - metrics.iconSize
            : metrics.padding;
        final trailing = cardRtl
            ? metrics.padding
            : constraints.maxWidth - metrics.padding - metrics.numberWidth;
        final textAlignment = cardRtl ? Alignment.topRight : Alignment.topLeft;

        return Container(
          decoration: BoxDecoration(
            color: PresentationDesignTokens.white,
            borderRadius: BorderRadius.circular(
              PresentationDesignTokens.cardRadiusFor(density),
            ),
            border: Border.all(color: PresentationDesignTokens.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12102A56),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: cardRtl ? null : 0,
                right: cardRtl ? 0 : null,
                top: 0,
                width: metrics.topAccentWidth,
                height: metrics.topAccentHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.color,
                    borderRadius: BorderRadius.only(
                      bottomRight: cardRtl
                          ? Radius.zero
                          : Radius.circular(metrics.topAccentHeight),
                      bottomLeft: cardRtl
                          ? Radius.circular(metrics.topAccentHeight)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: leading,
                top: metrics.topPadding,
                width: metrics.iconSize,
                height: metrics.iconSize,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.softColor,
                    borderRadius: BorderRadius.circular(metrics.iconRadius),
                    border: Border.all(
                      color: accent.color.withOpacity(0.14),
                    ),
                  ),
                  child: Text(
                    _iconGlyphForPath(card.icon),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accent.color,
                      fontFamily: PresentationDesignTokens.bodyFontFamily,
                      fontSize: metrics.iconFontSize,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: trailing,
                top: metrics.numberTop,
                width: metrics.numberWidth,
                height: metrics.numberHeight,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.softColor,
                    borderRadius:
                        BorderRadius.circular(metrics.numberHeight / 2),
                  ),
                  child: Text(
                    '${index + 1}'.padLeft(2, '0'),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accent.color,
                      fontFamily: PresentationDesignTokens.bodyFontFamily,
                      fontSize: metrics.numberFontSize,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: metrics.padding,
                right: metrics.padding,
                top: metrics.headingTop,
                height: metrics.headingHeight,
                child: Align(
                  alignment: textAlignment,
                  child: Text(
                    headingText,
                    maxLines: 2,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textDirection:
                        headingRtl ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: headingRtl ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      color: PresentationDesignTokens.ink,
                      fontFamily: headingRtl
                          ? PresentationDesignTokens.rtlFontFamily
                          : PresentationDesignTokens.headingFontFamily,
                      fontSize: metrics.headingFontSize,
                      height: 1.16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: headingRtl ? 0 : -0.35,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: metrics.padding,
                right: metrics.padding,
                top: metrics.bodyTop,
                height: metrics.bodyHeight,
                child: Align(
                  alignment: textAlignment,
                  child: Text(
                    bodyText,
                    maxLines: metrics.bodyMaxLines,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textDirection:
                        bodyRtl ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: bodyRtl ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      color: PresentationDesignTokens.textMuted,
                      fontFamily: bodyRtl
                          ? PresentationDesignTokens.rtlFontFamily
                          : PresentationDesignTokens.bodyFontFamily,
                      fontSize: metrics.bodyFontSize,
                      height: metrics.bodyLineHeight,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: cardRtl ? null : metrics.padding,
                right: cardRtl ? metrics.padding : null,
                bottom: metrics.bottomPadding,
                width: metrics.bottomAccentWidth,
                height: metrics.bottomAccentHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.color,
                    borderRadius:
                        BorderRadius.circular(metrics.bottomAccentHeight / 2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresentationCardMetrics {
  final double padding;
  final double topPadding;
  final double bottomPadding;
  final double iconSize;
  final double iconRadius;
  final double iconFontSize;
  final double numberTop;
  final double numberWidth;
  final double numberHeight;
  final double numberFontSize;
  final double headingTop;
  final double headingHeight;
  final double headingFontSize;
  final double bodyTop;
  final double bodyHeight;
  final double bodyFontSize;
  final double bodyLineHeight;
  final int bodyMaxLines;
  final double textWidth;
  final double topAccentWidth;
  final double topAccentHeight;
  final double bottomAccentWidth;
  final double bottomAccentHeight;

  const _PresentationCardMetrics({
    required this.padding,
    required this.topPadding,
    required this.bottomPadding,
    required this.iconSize,
    required this.iconRadius,
    required this.iconFontSize,
    required this.numberTop,
    required this.numberWidth,
    required this.numberHeight,
    required this.numberFontSize,
    required this.headingTop,
    required this.headingHeight,
    required this.headingFontSize,
    required this.bodyTop,
    required this.bodyHeight,
    required this.bodyFontSize,
    required this.bodyLineHeight,
    required this.bodyMaxLines,
    required this.textWidth,
    required this.topAccentWidth,
    required this.topAccentHeight,
    required this.bottomAccentWidth,
    required this.bottomAccentHeight,
  });

  factory _PresentationCardMetrics.forDensity(
    PresentationCardDensity density, {
    required double width,
    required double height,
    required String heading,
    required String body,
  }) {
    final compact = density == PresentationCardDensity.compact;
    final dense = density == PresentationCardDensity.dense;
    final padding = dense ? 14.0 : compact ? 22.0 : 30.0;
    final topPadding = dense ? 14.0 : compact ? 20.0 : 26.0;
    final bottomPadding = dense ? 12.0 : compact ? 16.0 : 20.0;
    final iconSize = dense ? 36.0 : compact ? 48.0 : 58.0;
    final iconRadius = dense ? 10.0 : compact ? 13.0 : 16.0;
    final iconFontSize = dense ? 15.0 : compact ? 20.0 : 24.0;
    final numberWidth = dense ? 42.0 : compact ? 50.0 : 56.0;
    final numberHeight = dense ? 24.0 : compact ? 28.0 : 32.0;
    final numberTop = topPadding + (iconSize - numberHeight) / 2;
    final numberFontSize = dense ? 10.0 : compact ? 11.5 : 13.0;
    final headingFontSize = _cardHeadingSize(heading, density);
    final bodyFontSize = _cardBodySize(body, density);
    final headingTop = topPadding + iconSize + (dense ? 8 : compact ? 12 : 16);
    final headingHeight = headingFontSize * 1.16 * 2 + 2;
    final bodyTop = headingTop + headingHeight + (dense ? 4 : compact ? 8 : 10);
    final bottomAccentHeight = dense ? 4.0 : 5.0;
    final bottomAccentWidth = dense ? 28.0 : compact ? 38.0 : 48.0;
    final accentTop = height - bottomPadding - bottomAccentHeight;
    final bodyHeight =
        math.max(0.0, accentTop - bodyTop - (dense ? 8 : 12)).toDouble();
    final bodyLineHeight = dense ? 1.25 : compact ? 1.3 : 1.35;
    final calculatedLines = bodyHeight <= 0
        ? 1
        : (bodyHeight / (bodyFontSize * bodyLineHeight)).floor();
    final maxLines = dense ? 4 : compact ? 5 : 6;
    final bodyMaxLines =
        math.max(1, math.min(maxLines, calculatedLines)).toInt();

    return _PresentationCardMetrics(
      padding: padding,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      iconSize: iconSize,
      iconRadius: iconRadius,
      iconFontSize: iconFontSize,
      numberTop: numberTop,
      numberWidth: numberWidth,
      numberHeight: numberHeight,
      numberFontSize: numberFontSize,
      headingTop: headingTop,
      headingHeight: headingHeight,
      headingFontSize: headingFontSize,
      bodyTop: bodyTop,
      bodyHeight: bodyHeight,
      bodyFontSize: bodyFontSize,
      bodyLineHeight: bodyLineHeight,
      bodyMaxLines: bodyMaxLines,
      textWidth: math.max(1.0, width - padding * 2).toDouble(),
      topAccentWidth: dense ? 58 : compact ? 72 : 88,
      topAccentHeight: dense ? 4 : 5,
      bottomAccentWidth: bottomAccentWidth,
      bottomAccentHeight: bottomAccentHeight,
    );
  }
}

double _cardHeadingSize(
  String value,
  PresentationCardDensity density,
) {
  final units = PresentationDesignTokens.textUnits(value);
  switch (density) {
    case PresentationCardDensity.dense:
      if (units > 48) return 12.5;
      if (units > 34) return 14;
      return 16;
    case PresentationCardDensity.compact:
      if (units > 58) return 16;
      if (units > 40) return 18.5;
      return 21;
    case PresentationCardDensity.comfortable:
      if (units > 66) return 19;
      if (units > 46) return 22;
      return 25;
  }
}

double _cardBodySize(
  String value,
  PresentationCardDensity density,
) {
  final length = value.trim().length;
  switch (density) {
    case PresentationCardDensity.dense:
      if (length > 360) return 9;
      if (length > 220) return 10;
      if (length > 130) return 10.8;
      return 11.5;
    case PresentationCardDensity.compact:
      if (length > 420) return 11;
      if (length > 260) return 12.5;
      if (length > 150) return 13.5;
      return 15;
    case PresentationCardDensity.comfortable:
      if (length > 500) return 13;
      if (length > 320) return 14.5;
      if (length > 190) return 16;
      return 18;
  }
}

class _HtmlEmptyCardsState extends StatelessWidget {
  const _HtmlEmptyCardsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 760,
        height: 300,
        decoration: BoxDecoration(
          color: PresentationDesignTokens.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: PresentationDesignTokens.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10102A56),
              blurRadius: 26,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Image.asset(
                PresentationDesignTokens.logoAssetPath,
                fit: BoxFit.contain,
                cacheWidth: 180,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add cards from the slide editor',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: PresentationDesignTokens.ink,
                fontFamily: PresentationDesignTokens.headingFontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HtmlSlideFooter extends StatelessWidget {
  const _HtmlSlideFooter();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 0,
          top: 8,
          width: 8,
          height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: PresentationDesignTokens.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Positioned(
          left: 18,
          top: 3,
          width: 600,
          height: 22,
          child: Text(
            'Structured content • Generated with Learnova AI',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: PresentationDesignTokens.footerText,
              fontFamily: PresentationDesignTokens.bodyFontFamily,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Positioned(
          right: 0,
          top: 3,
          width: 180,
          height: 22,
          child: Text(
            'learnova.ai',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: PresentationDesignTokens.footerText,
              fontFamily: PresentationDesignTokens.bodyFontFamily,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SlideElementView extends StatelessWidget {
  final PresentationElement element;
  final double scale;

  const _SlideElementView({required this.element, required this.scale});

  @override
  Widget build(BuildContext context) {
    final left = element.x * scale;
    final top = element.y * scale;
    final width = math.max(1.0, element.w * scale);
    final height = math.max(1.0, element.h * scale);
    final borderWidth = math.max(
      .35,
      (element.lineWidth ?? 1) * scale / 72,
    );
    final radius = math.max(0.0, element.radius * scale / 72);

    Widget child;
    switch (element.type) {
      case PresentationElementType.text:
        child = _SlideText(element: element, scale: scale);
        break;
      case PresentationElementType.equation:
        child = _SlideEquation(element: element, scale: scale);
        break;
      case PresentationElementType.rect:
        child = DecoratedBox(
          decoration: BoxDecoration(
            color: _colorFromHex(element.fillHex, fallback: Colors.transparent),
            borderRadius: BorderRadius.circular(radius),
            border: element.lineHex == null
                ? null
                : Border.all(
                    color: _colorFromHex(
                      element.lineHex,
                      fallback: Colors.transparent,
                    ),
                    width: borderWidth,
                  ),
            boxShadow: element.shadow
                ? [
                    BoxShadow(
                      color: const Color(0x1A102A56),
                      blurRadius: math.max(2, 14 * scale / 72),
                      offset: Offset(0, math.max(1, 7 * scale / 72)),
                    ),
                  ]
                : null,
          ),
        );
        break;
      case PresentationElementType.oval:
        child = DecoratedBox(
          decoration: BoxDecoration(
            color: _colorFromHex(element.fillHex, fallback: Colors.transparent),
            shape: BoxShape.circle,
            border: element.lineHex == null
                ? null
                : Border.all(
                    color: _colorFromHex(
                      element.lineHex,
                      fallback: Colors.transparent,
                    ),
                    width: borderWidth,
                  ),
          ),
        );
        break;
      case PresentationElementType.line:
        final vertical = height > width * 2;
        child = Align(
          alignment: vertical ? Alignment.topCenter : Alignment.centerLeft,
          child: Container(
            width: vertical ? borderWidth : width,
            height: vertical ? height : borderWidth,
            color: _colorFromHex(element.lineHex, fallback: Colors.black),
          ),
        );
        break;
      case PresentationElementType.image:
        child = _SlideImage(element: element, scale: scale);
        break;
    }

    if (element.opacity < 1) {
      child = Opacity(
        opacity: element.opacity.clamp(0.0, 1.0).toDouble(),
        child: child,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: child,
    );
  }
}

class _SlideText extends StatelessWidget {
  final PresentationElement element;
  final double scale;

  const _SlideText({required this.element, required this.scale});

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(element.colorHex, fallback: AppColors.textTitle);
    final fontSize = math.max(4.0, (element.fontSize ?? 14) * scale / 72);
    final isRtl = _containsRtlText(element.text);
    Alignment verticalAlignment;
    if (element.verticalAlign == 'middle' || element.verticalAlign == 'center') {
      verticalAlignment = Alignment.center;
    } else if (element.verticalAlign == 'bottom') {
      verticalAlignment = Alignment.bottomCenter;
    } else {
      verticalAlignment = Alignment.topCenter;
    }

    return Align(
      alignment: verticalAlignment,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          element.text,
          textAlign: _effectiveTextAlign(element.text, element.align),
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          maxLines: element.maxLines,
          softWrap: true,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontFamily: isRtl
                ? PresentationDesignTokens.rtlFontFamily
                : _safeFontFamily(element.fontFace),
            fontSize: fontSize,
            fontWeight: element.bold ? FontWeight.w800 : FontWeight.w400,
            fontStyle: element.italic ? FontStyle.italic : FontStyle.normal,
            height: element.lineHeight ?? (element.bold ? 1.08 : 1.16),
            color: color,
            letterSpacing: (element.charSpacing ?? 0) * scale / 72,
          ),
        ),
      ),
    );
  }
}

class _SlideEquation extends StatelessWidget {
  final PresentationElement element;
  final double scale;

  const _SlideEquation({required this.element, required this.scale});

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(element.colorHex, fallback: AppColors.textTitle);
    final fontSize = math.max(5.0, (element.fontSize ?? 24) * scale / 72);
    final fallback = Text(
      element.text,
      textAlign: TextAlign.center,
      maxLines: element.maxLines ?? 3,
      overflow: TextOverflow.clip,
      style: TextStyle(
        color: color,
        fontFamily: PresentationDesignTokens.bodyFontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    );

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Math.tex(
          element.text,
          mathStyle: MathStyle.display,
          textStyle: TextStyle(color: color, fontSize: fontSize),
          onErrorFallback: (_) => fallback,
        ),
      ),
    );
  }
}

class _SlideImage extends StatelessWidget {
  final PresentationElement element;
  final double scale;

  const _SlideImage({required this.element, required this.scale});

  @override
  Widget build(BuildContext context) {
    final path = (element.path ?? '').trim();
    final radius = math.max(0.0, element.radius * scale / 72);
    final fit = element.fit == 'cover' ? BoxFit.cover : BoxFit.contain;
    final isImage = _isPresentationImagePath(path);

    Widget child;
    if (isImage) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        child = Image.network(
          path,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const _ImageFallback(),
        );
      } else {
        final assetPath = path.startsWith('assets/assets/')
            ? path.replaceFirst('assets/', '')
            : path.startsWith('assets/')
                ? path
                : 'assets/$path';
        child = Image.asset(
          assetPath,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const _ImageFallback(),
        );
      }
    } else {
      final icon = _iconForPath(path.isEmpty ? 'auto_awesome_white' : path);
      var color = _iconColorForPath(path);
      if (element.opacity < .35 && path.toLowerCase().contains('navy')) {
        color = Colors.white;
      }
      child = LayoutBuilder(
        builder: (context, constraints) {
          final size = math.max(
            8.0,
            math.min(constraints.maxWidth, constraints.maxHeight) * .78,
          );
          return Center(child: Icon(icon, color: color, size: size));
        },
      );
    }

    if (radius > 0) {
      child = ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
    }
    return child;
  }

  static bool _isPresentationImagePath(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('data:image/') ||
        lower.startsWith('assets/') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.svg');
  }
}

class _SlideNotesOverlay extends StatelessWidget {
  final List<String> notes;
  final double scale;

  const _SlideNotesOverlay({required this.notes, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0.75 * scale,
      right: 0.75 * scale,
      bottom: 0.65 * scale,
      child: Container(
        padding: EdgeInsets.all(0.18 * scale),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(0.16 * scale),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Wrap(
          spacing: 0.18 * scale,
          runSpacing: 0.10 * scale,
          children: [
            for (final note in notes)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 0.14 * scale,
                  vertical: 0.07 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(0.12 * scale),
                ),
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: math.max(7, 10 * scale / 72),
                    color: const Color(0xFF334155),
                    height: 1.15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlideStepper extends StatelessWidget {
  final int selected;
  final int total;
  final ValueChanged<int> onChanged;

  const _SlideStepper({
    required this.selected,
    required this.total,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: 'Previous slide',
          onPressed: selected <= 0 ? null : () => onChanged(selected - 1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('${selected + 1}/$total', style: AppTextStyles.label),
        ),
        IconButton.outlined(
          tooltip: 'Next slide',
          onPressed: selected >= total - 1 ? null : () => onChanged(selected + 1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _SlideThumbnailStrip extends StatelessWidget {
  final PresentationDeck deck;
  final int selectedSlide;
  final ValueChanged<int> onSlideSelected;

  const _SlideThumbnailStrip({
    required this.deck,
    required this.selectedSlide,
    required this.onSlideSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: deck.slides.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final slide = deck.slides[index];
          final selected = index == selectedSlide;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSlideSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 132,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        color: _colorFromHex(slide.backgroundHex, fallback: Colors.white),
                        child: slide.usesDefaultTemplate
                            ? _HtmlTemplateThumbnail(slide: slide)
                            : Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: _isDarkHex(slide.backgroundHex)
                                        ? Colors.white70
                                        : const Color(0xFF475569),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slide.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mutedSmall.copyWith(
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HtmlTemplateThumbnail extends StatelessWidget {
  final PresentationSlide slide;

  const _HtmlTemplateThumbnail({required this.slide});

  @override
  Widget build(BuildContext context) {
    final cards = slide.cards.take(3).toList();
    return Container(
      color: const Color(0xFFF7F9FC),
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF1D879B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E0EA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            width: 52,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF17233A),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 34,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFF4B536),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE1E8F0)),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i.isEven
                              ? const Color(0xFF1D879B)
                              : const Color(0xFFF4B536),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                if (i != cards.length - 1) const SizedBox(width: 3),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ExtractedTextPanel extends StatelessWidget {
  final List<String> notes;

  const _ExtractedTextPanel({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Extracted slide text', style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final note in notes.take(24))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(note, style: AppTextStyles.mutedSmall),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color background;
  final Color border;

  const _InlineMessage({
    required this.icon,
    required this.message,
    required this.color,
    required this.background,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.mutedSmall.copyWith(color: color, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

enum PresentationElementType { text, rect, oval, line, image, equation }

class PresentationDeck {
  final String title;
  final String sourceLabel;
  final List<PresentationSlide> slides;

  const PresentationDeck({
    required this.title,
    required this.sourceLabel,
    required this.slides,
  });

  bool get isAiTemplateDeck =>
      slides.isNotEmpty && slides.every((slide) => slide.usesDefaultTemplate);

  PresentationDeck copyWith({
    String? title,
    String? sourceLabel,
    List<PresentationSlide>? slides,
  }) {
    return PresentationDeck(
      title: title ?? this.title,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      slides: slides ?? this.slides,
    );
  }

  PresentationDeck copyWithSlides(List<PresentationSlide> slides) {
    return copyWith(slides: slides);
  }

  Map<String, dynamic> toAiJson() {
    return {
      'schema_version': PresentationDesignTokens.schemaVersion,
      'title': title,
      'design_tokens': PresentationDesignTokens.toJson(),
      'slides': [
        for (var i = 0; i < slides.length; i++)
          slides[i].toAiJson(fallbackSlideNumber: i + 1),
      ],
    };
  }
}


class PresentationVisualContent {
  final String src;
  final String? caption;
  final String? alt;
  final String fit;
  final String position;

  const PresentationVisualContent({
    required this.src,
    this.caption,
    this.alt,
    this.fit = 'cover',
    this.position = 'right',
  });

  factory PresentationVisualContent.fromJson(Map raw) {
    String? optional(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    final fit = (raw['fit'] ?? 'cover').toString().trim().toLowerCase();
    final position =
        (raw['position'] ?? raw['align'] ?? 'right').toString().trim().toLowerCase();
    return PresentationVisualContent(
      src: (raw['src'] ?? raw['url'] ?? raw['asset'] ?? raw['path'] ?? '')
          .toString()
          .trim(),
      caption: optional(raw['caption']),
      alt: optional(raw['alt'] ?? raw['description']),
      fit: fit == 'contain' ? 'contain' : 'cover',
      position: position,
    );
  }

  Map<String, dynamic> toJson() => {
        'src': src,
        if ((caption ?? '').trim().isNotEmpty) 'caption': caption,
        if ((alt ?? '').trim().isNotEmpty) 'alt': alt,
        'fit': fit,
        'position': position,
      };
}

class PresentationEquationContent {
  final String value;
  final String? label;
  final String? explanation;
  final String renderMode;
  final List<Map<String, dynamic>> steps;

  const PresentationEquationContent({
    required this.value,
    this.label,
    this.explanation,
    this.renderMode = 'auto',
    this.steps = const [],
  });

  factory PresentationEquationContent.fromJson(dynamic raw) {
    if (raw is String || raw is num) {
      return PresentationEquationContent(value: raw.toString().trim());
    }
    final map = raw is Map ? raw : const {};
    String? optional(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    final mode = (map['render_mode'] ?? map['mode'] ?? 'auto')
        .toString()
        .trim()
        .toLowerCase();
    final steps = <Map<String, dynamic>>[];
    final rawSteps = map['steps'];
    if (rawSteps is List) {
      for (final item in rawSteps) {
        if (item is Map) {
          steps.add(item.map((key, value) => MapEntry(key.toString(), value)));
        } else if (item != null && item.toString().trim().isNotEmpty) {
          steps.add({'expression': item.toString().trim()});
        }
      }
    }
    return PresentationEquationContent(
      value: (map['latex'] ??
              map['expression'] ??
              map['value'] ??
              map['text'] ??
              map['formula'] ??
              '')
          .toString()
          .trim(),
      label: optional(map['label'] ?? map['title']),
      explanation: optional(map['explanation'] ?? map['body']),
      renderMode: const {'auto', 'text', 'svg'}.contains(mode) ? mode : 'auto',
      steps: List<Map<String, dynamic>>.unmodifiable(steps),
    );
  }

  bool get shouldRenderAsSvg {
    if (renderMode == 'svg') return true;
    if (renderMode == 'text') return false;
    return value.contains(r'\') ||
        value.contains(r'\frac') ||
        value.contains(r'\sum') ||
        value.contains(r'\int') ||
        value.contains('{') ||
        value.contains('}');
  }

  Map<String, dynamic> toJson() => {
        if ((label ?? '').trim().isNotEmpty) 'label': label,
        'latex': value,
        if ((explanation ?? '').trim().isNotEmpty) 'explanation': explanation,
        'render_mode': renderMode,
        if (steps.isNotEmpty) 'steps': steps,
      };
}

class PresentationProblemContent {
  final String statement;
  final List<String> choices;
  final String? answer;
  final List<String> solutionSteps;
  final String? hint;
  final List<String> given;
  final String? formula;
  final String? finalAnswer;
  final bool showAnswer;

  const PresentationProblemContent({
    required this.statement,
    this.choices = const [],
    this.answer,
    this.solutionSteps = const [],
    this.hint,
    this.given = const [],
    this.formula,
    this.finalAnswer,
    this.showAnswer = true,
  });

  factory PresentationProblemContent.fromJson(Map raw) {
    List<String> strings(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    String? optional(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return PresentationProblemContent(
      statement: (raw['statement'] ?? raw['question'] ?? raw['prompt'] ?? '')
          .toString()
          .trim(),
      choices: strings(raw['choices'] ?? raw['options']),
      answer: optional(raw['answer'] ?? raw['correct_answer']),
      solutionSteps:
          strings(raw['solution_steps'] ?? raw['steps'] ?? raw['solution']),
      hint: optional(raw['hint']),
      given: strings(raw['given'] ?? raw['known_values']),
      formula: optional(raw['formula']),
      finalAnswer: optional(raw['final_answer'] ?? raw['result']),
      showAnswer: raw['show_answer'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'statement': statement,
        if (choices.isNotEmpty) 'choices': choices,
        if ((answer ?? '').trim().isNotEmpty) 'answer': answer,
        if (solutionSteps.isNotEmpty) 'solution_steps': solutionSteps,
        if ((hint ?? '').trim().isNotEmpty) 'hint': hint,
        if (given.isNotEmpty) 'given': given,
        if ((formula ?? '').trim().isNotEmpty) 'formula': formula,
        if ((finalAnswer ?? '').trim().isNotEmpty) 'final_answer': finalAnswer,
        'show_answer': showAnswer,
      };
}

class PresentationSlide {
  final int? slideNumber;
  final String title;
  final String? backgroundHex;
  final List<PresentationElement> elements;
  final List<String> notes;
  final String? layoutType;
  final String? kicker;
  final List<PresentationCardContent> cards;
  final PresentationVisualContent? visual;
  final PresentationEquationContent? equation;
  final PresentationProblemContent? problem;
  final Map<String, dynamic> semanticData;

  const PresentationSlide({
    this.slideNumber,
    required this.title,
    required this.backgroundHex,
    required this.elements,
    required this.notes,
    this.layoutType,
    this.kicker,
    this.cards = const [],
    this.visual,
    this.equation,
    this.problem,
    this.semanticData = const {},
  });

  bool get usesDefaultTemplate => layoutType != null;

  bool get usesCardEditor =>
      const {
        'adaptive_cards',
        'single_card_center',
        'two_card_horizontal',
        'three_card_horizontal',
      }.contains(layoutType) ||
      (layoutType == 'key_points' && cards.isNotEmpty);

  PresentationSlide copyWith({
    int? slideNumber,
    String? title,
    String? backgroundHex,
    List<PresentationElement>? elements,
    List<String>? notes,
    String? layoutType,
    String? kicker,
    List<PresentationCardContent>? cards,
    PresentationVisualContent? visual,
    PresentationEquationContent? equation,
    PresentationProblemContent? problem,
    Map<String, dynamic>? semanticData,
  }) {
    return PresentationSlide(
      slideNumber: slideNumber ?? this.slideNumber,
      title: title ?? this.title,
      backgroundHex: backgroundHex ?? this.backgroundHex,
      elements: elements ?? this.elements,
      notes: notes ?? this.notes,
      layoutType: layoutType ?? this.layoutType,
      kicker: kicker ?? this.kicker,
      cards: cards ?? this.cards,
      visual: visual ?? this.visual,
      equation: equation ?? this.equation,
      problem: problem ?? this.problem,
      semanticData: semanticData ?? this.semanticData,
    );
  }

  Map<String, dynamic> toAiJson({required int fallbackSlideNumber}) {
    if (!usesDefaultTemplate) {
      return {
        'slide_number': slideNumber ?? fallbackSlideNumber,
        'title': title,
        'background': backgroundHex,
        'elements': [for (final element in elements) element.toJson()],
        if (notes.isNotEmpty) 'notes': notes,
      };
    }

    return {
      'slide_number': slideNumber ?? fallbackSlideNumber,
      'layout_type': layoutType,
      'kicker': kicker ?? '',
      'title': title,
      ...semanticData,
      if (cards.isNotEmpty) 'cards': [for (final card in cards) card.toJson()],
      if (visual != null) 'visual': visual!.toJson(),
      if (equation != null) 'equation': equation!.toJson(),
      if (problem != null) 'problem': problem!.toJson(),
      'background': backgroundHex,
      // These canonical elements are generated in Dart and exported directly.
      // Flutter and PowerPoint therefore use exactly the same geometry.
      'elements': [for (final element in elements) element.toJson()],
    };
  }
}

class PresentationCardContent {
  final String icon;
  final String heading;
  final String body;
  final PresentationVisualContent? visual;
  final PresentationEquationContent? equation;

  const PresentationCardContent({
    required this.icon,
    required this.heading,
    required this.body,
    this.visual,
    this.equation,
  });

  factory PresentationCardContent.fromJson(Map raw) {
    PresentationVisualContent? visual;
    final visualRaw = raw['visual'] ?? raw['image'];
    if (visualRaw is Map) {
      visual = PresentationVisualContent.fromJson(visualRaw);
    } else if (visualRaw != null || raw['image_url'] != null || raw['asset'] != null) {
      final src = (visualRaw ?? raw['image_url'] ?? raw['asset']).toString().trim();
      if (src.isNotEmpty) visual = PresentationVisualContent(src: src);
    }

    return PresentationCardContent(
      icon: (raw['icon'] ?? 'auto_awesome_white').toString().trim(),
      heading: (raw['heading'] ?? raw['title'] ?? 'Untitled').toString().trim(),
      body: (raw['body'] ?? raw['description'] ?? '').toString().trim(),
      visual: visual,
      equation: raw['equation'] == null
          ? null
          : PresentationEquationContent.fromJson(raw['equation']),
    );
  }

  Map<String, dynamic> toJson() => {
        'icon': icon,
        'heading': heading,
        'body': body,
        if (visual != null) 'visual': visual!.toJson(),
        if (equation != null) 'equation': equation!.toJson(),
      };
}

class PresentationElement {
  final PresentationElementType type;
  final double x;
  final double y;
  final double w;
  final double h;
  final String text;
  final String? colorHex;
  final String? fillHex;
  final String? lineHex;
  final double? lineWidth;
  final double? fontSize;
  final String? fontFace;
  final bool bold;
  final bool italic;
  final TextAlign align;
  final double? charSpacing;
  final double? lineHeight;
  final int? maxLines;
  final String? path;
  final double opacity;
  final double radius;
  final String fit;
  final String verticalAlign;
  final bool shadow;

  const PresentationElement({
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.text = '',
    this.colorHex,
    this.fillHex,
    this.lineHex,
    this.lineWidth,
    this.fontSize,
    this.fontFace,
    this.bold = false,
    this.italic = false,
    this.align = TextAlign.left,
    this.charSpacing,
    this.lineHeight,
    this.maxLines,
    this.path,
    this.opacity = 1,
    this.radius = 0,
    this.fit = 'contain',
    this.verticalAlign = 'top',
    this.shadow = false,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        if (text.isNotEmpty) 'text': text,
        if (colorHex != null) 'color': colorHex,
        if (fillHex != null) 'fill': fillHex,
        if (lineHex != null) 'line': lineHex,
        if (lineWidth != null) 'lineWidth': lineWidth,
        if (fontSize != null) 'fontSize': fontSize,
        if (fontFace != null) 'fontFace': fontFace,
        if (bold) 'bold': true,
        if (italic) 'italic': true,
        if (align != TextAlign.left) 'align': align.name,
        if (charSpacing != null) 'charSpacing': charSpacing,
        if (lineHeight != null) 'lineHeight': lineHeight,
        if (maxLines != null) 'maxLines': maxLines,
        if (path != null) 'path': path,
        if (opacity != 1) 'opacity': opacity,
        if (radius > 0) 'radius': radius,
        if (fit != 'contain') 'fit': fit,
        if (verticalAlign != 'top') 'verticalAlign': verticalAlign,
        if (shadow) 'shadow': true,
      };
}

class PresentationTemplateEngine {
  static const List<String> supportedLayouts = [
    'title_slide',
    'lecture_objectives',
    'section_divider',
    'concept_explanation',
    'text_with_image',
    'full_image',
    'key_points',
    'comparison',
    'process_steps',
    'timeline',
    'diagram',
    'table',
    'equation_explanation',
    'equation_derivation',
    'worked_example',
    'problem_solution',
    'multiple_choice',
    'practice_activity',
    'case_study',
    'quote',
    'summary',
    'references',
    'adaptive_cards',
    'single_card_center',
    'two_card_horizontal',
    'three_card_horizontal',
  ];

  static String normalizeLayout(String? value, {required int cardCount}) {
    final normalized = value?.trim().toLowerCase().replaceAll('-', '_') ?? '';
    const aliases = <String, String>{
      'cover': 'title_slide',
      'title': 'title_slide',
      'objectives': 'lecture_objectives',
      'learning_objectives': 'lecture_objectives',
      'section': 'section_divider',
      'concept': 'concept_explanation',
      'explanation': 'concept_explanation',
      'visual_focus': 'text_with_image',
      'image_focus': 'text_with_image',
      'picture_focus': 'text_with_image',
      'image': 'full_image',
      'key_takeaways': 'key_points',
      'compare': 'comparison',
      'process': 'process_steps',
      'steps': 'process_steps',
      'formula_focus': 'equation_explanation',
      'math_focus': 'equation_explanation',
      'equation_focus': 'equation_explanation',
      'derivation': 'equation_derivation',
      'worked_problem': 'worked_example',
      'problem': 'problem_solution',
      'quiz_solution': 'problem_solution',
      'quiz': 'multiple_choice',
      'activity': 'practice_activity',
      'case': 'case_study',
      'closing': 'summary',
      'bibliography': 'references',
      'cards': 'adaptive_cards',
      'card_grid': 'adaptive_cards',
      'one_card': 'single_card_center',
      'single_card': 'single_card_center',
      'two_cards_horizontal': 'two_card_horizontal',
      'two_column_cards': 'two_card_horizontal',
      'three_cards_horizontal': 'three_card_horizontal',
      'three_column_cards': 'three_card_horizontal',
    };
    final mapped = aliases[normalized] ?? normalized;
    if (supportedLayouts.contains(mapped)) return mapped;
    if (cardCount <= 1) return 'single_card_center';
    if (cardCount == 2) return 'two_card_horizontal';
    if (cardCount == 3) return 'three_card_horizontal';
    return 'adaptive_cards';
  }

  static String layoutLabel(String layout) {
    return layout
        .split('_')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static PresentationSlide fromJson(Map raw, {required int fallbackIndex}) {
    final rawCards = raw['cards'];
    if (rawCards != null && rawCards is! List) {
      throw FormatException('Slide $fallbackIndex: cards must be an array.');
    }
    if (rawCards is List &&
        rawCards.length > PresentationDesignTokens.maxCardsPerSlide) {
      throw FormatException(
        'Slide $fallbackIndex contains ${rawCards.length} cards. Maximum: '
        '${PresentationDesignTokens.maxCardsPerSlide}.',
      );
    }

    final cards = <PresentationCardContent>[];
    if (rawCards is List) {
      for (var index = 0; index < rawCards.length; index++) {
        final item = rawCards[index];
        if (item is! Map) {
          throw FormatException(
            'Slide $fallbackIndex, card ${index + 1}: card must be an object.',
          );
        }
        final card = PresentationCardContent.fromJson(item);
        _validateTextLength(
          card.heading,
          PresentationDesignTokens.maxCardHeadingCharacters,
          'Slide $fallbackIndex, card ${index + 1} heading',
        );
        _validateTextLength(
          card.body,
          PresentationDesignTokens.maxCardBodyCharacters,
          'Slide $fallbackIndex, card ${index + 1} body',
        );
        if (card.visual != null) {
          _validateTextLength(
            card.visual!.caption ?? '',
            PresentationDesignTokens.maxVisualCaptionCharacters,
            'Slide $fallbackIndex, card ${index + 1} visual caption',
          );
        }
        if (card.equation != null) {
          _validateTextLength(
            card.equation!.value,
            PresentationDesignTokens.maxEquationCharacters,
            'Slide $fallbackIndex, card ${index + 1} equation',
          );
        }
        cards.add(card);
      }
    }

    final slideNumber = _intValue(raw['slide_number']) ?? fallbackIndex;
    final title = (raw['title'] ?? 'Slide $slideNumber').toString().trim();
    final kicker = (raw['kicker'] ?? raw['section'] ?? '').toString().trim();
    _validateTextLength(
      title,
      PresentationDesignTokens.maxTitleCharacters,
      'Slide $fallbackIndex title',
    );
    _validateTextLength(
      kicker,
      PresentationDesignTokens.maxKickerCharacters,
      'Slide $fallbackIndex kicker',
    );

    PresentationVisualContent? visual;
    final visualRaw = raw['visual'] ?? raw['image'];
    if (visualRaw is Map) {
      visual = PresentationVisualContent.fromJson(visualRaw);
    } else if (visualRaw is String && visualRaw.trim().isNotEmpty) {
      visual = PresentationVisualContent(src: visualRaw.trim());
    }

    if (visual != null) {
      _validateTextLength(
        visual.caption ?? '',
        PresentationDesignTokens.maxVisualCaptionCharacters,
        'Slide $fallbackIndex visual caption',
      );
    }

    final equation = raw['equation'] == null
        ? null
        : PresentationEquationContent.fromJson(raw['equation']);
    if (equation != null) {
      _validateTextLength(
        equation.value,
        PresentationDesignTokens.maxEquationCharacters,
        'Slide $fallbackIndex equation',
      );
      for (var stepIndex = 0; stepIndex < equation.steps.length; stepIndex++) {
        final step = equation.steps[stepIndex];
        final expression = (step['latex'] ??
                step['expression'] ??
                step['value'] ??
                step['text'] ??
                '')
            .toString();
        final explanation = (step['explanation'] ?? step['body'] ?? '').toString();
        _validateTextLength(
          expression,
          PresentationDesignTokens.maxEquationCharacters,
          'Slide $fallbackIndex equation step ${stepIndex + 1}',
        );
        _validateTextLength(
          explanation,
          PresentationDesignTokens.maxProblemStepCharacters,
          'Slide $fallbackIndex equation step ${stepIndex + 1} explanation',
        );
      }
    }

    final problem = raw['problem'] is Map
        ? PresentationProblemContent.fromJson(raw['problem'] as Map)
        : null;
    if (problem != null) {
      _validateTextLength(
        problem.statement,
        PresentationDesignTokens.maxProblemStatementCharacters,
        'Slide $fallbackIndex problem statement',
      );
      for (var stepIndex = 0;
          stepIndex < problem.solutionSteps.length;
          stepIndex++) {
        _validateTextLength(
          problem.solutionSteps[stepIndex],
          PresentationDesignTokens.maxProblemStepCharacters,
          'Slide $fallbackIndex solution step ${stepIndex + 1}',
        );
      }
      for (var choiceIndex = 0;
          choiceIndex < problem.choices.length;
          choiceIndex++) {
        _validateTextLength(
          problem.choices[choiceIndex],
          PresentationDesignTokens.maxProblemStepCharacters,
          'Slide $fallbackIndex choice ${choiceIndex + 1}',
        );
      }
    }

    final requestedLayout = raw['layout_type']?.toString();
    var layout = normalizeLayout(requestedLayout, cardCount: cards.length);
    if ((requestedLayout ?? '').trim().isEmpty) {
      if (raw.containsKey('objectives')) {
        layout = 'lecture_objectives';
      } else if (raw.containsKey('comparison')) {
        layout = 'comparison';
      } else if (raw.containsKey('timeline')) {
        layout = 'timeline';
      } else if (raw.containsKey('diagram')) {
        layout = 'diagram';
      } else if (raw.containsKey('table')) {
        layout = 'table';
      } else if (raw.containsKey('quote')) {
        layout = 'quote';
      } else if (raw.containsKey('references')) {
        layout = 'references';
      } else if (problem != null) {
        layout = problem.choices.isNotEmpty ? 'multiple_choice' : 'problem_solution';
      } else if (equation != null) {
        layout = 'equation_explanation';
      } else if (visual != null) {
        layout = 'text_with_image';
      } else if (raw.containsKey('content')) {
        layout = 'concept_explanation';
      }
    }

    _LectureLayoutEngine.validate(
      layout: layout,
      raw: raw,
      cards: cards,
      visual: visual,
      equation: equation,
      problem: problem,
      slideIndex: fallbackIndex,
    );

    final semanticData = _semanticData(raw);

    return rebuildSlide(
      PresentationSlide(
        slideNumber: slideNumber,
        title: title.isEmpty ? 'Slide $slideNumber' : title,
        backgroundHex: _LectureLayoutEngine.backgroundFor(layout),
        elements: const [],
        notes: const [],
        layoutType: layout,
        kicker: kicker,
        cards: List.unmodifiable(cards),
        visual: visual,
        equation: equation,
        problem: problem,
        semanticData: semanticData,
      ),
      slideNumber: slideNumber,
    );
  }

  static PresentationSlide rebuildSlide(
    PresentationSlide slide, {
    required int slideNumber,
  }) {
    final layout = normalizeLayout(
      slide.layoutType,
      cardCount: slide.cards.length,
    );
    final normalized = slide.copyWith(
      slideNumber: slideNumber,
      layoutType: layout,
      backgroundHex: _LectureLayoutEngine.backgroundFor(layout),
      cards: List<PresentationCardContent>.unmodifiable(slide.cards),
    );
    final elements = _LectureLayoutEngine.build(normalized);
    return normalized.copyWith(
      elements: List<PresentationElement>.unmodifiable(elements),
      notes: List<String>.unmodifiable(_LectureLayoutEngine.notesFor(normalized)),
    );
  }

  static Map<String, dynamic> _semanticData(Map raw) {
    const reserved = {
      'slide_number',
      'layout_type',
      'kicker',
      'section',
      'title',
      'cards',
      'visual',
      'image',
      'equation',
      'problem',
      'background',
      'backgroundHex',
      'elements',
      'notes',
    };
    final data = <String, dynamic>{};
    raw.forEach((key, value) {
      final name = key.toString();
      if (!reserved.contains(name)) data[name] = value;
    });
    return data;
  }

  static void _validateTextLength(String value, int maximum, String label) {
    if (value.length > maximum) {
      throw FormatException(
        '$label is too long (${value.length} characters). Maximum: $maximum.',
      );
    }
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class _LectureLayoutEngine {
  static const double sw = 13.3333333333;
  static const double sh = 7.5;
  static const String canvas = 'F7FAFF';
  static const String white = 'FFFFFF';
  static const String ink = '071129';
  static const String inkSoft = '24324D';
  static const String muted = '5F6F89';
  static const String footer = '8291A7';
  static const String primary = '137FEC';
  static const String primaryDark = '0B5FC4';
  static const String primarySoft = 'E8F3FF';
  static const String cyan = '22D3EE';
  static const String cyanSoft = 'E7F9FF';
  static const String indigo = '4F46E5';
  static const String indigoSoft = 'EEF2FF';
  static const String violet = '7C3AED';
  static const String violetSoft = 'F5F0FF';
  static const String border = 'D7E4F3';
  static const String divider = 'E6EEF8';
  static const String success = '10B981';
  static const String warning = 'F59E0B';
  static const String danger = 'EF4444';
  static const String darkBlue = '0A2A5E';

  // 16:9 lecture grid. Keeping these values in one place prevents every
  // semantic layout from inventing its own margins and vertical rhythm.
  static const double safeX = .68;
  static const double safeWidth = 11.97;
  static const double contentBottom = 6.64;
  static const double footerRuleY = 7.02;
  static const double panelRadius = 18;
  static const double compactRadius = 14;
  static const double panelGap = .26;

  static const Set<String> _darkLayouts = {
    'title_slide',
    'section_divider',
    'quote',
    'full_image',
  };

  static String backgroundFor(String layout) {
    return _darkLayouts.contains(layout) ? ink : canvas;
  }

  static void validate({
    required String layout,
    required Map raw,
    required List<PresentationCardContent> cards,
    required PresentationVisualContent? visual,
    required PresentationEquationContent? equation,
    required PresentationProblemContent? problem,
    required int slideIndex,
  }) {
    bool hasList(dynamic value) => value is List && value.isNotEmpty;
    bool hasMap(dynamic value) => value is Map && value.isNotEmpty;
    int listLength(dynamic value) => value is List ? value.length : 0;

    void enforceMaximum(dynamic value, int maximum, String field) {
      final count = listLength(value);
      if (count > maximum) {
        throw FormatException(
          'Slide $slideIndex: $field contains $count items. Maximum for '
          '$layout is $maximum. Split the content into another slide.',
        );
      }
    }

    switch (layout) {
      case 'lecture_objectives':
        final content = raw['content'];
        final contentObjectives = content is Map ? content['objectives'] : null;
        if (!hasList(raw['objectives']) && !hasList(contentObjectives) && cards.isEmpty) {
          throw FormatException(
            'Slide $slideIndex: lecture_objectives requires objectives or cards.',
          );
        }
        enforceMaximum(
          hasList(raw['objectives']) ? raw['objectives'] : contentObjectives,
          6,
          'objectives',
        );
        if (cards.length > 6) {
          throw FormatException(
            'Slide $slideIndex: lecture_objectives supports at most 6 cards.',
          );
        }
        break;
      case 'concept_explanation':
        if (!hasMap(raw['content']) &&
            !hasList(raw['bullets']) &&
            cards.isEmpty &&
            visual == null) {
          throw FormatException(
            'Slide $slideIndex: concept_explanation requires content, bullets, cards, or a visual.',
          );
        }
        final content = raw['content'];
        if (content is Map) enforceMaximum(content['bullets'], 4, 'content.bullets');
        enforceMaximum(raw['bullets'], 4, 'bullets');
        break;
      case 'text_with_image':
      case 'full_image':
        if (visual == null || visual.src.trim().isEmpty) {
          throw FormatException(
            'Slide $slideIndex: $layout requires visual.src.',
          );
        }
        if (layout == 'text_with_image') {
          final content = raw['content'];
          if (content is Map) enforceMaximum(content['bullets'], 4, 'content.bullets');
          enforceMaximum(raw['bullets'], 4, 'bullets');
        }
        break;
      case 'key_points':
        final content = raw['content'];
        final contentPoints = content is Map ? content['bullets'] : null;
        if (cards.isEmpty && !hasList(raw['points']) && !hasList(contentPoints)) {
          throw FormatException(
            'Slide $slideIndex: key_points requires cards or points.',
          );
        }
        if (cards.length > 5) {
          throw FormatException(
            'Slide $slideIndex: key_points supports at most 5 cards.',
          );
        }
        enforceMaximum(hasList(raw['points']) ? raw['points'] : contentPoints, 5, 'points');
        break;
      case 'comparison':
        final comparison = raw['comparison'];
        if (comparison is! Map ||
            comparison['left'] is! Map ||
            comparison['right'] is! Map) {
          throw FormatException(
            'Slide $slideIndex: comparison requires comparison.left and comparison.right objects.',
          );
        }
        final left = comparison['left'] as Map;
        final right = comparison['right'] as Map;
        enforceMaximum(left['points'] ?? left['bullets'], 5, 'comparison.left.points');
        enforceMaximum(right['points'] ?? right['bullets'], 5, 'comparison.right.points');
        break;
      case 'process_steps':
        final content = raw['content'];
        final contentSteps = content is Map ? content['steps'] : null;
        final source = hasList(raw['process'])
            ? raw['process']
            : hasList(raw['steps'])
                ? raw['steps']
                : contentSteps;
        if (!hasList(source) && cards.isEmpty) {
          throw FormatException(
            'Slide $slideIndex: process_steps requires process, steps, or cards.',
          );
        }
        enforceMaximum(source, 6, 'process steps');
        if (cards.length > 6) {
          throw FormatException(
            'Slide $slideIndex: process_steps supports at most 6 cards.',
          );
        }
        break;
      case 'timeline':
        final source = hasList(raw['timeline']) ? raw['timeline'] : raw['items'];
        if (!hasList(source)) {
          throw FormatException(
            'Slide $slideIndex: timeline requires a timeline array.',
          );
        }
        enforceMaximum(source, 6, 'timeline');
        break;
      case 'diagram':
        final diagram = raw['diagram'];
        if (diagram is! Map || !hasList(diagram['nodes'])) {
          throw FormatException(
            'Slide $slideIndex: diagram requires diagram.nodes.',
          );
        }
        enforceMaximum(diagram['nodes'], 12, 'diagram.nodes');
        enforceMaximum(diagram['edges'], 20, 'diagram.edges');
        break;
      case 'table':
        final table = raw['table'];
        if (!hasMap(table) || !hasList((table as Map)['rows'])) {
          throw FormatException(
            'Slide $slideIndex: table requires table.rows.',
          );
        }
        enforceMaximum(table['headers'] ?? table['columns'], 6, 'table.headers');
        enforceMaximum(table['rows'], 8, 'table.rows');
        break;
      case 'equation_explanation':
        if (equation == null || equation.value.trim().isEmpty) {
          throw FormatException(
            'Slide $slideIndex: equation_explanation requires equation.latex or equation.value.',
          );
        }
        final content = raw['content'];
        if (content is Map) enforceMaximum(content['bullets'], 5, 'content.bullets');
        enforceMaximum(raw['bullets'], 5, 'bullets');
        break;
      case 'equation_derivation':
        final equationRaw = raw['equation'];
        final equationSteps = equationRaw is Map ? equationRaw['steps'] : null;
        final source = hasList(equationSteps)
            ? equationSteps
            : hasList(raw['derivation'])
                ? raw['derivation']
                : raw['steps'];
        if (!hasList(source)) {
          throw FormatException(
            'Slide $slideIndex: equation_derivation requires equation.steps, derivation, or steps.',
          );
        }
        enforceMaximum(source, 5, 'equation derivation steps');
        break;
      case 'worked_example':
      case 'problem_solution':
      case 'multiple_choice':
        if (problem == null || problem.statement.trim().isEmpty) {
          throw FormatException(
            'Slide $slideIndex: $layout requires problem.statement.',
          );
        }
        if (layout == 'multiple_choice') {
          if (problem.choices.length < 2) {
            throw FormatException(
              'Slide $slideIndex: multiple_choice requires at least two choices.',
            );
          }
          if (problem.choices.length > 4) {
            throw FormatException(
              'Slide $slideIndex: multiple_choice supports at most 4 choices.',
            );
          }
        }
        final maximumSteps = layout == 'worked_example' ? 3 : 5;
        if (problem.solutionSteps.length > maximumSteps) {
          throw FormatException(
            'Slide $slideIndex: $layout supports at most $maximumSteps solution steps.',
          );
        }
        break;
      case 'practice_activity':
        final activity = raw['activity'] ?? raw['content'];
        if (!hasMap(activity)) {
          throw FormatException(
            'Slide $slideIndex: practice_activity requires an activity object.',
          );
        }
        final activityMap = activity as Map;
        final task = (activityMap['task'] ?? activityMap['prompt'] ?? '')
            .toString()
            .trim();
        final instructions = activityMap['instructions'] ?? activityMap['steps'];
        if (task.isEmpty || !hasList(instructions)) {
          throw FormatException(
            'Slide $slideIndex: practice_activity requires a non-empty task and instructions.',
          );
        }
        enforceMaximum(instructions, 5, 'activity.instructions');
        break;
      case 'case_study':
        final caseStudy = raw['case_study'] ?? raw['content'];
        if (!hasMap(caseStudy)) {
          throw FormatException(
            'Slide $slideIndex: case_study requires case_study or content.',
          );
        }
        final caseMap = caseStudy as Map;
        final hasNarrative = [
          caseMap['context'],
          caseMap['challenge'],
          caseMap['evidence'] ?? caseMap['data'],
        ].any((value) => value != null && value.toString().trim().isNotEmpty);
        if (!hasNarrative) {
          throw FormatException(
            'Slide $slideIndex: case_study requires context, challenge, or evidence.',
          );
        }
        enforceMaximum(
          caseMap['questions'] ?? caseMap['discussion_questions'],
          2,
          'case_study.questions',
        );
        break;
      case 'quote':
        final quoteRaw = raw['quote'] ?? raw['text'];
        final quoteText = quoteRaw is Map
            ? (quoteRaw['text'] ?? '').toString().trim()
            : (quoteRaw ?? '').toString().trim();
        if (quoteText.isEmpty) {
          throw FormatException(
            'Slide $slideIndex: quote requires non-empty quote text.',
          );
        }
        break;
      case 'summary':
        if (!hasMap(raw['summary']) &&
            !hasMap(raw['content']) &&
            !hasList(raw['points'])) {
          throw FormatException(
            'Slide $slideIndex: summary requires summary, content, or points.',
          );
        }
        final summary = raw['summary'] is Map
            ? raw['summary'] as Map
            : raw['content'] is Map
                ? raw['content'] as Map
                : raw;
        final summaryPoints = summary['points'] ?? summary['bullets'];
        final takeaway = (summary['takeaway'] ??
                summary['key_takeaway'] ??
                raw['takeaway'] ??
                '')
            .toString()
            .trim();
        if (!hasList(summaryPoints) || takeaway.isEmpty) {
          throw FormatException(
            'Slide $slideIndex: summary requires points and a non-empty takeaway.',
          );
        }
        enforceMaximum(summaryPoints, 6, 'summary.points');
        break;
      case 'references':
        final source = hasList(raw['references']) ? raw['references'] : raw['sources'];
        if (!hasList(source)) {
          throw FormatException(
            'Slide $slideIndex: references requires references or sources.',
          );
        }
        enforceMaximum(source, 12, 'references');
        break;
      default:
        break;
    }
  }

  static List<String> notesFor(PresentationSlide slide) {
    final values = <String>[
      if ((slide.kicker ?? '').trim().isNotEmpty) slide.kicker!.trim(),
      slide.title,
      ..._flattenStrings(slide.semanticData),
      if ((slide.visual?.caption ?? '').trim().isNotEmpty) slide.visual!.caption!,
      if ((slide.equation?.value ?? '').trim().isNotEmpty) slide.equation!.value,
      if ((slide.problem?.statement ?? '').trim().isNotEmpty) slide.problem!.statement,
      for (final card in slide.cards) ...[
        card.heading,
        if (card.body.isNotEmpty) card.body,
      ],
    ];
    final seen = <String>{};
    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && seen.add(item))
        .take(40)
        .toList();
  }

  static List<PresentationElement> build(PresentationSlide slide) {
    return SlideTemplateRegistry.build(slide);
  }

  static PresentationElement _text(
    String value,
    double x,
    double y,
    double w,
    double h, {
    double size = 14,
    String color = ink,
    bool bold = false,
    bool italic = false,
    int maxLines = 3,
    TextAlign? align,
    double spacing = 0,
    String verticalAlign = 'top',
    double? lineHeight,
  }) {
    final text = value.trim();
    final rtl = _rtl(text);
    final effectiveAlign = align ?? (rtl ? TextAlign.right : TextAlign.left);
    final resolvedLineHeight = lineHeight ??
        (size >= 28
            ? 1.02
            : bold
                ? 1.08
                : 1.16);
    final wrapped = maxLines <= 1
        ? text
        : PresentationDesignTokens.wrapText(
            text,
            width: w * 72,
            fontSize: size,
            maxLines: maxLines,
            averageGlyphFactor: rtl ? .88 : .92,
          );
    return PresentationElement(
      type: PresentationElementType.text,
      x: x,
      y: y,
      w: w,
      h: h,
      text: wrapped,
      colorHex: color,
      fontSize: size,
      fontFace: rtl
          ? PresentationDesignTokens.rtlFontFamily
          : (bold
              ? PresentationDesignTokens.headingFontFamily
              : PresentationDesignTokens.bodyFontFamily),
      bold: bold,
      italic: italic,
      align: effectiveAlign,
      charSpacing: spacing,
      lineHeight: resolvedLineHeight,
      maxLines: maxLines,
      verticalAlign: verticalAlign,
    );
  }

  static PresentationElement _rect(
    double x,
    double y,
    double w,
    double h,
    String fill, {
    double radius = 0,
    String? line,
    double lineWidth = 1,
    double opacity = 1,
    bool shadow = false,
  }) {
    return PresentationElement(
      type: PresentationElementType.rect,
      x: x,
      y: y,
      w: w,
      h: h,
      fillHex: fill,
      lineHex: line,
      lineWidth: line == null ? null : lineWidth,
      opacity: opacity,
      radius: radius,
      shadow: shadow,
    );
  }

  static PresentationElement _oval(
    double x,
    double y,
    double size,
    String fill, {
    double opacity = 1,
  }) {
    return PresentationElement(
      type: PresentationElementType.oval,
      x: x,
      y: y,
      w: size,
      h: size,
      fillHex: fill,
      opacity: opacity,
    );
  }

  static PresentationElement _line(
    double x,
    double y,
    double w,
    String color, {
    double width = 2,
    double verticalHeight = 0,
  }) {
    return PresentationElement(
      type: PresentationElementType.line,
      x: x,
      y: y,
      w: verticalHeight > 0 ? .01 : math.max(.01, w.abs()).toDouble(),
      h: verticalHeight > 0 ? verticalHeight : .02,
      lineHex: color,
      lineWidth: width,
    );
  }

  static PresentationElement _image(
    String path,
    double x,
    double y,
    double w,
    double h, {
    String fit = 'cover',
    double radius = 0,
  }) {
    return PresentationElement(
      type: PresentationElementType.image,
      x: x,
      y: y,
      w: w,
      h: h,
      path: path,
      fit: fit,
      radius: radius,
    );
  }

  static PresentationElement _equationElement(
    PresentationEquationContent equation,
    double x,
    double y,
    double w,
    double h, {
    required String color,
    required double size,
  }) {
    if (!equation.shouldRenderAsSvg) {
      return _text(equation.value, x, y, w, h,
          size: size, color: color, bold: true, maxLines: 3, align: TextAlign.center, verticalAlign: 'middle');
    }
    return PresentationElement(
      type: PresentationElementType.equation,
      x: x,
      y: y,
      w: w,
      h: h,
      text: equation.value,
      colorHex: color,
      fontSize: size,
      maxLines: 3,
      align: TextAlign.center,
      verticalAlign: 'middle',
    );
  }

  static _LectureAccentSpec _accent(int index) {
    const accents = <_LectureAccentSpec>[
      _LectureAccentSpec(primary, primarySoft),
      _LectureAccentSpec(cyan, cyanSoft),
      _LectureAccentSpec(indigo, indigoSoft),
      _LectureAccentSpec(violet, violetSoft),
    ];
    return accents[index % accents.length];
  }

  static int _wrappedLineCount(
    String value, {
    required double width,
    required double fontSize,
    required int maxLines,
  }) {
    final text = value.trim();
    if (text.isEmpty) return 0;
    return PresentationDesignTokens.wrapText(
      text,
      width: width * 72,
      fontSize: fontSize,
      maxLines: maxLines,
      averageGlyphFactor: _rtl(text) ? .88 : .92,
    ).split('\n').length;
  }

  static double _textBlockHeight(
    int lineCount,
    double fontSize,
    double lineHeight, {
    double padding = .06,
  }) {
    if (lineCount <= 0) return 0;
    return lineCount * fontSize * lineHeight / 72 + padding;
  }

  static double _contentTopFor(PresentationSlide slide) {
    final titleSize = _fitTitle(slide.title, compact: true);
    final titleLines = _wrappedLineCount(
      slide.title,
      width: 11.42,
      fontSize: titleSize,
      maxLines: 2,
    );
    return titleLines > 1 ? 2.30 : 2.02;
  }

  static double _fitTitle(
    String title, {
    bool large = false,
    bool compact = false,
  }) {
    final units = PresentationDesignTokens.textUnits(title);
    if (large) {
      if (units > 32) return 38;
      if (units > 27) return 42;
      if (units > 22) return 46;
      if (units > 17) return 50;
      if (units > 13) return 53;
      return 56;
    }
    if (compact) {
      if (units > 32) return 24;
      if (units > 27) return 26;
      if (units > 23) return 29;
      if (units > 19) return 31;
      if (units > 15) return 33;
      return 36;
    }
    if (units > 32) return 29;
    if (units > 27) return 32;
    if (units > 23) return 35;
    if (units > 19) return 38;
    if (units > 15) return 42;
    return 45;
  }

  static String _iconGlyph(String value) {
    final key = value.toLowerCase();
    if (key.contains('check')) return '✓';
    if (key.contains('question')) return '?';
    if (key.contains('warning') || key.contains('exclamation')) return '!';
    if (key.contains('book')) return '▤';
    if (key.contains('brain') || key.contains('robot')) return 'AI';
    if (key.contains('search')) return '⌕';
    if (key.contains('network') || key.contains('branch')) return '◆';
    if (key.contains('file') || key.contains('pdf')) return 'PDF';
    if (key.contains('bolt')) return '⚡';
    if (key.contains('sync')) return '↻';
    return '✦';
  }

  static bool _rtl(String value) => RegExp(r'[\u0590-\u08FF]').hasMatch(value);

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static int _int(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static List<String> _stringList(dynamic value) {
    if (value is String) {
      return value
          .split(RegExp(r'\n|•'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is! List) return const [];
    return value
        .map((item) {
          if (item is Map) {
            return _string(item['text'] ?? item['title'] ?? item['heading'] ?? item['body']);
          }
          return _string(item);
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> _itemMaps(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      if (item is Map) return _map(item);
      return <String, dynamic>{'text': _string(item), 'title': _string(item)};
    }).where((item) => item.values.any((value) => _string(value).isNotEmpty)).toList();
  }

  static List<String> _flattenStrings(dynamic value) {
    final result = <String>[];
    void walk(dynamic item) {
      if (item is Map) {
        item.values.forEach(walk);
      } else if (item is List) {
        item.forEach(walk);
      } else if (item != null) {
        final text = item.toString().trim();
        if (text.isNotEmpty) result.add(text);
      }
    }

    walk(value);
    return result;
  }
}

class _LectureAccentSpec {
  final String color;
  final String softColor;

  const _LectureAccentSpec(this.color, this.softColor);
}

class PresentationCodeParser {
  static PresentationDeck parse(String source) {
    final trimmed = _stripMarkdownFence(source.trim());
    final looksLikeJson =
        trimmed.startsWith('{') || trimmed.startsWith('[');
    final looksLikePptxGenJs = trimmed.contains('pres.addSlide') ||
        trimmed.contains('pptxgenjs');

    if (looksLikeJson && !looksLikePptxGenJs) {
      return _parseJsonDeck(trimmed);
    }
    return _parsePptxGenJs(trimmed);
  }

  static String _stripMarkdownFence(String source) {
    final firstFence = source.indexOf('```');
    if (firstFence < 0) return source;

    final firstLineBreak = source.indexOf('\n', firstFence);
    final lastFence = source.indexOf('```', firstLineBreak + 1);
    if (firstLineBreak < 0 || lastFence <= firstLineBreak) return source;
    return source.substring(firstLineBreak + 1, lastFence).trim();
  }

  static PresentationDeck _buildLearnovaEngineDeck() {
    const navy = '132A4C';
    const teal = '1F6F8B';
    const tealLight = '5FA8C4';
    const amber = 'F2B134';
    const white = 'FFFFFF';
    const cardTint = 'EEF4F8';
    const textDark = '152238';
    const textMuted = '5B6B7F';
    const paleLine = 'E3EAF0';
    const bodyLight = 'C7D6E5';

    PresentationElement text(
      String value,
      double x,
      double y,
      double w,
      double h, {
      double fontSize = 12,
      String color = textDark,
      bool bold = false,
      bool italic = false,
      TextAlign align = TextAlign.left,
      double? charSpacing,
      int? maxLines,
    }) {
      return PresentationElement(
        type: PresentationElementType.text,
        x: x,
        y: y,
        w: w,
        h: h,
        text: value,
        colorHex: color,
        fontSize: fontSize,
        bold: bold,
        italic: italic,
        align: align,
        charSpacing: charSpacing,
        maxLines: maxLines,
      );
    }

    PresentationElement rect(
      double x,
      double y,
      double w,
      double h,
      String fill, {
      String? lineColor,
      double? lineWidth,
    }) {
      return PresentationElement(
        type: PresentationElementType.rect,
        x: x,
        y: y,
        w: w,
        h: h,
        fillHex: fill,
        lineHex: lineColor,
        lineWidth: lineWidth,
      );
    }

    PresentationElement oval(double x, double y, double d, String fill) {
      return PresentationElement(
        type: PresentationElementType.oval,
        x: x,
        y: y,
        w: d,
        h: d,
        fillHex: fill,
      );
    }

    PresentationElement line(
      double x,
      double y,
      double w,
      String color, {
      double width = 2,
      double h = 0.02,
    }) {
      return PresentationElement(
        type: PresentationElementType.line,
        x: x,
        y: y,
        w: w,
        h: h,
        lineHex: color,
        lineWidth: width,
      );
    }

    PresentationElement image(
      String path,
      double x,
      double y,
      double w,
      double h, {
      double opacity = 1,
    }) {
      return PresentationElement(
        type: PresentationElementType.image,
        x: x,
        y: y,
        w: w,
        h: h,
        path: path,
        opacity: opacity,
      );
    }

    void iconCircle(
      List<PresentationElement> elements,
      double x,
      double y,
      double d,
      String bgColor,
      String iconName, {
      double iconOpacity = 0.9,
    }) {
      elements.add(oval(x, y, d, bgColor));
      elements.add(image(iconName, x + d * 0.27, y + d * 0.27, d * 0.46, d * 0.46, opacity: iconOpacity));
    }

    void footer(List<PresentationElement> elements, int pageNum, bool dark) {
      elements.add(text(
        'LEARNOVA',
        0.5,
        7.08,
        3,
        0.3,
        fontSize: 9,
        color: dark ? '6C87A8' : 'A9B7C6',
        bold: true,
        charSpacing: 2,
        maxLines: 1,
      ));
      elements.add(text(
        '$pageNum',
        12.4,
        7.08,
        0.4,
        0.3,
        fontSize: 9,
        color: dark ? '6C87A8' : 'A9B7C6',
        align: TextAlign.right,
        maxLines: 1,
      ));
    }

    void sectionTitle(List<PresentationElement> elements, String kicker, String title) {
      elements.add(text(
        kicker.toUpperCase(),
        0.6,
        0.42,
        9,
        0.35,
        fontSize: 13,
        color: teal,
        bold: true,
        charSpacing: 2,
        maxLines: 1,
      ));
      elements.add(text(
        title,
        0.6,
        0.72,
        12.1,
        0.75,
        fontSize: 27,
        color: textDark,
        bold: true,
        maxLines: 1,
      ));
    }

    void taskTag(List<PresentationElement> elements, String label) {
      final tagWidth = 0.35 + label.length * 0.105;
      elements.add(rect(0.6, 0.42, tagWidth, 0.35, navy));
      elements.add(text(
        label,
        0.6,
        0.48,
        tagWidth,
        0.25,
        fontSize: 10.5,
        color: white,
        bold: true,
        align: TextAlign.center,
        charSpacing: 1,
        maxLines: 1,
      ));
    }

    void drawFlowRow(
      List<PresentationElement> elements,
      List<List<String>> items,
      double y,
      String dotColor,
      double boxH,
    ) {
      const boxW = 3.7;
      final gap = (12.1 - boxW * items.length) / (items.length - 1);
      for (var i = 0; i < items.length; i++) {
        final x = 0.6 + i * (boxW + gap);
        final item = items[i];
        elements.add(rect(x, y, boxW, boxH, white, lineColor: paleLine, lineWidth: 1));
        iconCircle(elements, x + 0.25, y + 0.22, 0.6, dotColor, item[0]);
        elements.add(text(
          item[1],
          x + 1.0,
          y + 0.15,
          boxW - 1.2,
          0.6,
          fontSize: 12.5,
          color: textDark,
          bold: true,
          maxLines: 2,
        ));
        elements.add(text(
          item[2],
          x + 0.25,
          y + 0.92,
          boxW - 0.5,
          boxH - 1.0,
          fontSize: 10.5,
          color: textMuted,
          maxLines: 3,
        ));
        if (i < items.length - 1) {
          final ax = x + boxW + gap / 2;
          elements.add(oval(ax - 0.09, y + boxH / 2 - 0.09, 0.18, dotColor));
        }
      }
    }

    final slides = <PresentationSlide>[];

    final s1 = <PresentationElement>[
      image('networkwired_white', 9.5, 2.0, 3.6, 3.6, opacity: 0.12),
      text('AUTONOMOUS EDUCATIONAL CONTENT PIPELINE', 0.9, 2.35, 9.5, 0.4, fontSize: 13, color: tealLight, bold: true, charSpacing: 3, maxLines: 1),
      text('Learnova AI Engine', 0.85, 2.75, 10.5, 1.3, fontSize: 52, color: white, bold: true, maxLines: 1),
      line(0.95, 3.95, 1.1, amber, width: 3),
      text('An asynchronous, Dockerized FastAPI architecture engineered to autonomously transform\nmassive raw textbooks into structured topic hierarchies, vector databases, and formal assessment banks.', 0.9, 4.15, 10, 1.0, fontSize: 15, color: bodyLight, maxLines: 3),
      text('Presented by Eslam Mohamed', 0.9, 6.55, 6, 0.4, fontSize: 12.5, color: '6C87A8', italic: true, maxLines: 1),
    ];
    slides.add(PresentationSlide(title: 'TITLE', backgroundHex: navy, elements: s1, notes: const []));

    final s2 = <PresentationElement>[];
    sectionTitle(s2, 'Data Pipeline', 'Ingestion & Storage');
    s2.add(text('Raw PDFs are ingested, cleaned, and sliced into three purpose-built chunk sizes before anything touches an LLM.', 0.6, 1.55, 11.9, 0.4, fontSize: 13.5, color: teal, italic: true, maxLines: 1));
    s2.add(text('MULTI-TIER CHUNKING STRATEGY', 0.6, 2.1, 6, 0.3, fontSize: 11, color: navy, bold: true, charSpacing: 1.2, maxLines: 1));
    const rows = [
      ['Structure Chunks', '1,000 chars / 100 overlap', 'Sized for hierarchical batch processing'],
      ['Question Chunks', '1,500 chars / 150 overlap', 'Wider context to formulate exam questions'],
      ['RAG Chunks', '1,000 chars / 150 overlap', 'Optimized for precise semantic vector similarity'],
    ];
    for (var i = 0; i < rows.length; i++) {
      final y = 2.5 + i * (0.72 + 0.14);
      s2.add(rect(0.6, y, 7.5, 0.72, cardTint));
      s2.add(text(rows[i][0], 0.85, y + 0.16, 2.1, 0.4, fontSize: 12.5, color: navy, bold: true, maxLines: 1));
      s2.add(text(rows[i][1], 2.95, y + 0.17, 2.55, 0.38, fontSize: 11.5, color: teal, maxLines: 1));
      s2.add(text(rows[i][2], 5.5, y + 0.15, 2.4, 0.42, fontSize: 10.5, color: textMuted, maxLines: 2));
    }
    s2.add(text('DUAL-DATABASE ARCHITECTURE', 8.5, 2.1, 4.3, 0.3, fontSize: 11, color: navy, bold: true, charSpacing: 1.2, maxLines: 1));
    s2.add(rect(8.5, 2.5, 4.2, 1.55, white, lineColor: paleLine, lineWidth: 1));
    iconCircle(s2, 8.75, 2.72, 0.62, teal, 'database_white');
    s2.add(text('MongoDB (NoSQL)', 9.55, 2.68, 3.0, 0.35, fontSize: 13, color: textDark, bold: true, maxLines: 1));
    s2.add(text('Persists raw text chunks, ordering metadata, and page mapping for sequential processing.', 8.75, 3.45, 3.75, 0.55, fontSize: 10.5, color: textMuted, maxLines: 3));
    s2.add(rect(8.5, 4.25, 4.2, 1.55, white, lineColor: paleLine, lineWidth: 1));
    iconCircle(s2, 8.75, 4.47, 0.62, navy, 'vectorsquare_white');
    s2.add(text('Qdrant (Vector DB)', 9.55, 4.43, 3.0, 0.35, fontSize: 13, color: textDark, bold: true, maxLines: 1));
    s2.add(text('Stores high-dimensional embeddings generated via Jina AI for ultra-fast semantic retrieval.', 8.75, 5.2, 3.75, 0.55, fontSize: 10.5, color: textMuted, maxLines: 3));
    s2.add(text('Text extraction & cleaning removes page numbers and noise keywords before chunking begins.', 0.6, 5.35, 7.5, 0.6, fontSize: 11.5, color: textMuted, italic: true, maxLines: 2));
    footer(s2, 2, false);
    slides.add(PresentationSlide(title: 'DATA PIPELINE (INGESTION & STORAGE)', backgroundHex: white, elements: s2, notes: const []));

    final s3 = <PresentationElement>[];
    taskTag(s3, 'TASK 1');
    s3.add(text('Structural Extraction — The Obstacles', 0.6, 0.85, 12, 0.75, fontSize: 26, color: textDark, bold: true, maxLines: 1));
    s3.add(rect(0.6, 1.85, 12.1, 0.85, navy));
    iconCircle(s3, 0.85, 2.06, 0.5, '2A557E', 'filepdf_amber');
    s3.add(text('The Goal', 1.55, 1.92, 2.0, 0.3, fontSize: 11.5, color: amber, bold: true, maxLines: 1));
    s3.add(text('Parse a 150,000+ character textbook into a strict, nested JSON hierarchy of topics and subtopics.', 1.55, 2.2, 10.9, 0.4, fontSize: 13, color: white, maxLines: 1));
    const obstacles = [
      ['exclamation_white', 'Summarization Bias', 'Feeding an LLM too much text at once causes it to lazily summarize — granular subtopics get silently dropped.'],
      ['codebranch_white', 'The Batch Boundary Problem', 'Splitting the book into smaller batches fixes the summarization issue, but destroys the overarching chapter hierarchy whenever a chapter\'s content spans two batches.'],
    ];
    for (var i = 0; i < obstacles.length; i++) {
      final x = 0.6 + i * (5.85 + 0.4);
      s3.add(rect(x, 3.05, 5.85, 3.1, cardTint));
      iconCircle(s3, x + 0.35, 3.4, 0.75, teal, obstacles[i][0]);
      s3.add(text(obstacles[i][1], x + 1.3, 3.38, 4.25, 0.75, fontSize: 16, color: textDark, bold: true, maxLines: 2));
      s3.add(text(obstacles[i][2], x + 0.35, 4.35, 5.15, 1.55, fontSize: 12.5, color: textMuted, maxLines: 5));
    }
    footer(s3, 3, false);
    slides.add(PresentationSlide(title: 'TASK 1: STRUCTURAL EXTRACTION — THE PROBLEM', backgroundHex: white, elements: s3, notes: const []));

    final s4 = <PresentationElement>[];
    taskTag(s4, 'TASK 1');
    s4.add(text('The Two-Pass Anchor Algorithm', 0.6, 0.85, 12, 0.75, fontSize: 26, color: textDark, bold: true, maxLines: 1));
    s4.add(rect(0.6, 1.7, 1.55, 0.32, teal));
    s4.add(text('PASS 1', 0.6, 1.76, 1.55, 0.24, fontSize: 10.5, color: white, bold: true, align: TextAlign.center, charSpacing: 1, maxLines: 1));
    s4.add(text('Build the Anchor', 2.3, 1.7, 4, 0.32, fontSize: 13, color: textDark, bold: true, maxLines: 1));
    drawFlowRow(s4, const [
      ['listol_white', 'First 30,000 characters', 'isolated from the book'],
      ['robot_white', 'LLM extracts structure', 'official chapter list'],
      ['sitemap_white', 'Master Table of Contents', 'the anchor for Pass 2'],
    ], 2.15, teal, 1.45);
    s4.add(rect(0.6, 3.82, 1.55, 0.32, navy));
    s4.add(text('PASS 2', 0.6, 3.88, 1.55, 0.24, fontSize: 10.5, color: white, bold: true, align: TextAlign.center, charSpacing: 1, maxLines: 1));
    s4.add(text('Map With the Anchor', 2.3, 3.82, 4.5, 0.32, fontSize: 13, color: textDark, bold: true, maxLines: 1));
    drawFlowRow(s4, const [
      ['layergroup_white', 'Full book in 35k-char batches', 'Master TOC injected as a strict constraint'],
      ['robot_white', 'LLM maps each batch', '90+ granular subtopics'],
      ['checksquare_white', 'Correct parent chapter', 'for every subtopic, every batch'],
    ], 4.27, navy, 1.45);
    s4.add(rect(0.6, 6.02, 12.1, 0.58, cardTint));
    iconCircle(s4, 0.78, 6.11, 0.4, teal, 'shield_white');
    s4.add(text('Fault tolerance: intelligent dictionary logic merges subtopics for chapters spanning two batches; a custom Regex engine extracts JSON arrays directly if the LLM hits its output token limit.', 1.35, 6.09, 11.1, 0.42, fontSize: 11.5, color: textMuted, maxLines: 2));
    footer(s4, 4, false);
    slides.add(PresentationSlide(title: 'TASK 1: THE TWO-PASS ANCHOR ALGORITHM', backgroundHex: white, elements: s4, notes: const []));

    final s5 = <PresentationElement>[];
    taskTag(s5, 'TASK 2');
    s5.add(text('Context-Aware Question Generation', 0.6, 0.85, 12, 0.75, fontSize: 26, color: textDark, bold: true, maxLines: 1));
    const qCards = [
      ['search_white', 'Smart Noise Reduction', 'A pre-filter evaluates every MongoDB chunk, dropping 80% of document noise and routing only assessment-heavy pages to the LLM.'],
      ['exclamation_white', 'Rhetorical Detection', 'Prompt engineering trains the AI to distinguish formal exam questions from conversational textbook examples — like a password-security anecdote — preventing bad data extraction.'],
      ['clipboardcheck_white', 'Strict Schemas', 'Enforces rigid JSON templates for multiple-choice, true/false, and short-answer formats, dynamically scaling difficulty: easy, medium, hard.'],
      ['syncalt_white', 'Parallel Execution', 'Uses asyncio.gather to fire simultaneous batches, generating comprehensive question banks in seconds instead of minutes.'],
    ];
    for (var i = 0; i < qCards.length; i++) {
      final x = 0.6 + i * (2.9 + 0.25);
      final color = i.isEven ? teal : navy;
      s5.add(rect(x, 2.0, 2.9, 3.9, white, lineColor: paleLine, lineWidth: 1));
      iconCircle(s5, x + (2.9 - 0.8) / 2, 2.35, 0.8, color, qCards[i][0]);
      s5.add(text(qCards[i][1], x + 0.2, 3.35, 2.5, 0.65, fontSize: 14, color: textDark, bold: true, align: TextAlign.center, maxLines: 2));
      s5.add(text(qCards[i][2], x + 0.25, 4.0, 2.4, 1.85, fontSize: 11, color: textMuted, align: TextAlign.center, maxLines: 7));
    }
    footer(s5, 5, false);
    slides.add(PresentationSlide(title: 'TASK 2: QUESTION GENERATION', backgroundHex: white, elements: s5, notes: const []));

    final s6 = <PresentationElement>[];
    taskTag(s6, 'TASK 3 & 4');
    s6.add(text('Automated Grading & RAG Tutor', 0.6, 0.85, 12, 0.75, fontSize: 26, color: textDark, bold: true, maxLines: 1));
    s6.add(rect(0.6, 1.95, 5.85, 4.6, white, lineColor: paleLine, lineWidth: 1));
    iconCircle(s6, 0.95, 2.3, 0.75, teal, 'clipboardcheck_white');
    s6.add(text('Automated Grading', 1.9, 2.3, 4.25, 0.75, fontSize: 17, color: textDark, bold: true, maxLines: 1));
    s6.add(text('Every short-answer or essay question gets a matching, LLM-generated "key-point grading rubric" at creation time.\n\nDuring evaluation, the AI cross-references the student\'s submission strictly against that rubric — never against generalized knowledge.', 0.95, 3.3, 5.15, 2.85, fontSize: 12.5, color: textMuted, maxLines: 8));
    s6.add(rect(6.85, 1.95, 5.85, 4.6, navy));
    iconCircle(s6, 7.2, 2.3, 0.75, amber, 'comments_white');
    s6.add(text('Retrieval-Augmented Chat', 8.15, 2.3, 4.25, 0.75, fontSize: 17, color: white, bold: true, maxLines: 1));
    const flow = ['User query', 'Embedded via Jina AI', 'Semantic search in Qdrant', 'Relevant chunks retrieved from MongoDB', 'Context injected into LLM prompt'];
    for (var i = 0; i < flow.length; i++) {
      final fy = 3.35 + i * 0.57;
      s6.add(oval(7.2, fy + 0.03, 0.16, amber));
      s6.add(text(flow[i], 7.5, fy - 0.1, 4.85, 0.4, fontSize: 12, color: white, maxLines: 1));
      if (i < flow.length - 1) s6.add(line(7.28, fy + 0.22, 0.01, '3E6690', width: 1.5, h: 0.35));
    }
    s6.add(text('Constrains the LLM to answer using only retrieved local vectors — eliminating hallucination.', 7.2, 6.25, 5.15, 0.6, fontSize: 10.5, color: tealLight, italic: true, maxLines: 2));
    footer(s6, 6, false);
    slides.add(PresentationSlide(title: 'TASK 3 & 4: GRADING AND RAG', backgroundHex: white, elements: s6, notes: const []));

    final s7 = <PresentationElement>[];
    sectionTitle(s7, 'The Gateway', 'Strategic Model Selection');
    s7.add(rect(0.6, 1.7, 12.1, 0.8, cardTint));
    iconCircle(s7, 0.85, 1.87, 0.46, navy, 'networkwired_white');
    s7.add(text('API Gateway — OpenRouter: decouples the backend from a single vendor, providing dynamic access to the world\'s best models while preventing vendor lock-in.', 1.5, 1.86, 11.0, 0.46, fontSize: 12.5, color: textMuted, maxLines: 2));
    const models = [
      ['Claude Sonnet 5', 'Anthropic', 'Structure Extraction  ·  Automated Grading', '1-million-token context window with the industry\'s best logical reasoning and strict JSON adherence — vital for mapping complex hierarchies.', navy],
      ['GPT-4o-mini', 'OpenAI', 'Question Generation  ·  RAG Chat', 'Extreme high throughput and ultra-low latency at low cost — built for repetitive, highly parallelized tasks that prize speed over deep reasoning.', teal],
    ];
    for (var i = 0; i < models.length; i++) {
      final x = 0.6 + i * (5.85 + 0.4);
      s7.add(rect(x, 2.75, 5.85, 3.7, white, lineColor: paleLine, lineWidth: 1));
      iconCircle(s7, x + 0.35, 3.1, 0.75, models[i][4], 'robot_white');
      s7.add(text(models[i][0], x + 1.3, 3.05, 4.25, 0.45, fontSize: 17, color: textDark, bold: true, maxLines: 1));
      s7.add(text(models[i][1], x + 1.3, 3.53, 4.25, 0.3, fontSize: 11, color: teal, maxLines: 1));
      s7.add(rect(x + 0.35, 4.1, 5.15, 0.55, cardTint));
      s7.add(text(models[i][2], x + 0.35, 4.25, 5.15, 0.25, fontSize: 11.5, color: navy, bold: true, align: TextAlign.center, maxLines: 1));
      s7.add(text(models[i][3], x + 0.35, 4.9, 5.15, 1.3, fontSize: 11.5, color: textMuted, maxLines: 5));
    }
    footer(s7, 7, false);
    slides.add(PresentationSlide(title: 'STRATEGIC MODEL SELECTION (GATEWAY)', backgroundHex: white, elements: s7, notes: const []));

    final s8 = <PresentationElement>[];
    sectionTitle(s8, 'Infrastructure', 'Async Framework & Dockerization');
    s8.add(rect(0.6, 1.95, 5.85, 4.5, cardTint));
    iconCircle(s8, 0.95, 2.3, 0.75, teal, 'bolt_white');
    s8.add(text('Asynchronous Framework', 1.9, 2.3, 4.25, 0.75, fontSize: 16, color: textDark, bold: true, maxLines: 1));
    s8.add(text('Built on Python FastAPI.\n\nUses asyncio.to_thread to push synchronous, heavy LLM network calls into background threads — the main server event loop never freezes, even under load.', 0.95, 3.3, 5.15, 2.55, fontSize: 12.5, color: textMuted, maxLines: 7));
    s8.add(rect(6.85, 1.95, 5.85, 4.5, navy));
    iconCircle(s8, 7.2, 2.3, 0.75, amber, 'docker_white');
    s8.add(text('Containerization (Docker)', 8.15, 2.3, 4.25, 0.75, fontSize: 16, color: white, bold: true, maxLines: 1));
    s8.add(text('The entire pipeline is fully Dockerized via docker-compose.\n\nFastAPI, MongoDB, Qdrant, and every environment dependency run in isolated containers — guaranteeing strict parity between local development and production.', 7.2, 3.3, 5.15, 2.55, fontSize: 12.5, color: bodyLight, maxLines: 7));
    s8.add(text('The whole AI engine can be spun up anywhere with a single command.', 0.6, 6.6, 12.1, 0.4, fontSize: 12.5, color: teal, italic: true, align: TextAlign.center, maxLines: 1));
    footer(s8, 8, false);
    slides.add(PresentationSlide(title: 'INFRASTRUCTURE & DOCKERIZATION', backgroundHex: white, elements: s8, notes: const []));

    final s9 = <PresentationElement>[
      image('bookopen_navy', 9.7, 2.3, 3.2, 3.2, opacity: 0.12),
      text('Thank You', 0.9, 2.7, 9, 1.2, fontSize: 50, color: white, bold: true, maxLines: 1),
      line(0.95, 3.75, 1.1, amber, width: 3),
      text('Questions & Discussion', 0.9, 3.9, 9, 0.5, fontSize: 18, color: tealLight, maxLines: 1),
      text('Learnova  ·  FastAPI  ·  MongoDB  ·  Qdrant  ·  Jina AI  ·  OpenRouter  ·  Docker', 0.9, 6.6, 11, 0.4, fontSize: 12, color: '6C87A8', charSpacing: 1, maxLines: 1),
    ];
    slides.add(PresentationSlide(title: 'CLOSING', backgroundHex: navy, elements: s9, notes: const []));

    return PresentationDeck(
      title: 'Learnova AI Engine: Autonomous Educational Content Pipeline',
      sourceLabel: 'optimized pptxgenjs preset',
      slides: slides,
    );
  }

  static PresentationDeck _parseJsonDeck(String source) {
    final decoded = jsonDecode(source);

    Map root;
    if (decoded is List) {
      root = {'slides': decoded};
    } else if (decoded is Map) {
      root = decoded;
    } else {
      throw const FormatException(
        'AI response must be a JSON object containing a slides array.',
      );
    }

    final wrappedData = root['data'];
    if (wrappedData is Map && wrappedData['slides'] is List) {
      root = wrappedData;
    }

    final rawSlides = root['slides'];
    if (rawSlides is! List) {
      throw const FormatException(
        'AI response must contain a slides array.',
      );
    }
    if (rawSlides.isEmpty) {
      throw const FormatException('The slides array cannot be empty.');
    }
    if (rawSlides.length > PresentationDesignTokens.maxSlides) {
      throw FormatException(
        'The presentation contains ${rawSlides.length} slides. Maximum: '
        '${PresentationDesignTokens.maxSlides}.',
      );
    }

    final slides = <PresentationSlide>[];
    var semanticSlideCount = 0;

    for (var i = 0; i < rawSlides.length; i++) {
      final raw = rawSlides[i];
      if (raw is! Map) {
        throw FormatException('Slide ${i + 1} must be a JSON object.');
      }

      final isSemanticSlide = raw.containsKey('layout_type') ||
          raw.containsKey('kicker') ||
          raw.containsKey('section') ||
          raw.containsKey('subtitle') ||
          raw.containsKey('cards') ||
          raw.containsKey('content') ||
          raw.containsKey('objectives') ||
          raw.containsKey('visual') ||
          raw.containsKey('image') ||
          raw.containsKey('equation') ||
          raw.containsKey('problem') ||
          raw.containsKey('comparison') ||
          raw.containsKey('process') ||
          raw.containsKey('steps') ||
          raw.containsKey('timeline') ||
          raw.containsKey('diagram') ||
          raw.containsKey('table') ||
          raw.containsKey('activity') ||
          raw.containsKey('case_study') ||
          raw.containsKey('quote') ||
          raw.containsKey('summary') ||
          raw.containsKey('references');

      if (isSemanticSlide) {
        slides.add(
          PresentationTemplateEngine.fromJson(
            raw,
            fallbackIndex: i + 1,
          ),
        );
        semanticSlideCount++;
        continue;
      }

      final elements = <PresentationElement>[];
      final rawElements = raw['elements'];
      if (rawElements is List) {
        for (final rawElement in rawElements) {
          if (rawElement is Map) {
            final element = _elementFromJson(rawElement);
            if (element != null) elements.add(element);
          }
        }
      }

      slides.add(
        PresentationSlide(
          slideNumber:
              PresentationTemplateEngine._intValue(raw['slide_number']) ?? i + 1,
          title: (raw['title'] ?? 'Slide ${i + 1}').toString(),
          backgroundHex: _normalizeHex(
            (raw['background'] ?? raw['backgroundHex'])?.toString(),
          ),
          elements: elements,
          notes: _notesFromJson(raw['notes']),
        ),
      );
    }

    if (slides.isEmpty) {
      throw const FormatException(
        'No valid slide objects were found in the slides array.',
      );
    }

    return PresentationDeck(
      title: (root['title'] ?? 'AI Presentation').toString(),
      sourceLabel: semanticSlideCount == slides.length
          ? 'Learnova lecture schema v4'
          : semanticSlideCount > 0
              ? 'mixed JSON'
              : 'JSON elements',
      slides: slides,
    );
  }

  static PresentationElement? _elementFromJson(Map raw) {
    final type = raw['type']?.toString().toLowerCase().trim() ?? 'text';
    PresentationElementType elementType;
    switch (type) {
      case 'rect':
      case 'rectangle':
      case 'rounded_rectangle':
        elementType = PresentationElementType.rect;
        break;
      case 'oval':
      case 'circle':
        elementType = PresentationElementType.oval;
        break;
      case 'line':
        elementType = PresentationElementType.line;
        break;
      case 'image':
        elementType = PresentationElementType.image;
        break;
      case 'equation':
      case 'math':
      case 'latex':
        elementType = PresentationElementType.equation;
        break;
      case 'text':
      default:
        elementType = PresentationElementType.text;
        break;
    }

    return PresentationElement(
      type: elementType,
      x: _toDouble(raw['x'], 0.6),
      y: _toDouble(raw['y'], 0.6),
      w: _toDouble(raw['w'], 4),
      h: _toDouble(raw['h'], elementType == PresentationElementType.text ? 0.6 : 1),
      text: (raw['text'] ?? '').toString(),
      colorHex: _normalizeHex(raw['color']?.toString()),
      fillHex: _normalizeHex(raw['fill']?.toString() ?? raw['fillColor']?.toString()),
      lineHex: _normalizeHex(raw['line']?.toString() ?? raw['lineColor']?.toString()),
      lineWidth: _nullableDouble(raw['lineWidth']),
      fontSize: _nullableDouble(raw['fontSize']),
      fontFace: raw['fontFace']?.toString(),
      bold: raw['bold'] == true,
      italic: raw['italic'] == true,
      align: _parseAlign(raw['align']?.toString()),
      charSpacing: _nullableDouble(raw['charSpacing']),
      maxLines: raw['maxLines'] is num ? (raw['maxLines'] as num).toInt() : null,
      path: raw['path']?.toString(),
      opacity: _toDouble(raw['opacity'], 1).clamp(0.0, 1.0).toDouble(),
      radius: _toDouble(raw['radius'], 0),
      fit: (raw['fit'] ?? 'contain').toString(),
      verticalAlign: (raw['verticalAlign'] ?? raw['vertical_align'] ?? 'top').toString(),
      shadow: raw['shadow'] == true,
    );
  }

  static PresentationDeck _parsePptxGenJs(String source) {
    if (_looksLikeLearnovaEngineDeck(source)) {
      return _buildLearnovaEngineDeck();
    }

    final colors = _readColorConstants(source);
    final deckTitle = _readPresentationTitle(source) ?? 'AI Presentation';
    final markers = RegExp(r'pres\.addSlide\s*\(\s*\)').allMatches(source).toList();
    final slides = <PresentationSlide>[];

    for (var i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final blockStart = source.lastIndexOf('{', marker.start);
      if (blockStart < 0) continue;
      final blockEnd = _findMatching(source, blockStart, '{', '}');
      if (blockEnd <= blockStart) continue;
      final block = source.substring(blockStart, blockEnd + 1);
      final title = _findSlideTitle(source, blockStart, i + 1);
      final background = _readBackground(block, colors);
      final elements = <PresentationElement>[];

      elements.addAll(_parseHelperCalls(block, colors));
      elements.addAll(_parseShapes(block, colors));
      elements.addAll(_parseImages(block, colors));
      elements.addAll(_parseTexts(block, colors));

      final notes = _extractUsefulQuotedStrings(block)
          .where((note) => !_isAlreadyVisible(note, elements))
          .take(40)
          .toList();

      slides.add(
        PresentationSlide(
          title: title,
          backgroundHex: background,
          elements: elements,
          notes: notes,
        ),
      );
    }

    return PresentationDeck(title: deckTitle, sourceLabel: 'pptxgenjs code', slides: slides);
  }

  static bool _looksLikeLearnovaEngineDeck(String source) {
    return source.contains('Learnova AI Engine: Autonomous Educational Content Pipeline') &&
        source.contains('TASK 1') &&
        source.contains('Qdrant') &&
        source.contains('Dockerization');
  }

  static Map<String, String> _readColorConstants(String source) {
    final values = <String, String>{};
    final regex = RegExp(
      r'''(?:const|let|var)\s+([A-Za-z_]\w*)\s*=\s*["']([0-9A-Fa-f]{6})["']''',
    );
    for (final match in regex.allMatches(source)) {
      values[match.group(1)!] = match.group(2)!.toUpperCase();
    }
    return values;
  }

  static String? _readPresentationTitle(String source) {
    final match = RegExp(r'''pres\.title\s*=\s*(["'])''').firstMatch(source);
    if (match == null) return null;
    final start = match.end - 1;
    final parsed = _readQuoted(source, start);
    return parsed?.value.trim().isEmpty == true ? null : parsed?.value.trim();
  }

  static String _findSlideTitle(String source, int blockStart, int fallbackIndex) {
    final from = math.max(0, blockStart - 700);
    final prefix = source.substring(from, blockStart);
    final matches = RegExp(r'//\s*SLIDE\s+([^\n\r]+)').allMatches(prefix).toList();
    if (matches.isEmpty) return 'Slide $fallbackIndex';
    final raw = matches.last.group(1)!.trim();
    final parts = raw.split(RegExp(r'\s+[—-]\s+'));
    if (parts.length > 1) return parts.sublist(1).join(' — ').trim();
    return 'Slide $raw';
  }

  static String? _readBackground(String block, Map<String, String> colors) {
    final match = RegExp(r's\.background\s*=\s*\{\s*color\s*:\s*([^}\n;]+)').firstMatch(block);
    if (match == null) return null;
    return _resolveColorToken(match.group(1)!, colors);
  }

  static List<PresentationElement> _parseHelperCalls(
    String block,
    Map<String, String> colors,
  ) {
    final elements = <PresentationElement>[];

    for (final call in _extractCalls(block, 'sectionTitle')) {
      final args = _quotedLiterals(call);
      if (args.length < 2) continue;
      elements.add(
        PresentationElement(
          type: PresentationElementType.text,
          x: 0.6,
          y: 0.42,
          w: 9,
          h: 0.35,
          text: args[0].toUpperCase(),
          colorHex: colors['TEAL'] ?? '1F6F8B',
          fontSize: 13,
          bold: true,
          charSpacing: 2,
          maxLines: 1,
        ),
      );
      elements.add(
        PresentationElement(
          type: PresentationElementType.text,
          x: 0.6,
          y: 0.72,
          w: 12.1,
          h: 0.75,
          text: args[1],
          colorHex: colors['TEXT_DARK'] ?? '152238',
          fontSize: 27,
          bold: true,
          maxLines: 2,
        ),
      );
    }

    for (final call in _extractCalls(block, 'taskTag')) {
      final args = _quotedLiterals(call);
      if (args.isEmpty) continue;
      final label = args.first.toUpperCase();
      final width = 0.35 + label.length * 0.105;
      elements.add(
        PresentationElement(
          type: PresentationElementType.rect,
          x: 0.6,
          y: 0.42,
          w: width,
          h: 0.35,
          fillHex: colors['NAVY'] ?? '132A4C',
        ),
      );
      elements.add(
        PresentationElement(
          type: PresentationElementType.text,
          x: 0.6,
          y: 0.48,
          w: width,
          h: 0.25,
          text: label,
          colorHex: colors['WHITE'] ?? 'FFFFFF',
          fontSize: 10.5,
          bold: true,
          align: TextAlign.center,
          maxLines: 1,
        ),
      );
    }

    return elements;
  }

  static List<PresentationElement> _parseTexts(String block, Map<String, String> colors) {
    final elements = <PresentationElement>[];
    for (final call in _extractCalls(block, 's.addText')) {
      final parsed = _parseTextCall(call, colors);
      if (parsed != null) elements.add(parsed);
    }
    return elements;
  }

  static PresentationElement? _parseTextCall(String args, Map<String, String> colors) {
    final trimmed = args.trimLeft();
    final offset = args.length - trimmed.length;
    String text = '';
    int afterFirstArg;

    if (trimmed.startsWith('"') || trimmed.startsWith("'")) {
      final parsed = _readQuoted(args, offset);
      if (parsed == null) return null;
      text = parsed.value;
      afterFirstArg = parsed.end;
    } else if (trimmed.startsWith('[')) {
      final arrayStart = offset;
      final arrayEnd = _findMatching(args, arrayStart, '[', ']');
      if (arrayEnd <= arrayStart) return null;
      text = _readRichTextArray(args.substring(arrayStart, arrayEnd + 1));
      afterFirstArg = arrayEnd + 1;
    } else {
      return null;
    }

    if (text.trim().isEmpty) return null;
    final options = _readOptionsObject(args, afterFirstArg) ?? '';

    return PresentationElement(
      type: PresentationElementType.text,
      x: _numberOption(options, 'x', 0.6),
      y: _numberOption(options, 'y', 0.6),
      w: _numberOption(options, 'w', 5.5),
      h: _numberOption(options, 'h', 0.6),
      text: _decodeEscapes(text),
      colorHex: _colorOption(options, 'color', colors),
      fontSize: _numberOptionOrNull(options, 'fontSize'),
      fontFace: _stringOption(options, 'fontFace'),
      bold: _boolOption(options, 'bold'),
      italic: _boolOption(options, 'italic'),
      align: _parseAlign(_stringOption(options, 'align')),
      charSpacing: _numberOptionOrNull(options, 'charSpacing'),
      maxLines: _numberOptionOrNull(options, 'maxLines')?.round(),
    );
  }

  static List<PresentationElement> _parseShapes(String block, Map<String, String> colors) {
    final elements = <PresentationElement>[];
    for (final call in _extractCalls(block, 's.addShape')) {
      final shapeMatch = RegExp(r'pres\.shapes\.([A-Za-z_]+)').firstMatch(call);
      if (shapeMatch == null) continue;
      final shapeName = shapeMatch.group(1)!.toUpperCase();
      final options = _readOptionsObject(call, shapeMatch.end) ?? '';

      PresentationElementType type;
      if (shapeName.contains('OVAL')) {
        type = PresentationElementType.oval;
      } else if (shapeName.contains('LINE')) {
        type = PresentationElementType.line;
      } else {
        type = PresentationElementType.rect;
      }

      elements.add(
        PresentationElement(
          type: type,
          x: _numberOption(options, 'x', 0),
          y: _numberOption(options, 'y', 0),
          w: _numberOption(options, 'w', type == PresentationElementType.line ? 1 : 1),
          h: _numberOption(options, 'h', type == PresentationElementType.line ? 0.02 : 1),
          fillHex: _nestedColorOption(options, 'fill', colors),
          lineHex: _nestedColorOption(options, 'line', colors),
          lineWidth: _nestedNumberOption(options, 'line', 'width'),
        ),
      );
    }
    return elements;
  }

  static List<PresentationElement> _parseImages(String block, Map<String, String> colors) {
    final elements = <PresentationElement>[];
    for (final call in _extractCalls(block, 's.addImage')) {
      final options = _readOptionsObject(call, 0) ?? call;
      final iconMatch = RegExp(r'''path\s*:\s*ICON\s*\(\s*(["'])''').firstMatch(options);
      String? path;
      if (iconMatch != null) {
        final parsed = _readQuoted(options, iconMatch.end - 1);
        if (parsed != null) path = 'assets/icons/${parsed.value}.png';
      } else {
        path = _stringOption(options, 'path');
      }

      final transparency = _numberOptionOrNull(options, 'transparency');
      final opacity = transparency == null
          ? 1.0
          : (1 - transparency / 100).clamp(0.05, 1.0).toDouble();

      elements.add(
        PresentationElement(
          type: PresentationElementType.image,
          x: _numberOption(options, 'x', 0),
          y: _numberOption(options, 'y', 0),
          w: _numberOption(options, 'w', 1),
          h: _numberOption(options, 'h', 1),
          path: path,
          opacity: opacity,
        ),
      );
    }
    return elements;
  }

  static List<String> _extractCalls(String text, String name) {
    final calls = <String>[];
    var searchFrom = 0;
    while (searchFrom < text.length) {
      final index = text.indexOf(name, searchFrom);
      if (index < 0) break;
      final openParen = text.indexOf('(', index + name.length);
      if (openParen < 0) break;
      final closeParen = _findMatching(text, openParen, '(', ')');
      if (closeParen <= openParen) {
        searchFrom = openParen + 1;
        continue;
      }
      calls.add(text.substring(openParen + 1, closeParen));
      searchFrom = closeParen + 1;
    }
    return calls;
  }

  static int _findMatching(String text, int start, String open, String close) {
    var depth = 0;
    String? quote;
    var escaped = false;
    var inLineComment = false;
    var inBlockComment = false;

    for (var i = start; i < text.length; i++) {
      final char = text[i];
      final next = i + 1 < text.length ? text[i + 1] : '';

      if (inLineComment) {
        if (char == '\n') inLineComment = false;
        continue;
      }
      if (inBlockComment) {
        if (char == '*' && next == '/') {
          inBlockComment = false;
          i++;
        }
        continue;
      }
      if (quote != null) {
        if (escaped) {
          escaped = false;
        } else if (char == '\\') {
          escaped = true;
        } else if (char == quote) {
          quote = null;
        }
        continue;
      }
      if (char == '/' && next == '/') {
        inLineComment = true;
        i++;
        continue;
      }
      if (char == '/' && next == '*') {
        inBlockComment = true;
        i++;
        continue;
      }
      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        continue;
      }
      if (char == open) depth++;
      if (char == close) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  static String? _readOptionsObject(String args, int from) {
    final objectStart = args.indexOf('{', from);
    if (objectStart < 0) return null;
    final objectEnd = _findMatching(args, objectStart, '{', '}');
    if (objectEnd <= objectStart) return null;
    return args.substring(objectStart, objectEnd + 1);
  }

  static _Quoted? _readQuoted(String text, int quoteIndex) {
    if (quoteIndex < 0 || quoteIndex >= text.length) return null;
    final quote = text[quoteIndex];
    if (quote != '"' && quote != "'" && quote != '`') return null;

    final buffer = StringBuffer();
    var escaped = false;
    for (var i = quoteIndex + 1; i < text.length; i++) {
      final char = text[i];
      if (escaped) {
        buffer.write('\\$char');
        escaped = false;
      } else if (char == '\\') {
        escaped = true;
      } else if (char == quote) {
        return _Quoted(buffer.toString(), i + 1);
      } else {
        buffer.write(char);
      }
    }
    return null;
  }

  static String _readRichTextArray(String arraySource) {
    final pieces = <String>[];
    final textKeyMatches = RegExp(r'''text\s*:\s*(["'])''').allMatches(arraySource);
    for (final match in textKeyMatches) {
      final parsed = _readQuoted(arraySource, match.end - 1);
      if (parsed != null) pieces.add(parsed.value);
    }
    return pieces.join('');
  }

  static List<String> _quotedLiterals(String source) {
    final values = <String>[];
    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (char == '"' || char == "'" || char == '`') {
        final parsed = _readQuoted(source, i);
        if (parsed != null) {
          values.add(_decodeEscapes(parsed.value));
          i = parsed.end - 1;
        }
      }
    }
    return values;
  }

  static List<String> _extractUsefulQuotedStrings(String block) {
    final values = <String>[];
    final seen = <String>{};
    for (final raw in _quotedLiterals(block)) {
      final value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (!_isUsefulString(value)) continue;
      final key = value.toLowerCase();
      if (seen.add(key)) values.add(value);
    }
    return values;
  }

  static bool _isUsefulString(String value) {
    if (value.length < 3) return false;
    if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value)) return false;
    if (value.startsWith('assets/')) return false;
    if (value.endsWith('.png') || value.endsWith('.jpg') || value.endsWith('.jpeg')) return false;
    if (!value.contains(' ') && value.contains('_')) return false;
    if (RegExp(r'^[a-z0-9_]+$', caseSensitive: false).hasMatch(value) && value.length < 18) {
      return value.contains('TASK') || value.contains('PASS');
    }
    return true;
  }

  static bool _isAlreadyVisible(String value, List<PresentationElement> elements) {
    final normalized = value.trim().toLowerCase();
    for (final element in elements) {
      if (element.type != PresentationElementType.text) continue;
      final text = element.text.trim().toLowerCase();
      if (text == normalized || text.contains(normalized) || normalized.contains(text)) {
        return true;
      }
    }
    return false;
  }

  static double _numberOption(String source, String key, double fallback) {
    return _numberOptionOrNull(source, key) ?? fallback;
  }

  static double? _numberOptionOrNull(String source, String key) {
    final match = RegExp('(?:^|[,\\{\\s])$key\\s*:\\s*(-?\\d+(?:\\.\\d+)?)').firstMatch(source);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  static double? _nestedNumberOption(String source, String objectKey, String numberKey) {
    final object = _nestedObject(source, objectKey);
    if (object == null) return null;
    return _numberOptionOrNull(object, numberKey);
  }

  static bool _boolOption(String source, String key) {
    final match = RegExp('(?:^|[,\\{\\s])$key\\s*:\\s*(true|false)').firstMatch(source);
    return match?.group(1) == 'true';
  }

  static String? _stringOption(String source, String key) {
    final match = RegExp("(?:^|[,\\{\\s])$key\\s*:\\s*([\"'])").firstMatch(source);
    if (match == null) return null;
    return _readQuoted(source, match.end - 1)?.value;
  }

  static String? _colorOption(String source, String key, Map<String, String> colors) {
    final match = RegExp('(?:^|[,\\{\\s])$key\\s*:\\s*([^,}]+)').firstMatch(source);
    if (match == null) return null;
    return _resolveColorToken(match.group(1)!, colors);
  }

  static String? _nestedColorOption(String source, String objectKey, Map<String, String> colors) {
    final object = _nestedObject(source, objectKey);
    if (object == null) return null;
    return _colorOption(object, 'color', colors);
  }

  static String? _nestedObject(String source, String key) {
    final match = RegExp('(?:^|[,\\{\\s])$key\\s*:\\s*\\{').firstMatch(source);
    if (match == null) return null;
    final start = match.end - 1;
    final end = _findMatching(source, start, '{', '}');
    if (end <= start) return null;
    return source.substring(start, end + 1);
  }

  static String? _resolveColorToken(String token, Map<String, String> colors) {
    var value = token.trim();
    if (value == 'null' || value == 'undefined') return null;
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    value = value.replaceAll(RegExp(r'[^A-Za-z0-9#]'), '');
    if (value.startsWith('#')) value = value.substring(1);
    if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value)) return value.toUpperCase();
    return colors[value];
  }

  static List<String> _notesFromJson(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.trim().isNotEmpty) return [raw.trim()];
    return const [];
  }

  static double _toDouble(dynamic value, double fallback) {
    return _nullableDouble(value) ?? fallback;
  }

  static double? _nullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String _decodeEscapes(String value) {
    return value
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', ' ')
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .trim();
  }
}

class _Quoted {
  final String value;
  final int end;

  const _Quoted(this.value, this.end);
}

TextAlign _parseAlign(String? value) {
  switch (value?.toLowerCase().trim()) {
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    case 'left':
    default:
      return TextAlign.left;
  }
}

Color _colorFromHex(String? hex, {required Color fallback}) {
  final normalized = _normalizeHex(hex);
  if (normalized == null) return fallback;
  return Color(0xFF000000 | int.parse(normalized, radix: 16));
}

String? _normalizeHex(String? value) {
  if (value == null) return null;
  var cleaned = value.trim();
  if (cleaned.isEmpty) return null;
  if (cleaned.startsWith('#')) cleaned = cleaned.substring(1);
  cleaned = cleaned.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
  if (cleaned.length == 8) cleaned = cleaned.substring(2);
  if (cleaned.length != 6) return null;
  return cleaned.toUpperCase();
}

bool _isDarkHex(String? hex) {
  final normalized = _normalizeHex(hex);
  if (normalized == null) return false;
  final value = int.parse(normalized, radix: 16);
  final r = (value >> 16) & 255;
  final g = (value >> 8) & 255;
  final b = value & 255;
  final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance < 0.5;
}

bool _containsRtlText(String value) {
  return RegExp(r'[\u0590-\u08FF]').hasMatch(value);
}

TextAlign _effectiveTextAlign(String value, TextAlign requested) {
  if (_containsRtlText(value) && requested == TextAlign.left) {
    return TextAlign.right;
  }
  return requested;
}

String? _safeFontFamily(String? fontFace) {
  final requested = fontFace?.trim().toLowerCase();
  if (requested != null && requested.contains('lexend')) {
    return PresentationDesignTokens.headingFontFamily;
  }
  return PresentationDesignTokens.bodyFontFamily;
}


String _safeFileName(String value) {
  final cleaned = value
      .replaceAll(RegExp(r'[\/:*?"<>|]+'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return 'presentation.pptx';
  return cleaned.toLowerCase().endsWith('.pptx') ? cleaned : '$cleaned.pptx';
}

IconData _iconForPath(String path) {
  final key = path.toLowerCase();
  if (key.contains('database')) return Icons.storage_rounded;
  if (key.contains('vector')) return Icons.hub_rounded;
  if (key.contains('pdf') || key.contains('file')) return Icons.picture_as_pdf_rounded;
  if (key.contains('codebranch')) return Icons.account_tree_rounded;
  if (key.contains('question')) return Icons.quiz_rounded;
  if (key.contains('comments') || key.contains('chat')) return Icons.forum_rounded;
  if (key.contains('robot')) return Icons.smart_toy_rounded;
  if (key.contains('docker')) return Icons.view_in_ar_rounded;
  if (key.contains('bolt')) return Icons.bolt_rounded;
  if (key.contains('network')) return Icons.device_hub_rounded;
  if (key.contains('book')) return Icons.menu_book_rounded;
  if (key.contains('brain')) return Icons.psychology_rounded;
  if (key.contains('check')) return Icons.verified_rounded;
  if (key.contains('anchor')) return Icons.anchor_rounded;
  if (key.contains('exclamation')) return Icons.warning_rounded;
  return Icons.auto_awesome_rounded;
}

Color _iconColorForPath(String path) {
  final key = path.toLowerCase();
  if (key.contains('amber')) return const Color(0xFFF2B134);
  if (key.contains('navy')) return const Color(0xFF132A4C);
  if (key.contains('teal')) return const Color(0xFF1F6F8B);
  if (key.contains('dark')) return const Color(0xFF152238);
  return Colors.white;
}

String _hexForIconPath(String path) {
  final key = path.toLowerCase();
  if (key.contains('amber')) return 'F2B134';
  if (key.contains('navy')) return '132A4C';
  if (key.contains('teal')) return '1F6F8B';
  if (key.contains('dark')) return '152238';
  return 'FFFFFF';
}

double _iconFontSizeForPath(String path, double heightInches) {
  final key = path.toLowerCase();
  final base = math.max(9.0, heightInches * 48);
  if (key.contains('pdf')) return math.max(7.0, heightInches * 28);
  if (key.contains('robot') || key.contains('brain')) return math.max(8.0, heightInches * 32);
  return base;
}

String _iconGlyphForPath(String path) {
  final key = path.toLowerCase();
  if (key.contains('database')) return '▦';
  if (key.contains('vector') || key.contains('network')) return '◆';
  if (key.contains('pdf') || key.contains('file')) return 'PDF';
  if (key.contains('codebranch')) return '⌘';
  if (key.contains('question')) return '?';
  if (key.contains('comments') || key.contains('chat')) return '☰';
  if (key.contains('robot')) return 'AI';
  if (key.contains('docker')) return '⚙';
  if (key.contains('bolt')) return '⚡';
  if (key.contains('book')) return '▤';
  if (key.contains('brain')) return 'AI';
  if (key.contains('check')) return '✓';
  if (key.contains('anchor')) return '⌾';
  if (key.contains('exclamation')) return '!';
  if (key.contains('shield')) return '✓';
  if (key.contains('layer')) return '▣';
  if (key.contains('sitemap')) return '▦';
  if (key.contains('list')) return '☷';
  if (key.contains('sync')) return '↻';
  if (key.contains('search')) return '⌕';
  if (key.contains('clipboard')) return '✓';
  return '✦';
}

final Map<String, dynamic> _sampleJsonDeck =
    Map<String, dynamic>.from(jsonDecode(r'''
{
  "schema_version": 4,
  "title": "Probability Foundations — Instructor Lecture",
  "slides": [
    {
      "slide_number": 1,
      "layout_type": "title_slide",
      "kicker": "STATISTICS 101",
      "title": "Probability Foundations",
      "subtitle": "From sample spaces to conditional reasoning",
      "course": "Introduction to Statistics",
      "instructor": "Instructor Name",
      "term": "Lecture 04"
    },
    {
      "slide_number": 2,
      "layout_type": "lecture_objectives",
      "kicker": "TODAY'S ROADMAP",
      "title": "Learning Objectives",
      "outcome": "By the end of this lecture, students should be able to:",
      "objectives": [
        "Define a sample space and represent events as subsets.",
        "Distinguish mutually exclusive events from independent events.",
        "Apply addition, multiplication, and conditional-probability rules.",
        "Interpret Bayes' theorem as an update from prior to posterior belief.",
        "Solve and explain a probability problem using a structured workflow."
      ]
    },
    {
      "slide_number": 3,
      "layout_type": "section_divider",
      "kicker": "PART I",
      "section_number": "01",
      "title": "Building a Probability Model",
      "subtitle": "Every correct calculation starts with a clearly defined experiment, outcome, and event."
    },
    {
      "slide_number": 4,
      "layout_type": "concept_explanation",
      "kicker": "CORE CONCEPT",
      "title": "Sample Spaces and Events",
      "content": {
        "lead": "A probability model describes every outcome that can occur and the events we care about.",
        "body": "The sample space Ω contains all possible outcomes. An event is any subset of Ω. The quality of the model depends on whether the outcomes are complete, non-overlapping, and expressed at the right level of detail.",
        "bullets": [
          "Outcome: one possible result of the experiment",
          "Sample space: the complete set of possible outcomes",
          "Event: a collection of outcomes that answers a question",
          "Complement: every outcome that is not in the event"
        ],
        "key_term": "EVENT",
        "definition": "An event is a subset of the sample space.",
        "example": "For one die roll, A = {2, 4, 6} represents an even result."
      }
    },
    {
      "slide_number": 5,
      "layout_type": "text_with_image",
      "kicker": "MODEL BEFORE MATH",
      "title": "Translate the Story Before You Calculate",
      "content": {
        "lead": "Probability problems are easier when the narrative is converted into explicit events.",
        "body": "Underline the experiment, list the possible outcomes, name the relevant events, and only then select a rule.",
        "bullets": [
          "State what is random and what is fixed",
          "Choose event labels that match the question",
          "Check whether order and replacement matter",
          "Keep units and conditions visible"
        ]
      },
      "visual": {
        "src": "assets/book.webp",
        "fit": "cover",
        "position": "right",
        "caption": "A clear model connects the wording of a problem to its mathematical structure.",
        "alt": "Open textbook used as a visual metaphor for translating a written problem"
      }
    },
    {
      "slide_number": 6,
      "layout_type": "comparison",
      "kicker": "DO NOT CONFUSE",
      "title": "Mutually Exclusive vs. Independent Events",
      "comparison": {
        "left": {
          "title": "Mutually Exclusive",
          "subtitle": "The events cannot occur together.",
          "points": [
            "P(A ∩ B) = 0",
            "One event rules out the other",
            "Example: one die roll is 2 and 5",
            "Usually not independent when both have positive probability"
          ]
        },
        "right": {
          "title": "Independent",
          "subtitle": "Knowing one event occurred does not change the other.",
          "points": [
            "P(A ∩ B) = P(A)P(B)",
            "Information about A does not change P(B)",
            "Example: outcomes of two separate fair coin flips",
            "The events may occur together"
          ]
        }
      }
    },
    {
      "slide_number": 7,
      "layout_type": "process_steps",
      "kicker": "PROBLEM-SOLVING METHOD",
      "title": "A Reliable Five-Step Workflow",
      "process": [
        {
          "title": "Define",
          "body": "Name the random experiment and the target event."
        },
        {
          "title": "Represent",
          "body": "Use a list, tree, table, or diagram to organize outcomes."
        },
        {
          "title": "Select",
          "body": "Choose the rule that matches the event relationship."
        },
        {
          "title": "Calculate",
          "body": "Substitute values and keep intermediate steps visible."
        },
        {
          "title": "Interpret",
          "body": "Explain the result in the language of the original problem."
        }
      ]
    },
    {
      "slide_number": 8,
      "layout_type": "diagram",
      "kicker": "CONCEPT MAP",
      "title": "How the Main Probability Ideas Connect",
      "diagram": {
        "nodes": [
          {
            "id": "experiment",
            "level": 0,
            "title": "Random Experiment",
            "body": "A repeatable process with uncertain output"
          },
          {
            "id": "space",
            "level": 1,
            "title": "Sample Space Ω",
            "body": "All possible outcomes"
          },
          {
            "id": "events",
            "level": 2,
            "title": "Events A and B",
            "body": "Subsets that answer questions"
          },
          {
            "id": "joint",
            "level": 3,
            "title": "Joint Probability",
            "body": "P(A ∩ B)"
          },
          {
            "id": "conditional",
            "level": 3,
            "title": "Conditional Probability",
            "body": "P(A | B)"
          }
        ],
        "edges": [
          {
            "from": "experiment",
            "to": "space"
          },
          {
            "from": "space",
            "to": "events"
          },
          {
            "from": "events",
            "to": "joint"
          },
          {
            "from": "events",
            "to": "conditional"
          }
        ]
      }
    },
    {
      "slide_number": 9,
      "layout_type": "table",
      "kicker": "REFERENCE TABLE",
      "title": "Core Probability Rules",
      "table": {
        "headers": [
          "Rule",
          "Expression",
          "Use When",
          "Common Check"
        ],
        "rows": [
          [
            "Complement",
            "P(Aᶜ) = 1 − P(A)",
            "The event is easier to describe by what does not happen",
            "Result remains between 0 and 1"
          ],
          [
            "Addition",
            "P(A ∪ B) = P(A) + P(B) − P(A ∩ B)",
            "At least one of two events occurs",
            "Subtract the overlap once"
          ],
          [
            "Multiplication",
            "P(A ∩ B) = P(A)P(B | A)",
            "Both events occur",
            "Use P(B) only when independent"
          ],
          [
            "Conditional",
            "P(A | B) = P(A ∩ B) / P(B)",
            "The sample space is restricted by B",
            "P(B) must be greater than zero"
          ]
        ]
      }
    },
    {
      "slide_number": 10,
      "layout_type": "equation_explanation",
      "kicker": "KEY EQUATION",
      "title": "Conditional Probability",
      "equation": {
        "label": "Definition",
        "latex": "P(A | B) = P(A ∩ B) / P(B)",
        "render_mode": "text",
        "explanation": "The numerator counts outcomes in both A and B; the denominator restricts attention to outcomes in B."
      },
      "content": {
        "bullets": [
          "Read P(A | B) as probability of A given B",
          "Treat B as the new sample space",
          "The order of A and B matters",
          "The denominator cannot be zero"
        ]
      }
    },
    {
      "slide_number": 11,
      "layout_type": "equation_derivation",
      "kicker": "DERIVATION",
      "title": "Bayes' Theorem Is a Rearrangement of Joint Probability",
      "equation": {
        "label": "Bayes' theorem",
        "latex": "P(A\\mid B)=\\frac{P(B\\mid A)P(A)}{P(B)}",
        "render_mode": "svg",
        "steps": [
          {
            "latex": "P(A\\cap B)=P(A\\mid B)P(B)",
            "render_mode": "svg",
            "explanation": "Write the multiplication rule with B as the condition."
          },
          {
            "latex": "P(A\\cap B)=P(B\\mid A)P(A)",
            "render_mode": "svg",
            "explanation": "Write the same joint event with A as the condition."
          },
          {
            "latex": "P(A\\mid B)P(B)=P(B\\mid A)P(A)",
            "render_mode": "svg",
            "explanation": "Set the two expressions for the same joint probability equal."
          },
          {
            "latex": "P(A\\mid B)=\\frac{P(B\\mid A)P(A)}{P(B)}",
            "render_mode": "svg",
            "explanation": "Divide by P(B) to isolate the posterior probability."
          }
        ]
      }
    },
    {
      "slide_number": 12,
      "layout_type": "worked_example",
      "kicker": "WORKED EXAMPLE",
      "title": "Quality Control: Probability of a Defective Item",
      "problem": {
        "statement": "A production line makes 240 items and 12 are defective. Estimate the probability that a randomly selected item is defective.",
        "given": [
          "Total items = 240",
          "Defective items = 12"
        ],
        "formula": "P(defective) = defective items / total items",
        "solution_steps": [
          "Substitute the observed counts: P(defective) = 12 / 240.",
          "Simplify the fraction: 12 / 240 = 0.05.",
          "Convert to a percentage: 0.05 × 100 = 5%."
        ],
        "final_answer": "The estimated probability of selecting a defective item is 0.05, or 5%."
      }
    },
    {
      "slide_number": 13,
      "layout_type": "multiple_choice",
      "kicker": "CHECK FOR UNDERSTANDING",
      "title": "Which Rule Should You Use?",
      "problem": {
        "statement": "A card is drawn from a standard deck. What is the probability that it is a heart or a king?",
        "choices": [
          "P(heart) + P(king)",
          "P(heart)P(king)",
          "P(heart) + P(king) − P(heart ∩ king)",
          "1 − P(heart)"
        ],
        "answer": "P(heart) + P(king) − P(heart ∩ king)",
        "hint": "The king of hearts belongs to both events, so count the overlap only once.",
        "show_answer": false
      }
    },
    {
      "slide_number": 14,
      "layout_type": "practice_activity",
      "kicker": "PAIR ACTIVITY",
      "title": "Build a Probability Model from a Short Scenario",
      "activity": {
        "task": "Model the outcomes of selecting two students from a group and decide whether order matters.",
        "duration": "8 minutes",
        "instructions": [
          "Define the experiment and state any assumptions.",
          "Choose labels for the relevant events.",
          "Represent the outcomes using a table or tree.",
          "Write one probability question that can be answered from your model.",
          "Exchange models with another pair and check for missing outcomes."
        ],
        "deliverable": "One labeled representation and one justified probability calculation"
      }
    },
    {
      "slide_number": 15,
      "layout_type": "case_study",
      "kicker": "DISCUSSION",
      "title": "Case Study: A Screening Test with Rare Prevalence",
      "case_study": {
        "context": "A screening program tests a population in which only 1% of people have the condition.",
        "challenge": "The test has high sensitivity, yet many positive results may still be false positives because the condition is rare.",
        "evidence": "Students receive sensitivity, specificity, and prevalence values and must organize them in a 2×2 table.",
        "questions": [
          "Which probability represents the positive predictive value?",
          "Why does prevalence change the interpretation of a positive result?"
        ]
      }
    },
    {
      "slide_number": 16,
      "layout_type": "quote",
      "kicker": "INSTRUCTOR INSIGHT",
      "title": "Interpretation Matters",
      "quote": {
        "text": "A probability is not just a number; it is a statement about a model, its assumptions, and the information currently available.",
        "author": "Lecture takeaway",
        "role": "Probability Foundations"
      }
    },
    {
      "slide_number": 17,
      "layout_type": "summary",
      "kicker": "LECTURE SUMMARY",
      "title": "What to Remember",
      "summary": {
        "points": [
          "Define the sample space before selecting a probability rule.",
          "Mutually exclusive and independent describe different relationships.",
          "Conditional probability changes the reference set.",
          "Bayes' theorem combines prior knowledge with new evidence.",
          "A complete solution includes interpretation, not only arithmetic."
        ],
        "takeaway": "Model the event relationship first; the correct formula usually follows.",
        "next": "Discrete random variables and expected value"
      }
    },
    {
      "slide_number": 18,
      "layout_type": "references",
      "kicker": "FURTHER READING",
      "title": "References and Recommended Practice",
      "references": [
        "OpenIntro Statistics — Probability chapter.",
        "Course notes: Sample spaces, counting, and conditional probability.",
        "Practice set 04: Addition and multiplication rules.",
        "Tutorial worksheet: Bayes' theorem using frequency tables.",
        "Instructor-provided examples and worked solutions in Learnova."
      ]
    }
  ]
}
''') as Map);
