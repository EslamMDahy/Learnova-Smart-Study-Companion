import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/theme/app_theme.dart';
import 'package:learnova/core/ui/toast.dart';
import 'package:learnova/features/instructor/data/courses_providers.dart';

class InviteStudentsDialog extends ConsumerStatefulWidget {
  final int courseId;
  const InviteStudentsDialog({super.key, required this.courseId});

  @override
  ConsumerState<InviteStudentsDialog> createState() =>
      _InviteStudentsDialogState();
}

class _InviteStudentsDialogState extends ConsumerState<InviteStudentsDialog> {
  bool _loading = false;
  PlatformFile? _pickedFile;
  bool _sendAfterUpload = true;

  // ألوان التصميم الجديد
  Color get _accentColor => AppColors.primary;
  Color get _bgLight => AppColors.surfaceBg;
  Color get _border => AppColors.border;


  Future<void> _downloadTemplate() async {
    AppToast.info(
      context,
      title: 'Template format',
      message: 'Use a spreadsheet with one column named email.',
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      allowMultiple: false,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final name = file.name.toLowerCase();
    final valid = name.endsWith('.xlsx') ||
        name.endsWith('.xls') ||
        name.endsWith('.csv');

    if (!valid) {
      AppToast.error(
        context,
        title: 'Invalid file',
        message: 'Please choose an Excel or CSV file.',
      );
      return;
    }

    setState(() => _pickedFile = file);
  }

  Future<void> _submit() async {
    final file = _pickedFile;
    final bytes = file?.bytes;

    if (file == null || bytes == null || bytes.isEmpty) {
      AppToast.error(
        context,
        title: 'No file selected',
        message: 'Choose an Excel or CSV file before uploading.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final repo = ref.read(coursesRepositoryProvider);
      await repo.uploadInvitationsFile(
        courseId: widget.courseId.toString(),
        bytes: bytes,
        filename: file.name,
      );

      if (_sendAfterUpload) {
        await repo.sendInvitations(courseId: widget.courseId.toString());
      }

      if (!mounted) return;
      AppToast.success(
        context,
        title: 'Invitations ready',
        message: _sendAfterUpload
            ? 'Students were uploaded and invitations were sent.'
            : 'Students were uploaded successfully.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Upload failed',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 550,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTemplateSection(),
                    SizedBox(height: 24),
                    _buildUploadZone(),
                    SizedBox(height: 24),
                    _buildSettingsToggle(),
                    SizedBox(height: 32),
                    _buildActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.group_add_rounded, color: _accentColor, size: 28),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite Students',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Import your student list via Excel/CSV',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please use our official template for a smooth import.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _downloadTemplate,
            icon: Icon(Icons.download_rounded, size: 18),
            label: Text('Download'),
            style: TextButton.styleFrom(foregroundColor: Colors.amber[900]),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadZone() {
    return InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: WidgetStatePropertyAll(Colors.transparent), 
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _pickedFile != null
              ? _accentColor.withOpacity(0.02)
              : _bgLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pickedFile != null ? _accentColor : _border,
            style: _pickedFile != null ? BorderStyle.solid : BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _pickedFile != null
                  ? Icons.insert_drive_file_rounded
                  : Icons.cloud_upload_outlined,
              size: 48,
              color: _pickedFile != null ? _accentColor : Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _pickedFile != null
                  ? _pickedFile!.name
                  : 'Click to select or drag file',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _pickedFile != null
                    ? _accentColor
                    : Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _pickedFile != null
                  ? '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB'
                  : 'Supports .xlsx, .xls, .csv up to 10MB',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(Icons.mark_email_read_outlined, color: AppColors.textMuted),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Invitations',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  'Notify students via email after upload',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: _sendAfterUpload,
            onChanged: (v) => setState(() => _sendAfterUpload = v),

            // لون الدائرة (الـ Thumb)
            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white; // لما يكون شغال تكون الدائرة بيضاء واضحة
              }
              return Colors.white;
            }),

            // لون المسار (الـ Track)
            trackColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return Color(
                  0xFF137FEC,
                ); // أزرق مريح للعين لما يكون Active
              }
              return AppColors.border; // رمادي فاتح جداً لما يكون المطفي
            }),

            // إخفاء الحدود الخارجية المزعجة
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.cardBg,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Upload & Continue',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
          ),
        ),
      ],
    );
  }
}
