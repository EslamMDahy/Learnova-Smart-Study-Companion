import 'package:flutter/material.dart';
import 'package:learnova/core/ui/toast.dart';
import 'package:learnova/features/instructor/data/courses_models.dart';

/// Result returned from [CreateCourseDialog].
class CreateCourseDialogResult {
  final CourseCreateRequest request;
  final bool needsInvites;
  const CreateCourseDialogResult({required this.request, required this.needsInvites});
}

// ── Design tokens (مطابق للبروتوتايب) ─────────────────────────────────────────
class _K {
  static const pageBg   = Color(0xFFF6F7F8);
  static const white    = Colors.white;
  static const border   = Color(0xFFE5E7EB);
  static const divider  = Color(0xFFF0F2F4);
  static const text     = Color(0xFF111418);
  static const muted    = Color(0xFF617589);
  static const hint     = Color(0xFF94A3B8);
  static const blue     = Color(0xFF137FEC);
  static const blueSoft = Color(0xFFEFF6FF);
  static const blueBdr  = Color(0xFFDBEAFE);
}

enum _PublishChoice    { published, draft }
enum _VisibilityChoice { publicCourse, privateCourse }

class CreateCourseDialog extends StatefulWidget {
  const CreateCourseDialog({super.key});
  @override
  State<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<CreateCourseDialog> {
  final _title      = TextEditingController();
  final _courseCode = TextEditingController();
  final _term       = TextEditingController();
  final _desc       = TextEditingController();

  _PublishChoice    _publish    = _PublishChoice.draft;
  _VisibilityChoice _visibility = _VisibilityChoice.privateCourse;

  String? _titleError;
  String? _codeError;

  static final _codeRx = RegExp(r'^[A-Za-z0-9][A-Za-z0-9\-_\/ ]*$');

  @override
  void initState() {
    super.initState();
    _title.addListener(_validate);
    _courseCode.addListener(_validate);
  }

  @override
  void dispose() {
    _title.removeListener(_validate);
    _courseCode.removeListener(_validate);
    _title.dispose(); _courseCode.dispose(); _term.dispose(); _desc.dispose();
    super.dispose();
  }

  void _validate() {
    final t = _title.text.trim();
    final c = _courseCode.text.trim();
    final tErr = t.isEmpty ? 'Course title is required.' : null;
    String? cErr;
    if (c.isNotEmpty) {
      if (c.length < 2 || c.length > 31)       cErr = 'Course code must be 2–31 characters.';
      else if (!_codeRx.hasMatch(c))            cErr = 'Use letters/numbers and - _ / only.';
    }
    if (tErr == _titleError && cErr == _codeError) return;
    if (!mounted) return;
    setState(() { _titleError = tErr; _codeError = cErr; });
  }

  bool get _canSubmit => _titleError == null && _codeError == null && _title.text.trim().isNotEmpty;

  void _submit() {
    _validate();
    if (!_canSubmit) {
      AppToast.show(context, title: 'Error', message: _titleError ?? _codeError ?? 'Fix highlighted fields.', icon: Icons.error_rounded);
      return;
    }
    final isPublic = _visibility == _VisibilityChoice.publicCourse;
    final status   = _publish   == _PublishChoice.published ? 'published' : 'draft';
    final request  = CourseCreateRequest(
      courseType: 'individual', organizationId: null,
      title: _title.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      coverImageUrl: null, bannerImageUrl: null,
      isPublic: isPublic, visibilityLevel: isPublic ? 'public' : 'private',
      requiresEnrollmentApproval: !isPublic,
      learningOutcomes: const [], tags: const [], category: null, status: status,
      courseCode: _courseCode.text.trim().isEmpty ? null : _courseCode.text.trim(),
      academicTerm: _term.text.trim().isEmpty ? null : _term.text.trim(),
      localStatus: status,
    );
    Navigator.of(context).pop(CreateCourseDialogResult(request: request, needsInvites: !isPublic));
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxW = size.width < 800 ? size.width * 0.96 : 720.0;
    final maxH = size.height * 0.92;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: Colors.transparent,
      child: Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Container(
          decoration: BoxDecoration(
            color: _K.pageBg,                             // background F6F7F8
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 40, offset: Offset(0, 16))],
          ),
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header ─────────────────────────────────────────────────────
            const Text('Create New Course',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _K.text)),
            const SizedBox(height: 5),
            const Text('Fill in the details below to set up a new learning module for your students. The AI assistant will use this information to generate relevant quizzes.',
              style: TextStyle(fontSize: 12.5, color: _K.muted, height: 1.5)),
            const SizedBox(height: 20),
            // ── Scrollable body ────────────────────────────────────────────
            Flexible(child: SingleChildScrollView(child: Column(children: [
              // Course Details section
              _Section(icon: Icons.article_outlined, title: 'Course Details', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _FormGroup(
                  label: 'Course Title', req: true,
                  child: _Input(controller: _title, hint: 'e.g. Introduction to Artificial Intelligence', error: _titleError, onChanged: (_) => _validate()),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _FormGroup(
                    label: 'Course Code', optional: true,
                    child: _Input(controller: _courseCode, hint: 'e.g. CS-101', error: _codeError, onChanged: (_) => _validate()),
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: _FormGroup(
                    label: 'Academic Term',
                    child: _Dropdown(value: _term.text.isEmpty ? 'Fall 2023' : _term.text, onSelect: (v) => setState(() => _term.text = v)),
                  )),
                ]),
                const SizedBox(height: 14),
                _FormGroup(label: 'Course Description', child: _TextArea(controller: _desc)),
                // AI Tip
                const SizedBox(height: 8),
                Row(children: const [
                  Icon(Icons.auto_awesome_rounded, size: 13, color: _K.blue),
                  SizedBox(width: 6),
                  Text('AI Tip: A detailed description helps generate better quiz questions.',
                    style: TextStyle(fontSize: 11.5, color: _K.blue, fontWeight: FontWeight.w600)),
                ]),
              ])),
              const SizedBox(height: 14),
              // Configuration + Cover side by side (bottom-sections grid)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Configuration
                Expanded(child: _Section(icon: Icons.tune_rounded, title: 'Configuration', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Visibility Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _K.muted)),
                  const SizedBox(height: 10),
                  // 2×2 visibility grid
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8, mainAxisSpacing: 8,
                    childAspectRatio: 2.6,
                    children: [
                      _VisOption(
                        title: 'Save as Draft', sub: 'Only visible to instructors',
                        selected: _publish == _PublishChoice.draft,
                        onTap: () => setState(() => _publish = _PublishChoice.draft),
                      ),
                      _VisOption(
                        title: 'Publish Now', sub: 'Visible to enrolled students',
                        selected: _publish == _PublishChoice.published,
                        onTap: () => setState(() => _publish = _PublishChoice.published),
                      ),
                      _VisOption(
                        title: 'Set as Private', sub: 'For specific students',
                        selected: _visibility == _VisibilityChoice.privateCourse,
                        onTap: () => setState(() => _visibility = _VisibilityChoice.privateCourse),
                      ),
                      _VisOption(
                        title: 'Set as Public', sub: 'For public students',
                        selected: _visibility == _VisibilityChoice.publicCourse,
                        onTap: () => setState(() => _visibility = _VisibilityChoice.publicCourse),
                      ),
                    ],
                  ),
                  // Private notice
                  if (_visibility == _VisibilityChoice.privateCourse) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: _K.blue),
                        SizedBox(width: 8),
                        Expanded(child: Text('Private courses require inviting students after creation.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _K.text))),
                      ]),
                    ),
                  ],
                ]))),
                const SizedBox(width: 14),
                // Course Cover
                SizedBox(width: 240, child: _Section(icon: Icons.image_outlined, title: 'Course Cover', child: _CoverUpload())),
              ]),
            ]))),
            // ── Footer ─────────────────────────────────────────────────────
            const SizedBox(height: 18),
            Container(height: 1, color: _K.divider),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _SecBtn(label: 'Cancel', onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 10),
              _PriBtn(label: 'Create Course', icon: Icons.add_rounded, onTap: _canSubmit ? _submit : null),
            ]),
          ]),
        ),
      )),
    );
  }
}

// =============================================================================
//  UI BLOCKS — pixel-perfect match to prototype
// =============================================================================

// ── Section card (.form-section) ─────────────────────────────────────────────
class _Section extends StatelessWidget {
  final IconData icon; final String title; final Widget child;
  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: _K.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _K.border),
    ),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section title row (.form-section-title)
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: _K.blueSoft,
            border: Border.all(color: _K.blueBdr),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: _K.blue),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _K.text)),
      ]),
      const SizedBox(height: 14),
      Container(height: 1, color: _K.divider),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

// ── Form group (label + child) ────────────────────────────────────────────────
class _FormGroup extends StatelessWidget {
  final String label; final Widget child; final bool req; final bool optional;
  const _FormGroup({required this.label, required this.child, this.req = false, this.optional = false});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _K.text)),
      if (req)      const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
      if (optional) const Text(' (Optional)', style: TextStyle(fontSize: 11, color: _K.blue, fontWeight: FontWeight.w600)),
    ]),
    const SizedBox(height: 6),
    child,
  ]);
}

// ── Text input (.form-input) ──────────────────────────────────────────────────
class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? error;
  final ValueChanged<String>? onChanged;

  const _Input({required this.controller, required this.hint, this.error, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hasErr = (error ?? '').isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        height: 40,
        decoration: BoxDecoration(
          color: _K.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: hasErr ? const Color(0xFFFCA5A5) : _K.border),
        ),
        child: TextField(
          controller: controller, onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: _K.text),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: _K.hint),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
        ),
      ),
      if (hasErr) ...[
        const SizedBox(height: 5),
        Text(error!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
      ],
    ]);
  }
}

// ── Dropdown (.form-select) ───────────────────────────────────────────────────
class _Dropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onSelect;
  const _Dropdown({required this.value, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const items = ['Fall 2023','Spring 2024','Fall 2024','Spring 2025','Fall 2025','Spring 2026'];
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _K.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: _K.border)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _K.hint, size: 18),
        style: const TextStyle(fontSize: 13, color: _K.text),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) { if (v != null) onSelect(v); },
      )),
    );
  }
}

// ── Textarea with toolbar (.textarea-wrap) ────────────────────────────────────
class _TextArea extends StatelessWidget {
  final TextEditingController controller;
  const _TextArea({required this.controller});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(9),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: _K.border), borderRadius: BorderRadius.circular(9)),
      child: Column(children: [
        // Toolbar (.textarea-toolbar)
        Container(
          height: 40,
          color: const Color(0xFFFAFBFC),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: const [
            _TbBtn(label: 'B', bold: true),
            _TbBtn(label: 'I', italic: true),
            _TbBtn(label: '≡'),
            _TbBtn(label: '🔗'),
          ]),
        ),
        Container(height: 1, color: _K.divider),
        SizedBox(
          height: 100,
          child: TextField(
            controller: controller, maxLines: null, expands: true,
            style: const TextStyle(fontSize: 13, color: _K.text),
            decoration: const InputDecoration(
              hintText: 'Enter a detailed description of the course content, objectives, and prerequisites...',
              hintStyle: TextStyle(fontSize: 13, color: _K.hint, height: 1.45),
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
            ),
          ),
        ),
      ]),
    ),
  );
}

class _TbBtn extends StatelessWidget {
  final String label; final bool bold; final bool italic;
  const _TbBtn({required this.label, this.bold = false, this.italic = false});
  @override
  Widget build(BuildContext context) => Container(
    width: 28, height: 28,
    child: Center(child: Text(label, style: TextStyle(
      fontSize: 12.5, fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: _K.muted,
    ))),
  );
}

// ── Visibility option (.vis-option) — custom radio UI ────────────────────────
class _VisOption extends StatefulWidget {
  final String title; final String sub; final bool selected; final VoidCallback onTap;
  const _VisOption({required this.title, required this.sub, required this.selected, required this.onTap});
  @override State<_VisOption> createState() => _VisOptionState();
}
class _VisOptionState extends State<_VisOption> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _h;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _K.blueSoft : _K.pageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.selected ? _K.blue : _K.border,
            width: widget.selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _K.text)),
            const SizedBox(height: 2),
            Text(widget.sub, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _K.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 6),
          // Custom radio circle (.radio-circle + .radio-dot)
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.selected ? _K.blue : _K.border, width: 2),
              color: _K.white,
            ),
            child: widget.selected
              ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _K.blue, shape: BoxShape.circle)))
              : null,
          ),
        ]),
      )),
    );
  }
}

// ── Cover upload area (.cover-upload) ────────────────────────────────────────
class _CoverUpload extends StatefulWidget {
  @override State<_CoverUpload> createState() => _CoverUploadState();
}
class _CoverUploadState extends State<_CoverUpload> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: _h ? _K.blueSoft : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _h ? _K.blue : _K.border,
          style: BorderStyle.solid, width: 1.5,
        ),
      ),
      child: Column(children: [
        Icon(Icons.image_outlined, size: 28, color: _h ? _K.blue : _K.muted),
        const SizedBox(height: 8),
        Text('Upload a file', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _h ? _K.blue : _K.blue)),
        const SizedBox(height: 4),
        const Text('or drag and drop', style: TextStyle(fontSize: 12, color: _K.hint)),
        const SizedBox(height: 6),
        const Text('PNG, JPG, GIF up to 10MB', style: TextStyle(fontSize: 11, color: _K.hint, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

// ── Primary button (.btn-primary) ─────────────────────────────────────────────
class _PriBtn extends StatefulWidget {
  final String label; final IconData? icon; final VoidCallback? onTap;
  const _PriBtn({required this.label, this.icon, this.onTap});
  @override State<_PriBtn> createState() => _PriBtnState();
}
class _PriBtnState extends State<_PriBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: !enabled ? const Color(0xFFE2E8F0) : _h ? const Color(0xFF0E6FD4) : _K.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 16, color: enabled ? _K.white : _K.hint),
            const SizedBox(width: 6),
          ],
          Text(widget.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: enabled ? _K.white : _K.hint)),
        ]),
      )),
    );
  }
}

// ── Secondary button (.btn-secondary) ─────────────────────────────────────────
class _SecBtn extends StatefulWidget {
  final String label; final VoidCallback onTap;
  const _SecBtn({required this.label, required this.onTap});
  @override State<_SecBtn> createState() => _SecBtnState();
}
class _SecBtnState extends State<_SecBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit:  (_) => setState(() => _h = false),
    child: GestureDetector(onTap: widget.onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 44, padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _h ? const Color(0xFFF1F5F9) : _K.white,
        border: Border.all(color: _K.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(widget.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _K.text))),
    )),
  );
}