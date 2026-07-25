import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_theme.dart';
import 'package:learnova/core/ui/toast.dart';
import 'package:learnova/core/utils/image_picker_bytes.dart';
import 'package:learnova/features/instructor/data/courses_models.dart';
import 'package:learnova/features/instructor/data/course_vocabulary.dart';
import 'package:learnova/features/instructor/data/learning_outcomes_models.dart';

class CreateCourseDialogResult {
  final CourseCreateRequest request;
  final bool needsInvites;
  final List<LearningOutcome> learningOutcomes;
  final List<int>? coverBytes;
  final String? coverContentType;
  final String? coverFilename;

  const CreateCourseDialogResult({
    required this.request,
    required this.needsInvites,
    required this.learningOutcomes,
    this.coverBytes,
    this.coverContentType,
    this.coverFilename,
  });
}

enum _PublishChoice    { published, draft }
enum _VisibilityChoice { publicCourse, privateCourse }

class CreateCourseDialog extends StatefulWidget {
  const CreateCourseDialog({super.key});
  @override
  State<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<CreateCourseDialog> {
  final _titleCtrl = TextEditingController();
  final _codeCtrl  = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  _PublishChoice    _publish    = _PublishChoice.draft;
  _VisibilityChoice _visibility = _VisibilityChoice.privateCourse;

  String? _titleError;
  String? _codeError;
  String? _categoryError;
  bool _titleTouched = false;
  bool _codeTouched  = false;
  bool _categoryTouched = false;

  final List<LearningOutcome> _outcomes = [];
  PickedBrowserFile? _coverFile;

  static final _codeRx = RegExp(r'^[A-Za-z0-9][A-Za-z0-9\-_\/ ]*$');

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onTitleChanged);
    _codeCtrl.addListener(_onCodeChanged);
    _categoryCtrl.addListener(_onCategoryChanged);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _codeCtrl.removeListener(_onCodeChanged);
    _categoryCtrl.removeListener(_onCategoryChanged);
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (!_titleTouched) return;
    _validateTitle();
  }

  void _onCodeChanged() {
    if (!_codeTouched) return;
    _validateCode();
  }

  void _onCategoryChanged() {
    if (!_categoryTouched) return;
    _validateCategory();
  }

  void _validateTitle() {
    final title = _titleCtrl.text.trim();
    String? err;
    if (title.isEmpty) {
      err = 'Course title is required.';
    } else if (title.length > 255) {
      err = 'Course title must be 255 characters or less.';
    }
    if (err == _titleError) return;
    if (mounted) setState(() => _titleError = err);
  }

  void _validateCode() {
    final c = _codeCtrl.text.trim();
    String? err;
    if (c.isNotEmpty) {
      if (c.length < 2 || c.length > 50) {
        err = 'Course code must be 2–50 characters.';
      } else if (!_codeRx.hasMatch(c)) {
        err = 'Use letters/numbers and - _ / only.';
      }
    }
    if (err == _codeError) return;
    if (mounted) setState(() => _codeError = err);
  }

  void _validateCategory() {
    final category = _categoryCtrl.text.trim();
    final err = category.length > 100 ? 'Category must be 100 characters or less.' : null;
    if (err == _categoryError) return;
    if (mounted) setState(() => _categoryError = err);
  }

  void _validateAll() {
    setState(() {
      _titleTouched = true;
      _codeTouched = true;
      _categoryTouched = true;
    });
    _validateTitle();
    _validateCode();
    _validateCategory();
  }

  bool get _canSubmit =>
      _titleCtrl.text.trim().isNotEmpty &&
      _titleError == null &&
      _codeError == null &&
      _categoryError == null;

  String? _coverValidationError(PickedBrowserFile file) {
    final contentType = (file.mimeType ?? '').trim().toLowerCase();
    final name = (file.name ?? '').trim().toLowerCase();
    final isAllowed = contentType == 'image/png' ||
        contentType == 'image/jpeg' ||
        contentType == 'image/jpg' ||
        name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg');

    if (!isAllowed) return 'Course cover must be PNG or JPG.';
    if (file.bytes.length > 5 * 1024 * 1024) {
      return 'Course cover must be 5MB or smaller.';
    }
    return null;
  }

  Future<void> _pickCover() async {
    try {
      final file = await pickSingleImageFile(
        accept: const ['image/png', 'image/jpeg', 'image/jpg'],
      );
      if (!mounted || file == null) return;

      final error = _coverValidationError(file);
      if (error != null) {
        AppToast.error(context, title: 'Invalid cover image', message: error);
        return;
      }

      setState(() => _coverFile = file);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Upload unavailable',
        message: 'Could not open the image picker in this browser.',
      );
    }
  }

  void _removeCover() {
    setState(() => _coverFile = null);
  }

  void _submit() {
    _validateAll();
    if (!_canSubmit) {
      AppToast.error(context, title: 'Validation Error',
          message: _titleError ?? _codeError ?? _categoryError ?? 'Fix highlighted fields.',);
      return;
    }
    final isPublic = _visibility == _VisibilityChoice.publicCourse;
    final status = (_publish == _PublishChoice.published
            ? CourseLifecycleStatus.published
            : CourseLifecycleStatus.draft)
        .backendValue;
    final request  = CourseCreateRequest(
      courseType: CourseAccessType.individual.backendValue,
      organizationId: null,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      coverImageUrl: null,
      bannerImageUrl: null,
      isPublic: isPublic,
      visibilityLevel: (isPublic ? CourseVisibility.public : CourseVisibility.private).backendValue,
      requiresEnrollmentApproval: !isPublic,
      learningOutcomes: _outcomes.map((o) => '${o.code}: ${o.description}').toList(),
      tags: [],
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      status: status,
      courseCode: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      localStatus: status,
    );
    Navigator.of(context).pop(CreateCourseDialogResult(
      request: request,
      needsInvites: !isPublic,
      learningOutcomes: _outcomes,
      coverBytes: _coverFile?.bytes,
      coverContentType: _coverFile?.mimeType,
      coverFilename: _coverFile?.name,
    ),);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final size = MediaQuery.of(context).size;
    final maxW = size.width < 860 ? size.width * 0.96 : 820.0;
    final maxH = size.height * 0.92;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                const BoxShadow(color: Color(0x22000000), blurRadius: 40, offset: Offset(0, 16)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                    child: Column(
                      children: [
                        _buildCourseDetailsCard(),
                        const SizedBox(height: 16),
                        _buildBottomRow(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: AppColors.headerBg)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              border: Border.all(color: AppColors.badgeBlueBg),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_box_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Course',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: AppColors.textTitle,),),
                const SizedBox(height: 1),
                Text('Fill in the details to set up a new learning module.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),),
              ],
            ),
          ),
          _HoverIconBtn(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── Course Details card ───────────────────────────────────────────────────
  Widget _buildCourseDetailsCard() {
    return _SectionCard(
      icon: Icons.article_outlined,
      title: 'Course Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Title
          _buildFieldLabel('Course Title', required: true),
          const SizedBox(height: 6),
          _TitledInputWithError(
            controller: _titleCtrl,
            hint: 'e.g. Introduction to Artificial Intelligence',
            prefixIcon: Icons.school_outlined,
            error: _titleError,
            onBlur: () {
              if (!_titleTouched) setState(() => _titleTouched = true);
              _validateTitle();
            },
          ),
          const SizedBox(height: 16),

          // Code + Category row
          _ResponsiveTwoColumn(
            spacing: 14,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Course Code', optional: true),
                const SizedBox(height: 6),
                _TitledInputWithError(
                  controller: _codeCtrl,
                  hint: 'e.g. CS-101',
                  prefixIcon: Icons.tag_rounded,
                  error: _codeError,
                  onBlur: () {
                    if (!_codeTouched) setState(() => _codeTouched = true);
                    _validateCode();
                  },
                ),
              ],
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Category', optional: true),
                const SizedBox(height: 6),
                _TitledInputWithError(
                  controller: _categoryCtrl,
                  hint: 'e.g. Computer Science',
                  prefixIcon: Icons.category_outlined,
                  error: _categoryError,
                  onBlur: () {
                    if (!_categoryTouched) setState(() => _categoryTouched = true);
                    _validateCategory();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _buildFieldLabel('Course Description', optional: true),
          const SizedBox(height: 6),
          _DescriptionField(controller: _descCtrl),
          const SizedBox(height: 10),

          // AI tip
          Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.badgeBlueBg),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Tip: A detailed description helps generate better quiz questions.',
                    style: TextStyle(fontSize: 12, color: AppColors.primary,
                        fontWeight: FontWeight.w500,),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Config + Cover row ────────────────────────────────────────────────────
  Widget _buildBottomRow() {
    final config = _SectionCard(
      icon: Icons.tune_rounded,
      title: 'Configuration',
      child: _ConfigSection(
        publish: _publish,
        visibility: _visibility,
        onPublishChanged: (v) => setState(() => _publish = v),
        onVisibilityChanged: (v) => setState(() => _visibility = v),
      ),
    );

    final cover = _SectionCard(
      icon: Icons.image_outlined,
      title: 'Course Cover',
      badge: 'Optional',
      child: _CoverUpload(
        file: _coverFile,
        onPick: _pickCover,
        onRemove: _removeCover,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              config,
              const SizedBox(height: 14),
              cover,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: config),
            const SizedBox(width: 14),
            SizedBox(width: 240, child: cover),
          ],
        );
      },
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppColors.headerBg)),
      ),
      child: Row(
        children: [
          const Spacer(),
          _OutlineBtn(label: 'Cancel', onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 10),
          _PrimaryBtn(label: '+ Create Course', onTap: _canSubmit ? _submit : null),
        ],
      ),
    );
  }

  // ── Helper: field label ───────────────────────────────────────────────────
  Widget _buildFieldLabel(String label, {bool required = false, bool optional = false}) {
    return Row(
      children: [
        Text(label,
            style: AppText.label.copyWith(fontSize: 13, fontWeight: FontWeight.w600),),
        if (required)
          const Text(' *',
              style: TextStyle(fontSize: 13, color: AppColors.errorDot, fontWeight: FontWeight.w600),),
        if (optional) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Optional',
                style: TextStyle(fontSize: 10.5, color: AppColors.primary,
                    fontWeight: FontWeight.w600,),),
          ),
        ],
      ],
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final String? badge;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  border: Border.all(color: AppColors.badgeBlueBg),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textTitle,),),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: Colors.white,),),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.headerBg),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}


class _ResponsiveTwoColumn extends StatelessWidget {
  final Widget first;
  final Widget second;
  final double spacing;

  const _ResponsiveTwoColumn({
    required this.first,
    required this.second,
    this.spacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              first,
              SizedBox(height: spacing),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            SizedBox(width: spacing),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

// ── Input with error display (uses AppLabeledTextField internals) ─────────────
class _TitledInputWithError extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final String? error;
  final VoidCallback? onBlur;

  const _TitledInputWithError({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.error,
    this.onBlur,
  });

  @override
  State<_TitledInputWithError> createState() => _TitledInputWithErrorState();
}

class _TitledInputWithErrorState extends State<_TitledInputWithError> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!mounted) return;
      final hasFocus = _focus.hasFocus;
      setState(() => _focused = hasFocus);
      if (!hasFocus) widget.onBlur?.call();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final hasErr = (widget.error ?? '').isNotEmpty;
    final borderColor = hasErr
        ? AppColors.errorDot
        : _focused
            ? AppColors.primary
            : AppColors.borderSoft;
    final borderWidth = _focused && !hasErr ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hasErr ? AppColors.dangerBg : AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(widget.prefixIcon, size: 16,
                    color: hasErr
                        ? AppColors.errorDot
                        : _focused
                            ? AppColors.primary
                            : AppColors.muted,),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  style: AppText.input,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppText.hint,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasErr) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 12, color: AppColors.errorDot),
              const SizedBox(width: 4),
              Text(widget.error!,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.errorDot,
                      fontWeight: FontWeight.w500,),),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Description field (toolbar + textarea) ────────────────────────────────────
class _DescriptionField extends StatefulWidget {
  final TextEditingController controller;
  const _DescriptionField({required this.controller});
  @override
  State<_DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<_DescriptionField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focused ? AppColors.primary : AppColors.borderSoft,
          width: _focused ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Column(
          children: [
            // Toolbar
            Container(
              height: 38,
              color: AppColors.surfaceBg,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Row(
                children: [
                  _TbBtn(icon: Icons.format_bold_rounded),
                  _TbBtn(icon: Icons.format_italic_rounded),
                  _TbBtn(icon: Icons.format_list_bulleted_rounded),
                  _TbBtn(icon: Icons.link_rounded),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.headerBg),
            // Text area
            SizedBox(
              height: 110,
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focus,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppText.input.copyWith(height: 1.55),
                decoration: InputDecoration(
                  hintText: 'Enter a detailed description of the course content, objectives, and prerequisites...',
                  hintStyle: AppText.hint.copyWith(height: 1.55),
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TbBtn extends StatefulWidget {
  final IconData icon;
  const _TbBtn({required this.icon});
  @override
  State<_TbBtn> createState() => _TbBtnState();
}

class _TbBtnState extends State<_TbBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: _h ? AppColors.border : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(child: Icon(widget.icon, size: 16, color: _h ? AppColors.text : AppColors.muted)),
    ),
  );
}

// ── Config section ────────────────────────────────────────────────────────────
class _ConfigSection extends StatelessWidget {
  final _PublishChoice publish;
  final _VisibilityChoice visibility;
  final ValueChanged<_PublishChoice> onPublishChanged;
  final ValueChanged<_VisibilityChoice> onVisibilityChanged;

  const _ConfigSection({
    required this.publish,
    required this.visibility,
    required this.onPublishChanged,
    required this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visibility Status',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                color: AppColors.textMuted, letterSpacing: 0.2,),),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _OptionTile(
            title: 'Save as Draft',
            sub: 'Only visible to instructors',
            selected: publish == _PublishChoice.draft,
            onTap: () => onPublishChanged(_PublishChoice.draft),
          ),),
          const SizedBox(width: 8),
          Expanded(child: _OptionTile(
            title: 'Publish Now',
            sub: 'Visible to enrolled students',
            selected: publish == _PublishChoice.published,
            onTap: () => onPublishChanged(_PublishChoice.published),
          ),),
        ],),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _OptionTile(
            title: 'Set as Private',
            sub: 'For specific Student',
            selected: visibility == _VisibilityChoice.privateCourse,
            onTap: () => onVisibilityChanged(_VisibilityChoice.privateCourse),
          ),),
          const SizedBox(width: 8),
          Expanded(child: _OptionTile(
            title: 'Set as Public',
            sub: 'For Public Student',
            selected: visibility == _VisibilityChoice.publicCourse,
            onTap: () => onVisibilityChanged(_VisibilityChoice.publicCourse),
          ),),
        ],),
        if (visibility == _VisibilityChoice.privateCourse) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('You can invite students after creating the course.',
                  style: TextStyle(fontSize: 12, color: AppColors.textTitle),),),
            ],),
          ),
        ],
      ],
    );
  }
}

class _OptionTile extends StatefulWidget {
  final String title, sub;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title, required this.sub,
    required this.selected, required this.onTap,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    const blue = AppColors.primary;
    final blueSoft = AppColors.primarySoft;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: widget.selected ? blueSoft : _h ? AppColors.pageBg : AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected ? blue : AppColors.border,
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Text block (left)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: widget.selected ? blue : AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.sub,
                      style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Radio dot (right) — matches Figma exactly
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.selected ? blue : AppColors.border,
                    width: 2,
                  ),
                  color: AppColors.cardBg,
                ),
                child: widget.selected
                    ? Center(
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: blue, shape: BoxShape.circle,),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cover upload ──────────────────────────────────────────────────────────────
class _CoverUpload extends StatefulWidget {
  final PickedBrowserFile? file;
  final Future<void> Function() onPick;
  final VoidCallback onRemove;

  const _CoverUpload({
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  @override
  State<_CoverUpload> createState() => _CoverUploadState();
}

class _CoverUploadState extends State<_CoverUpload> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final file = widget.file;
    final hasFile = file != null && file.bytes.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onPick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 184,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _h ? AppColors.primarySoft : AppColors.hoverBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _h || hasFile ? AppColors.primary : AppColors.border,
              width: _h || hasFile ? 1.5 : 1,
            ),
          ),
          child: hasFile
              ? _CoverPreview(
                  bytes: Uint8List.fromList(file.bytes),
                  filename: file.name,
                  onReplace: widget.onPick,
                  onRemove: widget.onRemove,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _h ? AppColors.primarySoft : AppColors.headerBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 22,
                        color: _h ? AppColors.primary : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload a file',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _h ? AppColors.primary : AppColors.muted,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or drag and drop',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PNG, JPG up to 5MB',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  final Uint8List bytes;
  final String? filename;
  final Future<void> Function() onReplace;
  final VoidCallback onRemove;

  const _CoverPreview({
    required this.bytes,
    required this.filename,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(bytes, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.58),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (filename ?? 'Course cover').trim().isEmpty
                      ? 'Course cover'
                      : filename!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _TinyCoverAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Replace',
                      onTap: onReplace,
                    ),
                    const SizedBox(width: 6),
                    _TinyCoverAction(
                      icon: Icons.close_rounded,
                      label: 'Remove',
                      onTap: onRemove,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyCoverAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TinyCoverAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hover close button ────────────────────────────────────────────────────────
class _HoverIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HoverIconBtn({required this.icon, required this.onTap});
  @override
  State<_HoverIconBtn> createState() => _HoverIconBtnState();
}

class _HoverIconBtnState extends State<_HoverIconBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: _h ? AppColors.headerBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(widget.icon, size: 18, color: AppColors.muted),
      ),
    ),
  );
}

// ── Buttons ───────────────────────────────────────────────────────────────────
class _PrimaryBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryBtn({required this.label, this.onTap});
  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: !enabled
                ? AppColors.border
                : _h ? const Color(0xFF0E6FD4) : AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(widget.label,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : AppColors.muted,),),
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});
  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: _h ? AppColors.headerBg : AppColors.cardBg,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(widget.label,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                  color: AppColors.text,),),
        ),
      ),
    ),
  );
}
