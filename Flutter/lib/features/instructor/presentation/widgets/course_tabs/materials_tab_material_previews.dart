part of 'materials_tab.dart';

enum _PK { pdf, image, video, audio, link, other }

class _FilePreviewWidget extends StatelessWidget {
  final MaterialItem material; final String? downloadUrl;
  final bool loading; final VoidCallback onRefresh;
  final bool interactive;
  final _PdfPageRange? pageRange;
  const _FilePreviewWidget({required this.material, required this.downloadUrl,
      required this.loading, required this.onRefresh, required this.interactive,
      this.pageRange,});

  _PK get _kind {
    final t = material.type.toLowerCase(); final m = (material.mimeType ?? '').toLowerCase();
    if (t == 'video' || m.startsWith('video/')) return _PK.video;
    if (t == 'pdf'   || m == 'application/pdf') return _PK.pdf;
    if (t == 'image' || m.startsWith('image/')) return _PK.image;
    if (t == 'audio' || m.startsWith('audio/')) return _PK.audio;
    if (t == 'link') return _PK.link;
    return _PK.other;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (loading) return _LoaderW(label: 'Loading preview…');
    if (material.isProcessing && material.status != 'uploaded') {
      return const _PlaceholderW(icon: Icons.hourglass_top_rounded,
        iconColor: _K.amber, iconBg: _K.amberSoft, title: 'Processing…',
        sub: 'Your file is being processed. Preview will be available shortly.',);
    }
    if (material.isError && material.status != 'uploaded') {
      return _PlaceholderW(icon: Icons.error_outline_rounded,
        iconColor: AppColors.dangerText, iconBg: _K.redSoft, title: 'Processing failed',
        sub: 'Something went wrong processing this file.',
        actionLabel: 'Retry', onAction: onRefresh,);
    }
    if (downloadUrl == null || downloadUrl!.isEmpty) {
      return _PlaceholderW(icon: Icons.link_off_rounded, iconColor: AppColors.textMuted,
          iconBg: _K.bg, title: 'Preview unavailable',
          sub: 'Could not load a URL for this file.',
          actionLabel: 'Retry', onAction: onRefresh,);
    }

    final url = downloadUrl!;
    return switch (_kind) {
      _PK.pdf   => _PdfPreviewWidget(url: url, material: material, interactive: interactive, pageRange: pageRange),
      _PK.image => _ImagePreviewWidget(url: url),
      _PK.video => _VideoPreviewWidget(url: url, material: material),
      _PK.audio => _AudioPreviewWidget(url: url, material: material),
      _PK.link  => _LinkPreviewWidget(url: url),
      _PK.other => _FallbackWidget(url: url, material: material),
    };
  }
}

class _PdfPreviewWidget extends StatefulWidget {
  final String url; final MaterialItem material;
  final bool interactive;
  final _PdfPageRange? pageRange;
  const _PdfPreviewWidget({required this.url, required this.material, required this.interactive, this.pageRange});
  @override
  State<_PdfPreviewWidget> createState() => _PdfPreviewWidgetState();
}

class _PdfPreviewWidgetState extends State<_PdfPreviewWidget> {
  late String _viewId;

  String _buildViewId() {
    final urlKey = widget.url.hashCode.toUnsigned(32);
    final range = widget.pageRange;
    final rangeKey = range == null ? 'full' : 'range-${range.start}-${range.end}';
    return 'pdf-iframe-${widget.material.id}-$urlKey-$rangeKey';
  }

  @override
  void initState() {
    super.initState();
    _viewId = _buildViewId();
    _registerView();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePointerEvents());
  }

  bool get _iframeCanHandlePointerEvents => widget.interactive;

  void _updatePointerEvents() {
    final range = widget.pageRange;
    updatePdfPreviewInteractivity(
      viewType: _viewId,
      interactive: _iframeCanHandlePointerEvents,
    );
    updatePdfPreviewSource(
      viewType: _viewId,
      url: widget.url,
      interactive: _iframeCanHandlePointerEvents,
      pageStart: range?.start,
      pageEnd: range?.end,
    );
  }

  @override
  void didUpdateWidget(covariant _PdfPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextViewId = _buildViewId();
    final viewChanged = nextViewId != _viewId;
    if (viewChanged) {
      _viewId = nextViewId;
      _registerView();
      WidgetsBinding.instance.addPostFrameCallback((_) => _updatePointerEvents());
      return;
    }

    final rangeChanged = oldWidget.pageRange?.start != widget.pageRange?.start ||
        oldWidget.pageRange?.end != widget.pageRange?.end;
    if (oldWidget.interactive != widget.interactive ||
        oldWidget.url != widget.url ||
        rangeChanged) {
      _updatePointerEvents();
    }
  }

  void _registerView() {
    final range = widget.pageRange;
    registerPdfPreviewView(
      viewType: _viewId,
      url: widget.url,
      interactive: _iframeCanHandlePointerEvents,
      pageStart: range?.start,
      pageEnd: range?.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (!widget.interactive) {
      return _PlaceholderW(
        icon: Icons.picture_as_pdf_rounded,
        iconColor: AppColors.primary,
        iconBg: _K.blueSoft,
        title: 'Preview hidden while editing',
        sub: 'The PDF viewer is hidden so the popup controls stay fully clickable.',
        actionLabel: 'Open file',
        onAction: () async {
          final uri = Uri.tryParse(widget.url);
          if (uri != null) {
            await launchUrl(uri);
          }
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: HtmlElementView(
        key: ValueKey<String>(_viewId),
        viewType: _viewId,
      ),
    );
  }
}

class _ImagePreviewWidget extends StatelessWidget {
  final String url; const _ImagePreviewWidget({required this.url});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20),
    child: Container(decoration: BoxDecoration(color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14), border: Border.all(color: _K.div),),
      child: ClipRRect(borderRadius: BorderRadius.circular(13), child: Stack(children: [
        Container(color: AppColors.surfaceBg),
        Center(child: Image.network(url, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _FallbackWidget(url: url, material: null),
            loadingBuilder: (_, child, p) => p == null ? child :
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),),),
        Positioned(top: 12, right: 12, child: _OBtn(url: url)),
      ],),),),);
}

class _VideoPreviewWidget extends StatelessWidget {
  final String url; final MaterialItem material;
  const _VideoPreviewWidget({required this.url, required this.material});
  static String _fmt(int s) {
    final h = s ~/ 3600; final m = (s % 3600) ~/ 60; final sec = s % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m ${sec}s';
  }
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _MetaStripW(material: material), const SizedBox(height: 14),
      Expanded(child: Container(
        decoration: BoxDecoration(color: AppColors.documentCanvasBg,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: _K.div),),
        child: ClipRRect(borderRadius: BorderRadius.circular(13),
            child: Stack(alignment: Alignment.center, children: [
          Container(decoration: BoxDecoration(gradient: RadialGradient(
              colors: [AppColors.documentCanvasRadial, AppColors.documentCanvasBg],),),),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle, border: Border.all(color: AppColors.cardBg.withValues(alpha: 0.2)),),
                child: const Icon(Icons.play_arrow_rounded, size: 44, color: Colors.white),),
            const SizedBox(height: 16),
            Text(material.displayTitle, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700, color: Colors.white,),),
            if (material.durationSeconds != null) ...[
              const SizedBox(height: 4),
              Text(_fmt(material.durationSeconds!),
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),),
            ],
            const SizedBox(height: 22),
            ElevatedButton.icon(onPressed: () {},
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Open Video'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBg.withValues(alpha: 0.15),
                    foregroundColor: Colors.white, elevation: 0,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),),),
          ],),
        ],),),),),
    ],),);
}

class _AudioPreviewWidget extends StatelessWidget {
  final String url; final MaterialItem material;
  const _AudioPreviewWidget({required this.url, required this.material});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20),
    child: Container(padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _K.div),),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(
            color: _K.greenSoft, borderRadius: BorderRadius.circular(22),),
            child: Icon(Icons.headphones_rounded, size: 40, color: _K.green),),
        const SizedBox(height: 18),
        Text(material.displayTitle, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textTitle,),),
        if (material.durationSeconds != null) ...[
          const SizedBox(height: 6),
          Text('Duration: ${material.durationSeconds! ~/ 60}m ${material.durationSeconds! % 60}s',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),),
        ],
        const SizedBox(height: 24),
        _OBtn(url: url, big: true),
      ],),),);
}

class _LinkPreviewWidget extends StatelessWidget {
  final String url; const _LinkPreviewWidget({required this.url});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20),
    child: Container(padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _K.div),),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(
            color: _K.blueSoft, borderRadius: BorderRadius.circular(18),),
            child: const Icon(Icons.link_rounded, size: 34, color: AppColors.primary),),
        const SizedBox(height: 16),
        Text('External Link', style: TextStyle(fontSize: 17,
            fontWeight: FontWeight.w800, color: AppColors.textTitle,),),
        const SizedBox(height: 8),
        Text(url, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),),
        const SizedBox(height: 20), _OBtn(url: url, big: true),
      ],),),);
}

class _FallbackWidget extends StatelessWidget {
  final String url; final MaterialItem? material;
  const _FallbackWidget({required this.url, required this.material});
  @override
  Widget build(BuildContext context) => _PlaceholderW(icon: Icons.insert_drive_file_rounded,
      iconColor: AppColors.textMuted, iconBg: _K.bg, title: 'Preview not available',
      sub: material != null ? 'This file type (${material!.type}) cannot be previewed inline.'
          : 'Preview not available.', actionLabel: 'Open / Download', onAction: () {},);
}

class _LoaderW extends StatelessWidget {
  final String label; const _LoaderW({required this.label});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircularProgressIndicator(strokeWidth: 2), const SizedBox(height: 12),
    Text(label, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),],),);
}

class _PlaceholderW extends StatelessWidget {
  final IconData icon; final Color iconColor, iconBg;
  final String title, sub; final String? actionLabel; final VoidCallback? onAction;
  const _PlaceholderW({required this.icon, required this.iconColor, required this.iconBg,
      required this.title, required this.sub, this.actionLabel, this.onAction,});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 70, height: 70,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, size: 32, color: iconColor),),
      const SizedBox(height: 16),
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textTitle)),
      const SizedBox(height: 6),
      Text(sub, style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
          textAlign: TextAlign.center,),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: onAction,
            icon: const Icon(Icons.open_in_new_rounded, size: 14), label: Text(actionLabel!),),
      ],
    ],),),);
}

class _MetaStripW extends StatelessWidget {
  final MaterialItem material; const _MetaStripW({required this.material});
  static String _fmt(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final items = <(IconData, String)>[];
    if (material.fileSize != null) items.add((Icons.storage_rounded, _fmt(material.fileSize!)));
    if (material.pageCount != null) items.add((Icons.menu_book_rounded, '${material.pageCount} pages'));
    if (material.durationSeconds != null) { final s = material.durationSeconds!;
      items.add((Icons.timer_rounded, '${s ~/ 60}m ${s % 60}s')); }
    final d = material.uploadedAt;
    items.add((Icons.calendar_today_rounded, 'Uploaded ${d.day}/${d.month}/${d.year}'));
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 14, runSpacing: 5, children: items.map((it) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(it.$1, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
          Text(it.$2, style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        ],),).toList(),);
  }
}

class _OBtn extends StatelessWidget {
  final String url; final bool big; const _OBtn({required this.url, this.big = false});

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (big) {
      return ElevatedButton.icon(onPressed: _open,
        icon: const Icon(Icons.open_in_new_rounded, size: 14), label: const Text('Open'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),),);
    }
    return Material(color: AppColors.primary, borderRadius: BorderRadius.circular(7),
        child: InkWell(hoverColor: Colors.transparent, splashColor: Colors.transparent, highlightColor: Colors.transparent, overlayColor: const WidgetStatePropertyAll(Colors.transparent), onTap: _open, borderRadius: BorderRadius.circular(7),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 5),
                  Text('Open', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ],),),),);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOPICS SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
