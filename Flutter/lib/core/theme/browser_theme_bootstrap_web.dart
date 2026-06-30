import 'package:web/web.dart' as web;

void applyBrowserThemeChromeImpl({required bool dark}) {
  final bg = dark ? '#0F172A' : '#F6F7F8';
  final surface = dark ? '#0F172A' : '#FFFFFF';

  // package:web exposes documentElement as Element, and Element does not have
  // a typed `style` getter. Use attributes so this compiles under both dart2js
  // and dart2wasm.
  web.document.documentElement?.setAttribute('style', 'background-color: $bg;');
  web.document.body?.setAttribute('style', 'background-color: $bg;');

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
