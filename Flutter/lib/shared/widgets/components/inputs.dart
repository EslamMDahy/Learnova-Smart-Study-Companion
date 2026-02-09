import 'package:flutter/material.dart';
import '../design_tokens.dart';

/// Text inputs (canonical + deprecated wrappers + search helpers).

class AppLabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final String? helper;
  final double height;
  final EdgeInsets contentPadding;
  final bool expands;
  final int? maxLines;
  final int? minLines;

  const AppLabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.helper,
    this.height = 44,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.expands = false,
    this.maxLines = 1,
    this.minLines,
  });

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        fillColor: Colors.transparent,
        hintStyle: AppText.hint.copyWith(height: expands ? 20 / 14 : null),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        AppSpacing.gap6,
        Container(
          height: height,
          padding: contentPadding,
          alignment: expands ? null : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            expands: expands,
            maxLines: expands ? null : maxLines,
            minLines: expands ? null : minLines,
            textAlignVertical:
                expands ? TextAlignVertical.top : TextAlignVertical.center,
            decoration: _decoration(hint),
            style: expands
                ? AppText.input.copyWith(height: 20 / 14)
                : AppText.input,
          ),
        ),
        if (helper != null) ...[
          AppSpacing.gap6,
          Text(helper!, style: AppText.mutedSmall),
        ],
      ],
    );
  }
}

class AppLabeledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const AppLabeledInput({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return AppLabeledTextField(
      label: label,
      controller: controller,
      hint: hint,
    );
  }
}


@Deprecated('Use AppLabeledTextField(obscureText: true)')

class AppLabeledPassword extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? helper;

  const AppLabeledPassword({
    super.key,
    required this.label,
    required this.controller,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return AppLabeledTextField(
      label: label,
      controller: controller,
      hint: "••••••••••••",
      obscureText: true,
      helper: helper,
    );
  }
}


@Deprecated('Use AppLabeledTextField(expands: true, height: 100)')

class AppLabeledTextarea extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const AppLabeledTextarea({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return AppLabeledTextField(
      label: label,
      controller: controller,
      hint: hint,
      height: 100,
      expands: true,
      contentPadding: const EdgeInsets.all(16),
    );
  }
}

class AppReadOnlyInput extends StatelessWidget {
  final String label;
  final String value;
  final String? rightTag;
  final IconData icon;

  const AppReadOnlyInput({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.rightTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        AppSpacing.gap6,
        Stack(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.only(left: 44, right: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.pageBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: AppText.input.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  if (rightTag != null)
                    Text(
                      rightTag!.toUpperCase(),
                      style: AppText.mutedSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(icon, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowThin,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 22 / 16,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 22 / 16,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 48),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

@Deprecated('Use AppButton(variant: AppButtonVariant.primarySoft)')

class AppHeaderSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const AppHeaderSearchField({
    super.key,
    required this.hint,
    this.onChanged,
  });

  static const Color _muted = Color(0xFF617589);
  static const Color _searchBg = Color(0xFFF0F2F4);
  static const Color _text = Color(0xFF111418);

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _searchBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, size: 20, color: _muted),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                  onChanged: onChanged,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  cursorHeight: 18,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 19 / 14,
                    color: _text,
                  ),
                  decoration: InputDecoration(
                    hint: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 19 / 14,
                        color: _muted,
                      ),
                    ),
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(right: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FigmaUmSearch40 extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const FigmaUmSearch40({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: "Manrope",
          fontSize: 14,
          height: 19 / 14,
          color: AppColors.cGray700,
        ),
        decoration: InputDecoration(
          hintText: "Search by name, ID, or email...",
          hintStyle: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 14,
            height: 19 / 14,
            color: AppColors.cGray500,
          ),
          filled: true,
          fillColor: AppColors.cSurface,
          prefixIcon:
              const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.only(top: 10, bottom: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFBFDBFE), width: 1.2),
          ),
        ),
      ),
    );
  }
}

@Deprecated('Use AppDropdown(height: 40)')

class JrInlineHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const JrInlineHint({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: "Manrope",
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}

/* =========================
   Filters Bar Pieces
========================= */
