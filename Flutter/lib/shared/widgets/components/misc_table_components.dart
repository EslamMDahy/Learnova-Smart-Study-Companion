part of 'misc.dart';

class FigmaUmPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const FigmaUmPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 36 / 30,
            letterSpacing: -0.75,
            color: AppColors.cText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
            color: AppColors.cMuted,
          ),
        ),
      ],
    );
  }
}

class FigmaUmSquareIconBtn40 extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const FigmaUmSquareIconBtn40({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), 
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: AppColors.cGray500),
        ),
      ),
    );
  }
}

class FigmaUmFiltersBar extends StatelessWidget {
  final TextEditingController controller;
  final String selectedRole;
  final String selectedStatus;
  final bool isNarrow;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatusChanged;

  final VoidCallback onMoreFilters;
  final VoidCallback onRefresh;

const FigmaUmFiltersBar({
    super.key,
    required this.controller,
    required this.selectedRole,
    required this.selectedStatus,
    required this.isNarrow,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onMoreFilters,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final roleDrop = FigmaUmDropdown40(
      width: isNarrow ? 150 : 140,
      value: selectedRole,
      items: ['All Roles', 'owner', 'teacher', 'student', 'assistant'],
      onChanged: onRoleChanged,
    );

    final statusDrop = FigmaUmDropdown40(
      width: isNarrow ? 150 : 140,
      value: selectedStatus,
      items: ['All Status', 'pending', 'accepted', 'suspended', 'declined'],
      onChanged: onStatusChanged,
    );

    final search = FigmaUmSearch40(
      controller: controller,
      onChanged: onSearchChanged,
    );

    final moreFilters = FigmaUmSquareIconBtn40(
      icon: Icons.tune_rounded,
      onTap: onMoreFilters,
      tooltip: 'More filters',
    );

    final refresh = FigmaUmSquareIconBtn40(
      icon: Icons.refresh,
      onTap: onRefresh,
      tooltip: 'Refresh',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cBorder),
        boxShadow: [
          const BoxShadow(
              color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1),),
        ],
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    roleDrop,
                    statusDrop,
                    moreFilters,
                    refresh,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 16),
                roleDrop,
                const SizedBox(width: 12),
                statusDrop,
                const Spacer(),
                moreFilters,
                const SizedBox(width: 8),
                refresh,
              ],
            ),
    );
  }
}

class FigmaUmTableHeader extends StatelessWidget {
  final bool isNarrow;
  final double actionsColWidth;
  final double cellLeftPad;
  final double rowHPad;

  const FigmaUmTableHeader({
    super.key,
    required this.isNarrow,
    required this.actionsColWidth,
    required this.cellLeftPad,
    required this.rowHPad,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      height: 49,
      color: AppColors.cSurface,
      padding: EdgeInsets.symmetric(horizontal: rowHPad),
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16),
          const SizedBox(width: 16),

          FigmaUmHeaderCellFlex(flex: 5, text: 'USER INFO', leftPad: cellLeftPad),
          FigmaUmHeaderCellFlex(flex: 2, text: 'ROLE', leftPad: cellLeftPad),

          if (!isNarrow)
            FigmaUmHeaderCellFlex(
                flex: 3, text: 'DEPARTMENT', leftPad: cellLeftPad,),
          if (!isNarrow)
            FigmaUmHeaderCellFlex(
                flex: 2, text: 'JOINED DATE', leftPad: cellLeftPad,),

          FigmaUmHeaderCellFlex(flex: 2, text: 'STATUS', leftPad: cellLeftPad),

          SizedBox(
            width: actionsColWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'ACTIONS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: AppColors.cGray500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FigmaUmHeaderCellFlex extends StatelessWidget {
  final int flex;
  final String text;
  final double leftPad;

  const FigmaUmHeaderCellFlex({
    super.key,
    required this.flex,
    required this.text,
    this.leftPad = 0,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.only(left: leftPad),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: AppColors.cGray500,
          ),
        ),
      ),
    );
  }
}

class FigmaUmEmptyTableState extends StatelessWidget {
  final String message;
  const FigmaUmEmptyTableState({
    super.key,
    this.message = 'No users match your filters right now.',
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      children: [
        Icon(Icons.inbox_outlined, color: AppColors.cGray500),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              color: AppColors.cGray500,
            ),
          ),
        ),
      ],
    );
  }
}

class FigmaUmTableFooter extends StatelessWidget {
  final String showingText;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const FigmaUmTableFooter({
    super.key,
    required this.showingText,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      height: 71,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cSurface,
        border: Border(top: BorderSide(color: AppColors.cBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              showingText,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                color: AppColors.cGray500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              FigmaUmPageBtn(
                label: 'Previous',
                icon: Icons.chevron_left,
                enabled: onPrev != null,
                onTap: onPrev,
                width: 105,
                trailingIcon: false,
              ),
              const SizedBox(width: 8),
              FigmaUmPageBtn(
                label: 'Next',
                icon: Icons.chevron_right,
                enabled: onNext != null,
                onTap: onNext,
                width: 79,
                trailingIcon: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FigmaUmPageBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final double width;
  final bool trailingIcon;

  const FigmaUmPageBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.width,
    required this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SizedBox(
        width: width,
        height: 38,
        child: OutlinedButton(
          onPressed: enabled ? onTap : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.borderSoft),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: AppColors.cBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: trailingIcon
                ? [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 20 / 14,
                          color: AppColors.cGray500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon, size: 18, color: AppColors.cGray500),
                  ]
                : [
                    Icon(icon, size: 18, color: AppColors.cGray500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 20 / 14,
                          color: AppColors.cGray500,
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   Join Requests - Figma Reusables (NO UI CHANGE)
============================================================ */

@Deprecated('Use AppCardShell(maxWidth: ...)')

class JrHScroll extends StatelessWidget {
  final Widget child;
  const JrHScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }
}

class JrHeaderTxt extends StatelessWidget {
  final String text;
  const JrHeaderTxt(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textGray500,
      ),
    );
  }
}

@Deprecated('Use FigmaUmEmptyTableState(message: ...)')

class JrEmptyTableState extends StatelessWidget {
  const JrEmptyTableState({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return const FigmaUmEmptyTableState(
      message: 'No pending join requests right now.',
    );
  }
}

class JrRefreshIconBtnFigma extends StatelessWidget {
  final VoidCallback? onPressed;
  const JrRefreshIconBtnFigma({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return SizedBox(
      height: 40,
      width: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: AppColors.borderGray),
          backgroundColor: AppColors.surfaceBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(Icons.refresh, size: 18, color: AppColors.textGray500),
      ),
    );
  }
}

/* =========================
   Role + Status
========================= */
