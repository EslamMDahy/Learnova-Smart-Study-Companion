import 'package:flutter/material.dart';
import '../design_tokens.dart';

/// Badges / chips / status pills.

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.title : Colors.white;
    final border = selected ? AppColors.title : AppColors.border;
    final textColor = selected ? Colors.white : const Color(0xFF334155);
    final weight = selected ? FontWeight.w700 : FontWeight.w500;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: weight,
            color: textColor,
            height: 20 / 14,
          ),
        ),
      ),
    );
  }
}

class FigmaUmRolePill extends StatelessWidget {
  final String role;
  const FigmaUmRolePill({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final r = role.toLowerCase();

    Color bg = const Color(0xFFDBEAFE);
    Color br = const Color(0xFFBFDBFE);
    Color fg = const Color(0xFF1E40AF);

    if (r == "teacher" || r == "instructor") {
      bg = const Color(0xFFF3E8FF);
      br = const Color(0xFFE9D5FF);
      fg = const Color(0xFF6B21A8);
    }

    if (r == "owner") {
      bg = const Color(0xFFE0E7FF);
      br = const Color(0xFFC7D2FE);
      fg = const Color(0xFF4338CA);
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: br),
        borderRadius: BorderRadius.circular(9999),
      ),
      alignment: Alignment.center,
      child: Text(
        _titleCase(r),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: "Manrope",
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: fg,
        ),
      ),
    );
  }

  String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

@Deprecated('Use JrStatusBadge (normalizes more cases)')

class JrRolePill extends StatelessWidget {
  final String role;
  const JrRolePill({super.key, required this.role});

  @override
  Widget build(BuildContext context) => FigmaUmRolePill(role: role);
}

class FigmaUmStatus extends StatelessWidget {
  final String status;
  const FigmaUmStatus({super.key, required this.status});

  @override
  Widget build(BuildContext context) => JrStatusBadge(status: status);
}

class JrStatusBadge extends StatelessWidget {
  final String status;
  const JrStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = jrNormalizeStatus(status);

    Color dot = const Color(0xFFEAB308);
    String label = normalized;

    if (normalized == 'accepted') {
      dot = const Color(0xFF22C55E);
      label = 'accepted';
    } else if (normalized == 'pending') {
      dot = const Color(0xFFEAB308);
      label = 'pending';
    } else if (normalized == 'suspended') {
      dot = const Color(0xFFEF4444);
      label = 'suspended';
    } else if (normalized == 'declined') {
      dot = const Color(0xFFEF4444);
      label = 'declined';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dot,
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: "Manrope",
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
            height: 20 / 14,
          ),
        ),
      ],
    );
  }
}

String jrNormalizeStatus(String raw) {
  final s = raw.toLowerCase().trim();
  if (s == 'pinding') return 'pending';
  if (s == 'declinate') return 'declined';
  return s;
}

/* ---------------- Toggle ---------------- */

class UpgradePeriodToggle extends StatelessWidget {
  final bool isYearly;
  final VoidCallback onToggle;

  const UpgradePeriodToggle({
    super.key,
    required this.isYearly,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UpgradeToggleChip(
            text: "Monthly",
            selected: !isYearly,
            onTap: isYearly ? onToggle : null,
          ),
          const SizedBox(width: 8),
          UpgradeToggleChip(
            text: "Yearly",
            selected: isYearly,
            onTap: !isYearly ? onToggle : null,
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              "Save more",
              style: TextStyle(
                color: Color(0xFF166534),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpgradeToggleChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const UpgradeToggleChip({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

/* ---------------- Card ---------------- */

enum UpgradeTone { primary, neutral }
