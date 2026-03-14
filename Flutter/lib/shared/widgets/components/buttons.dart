import 'package:flutter/material.dart';
import '../design_tokens.dart';

/// Buttons (canonical + deprecated wrappers).

enum AppButtonVariant { primary, soft, primarySoft, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final bool compact;
  final bool loading;
  final double? height;
  final EdgeInsets? padding;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = AppButtonVariant.primary,
    this.compact = false,
    this.loading = false,
    this.height,
    this.padding,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ??
        (variant == AppButtonVariant.danger
            ? 42
            : (compact ? 38 : 40));

    final EdgeInsets pad = padding ??
        (variant == AppButtonVariant.primary
            ? const EdgeInsets.symmetric(horizontal: 24)
            : EdgeInsets.symmetric(horizontal: compact ? 16 : 16.75));

    Color bg = AppColors.primary;
    Color? border;
    Color fg = Colors.white;
    List<BoxShadow> shadow = const [
      BoxShadow(
        blurRadius: 2,
        offset: Offset(0, 1),
        color: AppColors.shadowBlue,
      ),
    ];

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        shadow = const [
          BoxShadow(
            blurRadius: 2,
            offset: Offset(0, 1),
            color: AppColors.shadowBlue,
          ),
        ];
        break;

      case AppButtonVariant.soft:
        bg = Colors.white;
        border = AppColors.borderSoft;
        fg = AppColors.title;
        shadow = const [
          BoxShadow(
            blurRadius: 2,
            offset: Offset(0, 1),
            color: AppColors.shadowThin,
          ),
        ];
        break;

      case AppButtonVariant.primarySoft:
        bg = Colors.white;
        border = AppColors.border;
        fg = AppColors.title;
        shadow = const [
          BoxShadow(
            blurRadius: 2,
            offset: Offset(0, 1),
            color: AppColors.shadowThin,
          ),
        ];
        break;

      case AppButtonVariant.danger:
        bg = Colors.white;
        border = AppColors.dangerBorder;
        fg = AppColors.dangerText;
        shadow = const [];
        break;
    }

    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label, style: AppText.button.copyWith(color: fg));

    final btn = InkWell(
      onTap: (loading ? null : onTap),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: h,
        padding: pad,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: border == null ? null : Border.all(color: border),
          boxShadow: shadow,
        ),
        child: child,
      ),
    );

    if (!fullWidth) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }
}

class AppSoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const AppSoftButton({
    super.key,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onTap: onTap,
      compact: compact,
      variant: AppButtonVariant.soft,
    );
  }
}


@Deprecated('Use AppButton(variant: AppButtonVariant.primary)')

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onTap: onTap,
      variant: AppButtonVariant.primary,
    );
  }
}


@Deprecated('Use AppButton(variant: AppButtonVariant.danger)')

class AppDangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppDangerButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onTap: onTap,
      variant: AppButtonVariant.danger,
    );
  }
}


@Deprecated('Use AppLabeledTextField')

class AppPrimarySoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppPrimarySoftButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onTap: onTap,
      variant: AppButtonVariant.primarySoft,
    );
  }
}
