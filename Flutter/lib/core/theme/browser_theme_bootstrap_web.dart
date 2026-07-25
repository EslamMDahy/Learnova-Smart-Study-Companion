import 'package:web/web.dart' as web;

void applyBrowserThemeChromeImpl({required bool dark}) {
  final bg = dark ? '#0F172A' : '#F6F7F8';
  final surface = dark ? '#0F172A' : '#FFFFFF';

  // package:web exposes documentElement as Element, and Element does not have
  // a typed `style` getter. Use attributes so this compiles under both dart2js
  // and dart2wasm. Keep the browser page itself locked to the viewport;
  // Flutter owns the scrolling internally. This prevents native scrollbars from
  // appearing when HtmlElementView/PDF iframes are mounted inside long panels.
  final pageStyle = <String>[
    'margin: 0',
    'padding: 0',
    'width: 100%',
    'height: 100%',
    'max-width: 100vw',
    'max-height: 100vh',
    'overflow: hidden',
    'overscroll-behavior: none',
    'background-color: $bg',
  ].join('; ');

  web.document.documentElement?.setAttribute('style', pageStyle);
  web.document.body?.setAttribute('style', pageStyle);

  final head = web.document.head;
  if (head == null) return;

  web.HTMLMetaElement? themeColor;
  final matches = head.querySelectorAll('meta[name="theme-color"]');
  for (var i = 0; i < matches.length; i++) {
    final element = matches.item(i);
    if (element is web.HTMLMetaElement) {
      themeColor = element;
      break;
    }
  }

  themeColor ??= web.document.createElement('meta') as web.HTMLMetaElement;
  themeColor.name = 'theme-color';
  themeColor.setAttribute('data-learnova-managed', 'true');
  themeColor.content = surface;

  if (themeColor.parentNode == null) {
    head.appendChild(themeColor);
  }
}
