import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learnova/core/utils/file_download_stub.dart'
    if (dart.library.html) 'package:learnova/core/utils/file_download_web.dart'
    as file_download;

import '../../data/courses_providers.dart';

/// Dialog to invite students for PRIVATE courses.
///
/// Backend supports:
/// - POST /courses/{id}/invitations/upload (multipart file)
/// - POST /courses/{id}/invitations/send
///
/// So frontend should upload an Excel/CSV file then optionally trigger send.
class InviteStudentsDialog extends ConsumerStatefulWidget {
  final int courseId;

  const InviteStudentsDialog({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<InviteStudentsDialog> createState() => _InviteStudentsDialogState();
}

class _InviteStudentsDialogState extends ConsumerState<InviteStudentsDialog> {
  String? _error;
  bool _loading = false;

  PlatformFile? _pickedFile;
  Uint8List? _pickedBytes;

  bool _sendAfterUpload = true;

  void _downloadTemplate() {
    const csv = 'email,full_name\nstudent1@example.com,Student One\nstudent2@example.com,Student Two\n';
    file_download.downloadTextFile(
      filename: 'invite_template.csv',
      content: csv,
      mimeType: 'text/csv',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template downloaded. Fill it, then upload.')),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
    });

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true, // important for web + easier upload as bytes
    );

    if (res == null || res.files.isEmpty) return;

    final f = res.files.first;
    final bytes = f.bytes;

    if (bytes == null || bytes.isEmpty) {
      setState(() => _error = 'Could not read the selected file. Please try again.');
      return;
    }

    setState(() {
      _pickedFile = f;
      _pickedBytes = bytes;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_pickedFile == null || _pickedBytes == null) {
      setState(() => _error = 'Please select an Excel/CSV file first.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(coursesRepositoryProvider);

      await repo.uploadInvitationsFile(
        courseId: widget.courseId.toString(),
        bytes: _pickedBytes!,
        filename: _pickedFile!.name,
      );

      if (_sendAfterUpload) {
        await repo.sendInvitations(
          courseId: widget.courseId.toString(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _pickedFile?.name;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(color: Color(0x14000000), blurRadius: (kIsWeb ? 12 : 26), offset: Offset(0, 14)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.group_add_rounded, color: Color(0xFF137FEC)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite Students',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111418)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Upload an Excel/CSV file, then we’ll create invitations (and send them if you choose).',
                            style: TextStyle(fontSize: 12.4, fontWeight: FontWeight.w600, color: Color(0xFF617589)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF617589)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _loading ? null : _downloadTemplate,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download CSV template', style: TextStyle(fontWeight: FontWeight.w900)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF137FEC)),
                    ),
                    const Spacer(),
                    const Text(
                      'Accepted: .csv, .xlsx',
                      style: TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fileName == null ? 'No file selected' : fileName,
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w700,
                            color: fileName == null ? const Color(0xFF94A3B8) : const Color(0xFF111418),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _pickFile,
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('Choose file', style: TextStyle(fontWeight: FontWeight.w900)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF137FEC),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _sendAfterUpload,
                      onChanged: _loading ? null : (v) => setState(() => _sendAfterUpload = v ?? true),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Send invitations after upload',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111418)),
                      ),
                    ),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ],

                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton(
                      onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF617589),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      label: Text(
                        _loading ? 'Processing...' : 'Upload & Continue',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF137FEC),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}