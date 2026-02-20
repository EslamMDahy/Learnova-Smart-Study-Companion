import 'package:flutter/material.dart';

class CreateCourseDialog extends StatefulWidget {
  const CreateCourseDialog({super.key});

  @override
  State<CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<CreateCourseDialog> {
  _VisibilityChoice selected = _VisibilityChoice.draft;

  @override
  Widget build(BuildContext context) {
    // Figma size: 979 x 1293 (with padding 32 50) :contentReference[oaicite:1]{index=1}
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 979),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F4),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 32),
            child: LayoutBuilder(
              builder: (context, c) {
                // لو الشاشة قصيرة، نخليها scroll مرة واحدة فقط على مستوى الديالوج
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - 40,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const _DialogHeader(),
                        const SizedBox(height: 32),

                        // Course Details card
                        _FormCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                icon: Icons.description_outlined,
                                title: "Course Details",
                              ),
                              const SizedBox(height: 24),

                              const _FieldLabel("Course Title *"),
                              const SizedBox(height: 8),
                              const _FigmaTextField(
                                hint: "e.g. Introduction to Artificial Intelligence",
                              ),

                              const SizedBox(height: 24),

                              Row(
                                children: const [
                                  Expanded(
                                    child: _LabeledField(
                                      label: "Course Code",
                                      suffixHint: "(Optional)",
                                      child: _FigmaTextField(hint: "e.g. CS-101"),
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                  Expanded(
                                    child: _LabeledField(
                                      label: "Academic Term",
                                      child: _FigmaDropdown(value: "Fall 2023"),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              const _FieldLabel("Course Description"),
                              const SizedBox(height: 8),
                              const _RichEditor(),

                              const SizedBox(height: 12),

                              const _AiTip(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bottom row: Configuration + Course Cover
                        LayoutBuilder(
                          builder: (context, cc) {
                            final isStack = cc.maxWidth < 860;
                            if (isStack) {
                              return Column(
                                children: [
                                  _ConfigurationCard(
                                    selected: selected,
                                    onChange: (v) => setState(() => selected = v),
                                  ),
                                  const SizedBox(height: 24),
                                  const _CourseCoverCard(),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 10,
                                  child: _ConfigurationCard(
                                    selected: selected,
                                    onChange: (v) => setState(() => selected = v),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                const Expanded(
                                  flex: 6,
                                  child: _CourseCoverCard(),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Footer actions
                        _FooterActions(
                          onCancel: () => Navigator.pop(context),
                          onCreate: () {},
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// TOKENS (match Figma)
// ------------------------------------------------------------
class _T {
  static const card = Colors.white;

  static const text = Color(0xFF0D141B);
  static const muted = Color(0xFF4C739A);
  static const hint = Color(0xFF6B7280);

  static const inputBg = Color(0xFFF6F7F8);
  static const border = Color(0xFFE7EDF3);

  static const blue = Color(0xFF137FEC);

  static const r12 = 12.0;
  static const r8 = 8.0;

  static const shadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const inputShadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
}

// ------------------------------------------------------------
// Header
// ------------------------------------------------------------
class _DialogHeader extends StatelessWidget {
  const _DialogHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Create New Course",
          style: TextStyle(
            fontFamily: "Manrope",
            fontSize: 30,
            height: 36 / 30,
            fontWeight: FontWeight.w700,
            color: _T.text,
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: 672,
          child: Text(
            "Fill in the details below to set up a new learning module for your students. The AI assistant will use this information to generate relevant quizzes.",
            style: TextStyle(
              fontFamily: "Manrope",
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w400,
              color: _T.muted,
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Cards
// ------------------------------------------------------------
class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(_T.r12),
        boxShadow: _T.shadow,
      ),
      padding: const EdgeInsets.all(32),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _T.blue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: _T.blue),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 18,
            height: 28 / 18,
            fontWeight: FontWeight.w700,
            color: _T.text,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Fields
// ------------------------------------------------------------
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: "Manrope",
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: _T.text,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String? suffixHint;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
    this.suffixHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: "Manrope",
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: _T.text,
              ),
            ),
            if (suffixHint != null) ...[
              const SizedBox(width: 6),
              Text(
                suffixHint!,
                style: const TextStyle(
                  fontFamily: "Manrope",
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w400,
                  color: _T.muted,
                ),
              ),
            ]
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FigmaTextField extends StatelessWidget {
  final String hint;
  const _FigmaTextField({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _T.inputBg,
        borderRadius: BorderRadius.circular(_T.r8),
        border: Border.all(color: _T.border, width: 1),
        boxShadow: _T.inputShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: TextField(
        style: const TextStyle(
          fontFamily: "Manrope",
          fontSize: 16,
          height: 22 / 16,
          fontWeight: FontWeight.w400,
          color: _T.text,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w400,
            color: _T.hint,
          ),
          isCollapsed: true,
        ),
      ),
    );
  }
}

class _FigmaDropdown extends StatelessWidget {
  final String value;
  const _FigmaDropdown({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _T.inputBg,
        borderRadius: BorderRadius.circular(_T.r8),
        border: Border.all(color: _T.border, width: 1),
        boxShadow: _T.inputShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: "Manrope",
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w400,
                color: _T.text,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: _T.hint),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Rich Editor (toolbar + textarea + no nested scroll issues)
// ------------------------------------------------------------
class _RichEditor extends StatelessWidget {
  const _RichEditor();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.inputBg,
        borderRadius: BorderRadius.circular(_T.r8),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        children: [
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: _T.border),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_T.r8),
                topRight: Radius.circular(_T.r8),
              ),
            ),
            child: Row(
              children: const [
                _ToolIcon(Icons.format_bold_rounded),
                SizedBox(width: 10),
                _ToolIcon(Icons.format_italic_rounded),
                SizedBox(width: 10),
                _ToolIcon(Icons.format_list_bulleted_rounded),
                SizedBox(width: 10),
                SizedBox(width: 8),
                VerticalDivider(width: 18, thickness: 1, color: _T.border),
                _ToolIcon(Icons.link_rounded),
              ],
            ),
          ),
          // Textarea (بدون Scroll داخلي، يشتغل مع Scroll الخارجي للديالوج لو احتاج)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              maxLines: 5,
              style: const TextStyle(
                fontFamily: "Manrope",
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
                color: _T.text,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText:
                    "Enter a detailed description of the course content, objectives, and prerequisites...",
                hintStyle: TextStyle(
                  fontFamily: "Manrope",
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w400,
                  color: _T.hint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  final IconData icon;
  const _ToolIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 18, color: _T.muted),
    );
  }
}

class _AiTip extends StatelessWidget {
  const _AiTip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.auto_awesome_rounded, size: 14, color: _T.blue),
        SizedBox(width: 6),
        Text(
          "AI Tip: A detailed description helps generate better quiz questions.",
          style: TextStyle(
            fontFamily: "Manrope",
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w400,
            color: _T.muted,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Configuration
// ------------------------------------------------------------
enum _VisibilityChoice { draft, publish, privateC, publicC }

class _ConfigurationCard extends StatelessWidget {
  final _VisibilityChoice selected;
  final ValueChanged<_VisibilityChoice> onChange;

  const _ConfigurationCard({
    required this.selected,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.tune_rounded,
            title: "Configuration",
          ),
          const SizedBox(height: 24),
          const _FieldLabel("Visibility Status"),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _ChoiceTile(
                  title: "Save as Draft",
                  subtitle: "Only visible to instructors",
                  selected: selected == _VisibilityChoice.draft,
                  onTap: () => onChange(_VisibilityChoice.draft),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ChoiceTile(
                  title: "Publish Now",
                  subtitle: "Visible to enrolled students",
                  selected: selected == _VisibilityChoice.publish,
                  onTap: () => onChange(_VisibilityChoice.publish),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _T.border),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChoiceTile(
                  title: "Set as Private",
                  subtitle: "For specific Student",
                  selected: selected == _VisibilityChoice.privateC,
                  onTap: () => onChange(_VisibilityChoice.privateC),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ChoiceTile(
                  title: "Set as Public",
                  subtitle: "For Public Studnet",
                  selected: selected == _VisibilityChoice.publicC,
                  onTap: () => onChange(_VisibilityChoice.publicC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_T.r8),
        child: Container(
          height: 76,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _T.inputBg,
            borderRadius: BorderRadius.circular(_T.r8),
            border: Border.all(
              color: selected ? _T.blue : _T.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: _T.inputShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: "Manrope",
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        color: _T.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: "Manrope",
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w400,
                        color: _T.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? _T.blue : _T.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Course Cover
// ------------------------------------------------------------
class _CourseCoverCard extends StatelessWidget {
  const _CourseCoverCard();

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.image_outlined,
            title: "Course Cover",
          ),
          const SizedBox(height: 24),
          Container(
            height: 214,
            decoration: BoxDecoration(
              color: _T.inputBg,
              borderRadius: BorderRadius.circular(_T.r8),
              border: Border.all(color: _T.border, style: BorderStyle.solid),
            ),
            child: DottedBorderLike(
              radius: _T.r8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 48, color: _T.muted),
                  SizedBox(height: 12),
                  Text(
                    "Upload a file",
                    style: TextStyle(
                      fontFamily: "Manrope",
                      fontSize: 14,
                      height: 24 / 14,
                      fontWeight: FontWeight.w600,
                      color: _T.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6),
                  Text(
                    "or drag and drop",
                    style: TextStyle(
                      fontFamily: "Manrope",
                      fontSize: 14,
                      height: 24 / 14,
                      fontWeight: FontWeight.w400,
                      color: _T.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "PNG, JPG, GIF up to 10MB",
                    style: TextStyle(
                      fontFamily: "Manrope",
                      fontSize: 12,
                      height: 20 / 12,
                      fontWeight: FontWeight.w400,
                      color: _T.muted,
                    ),
                    textAlign: TextAlign.center,
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

/// بدل ما نجيب package dotted_border، عملت dashed بسيط بنفس شكل الفيجما.
class DottedBorderLike extends StatelessWidget {
  final Widget child;
  final double radius;
  const DottedBorderLike({super.key, required this.child, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(radius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final double radius;
  _DashPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final paint = Paint()
      ..color = _T.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dash = 6.0;
    const gap = 6.0;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    for (final m in metrics) {
      double dist = 0;
      while (dist < m.length) {
        final len = (dist + dash < m.length) ? dash : (m.length - dist);
        final seg = m.extractPath(dist, dist + len);
        canvas.drawPath(seg, paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------------------------------------------------
// Footer buttons
// ------------------------------------------------------------
class _FooterActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  const _FooterActions({
    required this.onCancel,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel
        SizedBox(
          height: 44,
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_T.r8),
                side: const BorderSide(color: _T.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontFamily: "Manrope",
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: _T.text,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Create
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.blue,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_T.r8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Create Course",
                  style: TextStyle(
                    fontFamily: "Manrope",
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
