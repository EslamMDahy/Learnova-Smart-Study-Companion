import 'package:flutter/material.dart';

class CreateOrgDialog extends StatefulWidget {
  const CreateOrgDialog({super.key});

  @override
  State<CreateOrgDialog> createState() => _CreateOrgDialogState();
}

class _CreateOrgDialogState extends State<CreateOrgDialog> {
  // required by backend
  final _orgName = TextEditingController();
  final _orgDesc = TextEditingController();
  final _logoUrl = TextEditingController();

  // figma-like extra fields (optional UI for now)
  final _primaryDomain = TextEditingController();
  final _location = TextEditingController();
  final _adminName = TextEditingController();
  final _adminEmail = TextEditingController();

  String _orgType = "Select type...";

  @override
  void dispose() {
    _orgName.dispose();
    _orgDesc.dispose();
    _logoUrl.dispose();
    _primaryDomain.dispose();
    _location.dispose();
    _adminName.dispose();
    _adminEmail.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _orgName.text.trim().isNotEmpty && _orgDesc.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;

    final logo = _logoUrl.text.trim();

    final payload = <String, dynamic>{
      "name": _orgName.text.trim(),
      "description": _orgDesc.text.trim(),
      if (logo.isNotEmpty) "logo_url": logo, // ✅
    };

    Navigator.pop<Map<String, dynamic>>(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF0F2F4), // figma bg
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1184,
          maxHeight: 820,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(48, 44, 48, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Create New Organization",
                      style: TextStyle(
                        fontFamily: "Lexend",
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 45 / 36,
                        letterSpacing: -1.188,
                        color: Color(0xFF111418),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Set up a new institutional account for your university, school, or research center.",
                      style: TextStyle(
                        fontFamily: "Lexend",
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 24 / 16,
                        color: Color(0xFF617589),
                      ),
                    ),
                    const SizedBox(height: 22),

                    _CardShell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardHeader(
                            icon: Icons.account_balance_outlined,
                            title: "Organization Details",
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: _LabeledField(
                                  label: "Organization Name",
                                  child: _Input(
                                    controller: _orgName,
                                    hint: "e.g. Stanford University",
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _LabeledField(
                                  label: "Organization Type",
                                  child: _Dropdown(
                                    value: _orgType,
                                    items: const [
                                      "Select type...",
                                      "University",
                                      "School",
                                      "Research Center",
                                      "Institute",
                                      "Training Center",
                                    ],
                                    onChanged: (v) {
                                      setState(() => _orgType = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _LabeledField(
                                  label: "Primary Domain",
                                  child: _Input(
                                    controller: _primaryDomain,
                                    hint: "e.g. stanford.edu",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _LabeledField(
                                  label: "Location",
                                  child: _Input(
                                    controller: _location,
                                    hint: "e.g. Palo Alto, CA",
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _LabeledField(
                            label: "Description (max 50 chars)",
                            child: _Input(
                              controller: _orgDesc,
                              hint: "Short description",
                              maxLen: 50,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),

                          const SizedBox(height: 18),

                          _LabeledField(
                            label: "Organization Logo",
                            child: _LogoUploader(
                              controller: _logoUrl,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),

                          const SizedBox(height: 22),
                          const Divider(height: 1, color: Color(0xFFEEF2F4)),
                          const SizedBox(height: 18),

                          const _SubHeader(title: "Primary Administrator"),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: _LabeledField(
                                  label: "Full Name",
                                  child: _Input(
                                    controller: _adminName,
                                    hint: "e.g. Alex Morgan",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _LabeledField(
                                  label: "Administrator Email",
                                  child: _Input(
                                    controller: _adminEmail,
                                    hint: "admin@university.edu",
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD5E7FF)),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline,
                                    color: Color(0xFF137FEC), size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Need help? Chat with our support team or learn more about how organizations work.",
                                    style: TextStyle(
                                      fontFamily: "Lexend",
                                      fontSize: 13,
                                      height: 20 / 13,
                                      color: Color(0xFF33506B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 14,
                              runSpacing: 12,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF111418),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontFamily: "Lexend",
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _canSubmit ? _submit : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF137FEC),
                                    disabledBackgroundColor:
                                        const Color(0xFF93C5FD),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size(0, 48),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Create Organization",
                                    style: TextStyle(
                                      fontFamily: "Lexend",
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Center(
                      child: Text(
                        "© 2024 Learnova Academic Platform. All rights reserved.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Lexend",
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 20 / 14,
                          color: Color(0xFF617589),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- UI Building Blocks ---------------- */

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBE0E6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF137FEC)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: "Lexend",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 25 / 20,
            color: Color(0xFF111418),
          ),
        ),
      ],
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String title;
  const _SubHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: "Lexend",
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111418),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Lexend",
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 21 / 14,
            color: Color(0xFF111418),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? maxLen;
  final ValueChanged<String>? onChanged;

  const _Input({
    required this.controller,
    required this.hint,
    this.maxLen,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        maxLength: maxLen,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: "Lexend",
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF111418),
        ),
        decoration: InputDecoration(
          counterText: "",
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: "Lexend",
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF617589),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDBE0E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF137FEC), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDBE0E6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF6B7280)),
              style: const TextStyle(
                fontFamily: "Lexend",
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111418),
              ),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              items: items
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Lexend",
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: e == "Select type..."
                              ? const Color(0xFF617589)
                              : const Color(0xFF111418),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoUploader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _LogoUploader({
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDBE0E6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDBE0E6)),
            ),
            child: const Icon(Icons.image_outlined, color: Color(0xFF617589)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: "Lexend",
                fontSize: 14,
                color: Color(0xFF111418),
              ),
              decoration: const InputDecoration(
                hintText: "Paste logo URL (optional)",
                hintStyle: TextStyle(
                  fontFamily: "Lexend",
                  fontSize: 14,
                  color: Color(0xFF617589),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Upload coming soon (use URL for now)."),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137FEC),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              "Upload Logo",
              style: TextStyle(
                fontFamily: "Lexend",
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
