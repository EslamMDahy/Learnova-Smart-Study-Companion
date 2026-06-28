part of 'instructor_course_widgets.dart';

class _ApiCourseCard extends StatefulWidget {
  final MyCourseItem course;
  final CourseUpdateAction? onUpdateCourse;
  final CoursePublishAction? onPublishCourse;
  final CourseArchiveAction? onArchiveCourse;
  final CourseDeleteAction? onDeleteCourse;
  final CourseCoverUploadAction? onUploadCover;

  const _ApiCourseCard({
    required this.course,
    this.onUpdateCourse,
    this.onPublishCourse,
    this.onArchiveCourse,
    this.onDeleteCourse,
    this.onUploadCover,
  });

  @override
  State<_ApiCourseCard> createState() => _ApiCourseCardState();
}

class _ApiCourseCardState extends State<_ApiCourseCard> {
  bool hover = false;
  final GlobalKey _moreKey = GlobalKey();

  Future<void> _showCourseMenuFromKey(
    BuildContext context,
    MyCourseItem c,
    GlobalKey anchorKey,
  ) async {
    final slug = buildCourseRouteSlug(c);

    final selected = await showFigmaUmMenu<String>(
      context: context,
      anchorKey: anchorKey,
      minWidth: 210,
      entries: const [
        FigmaUmMenuEntry.item(
          value: 'materials',
          label: 'View materials',
          icon: Icons.folder_open_rounded,
        ),
        FigmaUmMenuEntry.item(
          value: 'invite',
          label: 'Invite students',
          icon: Icons.person_add_alt_1_rounded,
        ),
        FigmaUmMenuEntry.item(
          value: 'edit',
          label: 'Edit course info',
          icon: Icons.edit_rounded,
        ),
        FigmaUmMenuEntry.item(
          value: 'publish',
          label: 'Publish course',
          icon: Icons.publish_rounded,
        ),
        FigmaUmMenuEntry.item(
          value: 'cover',
          label: 'Change course cover',
          icon: Icons.add_photo_alternate_outlined,
        ),
        FigmaUmMenuEntry.item(
          value: 'archive',
          label: 'Archive course',
          icon: Icons.archive_rounded,
        ),
        FigmaUmMenuEntry.divider(),
        FigmaUmMenuEntry.item(
          value: 'delete',
          label: 'Delete course',
          icon: Icons.delete_outline_rounded,
        ),
      ],
    );

    if (!context.mounted || selected == null) return;

    switch (selected) {
      case 'materials':
        SelectedCourseCache.set(c);
        context.go(Routes.courseMaterials(slug));
        return;
      case 'invite':
        if (c.isPublic) {
          AppToast.warning(
            context,
            title: 'Invitations unavailable',
            message: 'This course is open for enrollment, so it does not use private invitations.',
          );
          return;
        }
        await showDialog<bool>(
          context: context,
          builder: (_) => InviteStudentsDialog(courseId: c.id),
        );
        return;
      case 'edit':
        await _editCourse(c);
        return;
      case 'publish':
        await _publishCourse(c);
        return;
      case 'cover':
        await _changeCourseCover(c);
        return;
      case 'archive':
        await _archiveCourse(c);
        return;
      case 'delete':
        await _deleteCourse(c);
        return;
    }
  }

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

  Future<void> _changeCourseCover(MyCourseItem course) async {
    final action = widget.onUploadCover;
    if (action == null) {
      AppToast.warning(
        context,
        title: 'Unavailable',
        message: 'Course cover upload is not available in this build.',
      );
      return;
    }

    try {
      final file = await pickSingleImageFile(
        accept: const ['image/png', 'image/jpeg', 'image/jpg'],
      );
      if (!mounted || file == null) return;

      final validationError = _coverValidationError(file);
      if (validationError != null) {
        AppToast.error(
          context,
          title: 'Invalid cover image',
          message: validationError,
        );
        return;
      }

      final updated = await action(
        course: course,
        bytes: file.bytes,
        contentType: file.mimeType,
        filename: file.name ?? 'course-cover.jpg',
      );
      SelectedCourseCache.set(updated);
      if (!mounted) return;
      AppToast.success(
        context,
        title: 'Cover updated',
        message: 'The course cover image was updated successfully.',
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Cover upload failed',
        message: mapApiFailure(error).message,
      );
    }
  }

  Future<void> _editCourse(MyCourseItem course) async {
    final action = widget.onUpdateCourse;
    if (action == null) {
      AppToast.warning(
        context,
        title: 'Unavailable',
        message: 'The current backend exposes create, list, materials, and invitations only. Course update is not available.',
      );
      return;
    }

    final payload = await showDialog<CourseUpdateRequest>(
      context: context,
      builder: (_) => _EditCourseDialog(course: course),
    );

    if (!mounted || payload == null || payload.isEmpty) return;

    try {
      final updated = await action(course, payload);
      SelectedCourseCache.set(updated);
      if (!mounted) return;
      AppToast.success(
        context,
        title: 'Course updated',
        message: 'The course information was saved.',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Update failed',
        message: 'The course could not be updated.',
      );
    }
  }

  Future<void> _publishCourse(MyCourseItem course) async {
    final action = widget.onPublishCourse;
    if (action == null) {
      AppToast.warning(
        context,
        title: 'Unavailable',
        message: 'Course publishing is not available in this build.',
      );
      return;
    }

    if (course.lifecycleStatus == CourseLifecycleStatus.published ||
        course.lifecycleStatus == CourseLifecycleStatus.active) {
      AppToast.info(
        context,
        title: 'Already published',
        message: 'This course is already visible according to its current status.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CourseActionConfirmDialog(
        icon: Icons.publish_rounded,
        title: 'Publish course?',
        message:
            '“${course.safeTitle}” will become available according to its visibility and enrollment settings.',
        confirmLabel: 'Publish course',
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      final updated = await action(course);
      SelectedCourseCache.set(updated);
      if (!mounted) return;
      AppToast.success(
        context,
        title: 'Course published',
        message: 'The course was published successfully.',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Publish failed',
        message: 'The course could not be published.',
      );
    }
  }

  Future<void> _archiveCourse(MyCourseItem course) async {
    final action = widget.onArchiveCourse;
    if (action == null) {
      AppToast.warning(
        context,
        title: 'Unavailable',
        message: 'The current backend does not expose a course archive/update endpoint.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CourseActionConfirmDialog(
        icon: Icons.archive_rounded,
        title: 'Archive course?',
        message:
            '“${course.safeTitle}” will be moved to archived courses. You can keep its existing content, but it will no longer appear as an active course.',
        confirmLabel: 'Archive course',
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      final updated = await action(course);
      SelectedCourseCache.set(updated);
      if (!mounted) return;
      AppToast.success(
        context,
        title: 'Course archived',
        message: 'The course was archived successfully.',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Archive failed',
        message: 'The course could not be archived.',
      );
    }
  }

  Future<void> _deleteCourse(MyCourseItem course) async {
    final action = widget.onDeleteCourse;
    if (action == null) {
      AppToast.warning(
        context,
        title: 'Unavailable',
        message: 'The current backend does not expose a course delete endpoint.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CourseActionConfirmDialog(
        icon: Icons.delete_outline_rounded,
        title: 'Delete course?',
        message:
            'This will permanently delete “${course.safeTitle}” and remove it from My Courses. This action cannot be undone.',
        confirmLabel: 'Delete course',
        destructive: true,
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      await action(course);
      if (!mounted) return;
      AppToast.success(
        context,
        title: 'Course deleted',
        message: 'The course was deleted successfully.',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Delete failed',
        message: 'The course could not be deleted.',
      );
    }
  }

  @override
    Widget build(BuildContext context) {
    // HTML-matched card layout (hero gradient + code badge + status pill + stats + footer)
    final lifecycleStatus = widget.course.lifecycleStatus;
    final isActive = lifecycleStatus == CourseLifecycleStatus.active ||
        lifecycleStatus == CourseLifecycleStatus.published;
    final isDraft = lifecycleStatus == CourseLifecycleStatus.draft;
    final isArchived = lifecycleStatus == CourseLifecycleStatus.archived;
    final statusLabel = lifecycleStatus.label;
    final statusBg = isActive
        ? const Color(0xE616A34A)
        : (isDraft
            ? const Color(0xE5F59E0B)
            : const Color(0xBF64748B));
    final heroGradient = isDraft
        ? LinearGradient(colors: [AppColors.textTitle, const Color(0xFF1E293B)])
        : (isArchived
            ? LinearGradient(colors: [AppColors.textHint, AppColors.textGray500])
            : const LinearGradient(colors: [Color(0xFF134E4A), Color(0xFF0891B2)]));
    final coverUrl = (widget.course.coverImageUrl ?? '').trim();
    final hasCover = coverUrl.isNotEmpty;
    final enrollCount = widget.course.enrollmentCount ?? 0;
    final modulesCount = widget.course.moduleCount ?? 0;
    final code = (widget.course.courseCode?.isNotEmpty ?? false) ? widget.course.courseCode! : '—';
    final metaLeft = widget.course.category ?? 'General';
    final metaRight = widget.course.accessType.label;
    final meta = '$metaLeft • $metaRight';
  
  return MouseRegion(
    onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() => hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      transform: hover ? (Matrix4.identity()..setTranslationRaw(0.0, -1.0, 0.0)) : Matrix4.identity(),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hover ? AppColors.badgeBlueBorder : AppColors.border,
          width: hover ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (hover)
            const BoxShadow(color: Color(0x14137FEC), blurRadius: 28, offset: Offset(0, 10))
          else
            const BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), 
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final slug = buildCourseRouteSlug(widget.course);
          SelectedCourseCache.set(widget.course);
          context.go(Routes.courseDetails(slug)); // ✅ navigate to course details
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              SizedBox(
                height: 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hasCover
                          ? Image.network(
                              coverUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => DecoratedBox(
                                decoration: BoxDecoration(gradient: heroGradient),
                              ),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(gradient: heroGradient),
                            ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0x80000000), Color(0x00000000)],
                            stops: [0.0, 0.6],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xE6FFFFFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDraft ? Icons.edit_rounded : (isArchived ? Icons.inventory_2_outlined : Icons.check_rounded),
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textTitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CourseStat(icon: Icons.groups_rounded, label: '$enrollCount Students'),
                        const SizedBox(width: 14),
                        _CourseStat(icon: Icons.grid_view_rounded, label: '$modulesCount Modules'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: AppColors.divider),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Avatar stack (mocked, but matches HTML look)
                        const _AvatarStack(),
                        const Spacer(),
                        Row(
                          children: [
                            _IconBtnSm(icon: Icons.schedule_rounded, onTap: () {}),
                            const SizedBox(width: 4),
                            _IconBtnSm(
                              key: _moreKey,
                              icon: Icons.more_horiz_rounded,
                              onTap: () => _showCourseMenuFromKey(context, widget.course, _moreKey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

}


class _EditCourseDialog extends StatefulWidget {
  final MyCourseItem course;

  const _EditCourseDialog({required this.course});

  @override
  State<_EditCourseDialog> createState() => _EditCourseDialogState();
}

class _EditCourseDialogState extends State<_EditCourseDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _categoryCtrl;

  late String _visibility;
  bool _approvalRequired = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.course.safeTitle);
    _codeCtrl = TextEditingController(text: widget.course.courseCode ?? '');
    _categoryCtrl = TextEditingController(text: widget.course.category ?? '');
    _visibility = widget.course.visibility.backendValue;
    _approvalRequired = widget.course.isPrivate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  bool get _isPublic => _visibility == CourseVisibility.public.backendValue;

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      AppToast.error(
        context,
        title: 'Validation error',
        message: 'Course title is required.',
      );
      return;
    }

    Navigator.of(context).pop(
      CourseUpdateRequest(
        title: title,
        courseCode: _codeCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        isPublic: _isPublic,
        visibilityLevel: _visibility,
        requiresEnrollmentApproval: _approvalRequired,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: AppColors.primary, size: 20,),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit course info',
                            style: TextStyle(
                              color: AppColors.textTitle,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update the course name, code, category, and visibility.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.divider),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _EditCourseLabel('Course title'),
                      const SizedBox(height: 6),
                      _EditCourseTextField(
                        controller: _titleCtrl,
                        hint: 'Course title',
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _EditCourseLabel('Course code'),
                                const SizedBox(height: 6),
                                _EditCourseTextField(
                                  controller: _codeCtrl,
                                  hint: 'Optional code',
                                  icon: Icons.tag_rounded,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _EditCourseLabel('Category'),
                                const SizedBox(height: 6),
                                _EditCourseTextField(
                                  controller: _categoryCtrl,
                                  hint: 'General',
                                  icon: Icons.category_outlined,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _EditCourseDropdown(
                        label: 'Visibility',
                        value: _visibility,
                        items: const [
                          'private',
                          'public',
                          'unlisted',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _visibility = value;
                            _approvalRequired = value != 'public';
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10,),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Require enrollment approval',
                                    style: TextStyle(
                                      color: AppColors.textTitle,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Useful for private or controlled courses.',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _approvalRequired,
                              onChanged: (value) => setState(
                                  () => _approvalRequired = value,),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save changes'),
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

class _EditCourseLabel extends StatelessWidget {
  final String text;

  const _EditCourseLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textTitle,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _EditCourseTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _EditCourseTextField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.textTitle, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.surfaceBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      ),
    );
  }
}

class _EditCourseDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _EditCourseDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditCourseLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: AppColors.cardBg,
          iconEnabledColor: AppColors.muted,
          style: TextStyle(
            color: AppColors.textTitle,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item[0].toUpperCase() + item.substring(1)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _CourseActionConfirmDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  const _CourseActionConfirmDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.dangerText : AppColors.primary;
    final accentBg = destructive ? AppColors.dangerBg : AppColors.primarySoft;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: accent, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: destructive
                        ? FilledButton.styleFrom(backgroundColor: accent)
                        : null,
                    child: Text(confirmLabel),
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

class _CourseStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CourseStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: 56,
      child: Stack(
        children: [
          _AvatarDot(left: 0,  bg: AppColors.border),
          _AvatarDot(left: 16, bg: AppColors.badgeBlueBg),
          const _AvatarDot(left: 32, bg: Color(0xFFE9FBF1)),
        ],
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  final double left;
  final Color bg;

  const _AvatarDot({required this.left, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(Icons.person, size: 14, color: AppColors.textMuted),
      ),
    );
  }
}

class _IconBtnSm extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconBtnSm({super.key, required this.icon, this.onTap});

  @override
  State<_IconBtnSm> createState() => _IconBtnSmState();
}

class _IconBtnSmState extends State<_IconBtnSm> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), 
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: hover ? AppColors.headerBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(widget.icon, size: 18, color: AppColors.muted),
        ),
      ),
    );
  }
}

// ==================== Card Shell ====================

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _CardShell({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:        _CourseTokens.cardBg,
        borderRadius: BorderRadius.circular(_CourseTokens.radiusCard),
        border:       Border.all(color: _CourseTokens.border),
      ),
      child: child,
    );
  }
}

// ==================== Inline Error Banner ====================

class _InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _InlineErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_rounded, color: Color(0xFFB45309)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  color:      Color(0xFF92400E),
                  fontWeight: FontWeight.w700,),
              maxLines:  2,
              overflow:  TextOverflow.ellipsis,),
        ),
        const SizedBox(width: 10),
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon:  const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF92400E),),
          ),
      ],),
    );
  }
}