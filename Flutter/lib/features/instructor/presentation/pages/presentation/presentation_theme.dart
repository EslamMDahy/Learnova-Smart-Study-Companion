part of 'instructor_presentation_page.dart';

/// Instructor-controlled colour system for generated presentations.
///
/// The backend remains unchanged: presentation content is generated first,
/// then the selected palette is applied locally to the canonical slide
/// elements. The preview and exported editable PPTX therefore stay identical.
class PresentationPalette {
  final String id;
  final String name;
  final String description;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color accent;
  final Color accentSoft;
  final Color secondary;
  final Color secondarySoft;
  final Color violet;
  final Color violetSoft;
  final Color ink;
  final Color inkSoft;
  final Color textMuted;
  final Color canvas;
  final Color border;
  final Color divider;
  final Color pageBadge;

  const PresentationPalette({
    required this.id,
    required this.name,
    required this.description,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
    required this.secondary,
    required this.secondarySoft,
    required this.violet,
    required this.violetSoft,
    required this.ink,
    required this.inkSoft,
    required this.textMuted,
    required this.canvas,
    required this.border,
    required this.divider,
    required this.pageBadge,
  });

  static const learnovaBlue = PresentationPalette(
    id: 'learnova_blue',
    name: 'Learnova Blue',
    description: 'Clean, academic and familiar.',
    primary: Color(0xFF137FEC),
    primaryDark: Color(0xFF0B5FC4),
    primarySoft: Color(0xFFE8F3FF),
    accent: Color(0xFF22D3EE),
    accentSoft: Color(0xFFE7F9FF),
    secondary: Color(0xFF4F46E5),
    secondarySoft: Color(0xFFEEF2FF),
    violet: Color(0xFF7C3AED),
    violetSoft: Color(0xFFF5F0FF),
    ink: Color(0xFF071129),
    inkSoft: Color(0xFF24324D),
    textMuted: Color(0xFF5F6F89),
    canvas: Color(0xFFF7FAFF),
    border: Color(0xFFD7E4F3),
    divider: Color(0xFFE6EEF8),
    pageBadge: Color(0xFF0A2A5E),
  );

  static const indigoStudio = PresentationPalette(
    id: 'indigo_studio',
    name: 'Indigo Studio',
    description: 'Modern, focused and technology-led.',
    primary: Color(0xFF4F46E5),
    primaryDark: Color(0xFF3730A3),
    primarySoft: Color(0xFFEEF2FF),
    accent: Color(0xFF8B5CF6),
    accentSoft: Color(0xFFF5F3FF),
    secondary: Color(0xFF2563EB),
    secondarySoft: Color(0xFFEFF6FF),
    violet: Color(0xFFC026D3),
    violetSoft: Color(0xFFFDF4FF),
    ink: Color(0xFF11112B),
    inkSoft: Color(0xFF30304F),
    textMuted: Color(0xFF666785),
    canvas: Color(0xFFF8F8FF),
    border: Color(0xFFDCDCF5),
    divider: Color(0xFFE9E9F8),
    pageBadge: Color(0xFF29245F),
  );

  static const emeraldClass = PresentationPalette(
    id: 'emerald_class',
    name: 'Emerald Class',
    description: 'Calm, confident and highly readable.',
    primary: Color(0xFF059669),
    primaryDark: Color(0xFF047857),
    primarySoft: Color(0xFFECFDF5),
    accent: Color(0xFF14B8A6),
    accentSoft: Color(0xFFF0FDFA),
    secondary: Color(0xFF0EA5E9),
    secondarySoft: Color(0xFFF0F9FF),
    violet: Color(0xFF6366F1),
    violetSoft: Color(0xFFEEF2FF),
    ink: Color(0xFF07251E),
    inkSoft: Color(0xFF26463F),
    textMuted: Color(0xFF60756F),
    canvas: Color(0xFFF7FCFA),
    border: Color(0xFFD6EBE4),
    divider: Color(0xFFE5F2ED),
    pageBadge: Color(0xFF084C3B),
  );

  static const sunsetCoral = PresentationPalette(
    id: 'sunset_coral',
    name: 'Sunset Coral',
    description: 'Warm, energetic and presentation-ready.',
    primary: Color(0xFFF05A47),
    primaryDark: Color(0xFFC83A2B),
    primarySoft: Color(0xFFFFEFEC),
    accent: Color(0xFFF59E0B),
    accentSoft: Color(0xFFFFF7E6),
    secondary: Color(0xFFEC4899),
    secondarySoft: Color(0xFFFDF2F8),
    violet: Color(0xFF8B5CF6),
    violetSoft: Color(0xFFF5F3FF),
    ink: Color(0xFF2B1512),
    inkSoft: Color(0xFF50322D),
    textMuted: Color(0xFF7B625E),
    canvas: Color(0xFFFFFAF8),
    border: Color(0xFFF0DDD8),
    divider: Color(0xFFF7E9E5),
    pageBadge: Color(0xFF67251C),
  );

  static const midnight = PresentationPalette(
    id: 'midnight',
    name: 'Midnight',
    description: 'Premium dark accents with crisp contrast.',
    primary: Color(0xFF38BDF8),
    primaryDark: Color(0xFF0284C7),
    primarySoft: Color(0xFFE0F2FE),
    accent: Color(0xFFA78BFA),
    accentSoft: Color(0xFFF5F3FF),
    secondary: Color(0xFF2DD4BF),
    secondarySoft: Color(0xFFCCFBF1),
    violet: Color(0xFFF472B6),
    violetSoft: Color(0xFFFCE7F3),
    ink: Color(0xFF08111F),
    inkSoft: Color(0xFF263449),
    textMuted: Color(0xFF64748B),
    canvas: Color(0xFFF6F9FD),
    border: Color(0xFFD7E1EE),
    divider: Color(0xFFE6EDF5),
    pageBadge: Color(0xFF0F2746),
  );

  static const presets = <PresentationPalette>[
    learnovaBlue,
    indigoStudio,
    emeraldClass,
    sunsetCoral,
    midnight,
  ];

  factory PresentationPalette.custom({
    required Color primary,
    required Color accent,
    required Color ink,
    required Color canvas,
  }) {
    Color blend(Color a, Color b, double amount) =>
        Color.lerp(a, b, amount) ?? a;

    final secondary = blend(primary, accent, 0.48);
    final violet = blend(primary, const Color(0xFF8B5CF6), 0.52);
    return PresentationPalette(
      id: 'custom_${hex(primary)}_${hex(accent)}',
      name: 'Custom theme',
      description: 'Your own presentation colour system.',
      primary: primary,
      primaryDark: blend(primary, Colors.black, 0.22),
      primarySoft: blend(primary, Colors.white, 0.88),
      accent: accent,
      accentSoft: blend(accent, Colors.white, 0.88),
      secondary: secondary,
      secondarySoft: blend(secondary, Colors.white, 0.89),
      violet: violet,
      violetSoft: blend(violet, Colors.white, 0.90),
      ink: ink,
      inkSoft: blend(ink, Colors.white, 0.16),
      textMuted: blend(ink, Colors.white, 0.42),
      canvas: canvas,
      border: blend(primary, canvas, 0.84),
      divider: blend(primary, canvas, 0.91),
      pageBadge: blend(ink, primary, 0.18),
    );
  }

  List<Color> get previewColors => <Color>[
        primary,
        accent,
        secondary,
        violet,
      ];

  static String hex(Color color) {
    final value = color.value & 0x00FFFFFF;
    return value.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  static Color? tryParseHex(String input) {
    var normalized = input.trim().replaceAll('#', '');
    if (normalized.length == 3) {
      normalized = normalized.split('').map((c) => '$c$c').join();
    }
    if (normalized.length != 6) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}

abstract class PresentationThemeEngine {
  PresentationThemeEngine._();

  static const Map<String, String> _defaultTokenNames = <String, String>{
    'F7FAFF': 'canvas',
    '071129': 'ink',
    '24324D': 'inkSoft',
    '5F6F89': 'textMuted',
    '137FEC': 'primary',
    '0B5FC4': 'primaryDark',
    'E8F3FF': 'primarySoft',
    '22D3EE': 'accent',
    'E7F9FF': 'accentSoft',
    '4F46E5': 'secondary',
    'EEF2FF': 'secondarySoft',
    '7C3AED': 'violet',
    'F5F0FF': 'violetSoft',
    'D7E4F3': 'border',
    'E6EEF8': 'divider',
    '0A2A5E': 'pageBadge',
  };

  static PresentationDeck applyToDeck(
    PresentationDeck deck,
    PresentationPalette palette,
  ) {
    final slides = <PresentationSlide>[];
    for (var index = 0; index < deck.slides.length; index++) {
      final current = deck.slides[index];
      final base = current.usesDefaultTemplate
          ? PresentationTemplateEngine.rebuildSlide(
              current,
              slideNumber: index + 1,
            )
          : current;
      slides.add(_applyToSlide(base, palette));
    }
    return deck.copyWith(
      sourceLabel: deck.sourceLabel,
      slides: List<PresentationSlide>.unmodifiable(slides),
    );
  }

  static PresentationSlide _applyToSlide(
    PresentationSlide slide,
    PresentationPalette palette,
  ) {
    return slide.copyWith(
      backgroundHex: _replaceHex(slide.backgroundHex, palette),
      elements: <PresentationElement>[
        for (final element in slide.elements)
          element.copyWith(
            colorHex: element.type == PresentationElementType.image &&
                    !_isImagePath(element.path) &&
                    element.colorHex == null
                ? PresentationPalette.hex(palette.primaryDark)
                : _replaceHex(element.colorHex, palette),
            fillHex: _replaceHex(element.fillHex, palette),
            lineHex: _replaceHex(element.lineHex, palette),
          ),
      ],
    );
  }

  static bool _isImagePath(String? value) {
    final path = (value ?? '').trim().toLowerCase();
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('data:image/') ||
        path.startsWith('blob:') ||
        path.startsWith('assets/') ||
        RegExp(r'\.(png|jpe?g|webp|gif|svg)([?#].*)?$').hasMatch(path);
  }

  static String? _replaceHex(
    String? value,
    PresentationPalette palette,
  ) {
    if (value == null || value.trim().isEmpty) return value;
    final normalized = value.trim().replaceAll('#', '').toUpperCase();
    final token = _defaultTokenNames[normalized];
    if (token == null) return value;

    final replacement = switch (token) {
      'canvas' => palette.canvas,
      'ink' => palette.ink,
      'inkSoft' => palette.inkSoft,
      'textMuted' => palette.textMuted,
      'primary' => palette.primary,
      'primaryDark' => palette.primaryDark,
      'primarySoft' => palette.primarySoft,
      'accent' => palette.accent,
      'accentSoft' => palette.accentSoft,
      'secondary' => palette.secondary,
      'secondarySoft' => palette.secondarySoft,
      'violet' => palette.violet,
      'violetSoft' => palette.violetSoft,
      'border' => palette.border,
      'divider' => palette.divider,
      'pageBadge' => palette.pageBadge,
      _ => null,
    };
    return replacement == null ? value : PresentationPalette.hex(replacement);
  }
}
