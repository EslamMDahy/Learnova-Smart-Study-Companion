import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/browser_file_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Public contracts
// ─────────────────────────────────────────────────────────────────────────────
class UploadSheetResult {
  final Uint8List bytes;
  final String filename;
  final String contentType;
  final String title;
  const UploadSheetResult({
    required this.bytes,
    required this.filename,
    required this.contentType,
    required this.title,
  });
}

enum UploadSheetProcessingStage { uploading, processing, ready, error }

class UploadSheetUploadUpdate {
  final UploadSheetProcessingStage stage;
  final double? progress;
  final String? message;

  const UploadSheetUploadUpdate({
    required this.stage,
    this.progress,
    this.message,
  });
}

class UploadSheetUploadResult {
  final bool success;
  final bool ready;
  final int? materialId;
  final String? message;

  const UploadSheetUploadResult({
    required this.success,
    required this.ready,
    this.materialId,
    this.message,
  });

  const UploadSheetUploadResult.ready({int? materialId, String? message})
      : this(
          success: true,
          ready: true,
          materialId: materialId,
          message: message ?? 'AI analysis completed. Ready to save.',
        );

  const UploadSheetUploadResult.error(String message, {int? materialId})
      : this(
          success: false,
          ready: false,
          materialId: materialId,
          message: message,
        );
}

typedef UploadSheetUploadHandler = Future<UploadSheetUploadResult> Function(
  UploadSheetResult file,
  void Function(UploadSheetUploadUpdate update) update,
);

// ─────────────────────────────────────────────────────────────────────────────
//  Internal model
// ─────────────────────────────────────────────────────────────────────────────
enum _FileStatus { queued, uploading, processing, ready, error }

class _QueuedFile {
  final String name;
  final int sizeBytes;
  final Uint8List bytes;
  final _FileStatus status;
  final String? message;
  final int? materialId;
  final double progress;

  const _QueuedFile({
    required this.name,
    required this.sizeBytes,
    required this.bytes,
    required this.status,
    this.message,
    this.materialId,
    this.progress = 0,
  });

  _QueuedFile copyWith({
    _FileStatus? status,
    String? message,
    int? materialId,
    double? progress,
    bool clearMessage = false,
  }) {
    return _QueuedFile(
      name: name,
      sizeBytes: sizeBytes,
      bytes: bytes,
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
      materialId: materialId ?? this.materialId,
      progress: progress ?? this.progress,
    );
  }

  String get displaySize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1048576) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
  }

  String get ext {
    final i = name.lastIndexOf('.');
    return i >= 0 ? name.substring(i + 1).toUpperCase() : 'FILE';
  }

  bool get canRemove => status == _FileStatus.queued || status == _FileStatus.error;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dialog
// ─────────────────────────────────────────────────────────────────────────────
class UploadMaterialSheet extends StatefulWidget {
  final String moduleTitle;
  final UploadSheetUploadHandler? onUpload;

  const UploadMaterialSheet({
    super.key,
    required this.moduleTitle,
    this.onUpload,
  });

  @override
  State<UploadMaterialSheet> createState() => _UploadMaterialSheetState();
}

class _UploadMaterialSheetState extends State<UploadMaterialSheet>
    with TickerProviderStateMixin {
  final List<_QueuedFile> _queue = [];
  bool _hovering = false;
  bool _processing = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  static const int _maxBytes = 50 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _browse() async {
    if (_processing) return;
    final files = await pickBrowserFiles(acceptedExtensions: ['pdf']);
    if (!mounted) return;
    for (final file in files) {
      _queuePickedFile(file);
    }
  }

  void _queuePickedFile(PickedBrowserFile file) {
    final valid = file.sizeBytes <= _maxBytes && _isSupportedPdf(file);
    setState(() {
      _queue.add(_QueuedFile(
        name: file.name,
        sizeBytes: file.sizeBytes,
        bytes: file.bytes,
        status: valid ? _FileStatus.queued : _FileStatus.error,
        message: valid ? 'Waiting in queue' : 'Only PDF files are supported, up to 50 MB.',
      ));
    });
  }

  static final RegExp _pdfExtension = RegExp(r'\.pdf$', caseSensitive: false);

  bool _isSupportedPdf(PickedBrowserFile file) {
    final hasPdfExtension = _pdfExtension.hasMatch(file.name);
    final mime = file.mimeType.trim().toLowerCase();
    final mimeLooksPdf = mime.isEmpty || mime == 'application/pdf';
    return hasPdfExtension && mimeLooksPdf;
  }

  String _contentTypeForUpload(String filename) {
    if (_pdfExtension.hasMatch(filename)) return 'application/pdf';
    throw StateError('Unsupported upload type for $filename');
  }

  UploadSheetResult _resultFor(_QueuedFile file) {
    final dot = file.name.lastIndexOf('.');
    return UploadSheetResult(
      bytes: file.bytes,
      filename: file.name,
      contentType: _contentTypeForUpload(file.name),
      title: dot > 0 ? file.name.substring(0, dot) : file.name,
    );
  }

  void _remove(int i) {
    if (_processing || !_queue[i].canRemove) return;
    setState(() => _queue.removeAt(i));
  }

  void _clearTerminal() {
    if (_processing) return;
    setState(() => _queue.removeWhere(
          (f) => f.status == _FileStatus.ready || f.status == _FileStatus.error,
        ));
  }

  Future<void> _primaryAction() async {
    if (_processing) return;
    if (_queue.isEmpty) return;

    final queuedCount = _queue.where((f) => f.status == _FileStatus.queued).length;
    final readyCount = _queue.where((f) => f.status == _FileStatus.ready).length;
    final terminalCount = _queue.where((f) => f.status == _FileStatus.ready || f.status == _FileStatus.error).length;

    if (queuedCount == 0 && terminalCount == _queue.length && readyCount > 0) {
      Navigator.of(context).pop(true);
      return;
    }

    await _runQueue();
  }

  Future<void> _runQueue() async {
    final handler = widget.onUpload;
    if (handler == null) {
      setState(() {
        for (var i = 0; i < _queue.length; i++) {
          if (_queue[i].status == _FileStatus.queued) {
            _queue[i] = _queue[i].copyWith(
              status: _FileStatus.ready,
              progress: 1,
              message: 'Ready to save',
            );
          }
        }
      });
      return;
    }

    setState(() => _processing = true);
    try {
      for (var i = 0; i < _queue.length; i++) {
        if (!mounted) return;
        if (_queue[i].status != _FileStatus.queued) continue;

        setState(() {
          _queue[i] = _queue[i].copyWith(
            status: _FileStatus.uploading,
            progress: 0,
            message: 'Uploading to storage...',
            clearMessage: false,
          );
        });

        final file = _resultFor(_queue[i]);
        try {
          final result = await handler(file, (update) {
            if (!mounted) return;
            setState(() {
              _queue[i] = _queue[i].copyWith(
                status: _mapStage(update.stage),
                progress: update.progress,
                message: update.message,
              );
            });
          });

          if (!mounted) return;
          setState(() {
            _queue[i] = _queue[i].copyWith(
              status: result.success && result.ready ? _FileStatus.ready : _FileStatus.error,
              materialId: result.materialId,
              progress: result.success && result.ready ? 1 : _queue[i].progress,
              message: result.message ??
                  (result.success ? 'AI analysis completed.' : 'Upload failed.'),
            );
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _queue[i] = _queue[i].copyWith(
              status: _FileStatus.error,
              message: 'Upload failed. Please retry this file.',
            );
          });
        }
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  _FileStatus _mapStage(UploadSheetProcessingStage stage) {
    switch (stage) {
      case UploadSheetProcessingStage.uploading:
        return _FileStatus.uploading;
      case UploadSheetProcessingStage.processing:
        return _FileStatus.processing;
      case UploadSheetProcessingStage.ready:
        return _FileStatus.ready;
      case UploadSheetProcessingStage.error:
        return _FileStatus.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final readyCount = _queue.where((f) => f.status == _FileStatus.ready).length;
    final queuedCount = _queue.where((f) => f.status == _FileStatus.queued).length;
    final activeCount = _queue.where((f) => f.status == _FileStatus.uploading || f.status == _FileStatus.processing).length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 110, vertical: 54),
      child: LayoutBuilder(builder: (ctx, constraints) {
        return Container(
          width: constraints.maxWidth.clamp(0.0, 920.0),
          height: constraints.maxHeight.clamp(0.0, 560.0),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.10),
                blurRadius: 60,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Row(children: [
              Expanded(
                flex: 54,
                child: _LeftPanel(
                  moduleTitle: widget.moduleTitle,
                  hovering: _hovering,
                  pulse: _pulse,
                  queueCount: _queue.length,
                  processing: _processing,
                  onBrowse: _browse,
                  onEnter: () => setState(() => _hovering = true),
                  onExit: () => setState(() => _hovering = false),
                ),
              ),
              Expanded(
                flex: 46,
                child: _RightPanel(
                  queue: _queue,
                  readyCount: readyCount,
                  queuedCount: queuedCount,
                  activeCount: activeCount,
                  processing: _processing,
                  onRemove: _remove,
                  onClear: _clearTerminal,
                  onCancel: () => Navigator.of(context).pop(readyCount > 0),
                  onPrimary: _primaryButtonEnabled ? _primaryAction : null,
                  primaryLabel: _primaryLabel,
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }

  bool get _primaryButtonEnabled {
    if (_processing || _queue.isEmpty) return false;
    final hasQueued = _queue.any((f) => f.status == _FileStatus.queued);
    final hasReady = _queue.any((f) => f.status == _FileStatus.ready);
    return hasQueued || hasReady;
  }

  String get _primaryLabel {
    if (_processing) return 'Processing queue...';
    if (_queue.isEmpty) return 'Save to Course';
    final queuedCount = _queue.where((f) => f.status == _FileStatus.queued).length;
    final readyCount = _queue.where((f) => f.status == _FileStatus.ready).length;
    final terminalCount = _queue.where((f) => f.status == _FileStatus.ready || f.status == _FileStatus.error).length;
    if (queuedCount > 0) return queuedCount == 1 ? 'Upload & Analyze' : 'Upload Queue ($queuedCount)';
    if (terminalCount == _queue.length && readyCount > 0) {
      return readyCount == 1 ? 'Save to Course' : 'Save to Course ($readyCount)';
    }
    return 'Waiting for AI...';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LEFT dark panel
// ─────────────────────────────────────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  final String moduleTitle;
  final bool hovering;
  final Animation<double> pulse;
  final int queueCount;
  final bool processing;
  final VoidCallback onBrowse;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  const _LeftPanel({
    required this.moduleTitle,
    required this.hovering,
    required this.pulse,
    required this.queueCount,
    required this.processing,
    required this.onBrowse,
    required this.onEnter,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1727), Color(0xFF0F2540), Color(0xFF0A1929)],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        AnimatedBuilder(
          animation: pulse,
          builder: (_, __) => Positioned(
            left: -70,
            top: -70 + pulse.value * 18,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.16 + pulse.value * 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 34, 36, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.primary.withOpacity(0.38)),
                  ),
                  child: Icon(Icons.upload_file_rounded, size: 20, color: AppColors.infoText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      processing ? 'AI Pipeline Running' : 'Upload Materials',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.infoText,
                        letterSpacing: 0.35,
                      ),
                    ),
                    Text(
                      '→ $moduleTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.46)),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 32),
              const Text(
                'Upload PDFs\nfor AI analysis.',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.08,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'One file is processed at a time · PDF only · Max 50 MB',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.48)),
              ),
              const SizedBox(height: 34),
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => onEnter(),
                  onExit: (_) => onExit(),
                  child: GestureDetector(
                    onTap: processing ? null : onBrowse,
                    child: AnimatedBuilder(
                      animation: pulse,
                      builder: (_, __) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: hovering && !processing
                              ? AppColors.primary.withOpacity(0.12)
                              : Colors.white.withOpacity(0.04 + pulse.value * 0.015),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: hovering && !processing
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.12 + pulse.value * 0.05),
                            width: hovering && !processing ? 2 : 1.3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: pulse,
                              builder: (_, __) => Transform.translate(
                                offset: Offset(0, -3 + pulse.value * 6),
                                child: Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: hovering && !processing
                                        ? AppColors.primary.withOpacity(0.24)
                                        : Colors.white.withOpacity(0.07),
                                    border: Border.all(
                                      color: hovering && !processing
                                          ? AppColors.infoText.withOpacity(0.58)
                                          : Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Icon(
                                    processing ? Icons.sync_rounded : Icons.cloud_upload_outlined,
                                    size: 34,
                                    color: processing
                                        ? AppColors.infoText
                                        : Colors.white.withOpacity(0.62),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              processing
                                  ? 'Queue is locked while processing'
                                  : hovering
                                      ? 'Click to add PDFs'
                                      : 'Drag & drop PDFs',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: hovering && !processing
                                    ? AppColors.infoText
                                    : Colors.white.withOpacity(0.86),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              queueCount == 0
                                  ? 'Files will move from queued → processing → ready'
                                  : '$queueCount file${queueCount == 1 ? '' : 's'} in queue',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.42)),
                            ),
                            const SizedBox(height: 24),
                            IgnorePointer(
                              ignoring: processing,
                              child: Opacity(
                                opacity: processing ? 0.55 : 1,
                                child: GestureDetector(
                                  onTap: onBrowse,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.34),
                                          blurRadius: 18,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Browse Files',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 14, runSpacing: 8, children: [
                _Tip(icon: Icons.auto_awesome_rounded, text: 'AI auto-analysis'),
                _Tip(icon: Icons.linear_scale_rounded, text: 'Sequential queue'),
                _Tip(icon: Icons.text_snippet_outlined, text: 'OCR supported'),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.infoText),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.46))),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Grid painter
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  RIGHT panel
// ─────────────────────────────────────────────────────────────────────────────
class _RightPanel extends StatelessWidget {
  final List<_QueuedFile> queue;
  final int readyCount;
  final int queuedCount;
  final int activeCount;
  final bool processing;
  final ValueChanged<int> onRemove;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final VoidCallback? onPrimary;
  final String primaryLabel;

  const _RightPanel({
    required this.queue,
    required this.readyCount,
    required this.queuedCount,
    required this.activeCount,
    required this.processing,
    required this.onRemove,
    required this.onClear,
    required this.onCancel,
    required this.onPrimary,
    required this.primaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      color: AppColors.cardBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 0),
          child: Row(children: [
            Text(
              'Processing Queue',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.textTitle,
                letterSpacing: -0.35,
              ),
            ),
            const Spacer(),
            if (queue.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: activeCount > 0 ? const Color(0xFFFFF7E6) : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  activeCount > 0 ? '$activeCount active' : '${queue.length} files',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: activeCount > 0 ? const Color(0xFFD97706) : AppColors.primary,
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Text(
            queue.isEmpty
                ? 'Files you add will appear here'
                : '$readyCount ready · $queuedCount queued${activeCount > 0 ? ' · $activeCount processing' : ''}',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ),
        const SizedBox(height: 18),
        Divider(height: 1, color: AppColors.headerBg),
        Expanded(
          child: queue.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(Icons.inbox_outlined, size: 30, color: AppColors.borderSoft),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Nothing here yet',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add PDFs from the left.\nEach file will process one by one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.borderSoft, height: 1.45),
                    ),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  itemCount: queue.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.surfaceBg),
                  itemBuilder: (_, i) => _QueueTile(
                    file: queue[i],
                    onRemove: () => onRemove(i),
                  ),
                ),
        ),
        if (queue.isNotEmpty) ...[
          Divider(height: 1, color: AppColors.headerBg),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 12, 26, 8),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: processing ? null : onClear,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: AppColors.textMuted,
                ),
                child: const Text('Clear completed / failed', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.fromLTRB(26, 14, 26, 24),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.headerBg))),
          child: Column(children: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onPrimary,
                icon: processing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_alt_rounded, size: 18),
                label: Text(primaryLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textHint,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                onPressed: processing ? null : onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textHint,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Queue tile
// ─────────────────────────────────────────────────────────────────────────────
class _QueueTile extends StatelessWidget {
  final _QueuedFile file;
  final VoidCallback onRemove;
  const _QueueTile({required this.file, required this.onRemove});

  (IconData, Color, Color) get _fileVisual {
    switch (file.ext) {
      case 'PDF':
        return (Icons.picture_as_pdf_rounded, AppColors.dangerBorder, AppColors.errorDot);
      default:
        return (Icons.insert_drive_file_rounded, AppColors.purpleBg, const Color(0xFFA855F7));
    }
  }

  (String, IconData, Color, Color) get _statusVisual {
    switch (file.status) {
      case _FileStatus.queued:
        return ('Queued', Icons.schedule_rounded, AppColors.primarySoft, AppColors.primary);
      case _FileStatus.uploading:
        return ('Uploading', Icons.cloud_upload_rounded, const Color(0xFFE0F2FE), const Color(0xFF0369A1));
      case _FileStatus.processing:
        return ('Processing', Icons.sync_rounded, const Color(0xFFFFF7E6), const Color(0xFFD97706));
      case _FileStatus.ready:
        return ('Ready', Icons.check_circle_rounded, AppColors.successBg, AppColors.successDot);
      case _FileStatus.error:
        return ('Error', Icons.error_outline_rounded, AppColors.dangerBg, AppColors.errorDot);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final (icon, iconBg, iconFg) = _fileVisual;
    final (statusLabel, statusIcon, statusBg, statusFg) = _statusVisual;
    final showProgress = file.status == _FileStatus.uploading || file.status == _FileStatus.processing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 18, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 21, color: iconFg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textGray),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, size: 12, color: statusFg),
                  const SizedBox(width: 4),
                  Text(statusLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: statusFg)),
                ]),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              file.message ?? file.displaySize,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: file.status == _FileStatus.error ? AppColors.errorDot : AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showProgress) ...[
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: file.status == _FileStatus.processing
                      ? null
                      : file.progress.clamp(0.0, 1.0).toDouble(),
                  backgroundColor: AppColors.surfaceBg,
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onTap: file.canRemove ? onRemove : null,
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: file.canRemove ? 1 : 0.35,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.surfaceBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.close_rounded, size: 14, color: AppColors.borderSoft),
            ),
          ),
        ),
      ]),
    );
  }
}
