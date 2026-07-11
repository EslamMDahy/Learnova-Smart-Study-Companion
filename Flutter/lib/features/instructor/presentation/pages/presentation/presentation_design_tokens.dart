import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Canonical design system for Learnova presentation slides.
///
/// Flutter consumes these values directly. The exporter receives the same
/// values through `design_tokens`, so spacing, typography and card geometry
/// remain aligned between the website preview and the editable PowerPoint.
abstract class PresentationDesignTokens {
  PresentationDesignTokens._();
  static const int schemaVersion = 4;
  static const int maxSlides = 100;
  static const int maxCardsPerSlide = 12;
  static const int maxTitleCharacters = 240;
  static const int maxKickerCharacters = 80;
  static const int maxCardHeadingCharacters = 240;
  static const int maxCardBodyCharacters = 3000;
  static const int maxVisualCaptionCharacters = 260;
  static const int maxEquationCharacters = 900;
  static const int maxProblemStatementCharacters = 1600;
  static const int maxProblemStepCharacters = 800;

  static const double slideWidth = 1920;
  static const double slideHeight = 1080;

  static const String headingFontFamily = 'Lexend';
  static const String bodyFontFamily = 'Inter';
  // Inter and Lexend do not contain Arabic glyphs. Arial is selected
  // explicitly for RTL text so browser and Microsoft PowerPoint use the
  // same Arabic-capable family instead of choosing different fallbacks.
  static const String rtlFontFamily = 'Arial';
  static const String fontFamily = bodyFontFamily;
  static const List<String> headingFontFallbacks = ['Arial', 'sans-serif'];
  static const List<String> bodyFontFallbacks = ['Arial', 'Tahoma', 'sans-serif'];
  static const List<String> rtlFontFallbacks = ['Tahoma', 'sans-serif'];

  static const String logoAssetPath = 'assets/logo.webp';
  static const String logoWebPath = 'assets/assets/logo.webp';
  static const String interRegularWebPath =
      'assets/assets/fonts/Inter-Regular.ttf';
  static const String interBoldWebPath = 'assets/assets/fonts/Inter-Bold.ttf';
  static const String lexendRegularWebPath =
      'assets/assets/fonts/lexend/Lexend-Regular.ttf';
  static const String lexendBoldWebPath =
      'assets/assets/fonts/lexend/Lexend-Bold.ttf';

  // Learnova project palette.
  static const Color canvas = Color(0xFFF7FAFF);
  static const Color white = Colors.white;
  static const Color ink = Color(0xFF071129);
  static const Color inkSoft = Color(0xFF24324D);
  static const Color textMuted = Color(0xFF5F6F89);
  static const Color footerText = Color(0xFF8291A7);
  static const Color primary = Color(0xFF137FEC);
  static const Color primaryDark = Color(0xFF0B5FC4);
  static const Color primarySoft = Color(0xFFE8F3FF);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color cyanSoft = Color(0xFFE7F9FF);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoSoft = Color(0xFFEEF2FF);
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetSoft = Color(0xFFF5F0FF);
  static const Color border = Color(0xFFD7E4F3);
  static const Color divider = Color(0xFFE6EEF8);
  static const Color decorationPrimary = Color(0xFFE8F3FF);
  static const Color decorationCyan = Color(0xFFDFF8FF);
  static const Color decorationViolet = Color(0xFFF0E9FF);
  static const Color pageBadge = Color(0xFF0A2A5E);
  static const Color panelTint = Color(0xFFF0F7FF);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  static const double pagePaddingX = 96;
  static const double pagePaddingTop = 50;
  static const double pagePaddingBottom = 40;
  static const double headerHeight = 58;
  static const double contentBottom = 966;
  static const double footerY = 1010;
  static const double contentWidth = slideWidth - pagePaddingX * 2;
  static const double titleWidth = 1540;

  static Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'slide_width': slideWidth,
      'slide_height': slideHeight,
      'max_cards_per_slide': maxCardsPerSlide,
      'heading_font_family': headingFontFamily,
      'body_font_family': bodyFontFamily,
      'rtl_font_family': rtlFontFamily,
      'rtl_font_fallbacks': rtlFontFallbacks,
      // Kept for compatibility with older bridge builds.
      'font_family': bodyFontFamily,
      'heading_font_fallbacks': headingFontFallbacks,
      'font_fallbacks': bodyFontFallbacks,
      'assets': {
        'logo_web': logoWebPath,
        'inter_regular_web': interRegularWebPath,
        'inter_bold_web': interBoldWebPath,
        'lexend_regular_web': lexendRegularWebPath,
        'lexend_bold_web': lexendBoldWebPath,
      },
      'colors': {
        'canvas': _hex(canvas),
        'white': _hex(white),
        'ink': _hex(ink),
        'ink_soft': _hex(inkSoft),
        'text_muted': _hex(textMuted),
        'footer_text': _hex(footerText),
        'primary': _hex(primary),
        'primary_dark': _hex(primaryDark),
        'primary_soft': _hex(primarySoft),
        'cyan': _hex(cyan),
        'cyan_soft': _hex(cyanSoft),
        'indigo': _hex(indigo),
        'indigo_soft': _hex(indigoSoft),
        'violet': _hex(violet),
        'violet_soft': _hex(violetSoft),
        'border': _hex(border),
        'divider': _hex(divider),
        'decoration_primary': _hex(decorationPrimary),
        'decoration_cyan': _hex(decorationCyan),
        'decoration_violet': _hex(decorationViolet),
        'page_badge': _hex(pageBadge),
        'panel_tint': _hex(panelTint),
        'success': _hex(success),
        'warning': _hex(warning),
      },
      'spacing': {
        'page_padding_x': pagePaddingX,
        'page_padding_top': pagePaddingTop,
        'page_padding_bottom': pagePaddingBottom,
        'header_height': headerHeight,
        'content_bottom': contentBottom,
        'footer_y': footerY,
        'content_width': contentWidth,
        'title_width': titleWidth,
      },
    };
  }

  static PresentationGridSpec gridFor(String layout, int cardCount) {
    final count = math.max(1, math.min(maxCardsPerSlide, cardCount)).toInt();
    final normalized = layout.trim().toLowerCase();

    int columns;
    if (normalized == 'single_card_center' && count == 1) {
      columns = 1;
    } else if (normalized == 'two_card_horizontal' && count <= 6) {
      columns = math.min(2, count).toInt();
    } else if (normalized == 'three_card_horizontal' && count <= 6) {
      columns = math.min(3, count).toInt();
    } else if (count <= 3) {
      columns = count;
    } else if (count == 4) {
      columns = 2;
    } else if (count <= 6) {
      columns = 3;
    } else if (count <= 8) {
      columns = 4;
    } else if (count == 9) {
      columns = 3;
    } else {
      columns = 4;
    }

    final rows = (count / columns).ceil();
    final density = rows >= 3 || columns >= 4
        ? PresentationCardDensity.dense
        : rows >= 2 || columns >= 3
            ? PresentationCardDensity.compact
            : PresentationCardDensity.comfortable;

    return PresentationGridSpec(
      columns: columns,
      rows: rows,
      density: density,
    );
  }

  static PresentationSlideLayoutSpec layoutFor({
    required String layout,
    required int cardCount,
    required String title,
    required bool hasKicker,
  }) {
    final grid = gridFor(layout, cardCount);
    final titleFontSize = titleSizeFor(title, grid.density);
    final titleLines = wrapText(
      title,
      width: titleWidth,
      fontSize: titleFontSize,
      maxLines: 2,
      averageGlyphFactor: 1,
    ).split('\n');
    late final double contentTop;
    switch (grid.density) {
      case PresentationCardDensity.comfortable:
        contentTop = titleLines.length > 1 ? 380.0 : 332.0;
        break;
      case PresentationCardDensity.compact:
        contentTop = titleLines.length > 1 ? 350.0 : 306.0;
        break;
      case PresentationCardDensity.dense:
        contentTop = titleLines.length > 1 ? 314.0 : 276.0;
        break;
    }

    final adjustedContentTop = hasKicker ? contentTop : contentTop - 34;
    final gap = cardGapFor(grid.density);
    final availableHeight = contentBottom - adjustedContentTop;
    final naturalWidth =
        (contentWidth - gap * (grid.columns - 1)) / grid.columns;
    final naturalHeight =
        (availableHeight - gap * (grid.rows - 1)) / grid.rows;
    late final double maxSingleRowHeight;
    switch (grid.density) {
      case PresentationCardDensity.comfortable:
        maxSingleRowHeight = 330.0;
        break;
      case PresentationCardDensity.compact:
        maxSingleRowHeight = 315.0;
        break;
      case PresentationCardDensity.dense:
        maxSingleRowHeight = 295.0;
        break;
    }
    final cardWidth = grid.columns == 1
        ? math.min(naturalWidth, 1320).toDouble()
        : naturalWidth;
    final cardHeight = grid.rows == 1
        ? math.min(naturalHeight, maxSingleRowHeight).toDouble()
        : naturalHeight;
    final gridWidth = cardWidth * grid.columns + gap * (grid.columns - 1);
    final gridHeight = cardHeight * grid.rows + gap * (grid.rows - 1);
    final originX = pagePaddingX + (contentWidth - gridWidth) / 2;
    final originY = adjustedContentTop + (availableHeight - gridHeight) / 2;

    return PresentationSlideLayoutSpec(
      grid: grid,
      cardCount: cardCount,
      titleFontSize: titleFontSize,
      titleText: titleLines.join('\n'),
      contentTop: adjustedContentTop,
      gap: gap,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      originX: originX,
      originY: originY,
    );
  }

  static double titleSizeFor(
    String title,
    PresentationCardDensity density,
  ) {
    final units = textUnits(title);
    switch (density) {
      case PresentationCardDensity.comfortable:
        if (units > 92) return 44;
        if (units > 70) return 50;
        if (units > 52) return 56;
        return 62;
      case PresentationCardDensity.compact:
        if (units > 100) return 40;
        if (units > 76) return 46;
        if (units > 56) return 52;
        return 56;
      case PresentationCardDensity.dense:
        if (units > 110) return 34;
        if (units > 86) return 38;
        if (units > 62) return 42;
        return 46;
    }
  }

  static double cardGapFor(PresentationCardDensity density) {
    switch (density) {
      case PresentationCardDensity.comfortable:
        return 22;
      case PresentationCardDensity.compact:
        return 18;
      case PresentationCardDensity.dense:
        return 14;
    }
  }

  static double cardRadiusFor(PresentationCardDensity density) {
    switch (density) {
      case PresentationCardDensity.comfortable:
        return 28;
      case PresentationCardDensity.compact:
        return 24;
      case PresentationCardDensity.dense:
        return 18;
    }
  }

  static PresentationAccent accentFor(int index) {
    switch (index % 4) {
      case 0:
        return const PresentationAccent(primary, primarySoft);
      case 1:
        return const PresentationAccent(cyan, cyanSoft);
      case 2:
        return const PresentationAccent(indigo, indigoSoft);
      default:
        return const PresentationAccent(violet, violetSoft);
    }
  }

  static String wrapText(
    String value, {
    required double width,
    required double fontSize,
    required int maxLines,
    double averageGlyphFactor = 1,
  }) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return ' ';
    if (maxLines <= 0 || width <= 0 || fontSize <= 0) return normalized;

    final maxUnits = width / fontSize / averageGlyphFactor;
    final tokens = <_PresentationWrapToken>[];
    for (final word in normalized.split(' ')) {
      final chunks = _splitWordByUnits(word, maxUnits);
      for (var index = 0; index < chunks.length; index++) {
        tokens.add(
          _PresentationWrapToken(
            chunks[index],
            forceLineAfter: index < chunks.length - 1,
          ),
        );
      }
    }

    final lines = <String>[];
    var current = '';
    var consumedAll = true;

    for (var index = 0; index < tokens.length; index++) {
      final token = tokens[index];
      final candidate = current.isEmpty ? token.text : '$current ${token.text}';

      if (current.isEmpty || textUnits(candidate) <= maxUnits) {
        current = candidate;
      } else {
        lines.add(current);
        current = token.text;
        if (lines.length >= maxLines) {
          consumedAll = false;
          current = '';
          break;
        }
      }

      if (token.forceLineAfter && current.isNotEmpty) {
        lines.add(current);
        current = '';
        if (lines.length >= maxLines) {
          consumedAll = index == tokens.length - 1;
          break;
        }
      }
    }

    if (current.isNotEmpty) {
      if (lines.length < maxLines) {
        lines.add(current);
      } else {
        consumedAll = false;
      }
    }

    if (!consumedAll && lines.isNotEmpty) {
      var last = lines.last.replaceAll(RegExp(r'[\s…]+$'), '');
      while (last.isNotEmpty && textUnits('$last…') > maxUnits) {
        last = last.substring(0, last.length - 1).trimRight();
      }
      lines[lines.length - 1] = '${last.isEmpty ? '' : last}…';
    }

    return lines.take(maxLines).join('\n');
  }

  static List<String> _splitWordByUnits(String word, double maxUnits) {
    if (word.isEmpty || textUnits(word) <= maxUnits) return [word];

    final chunks = <String>[];
    final buffer = StringBuffer();
    var bufferUnits = 0.0;

    for (final rune in word.runes) {
      final character = String.fromCharCode(rune);
      final characterUnits = textUnits(character);
      if (buffer.isNotEmpty && bufferUnits + characterUnits > maxUnits) {
        chunks.add(buffer.toString());
        buffer.clear();
        bufferUnits = 0;
      }
      buffer.write(character);
      bufferUnits += characterUnits;
    }

    if (buffer.isNotEmpty) chunks.add(buffer.toString());
    return chunks.isEmpty ? [word] : chunks;
  }

  static double textUnits(String value) {
    var total = 0.0;
    for (final rune in value.runes) {
      if (rune == 32) {
        total += 0.34;
      } else if (rune >= 0x0590 && rune <= 0x08FF) {
        total += 0.62;
      } else if (rune >= 0x4E00 && rune <= 0x9FFF) {
        total += 1;
      } else if (rune >= 65 && rune <= 90) {
        total += 0.68;
      } else if ((rune >= 97 && rune <= 122) ||
          (rune >= 48 && rune <= 57)) {
        total += 0.52;
      } else {
        total += 0.42;
      }
    }
    return total;
  }

  static String _hex(Color color) {
    final value = color.value & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _PresentationWrapToken {
  final String text;
  final bool forceLineAfter;

  const _PresentationWrapToken(this.text, {required this.forceLineAfter});
}

enum PresentationCardDensity { comfortable, compact, dense }

class PresentationGridSpec {
  final int columns;
  final int rows;
  final PresentationCardDensity density;

  const PresentationGridSpec({
    required this.columns,
    required this.rows,
    required this.density,
  });
}

class PresentationSlideLayoutSpec {
  final PresentationGridSpec grid;
  final int cardCount;
  final double titleFontSize;
  final String titleText;
  final double contentTop;
  final double gap;
  final double cardWidth;
  final double cardHeight;
  final double originX;
  final double originY;

  const PresentationSlideLayoutSpec({
    required this.grid,
    required this.cardCount,
    required this.titleFontSize,
    required this.titleText,
    required this.contentTop,
    required this.gap,
    required this.cardWidth,
    required this.cardHeight,
    required this.originX,
    required this.originY,
  });

  Rect cardRect(int index, {bool rtl = false}) {
    final row = index ~/ grid.columns;
    final logicalColumn = index % grid.columns;
    final remaining = math.max(0, cardCount - row * grid.columns).toInt();
    final itemsInRow = math.min(grid.columns, remaining).toInt();
    final rowWidth = itemsInRow * cardWidth + (itemsInRow - 1) * gap;
    final rowStartX = PresentationDesignTokens.pagePaddingX +
        (PresentationDesignTokens.contentWidth - rowWidth) / 2;
    final visualColumn = rtl
        ? math.max(0, itemsInRow - 1 - logicalColumn).toInt()
        : logicalColumn;

    return Rect.fromLTWH(
      rowStartX + visualColumn * (cardWidth + gap),
      originY + row * (cardHeight + gap),
      cardWidth,
      cardHeight,
    );
  }
}

class PresentationAccent {
  final Color color;
  final Color softColor;

  const PresentationAccent(this.color, this.softColor);
}
