part of 'materials_tab.dart';

class _PreferencesDialogShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final double maxWidth;
  final Widget? leading;

  const _PreferencesDialogShell({
    required this.title,
    required this.child,
    this.subtitle,
    this.maxWidth = 620,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textTitle,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), 
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool multiline;
  final bool autofocus;

  const _DialogTextField({
    required this.controller,
    required this.hintText,
    this.multiline = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      constraints: BoxConstraints(minHeight: multiline ? 104 : 48),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: multiline ? 14 : 0,
      ),
      alignment: multiline ? Alignment.topLeft : Alignment.centerLeft,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        minLines: multiline ? 4 : 1,
        maxLines: multiline ? 5 : 1,
        style: AppText.input,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppText.hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final AppButtonVariant confirmVariant;

  const _DialogActions({
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.confirmVariant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Cancel',
            onTap: onCancel,
            variant: AppButtonVariant.soft,
            fullWidth: true,
            height: 40,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: confirmLabel,
            onTap: onConfirm,
            variant: confirmVariant,
            fullWidth: true,
            height: 40,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ShareModuleDialog — lets the instructor choose the target course
// ─────────────────────────────────────────────────────────────────────────────
final _shareTargetCoursesProvider = FutureProvider.family<List<MyCourseItem>, int>((ref, currentCourseId) async {
  final res = await ref.read(coursesRepositoryProvider).myCourses(
    
  );
  final items = [...res.items]
    ..removeWhere((course) => course.id == currentCourseId)
    ..sort((a, b) => a.safeTitle.toLowerCase().compareTo(b.safeTitle.toLowerCase()));
  return items;
});

class _ShareModuleDialog extends ConsumerStatefulWidget {
  final ModuleItem module;
  final int currentCourseId;
  const _ShareModuleDialog({required this.module, required this.currentCourseId});

  @override
  ConsumerState<_ShareModuleDialog> createState() => _ShareModuleDialogState();
}

class _ShareModuleDialogState extends ConsumerState<_ShareModuleDialog> {
  MyCourseItem? _selectedCourse;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final coursesAsync = ref.watch(_shareTargetCoursesProvider(widget.currentCourseId));
    return _PreferencesDialogShell(
      title: 'Share with Another Course',
      subtitle: 'Choose which course should receive a copied module',
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.copy_all_rounded, size: 18, color: AppColors.purpleText),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.folder_rounded, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.module.title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textTitle)),
                  if (widget.module.description != null && widget.module.description!.isNotEmpty)
                    Text(widget.module.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ],),
              ),
            ],),
          ),
          const SizedBox(height: 16),
          coursesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Text('Could not load your courses: $error', style: const TextStyle(fontSize: 13, color: Color(0xFF9F1239))),
            ),
            data: (courses) {
              if (courses.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoftBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: Text('No other instructor courses are available for sharing yet.', style: TextStyle(fontSize: 13, color: AppColors.warningText)),
                );
              }

              _selectedCourse ??= courses.first;
              final currentValue = courses.contains(_selectedCourse) ? _selectedCourse! : courses.first;
              return AppModernDropdown<MyCourseItem>(
                label: 'Target course',
                value: currentValue,
                items: [
                  for (final course in courses)
                    DropdownMenuItem<MyCourseItem>(
                      value: course,
                      child: Text(course.safeTitle, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedCourse = value),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningSoftBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 15, color: AppColors.warningText),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'This creates an independent copy in the selected course using the current backend copy endpoint.',
                style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.warningText),
              ),),
            ],),
          ),
          const SizedBox(height: 20),
          _DialogActions(
            onCancel: () => Navigator.pop(context),
            onConfirm: _selectedCourse == null ? null : () => Navigator.pop(context, _selectedCourse),
            confirmLabel: 'Copy Module',
          ),
        ],
      ),
    );
  }
}

class _DescriptionDialog extends StatelessWidget {
  final TextEditingController ctrl;
  const _DescriptionDialog({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _PreferencesDialogShell(
      title: 'Edit Description',
      subtitle: 'Update the module description shown in preferences and sharing flows.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DialogTextField(
            controller: ctrl,
            hintText: 'Write a short helpful description',
            multiline: true,
          ),
          const SizedBox(height: 16),
          _DialogActions(
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
            confirmLabel: 'Save',
          ),
        ],
      ),
    );
  }
}

class _ChangeModulePositionDialog extends StatefulWidget {
  final ModuleItem module;
  final List<ModuleItem> modules;
  const _ChangeModulePositionDialog({required this.module, required this.modules});

  @override
  State<_ChangeModulePositionDialog> createState() => _ChangeModulePositionDialogState();
}

class _ChangeModulePositionDialogState extends State<_ChangeModulePositionDialog> {
  late int _selectedPosition = widget.module.orderIndex + 1;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return _PreferencesDialogShell(
      title: 'Change Position',
      subtitle: 'Move "${widget.module.title}" to a new order inside this course.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppModernDropdown<int>(
            label: 'Position',
            value: _selectedPosition,
            items: [
              for (var i = 0; i < widget.modules.length; i++)
                DropdownMenuItem<int>(
                  value: i + 1,
                  child: Text('#${i + 1}'),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedPosition = value);
            },
          ),
          const SizedBox(height: 16),
          _DialogActions(
            onCancel: () => Navigator.pop(context),
            onConfirm: () => Navigator.pop(context, _selectedPosition),
            confirmLabel: 'Save',
          ),
        ],
      ),
    );
  }
}

