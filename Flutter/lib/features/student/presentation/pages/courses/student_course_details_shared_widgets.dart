part of 'student_course_details_page.dart';

class _AssistantMessage extends StatelessWidget {
  final bool isUser;
  final Widget child;

  const _AssistantMessage({required this.isUser, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth ? constraints.maxWidth : 520.0;
        final bubbleMaxWidth = isUser ? math.min(420.0, availableWidth * 0.84) : availableWidth;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
            child: Container(
              width: isUser ? null : double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isUser ? 14 : 15,
                vertical: isUser ? 10 : 13,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowThin,
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _AssistantChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AssistantChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;

    return Material(
      color: active ? AppColors.selectedBg : AppColors.headerBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primary : AppColors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantBotIcon extends StatelessWidget {
  final double size;

  const _AssistantBotIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.primary,
            AppColors.badgeIndigoFg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;

  const _SoftBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CourseWorkspaceLoading extends StatelessWidget {
  const _CourseWorkspaceLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 14),
              Text(
                'Loading course content...',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseRouteError extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  const _CourseRouteError({
    required this.title,
    required this.message,
    required this.onBack,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowThin,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.dangerText,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('My Courses'),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLessonState extends StatelessWidget {
  final int courseId;
  final VoidCallback onRefresh;

  const _EmptyLessonState({required this.courseId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, color: AppColors.textMuted, size: 42),
          const SizedBox(height: 14),
          Text(
            'No course content yet',
            style: TextStyle(
              color: AppColors.textTitle,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Only published modules and uploaded materials are visible to students. Ask the instructor to publish the module and make sure materials are uploaded, not still processing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _EmptySidebarState extends StatelessWidget {
  const _EmptySidebarState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off_outlined, color: AppColors.textMuted, size: 30),
          const SizedBox(height: 10),
          Text(
            'No published content',
            style: TextStyle(
              color: AppColors.textTitle,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Published modules with uploaded materials will appear here. Draft modules and processing files are hidden from students by the backend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _materialIcon(StudentCourseMaterial? material) {
  if (material == null) return Icons.play_circle_outline_rounded;

  final type = material.type.trim().toLowerCase();
  final mime = (material.mimeType ?? '').trim().toLowerCase();

  if (type.contains('video') || mime.startsWith('video/')) {
    return Icons.play_circle_outline_rounded;
  }
  if (type.contains('quiz') || type.contains('exam')) {
    return Icons.assignment_outlined;
  }
  if (type.contains('presentation') || type.contains('slide')) {
    return Icons.slideshow_outlined;
  }
  if (type.contains('link')) {
    return Icons.link_rounded;
  }
  if (type.contains('pdf') || mime.contains('pdf')) {
    return Icons.picture_as_pdf_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

bool _isPdfMaterial(StudentCourseMaterial material) {
  final type = material.type.trim().toLowerCase();
  final mime = (material.mimeType ?? '').trim().toLowerCase();
  final fileName = (material.fileName ?? '').trim().toLowerCase();
  return type.contains('pdf') || mime.contains('pdf') || fileName.endsWith('.pdf');
}

String _formatScore(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}


String _formatElapsedTime(int seconds) {
  if (seconds <= 0) return '0m 0s';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${remainingSeconds}s';
  }
  return '${remainingSeconds}s';
}

String _formatResultDate(DateTime? value) {
  if (value == null) return 'not submitted yet';
  final local = value.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final month = months[(local.month - 1).clamp(0, 11)];
  final minute = local.minute.toString().padLeft(2, '0');
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$month ${local.day}, ${local.year} • $hour12:$minute $period';
}

String _shortText(String value, int maxLength) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= maxLength) return normalized;
  if (maxLength <= 1) return normalized.substring(0, maxLength);
  return '${normalized.substring(0, maxLength - 1).trimRight()}…';
}


String _lessonTitle(
  StudentCourseModule module,
  StudentCourseMaterial? material,
) {
  if (material == null) return module.safeTitle;

  final index = module.materials.indexWhere((item) => item.id == material.id);
  final lessonNumber = index < 0 ? '' : '${module.orderIndex + 1}.${index + 1} ';
  return '$lessonNumber${material.safeTitle}';
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final fixed = value >= 10 || unitIndex == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$fixed ${units[unitIndex]}';
}


String _titleCase(String value) {
  final normalized = value.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) return 'Not provided';

  return normalized
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}

String _displayName() {
  final name = (UserStorage.userMap?['full_name'] ?? '').toString().trim();
  if (name.isNotEmpty) return name;
  return 'Student';
}

String _displaySubtitle() {
  final orgs = UserStorage.organizations;
  if (orgs.isNotEmpty) {
    final orgName = (orgs.first['name'] ?? '').toString().trim();
    if (orgName.isNotEmpty) return orgName;
  }
  return 'Student Portal';
}

