import 'dart:convert';
// ignore: undefined_prefixed_name
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

final _registeredPdfViews = <String>{};
final _registeredPdfIframes = <String, web.HTMLIFrameElement>{};
final _registeredPdfSourceKeys = <String, String>{};

bool _isScopedPdfRange(int? pageStart, int? pageEnd) {
  return pageStart != null &&
      pageEnd != null &&
      pageStart > 0 &&
      pageEnd >= pageStart;
}

String _buildNativePdfPreviewUrl(String url, {int? pageStart}) {
  final page = pageStart != null && pageStart > 0 ? pageStart : null;
  final params = <String>[
    if (page != null) 'page=$page',
    // Keep the native browser PDF renderer behavior. This is the same viewer
    // used for the full document: desktop wheel scroll, native zoom, native
    // scrollbar, and browser-level PDF rendering.
    'toolbar=0',
    'navpanes=0',
    'scrollbar=1',
    'view=FitH',
  ];

  final hashIndex = url.indexOf('#');
  final baseUrl = hashIndex >= 0 ? url.substring(0, hashIndex) : url;
  return '$baseUrl#${params.join('&')}';
}

String _resolvePdfUrlForEmbeddedViewer(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.hasScheme) return url;
  return Uri.base.resolveUri(uri).toString();
}

String _buildNativeRangePdfViewerHtml({
  required String url,
  required String viewType,
  required int pageStart,
  required int pageEnd,
}) {
  final safeStart = pageStart <= pageEnd ? pageStart : pageEnd;
  final safeEnd = pageEnd >= pageStart ? pageEnd : pageStart;
  final resolvedUrl = _resolvePdfUrlForEmbeddedViewer(url);
  final encodedUrl = jsonEncode(resolvedUrl);
  final encodedViewType = jsonEncode(viewType);
  final fallbackNativeUrl = jsonEncode(_buildNativePdfPreviewUrl(resolvedUrl, pageStart: safeStart));

  return '''<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body {
      margin: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #252525;
      font-family: Inter, Arial, sans-serif;
    }
    #viewerFrame {
      position: fixed;
      inset: 0;
      width: 100%;
      height: 100%;
      border: 0;
      background: #252525;
    }
    #loading, #error {
      position: fixed;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
      box-sizing: border-box;
      color: #475569;
      text-align: center;
      font-weight: 800;
      background: #f8fafc;
      z-index: 2;
    }
    [hidden] { display: none !important; }
    .panel {
      width: min(520px, calc(100vw - 48px));
      padding: 22px 24px;
      border: 1px solid #d8e2ee;
      border-radius: 18px;
      background: white;
      box-shadow: 0 14px 34px rgba(15, 23, 42, 0.10);
    }
    .spinner {
      width: 26px;
      height: 26px;
      margin: 0 auto 14px;
      border-radius: 999px;
      border: 3px solid #dbeafe;
      border-top-color: #0b83f6;
      animation: spin 0.9s linear infinite;
    }
    .hint {
      margin-top: 8px;
      color: #64748b;
      font-size: 12px;
      line-height: 1.5;
      font-weight: 700;
    }
    .open-native {
      display: inline-block;
      margin-top: 14px;
      padding: 10px 14px;
      border-radius: 999px;
      background: #0b83f6;
      color: white;
      text-decoration: none;
      font-size: 12px;
      font-weight: 900;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <iframe id="viewerFrame" title="PDF range viewer" allowfullscreen></iframe>
  <div id="loading">
    <div class="panel">
      <div class="spinner"></div>
      <div>Preparing PDF pages $safeStart–$safeEnd</div>
      <div class="hint">Creating a temporary in-browser PDF preview. The original file is not changed.</div>
    </div>
  </div>
  <div id="error" hidden></div>

  <script>
    const pdfUrl = $encodedUrl;
    const viewType = $encodedViewType;
    const startPage = $safeStart;
    const endPage = $safeEnd;
    const fallbackNativeUrl = $fallbackNativeUrl;
    const viewerFrame = document.getElementById('viewerFrame');
    const loading = document.getElementById('loading');
    const errorBox = document.getElementById('error');
    let objectUrl = null;

    function escapeHtml(value) {
      return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    }

    function showError(message) {
      loading.hidden = true;
      errorBox.hidden = false;
      errorBox.innerHTML = '<div class="panel">' +
        '<div>Could not prepare the page range.</div>' +
        '<div class="hint">' + escapeHtml(message) + '</div>' +
        '<div class="hint">The range viewer needs browser access to the PDF bytes. Check CORS or signed download permissions.</div>' +
        '<a class="open-native" href="' + escapeHtml(fallbackNativeUrl) + '" target="_blank" rel="noopener">Open original PDF at start page</a>' +
        '</div>';
    }

    function clearObjectUrl() {
      if (!objectUrl) return;
      try { URL.revokeObjectURL(objectUrl); } catch (_) {}
      objectUrl = null;
    }

    function loadScript(src) {
      return new Promise((resolve, reject) => {
        const existing = Array.from(document.scripts).find((script) => script.src === src);
        if (existing && window.PDFLib) {
          resolve();
          return;
        }
        const script = document.createElement('script');
        script.src = src;
        script.async = true;
        script.onload = resolve;
        script.onerror = () => reject(new Error('Could not load PDF range engine.'));
        document.head.appendChild(script);
      });
    }

    async function fetchPdfBytes() {
      const absolute = new URL(pdfUrl, window.location.href);
      const sameOrigin = absolute.origin === window.location.origin;
      const response = await fetch(absolute.href, {
        method: 'GET',
        credentials: sameOrigin ? 'include' : 'omit',
        cache: 'force-cache',
      });
      if (!response.ok) {
        throw new Error('PDF download failed: HTTP ' + response.status);
      }
      return await response.arrayBuffer();
    }

    async function boot() {
      try {
        await loadScript('https://cdn.jsdelivr.net/npm/pdf-lib@1.17.1/dist/pdf-lib.min.js');
        if (!window.PDFLib || !window.PDFLib.PDFDocument) {
          throw new Error('PDF range engine is unavailable.');
        }

        const sourceBytes = await fetchPdfBytes();
        const sourcePdf = await window.PDFLib.PDFDocument.load(sourceBytes, {
          ignoreEncryption: true,
        });
        const totalPages = sourcePdf.getPageCount();
        if (!totalPages || totalPages < 1) {
          throw new Error('The PDF has no pages.');
        }

        const safeStart = Math.max(1, Math.min(startPage, totalPages));
        const safeEnd = Math.max(safeStart, Math.min(endPage, totalPages));
        const pageIndexes = [];
        for (let page = safeStart; page <= safeEnd; page++) {
          pageIndexes.push(page - 1);
        }

        const rangePdf = await window.PDFLib.PDFDocument.create();
        const copiedPages = await rangePdf.copyPages(sourcePdf, pageIndexes);
        for (const page of copiedPages) {
          rangePdf.addPage(page);
        }

        const rangeBytes = await rangePdf.save();
        clearObjectUrl();
        objectUrl = URL.createObjectURL(new Blob([rangeBytes], { type: 'application/pdf' }));
        viewerFrame.src = objectUrl + '#toolbar=0&navpanes=0&scrollbar=1&view=FitH&page=1';
        viewerFrame.onload = () => { loading.hidden = true; };
        window.setTimeout(() => { loading.hidden = true; }, 1200);

        try {
          window.parent.postMessage({
            type: 'learnova_pdf_range_ready',
            viewType: viewType,
            startPage: safeStart,
            endPage: safeEnd,
            pageCount: copiedPages.length,
          }, '*');
        } catch (_) {}
      } catch (error) {
        const message = error && error.message ? error.message : String(error);
        showError(message);
      }
    }

    window.addEventListener('pagehide', clearObjectUrl);
    window.addEventListener('unload', clearObjectUrl);
    boot();
  </script>
</body>
</html>''';
}

String _pdfSourceKey({
  required String url,
  required bool scoped,
  required int? pageStart,
  required int? pageEnd,
}) {
  return scoped ? 'native-range|$url|$pageStart|$pageEnd' : 'native|$url|$pageStart';
}

void _applyPdfPreviewSource({
  required web.HTMLIFrameElement iframe,
  required String viewType,
  required String url,
  required bool interactive,
  int? pageStart,
  int? pageEnd,
}) {
  final scoped = _isScopedPdfRange(pageStart, pageEnd);
  final sourceKey = _pdfSourceKey(
    url: url,
    scoped: scoped,
    pageStart: pageStart,
    pageEnd: pageEnd,
  );

  iframe.style.pointerEvents = interactive ? 'auto' : 'none';
  iframe.style.overflow = 'hidden';
  iframe.setAttribute('scrolling', 'no');

  if (_registeredPdfSourceKeys[viewType] == sourceKey) return;
  _registeredPdfSourceKeys[viewType] = sourceKey;

  if (scoped) {
    iframe.removeAttribute('src');
    iframe.setAttribute(
      'srcdoc',
      _buildNativeRangePdfViewerHtml(
        url: url,
        viewType: viewType,
        pageStart: pageStart!,
        pageEnd: pageEnd!,
      ),
    );
  } else {
    iframe.removeAttribute('srcdoc');
    iframe.src = _buildNativePdfPreviewUrl(url, pageStart: pageStart);
  }
}

void registerPdfPreviewView({
  required String viewType,
  required String url,
  required bool interactive,
  int? pageStart,
  int? pageEnd,
}) {
  if (_registeredPdfViews.contains(viewType)) {
    updatePdfPreviewSource(
      viewType: viewType,
      url: url,
      interactive: interactive,
      pageStart: pageStart,
      pageEnd: pageEnd,
    );
    return;
  }

  _registeredPdfViews.add(viewType);

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.overflow = 'hidden'
      ..style.backgroundColor = scopedPreviewBackground(pageStart, pageEnd);
    iframe.setAttribute('scrolling', 'no');
    _registeredPdfIframes[viewType] = iframe;
    _applyPdfPreviewSource(
      iframe: iframe,
      viewType: viewType,
      url: url,
      interactive: interactive,
      pageStart: pageStart,
      pageEnd: pageEnd,
    );
    return iframe;
  });
}

String scopedPreviewBackground(int? pageStart, int? pageEnd) {
  return _isScopedPdfRange(pageStart, pageEnd) ? '#252525' : '#FFFFFF';
}

void updatePdfPreviewSource({
  required String viewType,
  required String url,
  required bool interactive,
  int? pageStart,
  int? pageEnd,
}) {
  final iframe = _registeredPdfIframes[viewType];
  if (iframe == null) return;
  iframe.style.backgroundColor = scopedPreviewBackground(pageStart, pageEnd);
  _applyPdfPreviewSource(
    iframe: iframe,
    viewType: viewType,
    url: url,
    interactive: interactive,
    pageStart: pageStart,
    pageEnd: pageEnd,
  );
}

void updatePdfPreviewInteractivity({
  required String viewType,
  required bool interactive,
}) {
  final iframe = _registeredPdfIframes[viewType];
  if (iframe == null) return;
  iframe.style.pointerEvents = interactive ? 'auto' : 'none';
}

void scrollPdfPreviewToPage({
  required String viewType,
  required int page,
}) {
  final iframe = _registeredPdfIframes[viewType];
  if (iframe == null || iframe.contentWindow == null) return;
  // The native browser PDF viewer does not expose a stable cross-browser
  // JavaScript API for page scrolling. Keep this as a safe no-op in WASM.
}
