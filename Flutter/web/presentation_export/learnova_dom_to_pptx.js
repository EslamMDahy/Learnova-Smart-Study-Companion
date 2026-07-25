(function learnovaDomToPptxBridge(global) {
  'use strict';

  const BRIDGE_VERSION = '5.2.0';
  const LIBRARY_VERSION = '2.0.3';
  const LIBRARY_RELATIVE_PATH = 'presentation_export/vendor/dom-to-pptx.bundle.js';
  const STYLE_ID = 'learnova-dom-to-pptx-styles';
  const EXPORT_ROOT_ID = 'learnova-dom-to-pptx-export-root';
  const LIBRARY_SCRIPT_ID = 'learnova-dom-to-pptx-library';
  const MATHJAX_SCRIPT_ID = 'learnova-mathjax-library';
  const MATHJAX_RELATIVE_PATH = 'presentation_export/vendor/mathjax/tex-svg-full.js';
  const RTL_PATTERN = /[\u0590-\u08FF]/;
  const DEFAULT_MAX_CARDS = 12;
  const MAX_SLIDES = 100;
  const MAX_TITLE_CHARACTERS = 240;
  const MAX_KICKER_CHARACTERS = 80;
  const MAX_CARD_HEADING_CHARACTERS = 240;
  const MAX_CARD_BODY_CHARACTERS = 3000;

  const DEFAULT_TOKENS = Object.freeze({
    schemaVersion: 4,
    slideWidth: 1920,
    slideHeight: 1080,
    maxCardsPerSlide: DEFAULT_MAX_CARDS,
    headingFontFamily: 'Lexend',
    bodyFontFamily: 'Inter',
    rtlFontFamily: 'Arial',
    headingFontFallbacks: ['Arial', 'sans-serif'],
    bodyFontFallbacks: ['Arial', 'Tahoma', 'sans-serif'],
    rtlFontFallbacks: ['Tahoma', 'sans-serif'],
    assets: Object.freeze({
      logoWeb: 'assets/assets/logo.webp',
      interRegularWeb: 'assets/assets/fonts/Inter-Regular.ttf',
      interBoldWeb: 'assets/assets/fonts/Inter-Bold.ttf',
      lexendRegularWeb: 'assets/assets/fonts/lexend/Lexend-Regular.ttf',
      lexendBoldWeb: 'assets/assets/fonts/lexend/Lexend-Bold.ttf',
    }),
    colors: Object.freeze({
      canvas: '#F7FAFF',
      white: '#FFFFFF',
      ink: '#071129',
      inkSoft: '#24324D',
      textMuted: '#5F6F89',
      footerText: '#8291A7',
      primary: '#137FEC',
      primaryDark: '#0B5FC4',
      primarySoft: '#EAF4FF',
      cyan: '#22D3EE',
      cyanSoft: '#E7F9FF',
      indigo: '#4F46E5',
      indigoSoft: '#EEF2FF',
      violet: '#7C3AED',
      violetSoft: '#F5F0FF',
      border: '#D7E4F3',
      divider: '#E6EEF8',
      decorationPrimary: '#E8F3FF',
      decorationCyan: '#DFF8FF',
      decorationViolet: '#F0E9FF',
      pageBadge: '#0A2A5E',
      panelTint: '#F0F7FF',
      success: '#10B981',
      warning: '#F59E0B',
    }),
    spacing: Object.freeze({
      pagePaddingX: 96,
      pagePaddingTop: 52,
      pagePaddingBottom: 40,
      headerHeight: 58,
      contentBottom: 966,
      footerY: 1010,
      contentWidth: 1728,
      titleWidth: 1540,
    }),
  });

  let libraryPromise = null;
  let mathJaxPromise = null;
  let activeExport = null;

  function assert(condition, message) {
    if (!condition) throw new Error(message);
  }

  function asString(value, fallback = '') {
    if (value === null || value === undefined) return fallback;
    return String(value).trim();
  }

  function asNumber(value, fallback) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  function asInteger(value, fallback) {
    return Math.trunc(asNumber(value, fallback));
  }

  function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, value));
  }

  function normalizeHex(value, fallback) {
    const clean = asString(value).replace(/^#/, '');
    if (/^[0-9a-fA-F]{6}$/.test(clean)) return `#${clean.toUpperCase()}`;
    if (/^[0-9a-fA-F]{8}$/.test(clean)) return `#${clean.slice(0, 6).toUpperCase()}`;
    return fallback;
  }

  function containsRtl(value) {
    return RTL_PATTERN.test(String(value || ''));
  }

  function validateLength(value, maximum, label) {
    if (value.length > maximum) {
      throw new Error(`${label} is too long (${value.length} characters). Maximum: ${maximum}.`);
    }
  }

  function sanitizeFileName(value) {
    const raw = String(value || 'presentation.pptx')
      .replace(/[\\/:*?"<>|\u0000-\u001F]+/g, '-')
      .replace(/\.+$/g, '')
      .replace(/\s+/g, ' ')
      .trim()
      .slice(0, 180);
    const safe = raw || 'presentation.pptx';
    return safe.toLowerCase().endsWith('.pptx') ? safe : `${safe}.pptx`;
  }

  function resolveFromBase(relativePath) {
    try {
      return new URL(relativePath, document.baseURI || global.location.href).toString();
    } catch (_) {
      return relativePath;
    }
  }

  function normalizeAssetPath(value, fallback) {
    const path = asString(value, fallback).replace(/^\/+/, '');
    if (!path || /^(?:data:|javascript:)/i.test(path)) return fallback;
    return path;
  }

  function normalizeFontFallbacks(value, fallback) {
    if (!Array.isArray(value)) return fallback;
    const fonts = value.map((item) => asString(item)).filter(Boolean).slice(0, 5);
    return fonts.length > 0 ? fonts : fallback;
  }

  function pickColor(rawColors, keys, fallback) {
    for (const key of keys) {
      if (rawColors[key] !== undefined) return normalizeHex(rawColors[key], fallback);
    }
    return fallback;
  }

  function normalizeTokens(rawTokens) {
    const raw = rawTokens && typeof rawTokens === 'object' && !Array.isArray(rawTokens)
      ? rawTokens
      : {};
    const rawColors = raw.colors && typeof raw.colors === 'object' ? raw.colors : {};
    const rawSpacing = raw.spacing && typeof raw.spacing === 'object' ? raw.spacing : {};
    const rawAssets = raw.assets && typeof raw.assets === 'object' ? raw.assets : {};

    const colors = {
      canvas: pickColor(rawColors, ['canvas'], DEFAULT_TOKENS.colors.canvas),
      white: pickColor(rawColors, ['white'], DEFAULT_TOKENS.colors.white),
      ink: pickColor(rawColors, ['ink', 'text_dark'], DEFAULT_TOKENS.colors.ink),
      inkSoft: pickColor(rawColors, ['ink_soft', 'navy'], DEFAULT_TOKENS.colors.inkSoft),
      textMuted: pickColor(rawColors, ['text_muted'], DEFAULT_TOKENS.colors.textMuted),
      footerText: pickColor(rawColors, ['footer_text'], DEFAULT_TOKENS.colors.footerText),
      primary: pickColor(rawColors, ['primary', 'teal'], DEFAULT_TOKENS.colors.primary),
      primaryDark: pickColor(rawColors, ['primary_dark', 'teal_dark'], DEFAULT_TOKENS.colors.primaryDark),
      primarySoft: pickColor(rawColors, ['primary_soft', 'teal_soft'], DEFAULT_TOKENS.colors.primarySoft),
      cyan: pickColor(rawColors, ['cyan', 'amber'], DEFAULT_TOKENS.colors.cyan),
      cyanSoft: pickColor(rawColors, ['cyan_soft', 'amber_soft'], DEFAULT_TOKENS.colors.cyanSoft),
      indigo: pickColor(rawColors, ['indigo'], DEFAULT_TOKENS.colors.indigo),
      indigoSoft: pickColor(rawColors, ['indigo_soft'], DEFAULT_TOKENS.colors.indigoSoft),
      violet: pickColor(rawColors, ['violet'], DEFAULT_TOKENS.colors.violet),
      violetSoft: pickColor(rawColors, ['violet_soft'], DEFAULT_TOKENS.colors.violetSoft),
      border: pickColor(rawColors, ['border'], DEFAULT_TOKENS.colors.border),
      divider: pickColor(rawColors, ['divider'], DEFAULT_TOKENS.colors.divider),
      decorationPrimary: pickColor(
        rawColors,
        ['decoration_primary', 'decoration_top'],
        DEFAULT_TOKENS.colors.decorationPrimary,
      ),
      decorationCyan: pickColor(
        rawColors,
        ['decoration_cyan', 'decoration_dot'],
        DEFAULT_TOKENS.colors.decorationCyan,
      ),
      decorationViolet: pickColor(
        rawColors,
        ['decoration_violet', 'decoration_bottom'],
        DEFAULT_TOKENS.colors.decorationViolet,
      ),
      pageBadge: pickColor(rawColors, ['page_badge', 'navy'], DEFAULT_TOKENS.colors.pageBadge),
      panelTint: pickColor(rawColors, ['panel_tint'], DEFAULT_TOKENS.colors.panelTint),
      success: pickColor(rawColors, ['success'], DEFAULT_TOKENS.colors.success),
      warning: pickColor(rawColors, ['warning'], DEFAULT_TOKENS.colors.warning),
    };

    const slideWidth = clamp(asNumber(raw.slide_width, DEFAULT_TOKENS.slideWidth), 960, 3840);
    const slideHeight = clamp(asNumber(raw.slide_height, DEFAULT_TOKENS.slideHeight), 540, 2160);
    const pagePaddingX = clamp(
      asNumber(rawSpacing.page_padding_x, DEFAULT_TOKENS.spacing.pagePaddingX),
      0,
      400,
    );

    return {
      schemaVersion: Math.max(1, asInteger(raw.schema_version, DEFAULT_TOKENS.schemaVersion)),
      slideWidth,
      slideHeight,
      maxCardsPerSlide: clamp(
        asInteger(raw.max_cards_per_slide, DEFAULT_TOKENS.maxCardsPerSlide),
        1,
        DEFAULT_MAX_CARDS,
      ),
      headingFontFamily: asString(
        raw.heading_font_family,
        asString(raw.font_family, DEFAULT_TOKENS.headingFontFamily),
      ),
      bodyFontFamily: asString(
        raw.body_font_family,
        asString(raw.font_family, DEFAULT_TOKENS.bodyFontFamily),
      ),
      rtlFontFamily: asString(
        raw.rtl_font_family,
        DEFAULT_TOKENS.rtlFontFamily,
      ),
      headingFontFallbacks: normalizeFontFallbacks(
        raw.heading_font_fallbacks,
        DEFAULT_TOKENS.headingFontFallbacks,
      ),
      bodyFontFallbacks: normalizeFontFallbacks(
        raw.body_font_fallbacks || raw.font_fallbacks,
        DEFAULT_TOKENS.bodyFontFallbacks,
      ),
      rtlFontFallbacks: normalizeFontFallbacks(
        raw.rtl_font_fallbacks,
        DEFAULT_TOKENS.rtlFontFallbacks,
      ),
      assets: {
        logoWeb: normalizeAssetPath(rawAssets.logo_web, DEFAULT_TOKENS.assets.logoWeb),
        interRegularWeb: normalizeAssetPath(
          rawAssets.inter_regular_web,
          DEFAULT_TOKENS.assets.interRegularWeb,
        ),
        interBoldWeb: normalizeAssetPath(
          rawAssets.inter_bold_web,
          DEFAULT_TOKENS.assets.interBoldWeb,
        ),
        lexendRegularWeb: normalizeAssetPath(
          rawAssets.lexend_regular_web,
          DEFAULT_TOKENS.assets.lexendRegularWeb,
        ),
        lexendBoldWeb: normalizeAssetPath(
          rawAssets.lexend_bold_web,
          DEFAULT_TOKENS.assets.lexendBoldWeb,
        ),
      },
      colors,
      spacing: {
        pagePaddingX,
        pagePaddingTop: clamp(
          asNumber(rawSpacing.page_padding_top, DEFAULT_TOKENS.spacing.pagePaddingTop),
          0,
          300,
        ),
        pagePaddingBottom: clamp(
          asNumber(rawSpacing.page_padding_bottom, DEFAULT_TOKENS.spacing.pagePaddingBottom),
          0,
          300,
        ),
        headerHeight: clamp(
          asNumber(rawSpacing.header_height, DEFAULT_TOKENS.spacing.headerHeight),
          30,
          160,
        ),
        contentBottom: clamp(
          asNumber(rawSpacing.content_bottom, DEFAULT_TOKENS.spacing.contentBottom),
          500,
          slideHeight - 40,
        ),
        footerY: clamp(
          asNumber(rawSpacing.footer_y, DEFAULT_TOKENS.spacing.footerY),
          500,
          slideHeight - 20,
        ),
        contentWidth: clamp(
          asNumber(rawSpacing.content_width, slideWidth - pagePaddingX * 2),
          400,
          slideWidth,
        ),
        titleWidth: clamp(
          asNumber(rawSpacing.title_width, DEFAULT_TOKENS.spacing.titleWidth),
          400,
          slideWidth - pagePaddingX,
        ),
      },
    };
  }

  function normalizeDeck(input) {
    let deck;
    try {
      deck = typeof input === 'string' ? JSON.parse(input) : input;
    } catch (error) {
      throw new Error(`Invalid presentation JSON: ${error.message || error}`);
    }

    assert(deck && typeof deck === 'object' && !Array.isArray(deck),
      'The presentation JSON must be an object.');
    assert(Array.isArray(deck.slides) && deck.slides.length > 0,
      'The presentation JSON must contain a non-empty slides array.');
    assert(deck.slides.length <= MAX_SLIDES,
      `The presentation contains ${deck.slides.length} slides. Maximum: ${MAX_SLIDES}.`);

    const tokens = normalizeTokens(deck.design_tokens);
    const title = asString(deck.title, 'AI Presentation');
    validateLength(title, MAX_TITLE_CHARACTERS, 'Presentation title');

    return {
      title,
      tokens,
      slides: deck.slides.map((rawSlide, index) => normalizeSlide(rawSlide, index, tokens)),
    };
  }


  function normalizeVisual(rawVisual) {
    if (rawVisual === undefined || rawVisual === null || rawVisual === '') return null;
    if (typeof rawVisual === 'string') return { src: rawVisual.trim(), caption: '', alt: '' };
    if (typeof rawVisual !== 'object' || Array.isArray(rawVisual)) return null;
    const src = asString(rawVisual.src || rawVisual.url || rawVisual.asset || rawVisual.path);
    if (!src) return null;
    return {
      src,
      caption: asString(rawVisual.caption),
      alt: asString(rawVisual.alt || rawVisual.description),
    };
  }

  function normalizeEquation(rawEquation) {
    if (rawEquation === undefined || rawEquation === null || rawEquation === '') return null;
    if (typeof rawEquation === 'string' || typeof rawEquation === 'number') {
      return { value: String(rawEquation).trim(), label: '', explanation: '' };
    }
    if (typeof rawEquation !== 'object' || Array.isArray(rawEquation)) return null;
    const value = asString(rawEquation.latex || rawEquation.value || rawEquation.text || rawEquation.formula);
    if (!value) return null;
    validateLength(value, 900, 'Equation');
    return {
      value,
      label: asString(rawEquation.label || rawEquation.title),
      explanation: asString(rawEquation.explanation || rawEquation.body),
    };
  }

  function normalizeProblem(rawProblem, slideIndex) {
    if (!rawProblem || typeof rawProblem !== 'object' || Array.isArray(rawProblem)) return null;
    const list = (value) => Array.isArray(value)
      ? value.map((item) => asString(item)).filter(Boolean).slice(0, 8)
      : [];
    const statement = asString(rawProblem.statement || rawProblem.question || rawProblem.prompt);
    if (!statement) return null;
    validateLength(statement, 1600, `Slide ${slideIndex + 1} problem statement`);
    const steps = list(rawProblem.solution_steps || rawProblem.steps || rawProblem.solution).slice(0, 6);
    steps.forEach((step, stepIndex) => validateLength(
      step,
      800,
      `Slide ${slideIndex + 1} solution step ${stepIndex + 1}`,
    ));
    return {
      statement,
      choices: list(rawProblem.choices || rawProblem.options).slice(0, 6),
      answer: asString(rawProblem.answer || rawProblem.correct_answer),
      solutionSteps: steps,
      hint: asString(rawProblem.hint),
    };
  }

  function normalizeSlide(rawSlide, index, tokens) {
    assert(rawSlide && typeof rawSlide === 'object' && !Array.isArray(rawSlide),
      `Slide ${index + 1} must be an object.`);
    const slide = rawSlide;
    const rawCards = slide.cards === undefined ? [] : slide.cards;
    assert(Array.isArray(rawCards), `Slide ${index + 1}: cards must be an array.`);
    assert(rawCards.length <= tokens.maxCardsPerSlide,
      `Slide ${index + 1} contains ${rawCards.length} cards. Maximum: ${tokens.maxCardsPerSlide}.`);

    const cards = rawCards.map((rawCard, cardIndex) => {
      assert(rawCard && typeof rawCard === 'object' && !Array.isArray(rawCard),
        `Slide ${index + 1}, card ${cardIndex + 1}: card must be an object.`);
      const heading = asString(rawCard.heading, `Card ${cardIndex + 1}`);
      const body = asString(rawCard.body);
      validateLength(heading, MAX_CARD_HEADING_CHARACTERS,
        `Slide ${index + 1}, card ${cardIndex + 1} heading`);
      validateLength(body, MAX_CARD_BODY_CHARACTERS,
        `Slide ${index + 1}, card ${cardIndex + 1} body`);
      return {
        icon: asString(rawCard.icon, 'auto_awesome_white'),
        heading,
        body,
        visual: normalizeVisual(rawCard.visual || rawCard.image || rawCard.image_url || rawCard.asset),
        equation: normalizeEquation(rawCard.equation),
      };
    });

    const title = asString(slide.title, `Slide ${index + 1}`);
    const kicker = asString(slide.kicker);
    validateLength(title, MAX_TITLE_CHARACTERS, `Slide ${index + 1} title`);
    validateLength(kicker, MAX_KICKER_CHARACTERS, `Slide ${index + 1} kicker`);

    const visual = normalizeVisual(slide.visual || slide.image);
    const equation = normalizeEquation(slide.equation);
    const problem = normalizeProblem(slide.problem, index);
    let layoutType = normalizeLayout(slide.layout_type, cards.length);
    const rawLayout = asString(slide.layout_type);
    if (problem) layoutType = 'problem_solution';
    else if (equation && !rawLayout) layoutType = 'equation_focus';
    else if (visual && !rawLayout) layoutType = 'visual_focus';

    return {
      slideNumber: Math.max(1, asInteger(slide.slide_number, index + 1)),
      isTemplate: Object.prototype.hasOwnProperty.call(slide, 'cards') ||
        Object.prototype.hasOwnProperty.call(slide, 'layout_type') ||
        Object.prototype.hasOwnProperty.call(slide, 'kicker') ||
        visual || equation || problem,
      layoutType,
      kicker,
      title,
      cards,
      visual,
      equation,
      problem,
      elements: Array.isArray(slide.elements) ? slide.elements : [],
      background: normalizeHex(slide.background, tokens.colors.canvas),
    };
  }

  function normalizeLayout(value, cardCount) {
    const layout = asString(value).toLowerCase();
    if (['single_card_center', 'single_card', 'one_card'].includes(layout)) {
      return cardCount === 1 ? 'single_card_center' : chooseLayout(cardCount);
    }
    if (['two_card_horizontal', 'two_cards_horizontal', 'two_column_cards'].includes(layout)) {
      return 'two_card_horizontal';
    }
    if (['three_card_horizontal', 'three_cards_horizontal', 'three_column_cards'].includes(layout)) {
      return 'three_card_horizontal';
    }
    if (['adaptive_cards', 'card_grid', 'cards'].includes(layout)) return 'adaptive_cards';
    if (['visual_focus', 'image_focus', 'picture_focus'].includes(layout)) return 'visual_focus';
    if (['equation_focus', 'formula_focus', 'math_focus'].includes(layout)) return 'equation_focus';
    if (['problem_solution', 'problem', 'quiz_solution'].includes(layout)) return 'problem_solution';
    return chooseLayout(cardCount);
  }

  function chooseLayout(cardCount) {
    if (cardCount <= 1) return 'single_card_center';
    if (cardCount === 2) return 'two_card_horizontal';
    if (cardCount === 3) return 'three_card_horizontal';
    return 'adaptive_cards';
  }

  function gridSpec(layoutType, cardCount) {
    const count = clamp(Math.max(1, cardCount), 1, DEFAULT_MAX_CARDS);
    const layout = asString(layoutType).toLowerCase();
    let columns;
    if (layout === 'single_card_center' && count === 1) columns = 1;
    else if (layout === 'two_card_horizontal' && count <= 6) columns = Math.min(2, count);
    else if (layout === 'three_card_horizontal' && count <= 6) columns = Math.min(3, count);
    else if (count <= 3) columns = count;
    else if (count === 4) columns = 2;
    else if (count <= 6) columns = 3;
    else if (count <= 8) columns = 4;
    else if (count === 9) columns = 3;
    else columns = 4;

    const rows = Math.ceil(count / columns);
    const density = rows >= 3 || columns >= 4
      ? 'dense'
      : rows >= 2 || columns >= 3
        ? 'compact'
        : 'comfortable';
    return { columns, rows, density };
  }

  function textUnits(value) {
    let total = 0;
    for (const character of String(value || '')) {
      const rune = character.codePointAt(0);
      if (rune === 32) total += 0.34;
      else if (rune >= 0x0590 && rune <= 0x08FF) total += 0.62;
      else if (rune >= 0x4E00 && rune <= 0x9FFF) total += 1;
      else if (rune >= 65 && rune <= 90) total += 0.68;
      else if ((rune >= 97 && rune <= 122) || (rune >= 48 && rune <= 57)) total += 0.52;
      else total += 0.42;
    }
    return total;
  }

  function splitWordByUnits(word, maxUnits) {
    if (!word || textUnits(word) <= maxUnits) return [word];
    const chunks = [];
    let current = '';
    let currentUnits = 0;

    for (const character of Array.from(word)) {
      const characterUnits = textUnits(character);
      if (current && currentUnits + characterUnits > maxUnits) {
        chunks.push(current);
        current = '';
        currentUnits = 0;
      }
      current += character;
      currentUnits += characterUnits;
    }

    if (current) chunks.push(current);
    return chunks.length > 0 ? chunks : [word];
  }

  function wrapText(value, width, fontSize, maxLines, averageGlyphFactor = 1) {
    const normalized = String(value || '').replace(/\s+/g, ' ').trim();
    if (!normalized) return ' ';
    if (maxLines <= 0 || width <= 0 || fontSize <= 0) return normalized;

    const maxUnits = width / fontSize / averageGlyphFactor;
    const tokens = [];
    for (const word of normalized.split(' ')) {
      const chunks = splitWordByUnits(word, maxUnits);
      chunks.forEach((text, index) => {
        tokens.push({ text, forceLineAfter: index < chunks.length - 1 });
      });
    }

    const lines = [];
    let current = '';
    let consumedAll = true;

    for (let index = 0; index < tokens.length; index += 1) {
      const token = tokens[index];
      const candidate = current ? `${current} ${token.text}` : token.text;

      if (!current || textUnits(candidate) <= maxUnits) {
        current = candidate;
      } else {
        lines.push(current);
        current = token.text;
        if (lines.length >= maxLines) {
          consumedAll = false;
          current = '';
          break;
        }
      }

      if (token.forceLineAfter && current) {
        lines.push(current);
        current = '';
        if (lines.length >= maxLines) {
          consumedAll = index === tokens.length - 1;
          break;
        }
      }
    }

    if (current) {
      if (lines.length < maxLines) lines.push(current);
      else consumedAll = false;
    }

    if (!consumedAll && lines.length > 0) {
      let last = lines[lines.length - 1].replace(/[\s…]+$/g, '');
      while (last && textUnits(`${last}…`) > maxUnits) {
        last = last.slice(0, -1).trimEnd();
      }
      lines[lines.length - 1] = `${last || ''}…`;
    }

    return lines.slice(0, maxLines).join('\n');
  }

  function titleSizeFor(title, density) {
    const units = textUnits(title);
    if (density === 'comfortable') {
      if (units > 92) return 44;
      if (units > 70) return 50;
      if (units > 52) return 56;
      return 64;
    }
    if (density === 'compact') {
      if (units > 100) return 40;
      if (units > 76) return 46;
      if (units > 56) return 52;
      return 58;
    }
    if (units > 110) return 34;
    if (units > 86) return 38;
    if (units > 62) return 42;
    return 48;
  }

  function cardGapFor(density) {
    if (density === 'comfortable') return 26;
    if (density === 'compact') return 22;
    return 16;
  }

  function cardRadiusFor(density) {
    if (density === 'comfortable') return 24;
    if (density === 'compact') return 20;
    return 16;
  }

  function layoutSpec(slide, tokens) {
    const grid = gridSpec(slide.layoutType, slide.cards.length);
    const titleFontSize = titleSizeFor(slide.title, grid.density);
    const titleText = wrapText(slide.title, tokens.spacing.titleWidth, titleFontSize, 2);
    const titleLineCount = titleText.split('\n').length;
    let contentTop;
    if (grid.density === 'comfortable') contentTop = titleLineCount > 1 ? 380 : 332;
    else if (grid.density === 'compact') contentTop = titleLineCount > 1 ? 350 : 306;
    else contentTop = titleLineCount > 1 ? 314 : 276;
    if (!slide.kicker) contentTop -= 34;

    const gap = cardGapFor(grid.density);
    const availableHeight = tokens.spacing.contentBottom - contentTop;
    const naturalWidth = (
      tokens.spacing.contentWidth - gap * (grid.columns - 1)
    ) / grid.columns;
    const naturalHeight = (
      availableHeight - gap * (grid.rows - 1)
    ) / grid.rows;
    const maxSingleRowHeight = grid.density === 'comfortable'
      ? 330
      : grid.density === 'compact'
        ? 315
        : 295;
    const cardWidth = grid.columns === 1 ? Math.min(naturalWidth, 1320) : naturalWidth;
    const cardHeight = grid.rows === 1 ? Math.min(naturalHeight, maxSingleRowHeight) : naturalHeight;
    const gridWidth = cardWidth * grid.columns + gap * (grid.columns - 1);
    const gridHeight = cardHeight * grid.rows + gap * (grid.rows - 1);
    const originX = tokens.spacing.pagePaddingX +
      (tokens.spacing.contentWidth - gridWidth) / 2;
    const originY = contentTop + (availableHeight - gridHeight) / 2;

    return {
      grid,
      cardCount: slide.cards.length,
      titleFontSize,
      titleText,
      titleLineCount,
      contentTop,
      gap,
      cardWidth,
      cardHeight,
      originX,
      originY,
    };
  }

  function cardHeadingSize(value, density) {
    const units = textUnits(value);
    if (density === 'dense') {
      if (units > 48) return 12.5;
      if (units > 34) return 14;
      return 16;
    }
    if (density === 'compact') {
      if (units > 58) return 16;
      if (units > 40) return 18.5;
      return 21;
    }
    if (units > 66) return 19;
    if (units > 46) return 22;
    return 25;
  }

  function cardBodySize(value, density) {
    const length = String(value || '').trim().length;
    if (density === 'dense') {
      if (length > 360) return 9;
      if (length > 220) return 10;
      if (length > 130) return 10.8;
      return 11.5;
    }
    if (density === 'compact') {
      if (length > 420) return 11;
      if (length > 260) return 12.5;
      if (length > 150) return 13.5;
      return 15;
    }
    if (length > 500) return 13;
    if (length > 320) return 14.5;
    if (length > 190) return 16;
    return 18;
  }

  function cardMetrics(density, width, height, heading, body) {
    const compact = density === 'compact';
    const dense = density === 'dense';
    const padding = dense ? 14 : compact ? 22 : 30;
    const topPadding = dense ? 14 : compact ? 20 : 26;
    const bottomPadding = dense ? 12 : compact ? 16 : 20;
    const iconSize = dense ? 36 : compact ? 48 : 58;
    const iconRadius = dense ? 10 : compact ? 13 : 16;
    const iconFontSize = dense ? 15 : compact ? 20 : 24;
    const numberWidth = dense ? 42 : compact ? 50 : 56;
    const numberHeight = dense ? 24 : compact ? 28 : 32;
    const numberTop = topPadding + (iconSize - numberHeight) / 2;
    const numberFontSize = dense ? 10 : compact ? 11.5 : 13;
    const headingFontSize = cardHeadingSize(heading, density);
    const bodyFontSize = cardBodySize(body, density);
    const headingTop = topPadding + iconSize + (dense ? 8 : compact ? 12 : 16);
    const headingHeight = headingFontSize * 1.16 * 2 + 2;
    const bodyTop = headingTop + headingHeight + (dense ? 4 : compact ? 8 : 10);
    const bottomAccentHeight = dense ? 4 : 5;
    const bottomAccentWidth = dense ? 28 : compact ? 38 : 48;
    const accentTop = height - bottomPadding - bottomAccentHeight;
    const bodyHeight = Math.max(0, accentTop - bodyTop - (dense ? 8 : 12));
    const bodyLineHeight = dense ? 1.25 : compact ? 1.3 : 1.35;
    const calculatedLines = bodyHeight <= 0
      ? 1
      : Math.floor(bodyHeight / (bodyFontSize * bodyLineHeight));
    const maxLines = dense ? 4 : compact ? 5 : 6;

    return {
      padding,
      topPadding,
      bottomPadding,
      iconSize,
      iconRadius,
      iconFontSize,
      numberTop,
      numberWidth,
      numberHeight,
      numberFontSize,
      headingTop,
      headingHeight,
      headingFontSize,
      bodyTop,
      bodyHeight,
      bodyFontSize,
      bodyLineHeight,
      bodyMaxLines: Math.max(1, Math.min(maxLines, calculatedLines)),
      textWidth: Math.max(1, width - padding * 2),
      topAccentWidth: dense ? 58 : compact ? 72 : 88,
      topAccentHeight: dense ? 4 : 5,
      bottomAccentWidth,
      bottomAccentHeight,
    };
  }

  function accentFor(index, tokens) {
    const accents = [
      [tokens.colors.primary, tokens.colors.primarySoft],
      [tokens.colors.cyan, tokens.colors.cyanSoft],
      [tokens.colors.indigo, tokens.colors.indigoSoft],
      [tokens.colors.violet, tokens.colors.violetSoft],
    ];
    const [color, softColor] = accents[index % accents.length];
    return { color, softColor };
  }

  function make(tag, className, text) {
    const element = document.createElement(tag);
    if (className) element.className = className;
    if (text !== undefined && text !== null) element.textContent = String(text);
    return element;
  }

  function append(parent, ...children) {
    children.filter(Boolean).forEach((child) => parent.appendChild(child));
    return parent;
  }

  function setStyles(element, styles) {
    Object.entries(styles).forEach(([key, value]) => {
      if (value !== null && value !== undefined && value !== '') {
        element.style[key] = String(value);
      }
    });
    return element;
  }

  function position(element, left, top, width, height) {
    return setStyles(element, {
      left: `${left}px`,
      top: `${top}px`,
      width: `${width}px`,
      height: `${height}px`,
    });
  }

  function setTextDirection(element, text) {
    const rtl = containsRtl(text);
    element.setAttribute('dir', rtl ? 'rtl' : 'ltr');
    element.setAttribute('lang', rtl ? 'ar' : 'en');
    element.style.direction = rtl ? 'rtl' : 'ltr';
    element.style.textAlign = rtl ? 'right' : 'left';
    if (rtl) element.style.fontFamily = 'var(--rtl-font-family)';
    return rtl;
  }

  function iconGlyph(iconKey) {
    const key = asString(iconKey).toLowerCase();
    if (key.includes('database')) return '▦';
    if (key.includes('vector') || key.includes('network')) return '◆';
    if (key.includes('pdf') || key.includes('file')) return 'PDF';
    if (key.includes('codebranch')) return '⌘';
    if (key.includes('question')) return '?';
    if (key.includes('comments') || key.includes('chat')) return '☰';
    if (key.includes('robot')) return 'AI';
    if (key.includes('docker')) return '⚙';
    if (key.includes('bolt')) return '⚡';
    if (key.includes('book')) return '▤';
    if (key.includes('brain')) return 'AI';
    if (key.includes('check') || key.includes('shield') || key.includes('clipboard')) return '✓';
    if (key.includes('anchor')) return '⌾';
    if (key.includes('exclamation') || key.includes('warning')) return '!';
    if (key.includes('layer')) return '▣';
    if (key.includes('sitemap')) return '▦';
    if (key.includes('list')) return '☷';
    if (key.includes('sync') || key.includes('refresh') || key.includes('update')) return '↻';
    if (key.includes('search')) return '⌕';
    return '✦';
  }

  function applyTokenVariables(root, tokens) {
    const headingFallbacks = tokens.headingFontFallbacks.join(', ');
    const bodyFallbacks = tokens.bodyFontFallbacks.join(', ');
    const variables = {
      '--slide-width': `${tokens.slideWidth}px`,
      '--slide-height': `${tokens.slideHeight}px`,
      '--heading-font-family': `'${tokens.headingFontFamily}', ${headingFallbacks}`,
      '--body-font-family': `'${tokens.bodyFontFamily}', ${bodyFallbacks}`,
      '--rtl-font-family': `'${tokens.rtlFontFamily}', ${tokens.rtlFontFallbacks.join(', ')}`,
      '--canvas': tokens.colors.canvas,
      '--white': tokens.colors.white,
      '--ink': tokens.colors.ink,
      '--ink-soft': tokens.colors.inkSoft,
      '--text-muted': tokens.colors.textMuted,
      '--footer-text': tokens.colors.footerText,
      '--primary': tokens.colors.primary,
      '--primary-dark': tokens.colors.primaryDark,
      '--primary-soft': tokens.colors.primarySoft,
      '--cyan': tokens.colors.cyan,
      '--cyan-soft': tokens.colors.cyanSoft,
      '--indigo': tokens.colors.indigo,
      '--indigo-soft': tokens.colors.indigoSoft,
      '--violet': tokens.colors.violet,
      '--violet-soft': tokens.colors.violetSoft,
      '--border': tokens.colors.border,
      '--divider': tokens.colors.divider,
      '--decoration-primary': tokens.colors.decorationPrimary,
      '--decoration-cyan': tokens.colors.decorationCyan,
      '--decoration-violet': tokens.colors.decorationViolet,
      '--page-badge': tokens.colors.pageBadge,
      '--panel-tint': tokens.colors.panelTint,
      '--success': tokens.colors.success,
      '--warning': tokens.colors.warning,
    };
    Object.entries(variables).forEach(([key, value]) => root.style.setProperty(key, value));
  }

  function buildHeader(slide, tokens) {
    const header = make('header', 'learnova-header');
    position(
      header,
      tokens.spacing.pagePaddingX,
      tokens.spacing.pagePaddingTop,
      tokens.spacing.contentWidth,
      tokens.spacing.headerHeight,
    );

    const logo = make('img', 'learnova-brand-logo');
    logo.alt = 'Learnova';
    logo.src = resolveFromBase(tokens.assets.logoWeb);
    logo.crossOrigin = 'anonymous';
    position(logo, 0, 2, 50, 50);

    const brand = make('div', 'learnova-brand-name', 'Learnova');
    position(brand, 64, 8, 190, 38);

    const product = make('div', 'learnova-product-badge', 'AI PRESENTATION');
    position(product, 260, 10, 230, 34);

    const page = make(
      'div',
      'learnova-page-number',
      String(slide.slideNumber).padStart(2, '0'),
    );
    position(page, tokens.spacing.contentWidth - 92, 6, 92, 42);

    return append(header, logo, brand, product, page);
  }

  function buildHero(slide, spec, tokens) {
    const hero = make('section', 'learnova-hero');
    position(
      hero,
      tokens.spacing.pagePaddingX,
      132,
      tokens.spacing.titleWidth,
      spec.contentTop - 146,
    );
    const titleRtl = containsRtl(slide.title);
    const kickerRtl = containsRtl(slide.kicker);
    const titleTop = slide.kicker ? 56 : 8;
    const titleHeight = spec.titleFontSize * 1.08 * spec.titleLineCount + 8;
    const marksTop = titleTop + titleHeight + 14;

    if (slide.kicker) {
      const kicker = make('div', 'learnova-kicker');
      position(kicker, titleRtl ? tokens.spacing.titleWidth - 360 : 0, 0, 360, 38);
      const dot = make('span', 'learnova-kicker-dot');
      position(dot, kickerRtl ? 334 : 18, 15, 8, 8);
      const text = make('span', 'learnova-kicker-text', slide.kicker.toUpperCase());
      position(text, kickerRtl ? 18 : 38, 8, 304, 22);
      setTextDirection(text, slide.kicker);
      append(kicker, dot, text);
      hero.appendChild(kicker);
    }

    const title = make('h1', 'learnova-title', spec.titleText);
    position(title, 0, titleTop, tokens.spacing.titleWidth, titleHeight);
    title.style.fontSize = `${spec.titleFontSize}px`;
    setTextDirection(title, slide.title);
    hero.appendChild(title);

    const marks = make('div', 'learnova-title-marks');
    position(marks, titleRtl ? tokens.spacing.titleWidth - 124 : 0, marksTop, 124, 8);
    const primaryMark = make('span', 'learnova-title-mark learnova-title-mark-primary');
    position(primaryMark, 0, 0, 88, 8);
    const cyanMark = make('span', 'learnova-title-mark learnova-title-mark-cyan');
    position(cyanMark, 98, 0, 26, 8);
    append(marks, primaryMark, cyanMark);
    hero.appendChild(marks);

    return hero;
  }

  function buildCard(card, index, spec, tokens, slideRtl) {
    const row = Math.floor(index / spec.grid.columns);
    const logicalColumn = index % spec.grid.columns;
    const remaining = Math.max(0, spec.cardCount - row * spec.grid.columns);
    const itemsInRow = Math.min(spec.grid.columns, remaining);
    const rowWidth = itemsInRow * spec.cardWidth + (itemsInRow - 1) * spec.gap;
    const rowStartX = tokens.spacing.pagePaddingX +
      (tokens.spacing.contentWidth - rowWidth) / 2;
    const visualColumn = slideRtl
      ? Math.max(0, itemsInRow - 1 - logicalColumn)
      : logicalColumn;
    const left = rowStartX + visualColumn * (spec.cardWidth + spec.gap);
    const top = spec.originY + row * (spec.cardHeight + spec.gap);
    const accent = accentFor(index, tokens);
    const metrics = cardMetrics(
      spec.grid.density,
      spec.cardWidth,
      spec.cardHeight,
      card.heading,
      card.body,
    );
    const headingRtl = containsRtl(card.heading);
    const bodyRtl = containsRtl(card.body);
    const cardRtl = card.heading ? headingRtl : bodyRtl;
    const headingText = wrapText(
      card.heading,
      metrics.textWidth,
      metrics.headingFontSize,
      2,
    );
    const bodyText = wrapText(
      card.body,
      metrics.textWidth,
      metrics.bodyFontSize,
      metrics.bodyMaxLines,
    );

    const element = make('article', `learnova-card learnova-card-${spec.grid.density}`);
    position(element, left, top, spec.cardWidth, spec.cardHeight);
    element.style.setProperty('--accent', accent.color);
    element.style.setProperty('--accent-soft', accent.softColor);
    element.style.borderRadius = `${cardRadiusFor(spec.grid.density)}px`;
    element.setAttribute('dir', cardRtl ? 'rtl' : 'ltr');

    const topAccent = make('div', 'learnova-card-top-accent');
    position(
      topAccent,
      cardRtl ? spec.cardWidth - metrics.topAccentWidth : 0,
      0,
      metrics.topAccentWidth,
      metrics.topAccentHeight,
    );

    const icon = make('div', 'learnova-card-icon', iconGlyph(card.icon));
    position(
      icon,
      cardRtl
        ? spec.cardWidth - metrics.padding - metrics.iconSize
        : metrics.padding,
      metrics.topPadding,
      metrics.iconSize,
      metrics.iconSize,
    );
    icon.style.borderRadius = `${metrics.iconRadius}px`;
    icon.style.fontSize = `${metrics.iconFontSize}px`;

    const number = make(
      'div',
      'learnova-card-number',
      String(index + 1).padStart(2, '0'),
    );
    position(
      number,
      cardRtl
        ? metrics.padding
        : spec.cardWidth - metrics.padding - metrics.numberWidth,
      metrics.numberTop,
      metrics.numberWidth,
      metrics.numberHeight,
    );
    number.style.borderRadius = `${metrics.numberHeight / 2}px`;
    number.style.fontSize = `${metrics.numberFontSize}px`;

    const heading = make('h2', 'learnova-card-heading', headingText);
    position(
      heading,
      metrics.padding,
      metrics.headingTop,
      metrics.textWidth,
      metrics.headingHeight,
    );
    heading.style.fontSize = `${metrics.headingFontSize}px`;
    setTextDirection(heading, card.heading);

    const body = make('p', 'learnova-card-body', bodyText);
    position(
      body,
      metrics.padding,
      metrics.bodyTop,
      metrics.textWidth,
      metrics.bodyHeight,
    );
    body.style.fontSize = `${metrics.bodyFontSize}px`;
    body.style.lineHeight = String(metrics.bodyLineHeight);
    setTextDirection(body, bodyContent);

    const bottomAccent = make('div', 'learnova-card-bottom-accent');
    position(
      bottomAccent,
      cardRtl
        ? spec.cardWidth - metrics.padding - metrics.bottomAccentWidth
        : metrics.padding,
      spec.cardHeight - metrics.bottomPadding - metrics.bottomAccentHeight,
      metrics.bottomAccentWidth,
      metrics.bottomAccentHeight,
    );
    bottomAccent.style.borderRadius = `${metrics.bottomAccentHeight / 2}px`;

    return append(element, topAccent, icon, number, heading, body, bottomAccent);
  }

  function buildEmptyState(spec, tokens) {
    const wrapper = make('div', 'learnova-empty-wrapper');
    position(
      wrapper,
      tokens.spacing.pagePaddingX,
      spec.contentTop,
      tokens.spacing.contentWidth,
      tokens.spacing.contentBottom - spec.contentTop,
    );
    const empty = make('div', 'learnova-empty-card');
    position(
      empty,
      (tokens.spacing.contentWidth - 760) / 2,
      (tokens.spacing.contentBottom - spec.contentTop - 300) / 2,
      760,
      300,
    );
    const logo = make('img', 'learnova-empty-logo');
    logo.alt = 'Learnova';
    logo.src = resolveFromBase(tokens.assets.logoWeb);
    logo.crossOrigin = 'anonymous';
    position(logo, 348, 74, 64, 64);
    const title = make('div', 'learnova-empty-title', 'Add cards from the slide editor');
    position(title, 80, 164, 600, 40);
    append(empty, logo, title);
    wrapper.appendChild(empty);
    return wrapper;
  }


  function imageSource(src) {
    const clean = asString(src).replace(/^\/+/, '');
    if (!clean) return '';
    if (/^(?:https?:|data:|blob:)/i.test(clean)) return clean;
    if (clean.startsWith('assets/assets/')) return resolveFromBase(clean);
    if (clean.startsWith('assets/')) return resolveFromBase(`assets/${clean}`);
    return resolveFromBase(`assets/${clean}`);
  }

  function contentWrapper(spec, tokens, className) {
    const wrapper = make('div', className || 'learnova-dynamic-wrapper');
    position(
      wrapper,
      tokens.spacing.pagePaddingX,
      spec.contentTop,
      tokens.spacing.contentWidth,
      tokens.spacing.contentBottom - spec.contentTop,
    );
    return wrapper;
  }

  function buildVisualFrame(visual, x, y, w, h) {
    const frame = make('div', 'learnova-visual-frame');
    position(frame, x, y, w, h);
    const image = make('img', 'learnova-visual-image');
    image.alt = visual.alt || visual.caption || 'Presentation visual';
    image.src = imageSource(visual.src);
    image.crossOrigin = 'anonymous';
    position(image, 0, 0, w, h);
    frame.appendChild(image);
    if (visual.caption) {
      const caption = make('div', 'learnova-visual-caption', visual.caption);
      position(caption, 30, h - 84, w - 60, 54);
      setTextDirection(caption, visual.caption);
      frame.appendChild(caption);
    }
    return frame;
  }

  function buildNarrativePanel(eyebrow, body, icon, x, y, w, h) {
    const rtl = containsRtl(`${eyebrow} ${body}`);
    const panel = make('div', 'learnova-narrative-panel');
    position(panel, x, y, w, h);
    const iconBox = make('div', 'learnova-narrative-icon', iconGlyph(icon));
    position(iconBox, 36, 36, 58, 58);
    const label = make('div', 'learnova-narrative-eyebrow', eyebrow);
    position(label, 36, 132, w - 72, 34);
    setTextDirection(label, eyebrow);
    const text = make('div', 'learnova-narrative-body', wrapText(body, w - 72, 30, 8, 0.9));
    position(text, 36, 190, w - 72, h - 220);
    setTextDirection(text, body);
    if (rtl) panel.setAttribute('dir', 'rtl');
    return append(panel, iconBox, label, text);
  }

  function buildMiniInsight(card, index, x, y, w, h, tokens) {
    const accent = accentFor(index, tokens);
    const rtl = containsRtl(`${card.heading} ${card.body}`);
    const mini = make('div', 'learnova-mini-insight');
    position(mini, x, y, w, h);
    mini.style.setProperty('--accent', accent.color);
    mini.style.setProperty('--accent-soft', accent.softColor);
    const icon = make('div', 'learnova-mini-icon', iconGlyph(card.icon));
    position(icon, rtl ? w - 70 : 22, 17, 48, 48);
    const heading = make('div', 'learnova-mini-heading', card.heading);
    position(heading, rtl ? 22 : 88, 18, w - 110, 24);
    setTextDirection(heading, card.heading);
    const body = make('div', 'learnova-mini-body', card.equation ? card.equation.value : card.body);
    position(body, rtl ? 22 : 88, 48, w - 110, 22);
    setTextDirection(body, card.equation ? card.equation.value : card.body);
    return append(mini, icon, heading, body);
  }

  function buildVisualFocusLayout(slide, spec, tokens) {
    const wrapper = contentWrapper(spec, tokens, 'learnova-visual-focus');
    const visual = slide.visual;
    const lead = slide.cards[0];
    const rest = slide.cards.slice(1, 4);
    const rtl = containsRtl(`${slide.title} ${lead ? lead.body : ''}`);
    const panelW = 700;
    const gap = 38;
    const imageW = tokens.spacing.contentWidth - panelW - gap;
    const height = tokens.spacing.contentBottom - spec.contentTop;
    const panelX = rtl ? tokens.spacing.contentWidth - panelW : 0;
    const imageX = rtl ? 0 : panelW + gap;
    wrapper.appendChild(buildVisualFrame(visual, imageX, 0, imageW, height));
    wrapper.appendChild(buildNarrativePanel(
      lead ? lead.heading : 'Visual insight',
      lead ? lead.body : (visual.caption || 'Add an image caption or supporting card content.'),
      lead ? lead.icon : 'image_white',
      panelX,
      12,
      panelW,
      Math.min(300, height - 24),
    ));
    rest.forEach((card, index) => {
      wrapper.appendChild(buildMiniInsight(card, index + 1, panelX, 330 + index * 104, panelW, 82, tokens));
    });
    return wrapper;
  }

  function buildEquationLayout(slide, spec, tokens) {
    const wrapper = contentWrapper(spec, tokens, 'learnova-equation-focus');
    const equation = slide.equation;
    const rtl = containsRtl(`${equation.explanation || ''} ${slide.title}`);
    const height = tokens.spacing.contentBottom - spec.contentTop;
    const sideW = 560;
    const gap = 38;
    const eqW = tokens.spacing.contentWidth - sideW - gap;
    const sideX = rtl ? tokens.spacing.contentWidth - sideW : 0;
    const eqX = rtl ? 0 : sideW + gap;
    const eqPanel = make('div', 'learnova-equation-panel');
    position(eqPanel, eqX, 0, eqW, height - 110);
    const label = make('div', 'learnova-equation-label', equation.label || 'Key equation');
    position(label, 54, 48, eqW - 108, 34);
    setTextDirection(label, label.textContent);
    const value = make('div', 'learnova-equation-value', equation.value);
    position(value, 54, 126, eqW - 108, height - 250);
    value.setAttribute('dir', 'ltr');
    value.style.textAlign = 'center';
    eqPanel.appendChild(label);
    eqPanel.appendChild(value);
    wrapper.appendChild(eqPanel);
    wrapper.appendChild(buildNarrativePanel(
      'Explanation',
      equation.explanation || 'Explain every variable and the learning objective behind the equation.',
      'function_white',
      sideX,
      0,
      sideW,
      height - 110,
    ));
    slide.cards.slice(0, 3).forEach((card, index) => {
      wrapper.appendChild(buildMiniInsight(card, index, index * 570, height - 86, 540, 86, tokens));
    });
    return wrapper;
  }

  function buildProblemLayout(slide, spec, tokens) {
    const wrapper = contentWrapper(spec, tokens, 'learnova-problem-layout');
    const problem = slide.problem;
    const rtl = containsRtl(problem.statement);
    const height = tokens.spacing.contentBottom - spec.contentTop;
    const questionW = 760;
    const solutionW = 748;
    const questionX = rtl ? tokens.spacing.contentWidth - questionW : 0;
    const solutionX = rtl ? 0 : tokens.spacing.contentWidth - solutionW;

    const qPanel = make('div', 'learnova-problem-panel');
    position(qPanel, questionX, 0, questionW, height);
    const qLabel = make('div', 'learnova-problem-label', 'Problem');
    position(qLabel, 38, 38, questionW - 76, 28);
    const statement = make('div', 'learnova-problem-statement', wrapText(problem.statement, questionW - 76, 30, 7));
    position(statement, 38, 86, questionW - 76, 248);
    setTextDirection(statement, problem.statement);
    qPanel.appendChild(qLabel);
    qPanel.appendChild(statement);
    problem.choices.slice(0, 4).forEach((choice, index) => {
      const option = make('div', 'learnova-problem-choice', `${String.fromCharCode(65 + index)}. ${choice}`);
      position(option, 38, 350 + index * 62, questionW - 76, 50);
      setTextDirection(option, choice);
      qPanel.appendChild(option);
    });

    const sPanel = make('div', 'learnova-solution-panel');
    position(sPanel, solutionX, 0, solutionW, height);
    const sLabel = make('div', 'learnova-solution-label', 'Solution path');
    position(sLabel, 36, 36, solutionW - 72, 32);
    sPanel.appendChild(sLabel);
    problem.solutionSteps.slice(0, 5).forEach((step, index) => {
      const number = make('div', 'learnova-step-number', String(index + 1));
      position(number, 36, 92 + index * 82, 34, 34);
      const stepText = make('div', 'learnova-step-text', step);
      position(stepText, 84, 90 + index * 82, solutionW - 122, 60);
      setTextDirection(stepText, step);
      sPanel.appendChild(number);
      sPanel.appendChild(stepText);
    });
    if (problem.answer) {
      const answer = make('div', 'learnova-answer-box', `Answer: ${problem.answer}`);
      position(answer, 36, height - 104, solutionW - 72, 68);
      setTextDirection(answer, problem.answer);
      sPanel.appendChild(answer);
    }

    wrapper.appendChild(qPanel);
    wrapper.appendChild(sPanel);
    return wrapper;
  }

  function buildFooter(tokens) {
    const divider = make('div', 'learnova-footer-divider');
    position(divider, tokens.spacing.pagePaddingX, 1000, tokens.spacing.contentWidth, 1);

    const footer = make('footer', 'learnova-footer');
    position(
      footer,
      tokens.spacing.pagePaddingX,
      tokens.spacing.footerY,
      tokens.spacing.contentWidth,
      28,
    );
    const dot = make('span', 'learnova-footer-dot');
    position(dot, 0, 8, 8, 8);
    const copy = make(
      'span',
      'learnova-footer-copy',
      'Structured content • Generated with Learnova AI',
    );
    position(copy, 18, 3, 600, 22);
    const domain = make('span', 'learnova-footer-domain', 'learnova.ai');
    position(domain, tokens.spacing.contentWidth - 180, 3, 180, 22);
    append(footer, dot, copy, domain);
    return [divider, footer];
  }

  function buildTemplateSlide(slide, tokens) {
    const spec = layoutSpec(slide, tokens);
    const slideRtl = containsRtl(slide.title) || containsRtl(slide.kicker);
    const root = make('section', 'learnova-pptx-slide');
    root.setAttribute('dir', 'ltr');
    root.setAttribute('lang', 'en');
    root.dataset.slideNumber = String(slide.slideNumber);
    root.dataset.density = spec.grid.density;
    applyTokenVariables(root, tokens);

    const decorationPrimary = make('div', 'learnova-decoration learnova-decoration-primary');
    position(decorationPrimary, tokens.slideWidth - 268, -176, 386, 386);
    const decorationCyan = make('div', 'learnova-decoration learnova-decoration-cyan');
    position(decorationCyan, tokens.slideWidth - 200, 22, 118, 118);
    const decorationViolet = make('div', 'learnova-decoration learnova-decoration-violet');
    position(decorationViolet, tokens.slideWidth - 88, 128, 56, 56);
    const decorationBottom = make('div', 'learnova-decoration learnova-decoration-bottom');
    position(decorationBottom, -112, tokens.slideHeight - 94, 244, 244);
    append(root, decorationPrimary, decorationCyan, decorationViolet, decorationBottom);

    root.appendChild(buildHeader(slide, tokens));
    root.appendChild(buildHero(slide, spec, tokens));

    if (slide.problem) {
      root.appendChild(buildProblemLayout(slide, spec, tokens));
    } else if (slide.equation) {
      root.appendChild(buildEquationLayout(slide, spec, tokens));
    } else if (slide.visual) {
      root.appendChild(buildVisualFocusLayout(slide, spec, tokens));
    } else if (slide.cards.length === 0) {
      root.appendChild(buildEmptyState(spec, tokens));
    } else {
      slide.cards.forEach((card, index) => {
        root.appendChild(buildCard(card, index, spec, tokens, slideRtl));
      });
    }

    append(root, ...buildFooter(tokens));
    return root;
  }

  function isPresentationImagePath(value) {
    const path = asString(value).toLowerCase();
    return /^(?:https?:|data:image\/|blob:)/.test(path) ||
      path.startsWith('assets/') ||
      /\.(?:png|jpe?g|webp|gif|svg)(?:[?#].*)?$/.test(path);
  }

  function resolvePresentationAsset(value) {
    const raw = asString(value).replace(/^\/+/, '');
    if (/^(?:https?:|data:|blob:)/i.test(raw)) return raw;
    if (raw.startsWith('assets/assets/')) return resolveFromBase(raw);
    if (raw.startsWith('assets/')) return resolveFromBase(`assets/${raw}`);
    return resolveFromBase(raw);
  }

  function buildLegacySlide(slide, tokens) {
    const root = make('section', 'learnova-pptx-slide learnova-legacy-slide');
    applyTokenVariables(root, tokens);
    root.style.background = slide.background;
    root.setAttribute('dir', 'ltr');

    const scaleX = tokens.slideWidth / 13.333333;
    const scaleY = tokens.slideHeight / 7.5;
    // Canonical element font sizes and stroke/radius values are expressed in
    // PowerPoint points. The export DOM is 1920×1080 (144 CSS pixels/inch), so
    // one point must render as two CSS pixels. Using the browser's normal
    // 96-DPI conversion here made every exported font and decorative detail
    // exactly one third smaller than the Flutter preview.
    const pixelsPerPoint = ((scaleX + scaleY) / 2) / 72;
    slide.elements.forEach((rawElement, index) => {
      const element = rawElement && typeof rawElement === 'object' ? rawElement : {};
      const type = asString(element.type, 'text').toLowerCase();
      const x = asNumber(element.x, 0) * scaleX;
      const y = asNumber(element.y, 0) * scaleY;
      const width = Math.max(1, asNumber(element.w, 1) * scaleX);
      const height = Math.max(1, asNumber(element.h, 1) * scaleY);
      const node = make('div', `learnova-legacy-element learnova-legacy-${type}`);
      setStyles(node, {
        left: `${x}px`,
        top: `${y}px`,
        width: `${width}px`,
        height: `${height}px`,
        opacity: String(clamp(asNumber(element.opacity, 1), 0, 1)),
      });
      node.dataset.elementIndex = String(index);

      if (type === 'text') {
        const text = asString(element.text);
        node.textContent = text;
        node.style.color = normalizeHex(element.color, tokens.colors.ink);
        node.style.fontSize = `${Math.max(5, asNumber(element.fontSize, 14) * pixelsPerPoint)}px`;
        node.style.fontWeight = element.bold ? '700' : '400';
        node.style.fontStyle = element.italic ? 'italic' : 'normal';
        node.style.whiteSpace = 'pre-wrap';
        node.style.lineHeight = String(clamp(
          asNumber(element.lineHeight || element.line_height, element.bold ? 1.08 : 1.16),
          0.95,
          1.45,
        ));
        node.style.letterSpacing = `${asNumber(element.charSpacing, 0) * pixelsPerPoint}px`;
        node.style.fontFamily = element.fontFace
          ? `'${asString(element.fontFace)}', Arial, Tahoma, sans-serif`
          : (element.bold ? 'var(--heading-font-family)' : 'var(--body-font-family)');
        node.style.display = 'flex';
        const vertical = asString(element.verticalAlign || element.vertical_align, 'top').toLowerCase();
        node.style.alignItems = vertical === 'middle' || vertical === 'center'
          ? 'center'
          : vertical === 'bottom'
            ? 'flex-end'
            : 'flex-start';
        const rtl = setTextDirection(node, text);
        if (!rtl && ['center', 'right', 'justify'].includes(asString(element.align))) {
          node.style.textAlign = asString(element.align);
        }
        node.style.justifyContent = node.style.textAlign === 'center'
          ? 'center'
          : node.style.textAlign === 'right'
            ? 'flex-end'
            : 'flex-start';
      } else if (type === 'equation' || type === 'math' || type === 'latex') {
        node.dataset.latex = asString(element.text);
        node.dataset.equationColor = normalizeHex(element.color, tokens.colors.ink);
        node.style.display = 'flex';
        node.style.alignItems = 'center';
        node.style.justifyContent = 'center';
        node.style.overflow = 'hidden';
      } else if (type === 'oval') {
        node.style.background = normalizeHex(element.fill, 'transparent');
        node.style.borderRadius = '50%';
        if (element.line) {
          node.style.border = `${Math.max(1, asNumber(element.lineWidth, 1) * pixelsPerPoint)}px solid ${normalizeHex(element.line, '#000000')}`;
        }
      } else if (type === 'line') {
        const lineWidth = Math.max(1, asNumber(element.lineWidth, 2) * pixelsPerPoint);
        node.style.background = normalizeHex(element.line, '#000000');
        if (height > width * 2) {
          node.style.width = `${lineWidth}px`;
          node.style.height = `${height}px`;
          node.style.left = `${x + Math.max(0, (width - lineWidth) / 2)}px`;
        } else {
          node.style.height = `${lineWidth}px`;
          node.style.top = `${y + Math.max(0, (height - lineWidth) / 2)}px`;
        }
      } else if (type === 'image') {
        const path = asString(element.path);
        const radius = Math.max(0, asNumber(element.radius, 0) * pixelsPerPoint);
        if (isPresentationImagePath(path)) {
          const image = document.createElement('img');
          image.src = resolvePresentationAsset(path);
          image.alt = asString(element.alt, 'Presentation visual');
          image.decoding = 'async';
          image.crossOrigin = /^(?:https?:)/i.test(image.src) ? 'anonymous' : '';
          setStyles(image, {
            width: '100%',
            height: '100%',
            objectFit: asString(element.fit, 'contain') === 'cover' ? 'cover' : 'contain',
            display: 'block',
            borderRadius: radius > 0 ? `${radius}px` : '0',
          });
          node.style.overflow = 'hidden';
          if (radius > 0) node.style.borderRadius = `${radius}px`;
          node.appendChild(image);
        } else {
          node.classList.add('learnova-legacy-icon');
          node.textContent = iconGlyph(path);
          node.style.color = normalizeHex(element.color, tokens.colors.primaryDark);
        }
      } else {
        node.style.background = normalizeHex(element.fill, 'transparent');
        const radius = Math.max(0, asNumber(element.radius, 0) * pixelsPerPoint);
        node.style.borderRadius = `${radius}px`;
        if (element.line) {
          node.style.border = `${Math.max(1, asNumber(element.lineWidth, 1) * pixelsPerPoint)}px solid ${normalizeHex(element.line, '#000000')}`;
        }
        if (element.shadow) {
          node.style.boxShadow = '0 10px 24px rgba(16, 42, 86, 0.08)';
        }
      }
      root.appendChild(node);
    });
    return root;
  }

  function buildExportDom(deck) {
    removeStaleExportRoot();
    ensureStyles(deck.tokens);

    const root = make('div', 'learnova-pptx-export-root');
    root.id = EXPORT_ROOT_ID;
    root.setAttribute('aria-hidden', 'true');
    root.style.width = `${deck.tokens.slideWidth}px`;
    applyTokenVariables(root, deck.tokens);

    const slides = deck.slides.map((slide) => {
      const element = slide.elements.length > 0
        ? buildLegacySlide(slide, deck.tokens)
        : slide.isTemplate
          ? buildTemplateSlide(slide, deck.tokens)
          : buildLegacySlide(slide, deck.tokens);
      root.appendChild(element);
      return element;
    });

    assert(document.body, 'The browser document body is not ready.');
    document.body.appendChild(root);
    return { root, slides };
  }

  function removeStaleExportRoot() {
    const previous = document.getElementById(EXPORT_ROOT_ID);
    if (previous) previous.remove();
  }

  function ensureStyles(tokens) {
    const signature = [
      tokens.assets.interRegularWeb,
      tokens.assets.interBoldWeb,
      tokens.assets.lexendRegularWeb,
      tokens.assets.lexendBoldWeb,
    ].join('|');
    const existing = document.getElementById(STYLE_ID);
    if (existing && existing.dataset.signature === signature) return;
    if (existing) existing.remove();

    const interRegular = resolveFromBase(tokens.assets.interRegularWeb);
    const interBold = resolveFromBase(tokens.assets.interBoldWeb);
    const lexendRegular = resolveFromBase(tokens.assets.lexendRegularWeb);
    const lexendBold = resolveFromBase(tokens.assets.lexendBoldWeb);
    const style = document.createElement('style');
    style.id = STYLE_ID;
    style.dataset.signature = signature;
    style.textContent = `
      @font-face {
        font-family: 'Inter'; src: url('${interRegular}') format('truetype');
        font-style: normal; font-weight: 400; font-display: block;
      }
      @font-face {
        font-family: 'Inter'; src: url('${interBold}') format('truetype');
        font-style: normal; font-weight: 700; font-display: block;
      }
      @font-face {
        font-family: 'Lexend'; src: url('${lexendRegular}') format('truetype');
        font-style: normal; font-weight: 400; font-display: block;
      }
      @font-face {
        font-family: 'Lexend'; src: url('${lexendBold}') format('truetype');
        font-style: normal; font-weight: 700; font-display: block;
      }
      .learnova-pptx-export-root {
        position: fixed; left: -100000px; top: 0; pointer-events: none;
        z-index: -2147483647; opacity: 1;
      }
      .learnova-pptx-export-root,
      .learnova-pptx-export-root * { box-sizing: border-box; }
      .learnova-pptx-slide {
        position: relative; display: block; width: var(--slide-width); height: var(--slide-height);
        overflow: hidden; margin: 0; padding: 0; background: var(--canvas);
        color: var(--ink); font-family: var(--body-font-family); direction: ltr;
      }
      .learnova-pptx-slide * { position: absolute; margin: 0; padding: 0; }
      .learnova-decoration { border-radius: 50%; }
      .learnova-decoration-primary, .learnova-decoration-bottom { background: var(--decoration-primary); }
      .learnova-decoration-cyan { background: var(--decoration-cyan); }
      .learnova-decoration-violet { background: var(--decoration-violet); }
      .learnova-header, .learnova-hero, .learnova-footer, .learnova-empty-wrapper {
        background: transparent;
      }
      .learnova-brand-logo, .learnova-empty-logo { object-fit: contain; }
      .learnova-brand-name {
        display: flex; align-items: center; color: var(--ink);
        font-family: var(--heading-font-family); font-size: 24px; font-weight: 700;
        line-height: 1; letter-spacing: -0.5px; white-space: nowrap; overflow: hidden;
      }
      .learnova-product-badge {
        display: flex; align-items: center; justify-content: center;
        border: 1px solid rgba(19, 127, 236, 0.16); border-radius: 17px;
        background: var(--primary-soft); color: var(--primary-dark);
        font-family: var(--body-font-family); font-size: 14px; font-weight: 700;
        line-height: 1; letter-spacing: 1.4px; white-space: nowrap; overflow: hidden;
        text-align: center;
      }
      .learnova-page-number {
        display: flex; align-items: center; justify-content: center;
        border-radius: 21px; background: var(--page-badge); color: var(--white);
        box-shadow: 0 10px 24px rgba(16, 42, 86, 0.14);
        font-family: var(--body-font-family); font-size: 16px; font-weight: 700;
        line-height: 1; letter-spacing: 1.2px; white-space: nowrap; overflow: hidden;
        text-align: center; direction: ltr;
      }
      .learnova-kicker {
        border: 1px solid rgba(19, 127, 236, 0.18); border-radius: 19px;
        background: var(--primary-soft); overflow: hidden;
      }
      .learnova-kicker-dot { border-radius: 50%; background: var(--primary); }
      .learnova-kicker-text {
        display: flex; align-items: center; color: var(--primary-dark);
        font-family: var(--body-font-family); font-size: 14px; font-weight: 700;
        line-height: 1; letter-spacing: 1.4px; white-space: nowrap; overflow: hidden;
      }
      .learnova-kicker-text[dir='rtl'] { letter-spacing: 0; }
      .learnova-title {
        color: var(--ink); font-family: var(--heading-font-family); font-weight: 700;
        line-height: 1.08; letter-spacing: -1.5px; white-space: pre; overflow: hidden;
      }
      .learnova-title[dir='rtl'] { letter-spacing: 0; }
      .learnova-title-mark { border-radius: 4px; }
      .learnova-title-mark-primary { background: var(--primary); }
      .learnova-title-mark-cyan { background: var(--cyan); }
      .learnova-card {
        overflow: hidden; border: 1px solid var(--border); background: var(--white);
        box-shadow: 0 12px 26px rgba(16, 42, 86, 0.07);
      }
      .learnova-card-top-accent, .learnova-card-bottom-accent { background: var(--accent); }
      .learnova-card-icon {
        display: flex; align-items: center; justify-content: center;
        border: 1px solid var(--accent-soft);
        background: var(--accent-soft); color: var(--accent);
        font-family: var(--body-font-family); font-weight: 700; line-height: 1;
        text-align: center; white-space: nowrap; overflow: hidden; direction: ltr;
      }
      .learnova-card-number {
        display: flex; align-items: center; justify-content: center;
        background: var(--accent-soft); color: var(--accent);
        font-family: var(--body-font-family); font-weight: 700; line-height: 1;
        letter-spacing: 0.6px; white-space: nowrap; overflow: hidden;
        text-align: center; direction: ltr;
      }
      .learnova-card-heading {
        color: var(--ink); font-family: var(--heading-font-family); font-weight: 700;
        line-height: 1.16; letter-spacing: -0.35px; white-space: pre; overflow: hidden;
      }
      .learnova-card-heading[dir='rtl'] { letter-spacing: 0; }
      .learnova-card-body {
        color: var(--text-muted); font-family: var(--body-font-family); font-weight: 400;
        white-space: pre; overflow: hidden;
      }

      .learnova-dynamic-wrapper, .learnova-visual-focus, .learnova-equation-focus, .learnova-problem-layout {
        background: transparent;
      }
      .learnova-visual-frame, .learnova-equation-panel, .learnova-problem-panel, .learnova-solution-panel,
      .learnova-mini-insight, .learnova-narrative-panel {
        overflow: hidden;
      }
      .learnova-visual-frame, .learnova-equation-panel, .learnova-problem-panel, .learnova-mini-insight {
        background: var(--white); border: 1px solid var(--border); border-radius: 34px;
        box-shadow: 0 16px 34px rgba(16, 42, 86, 0.07);
      }
      .learnova-visual-image { object-fit: cover; }
      .learnova-visual-caption {
        display: flex; align-items: center; padding: 0 22px; border-radius: 20px;
        background: rgba(255,255,255,0.90); color: var(--ink-soft);
        font-family: var(--body-font-family); font-size: 20px; font-weight: 600;
        line-height: 1.25; overflow: hidden;
      }
      .learnova-narrative-panel, .learnova-solution-panel {
        background: var(--page-badge); border-radius: 34px; box-shadow: 0 16px 34px rgba(16, 42, 86, 0.10);
      }
      .learnova-narrative-icon {
        display: flex; align-items: center; justify-content: center; border-radius: 18px;
        color: var(--white); background: rgba(255,255,255,0.12); font-family: var(--body-font-family);
        font-size: 24px; font-weight: 800; line-height: 1;
      }
      .learnova-narrative-eyebrow, .learnova-equation-label, .learnova-problem-label, .learnova-solution-label {
        color: var(--cyan); font-family: var(--body-font-family); font-size: 20px; font-weight: 800;
        line-height: 1.1; letter-spacing: 0.8px; white-space: nowrap; overflow: hidden;
      }
      .learnova-equation-label, .learnova-problem-label { color: var(--primary-dark); }
      .learnova-narrative-eyebrow[dir='rtl'], .learnova-equation-label[dir='rtl'] { letter-spacing: 0; }
      .learnova-narrative-body {
        color: var(--white); font-family: var(--heading-font-family); font-size: 30px; font-weight: 700;
        line-height: 1.22; letter-spacing: -0.35px; white-space: pre; overflow: hidden;
      }
      .learnova-narrative-body[dir='rtl'] { letter-spacing: 0; }
      .learnova-mini-insight {
        background: var(--white); border-radius: 22px;
      }
      .learnova-mini-icon {
        display: flex; align-items: center; justify-content: center; border-radius: 15px;
        background: var(--accent-soft); color: var(--accent); font-family: var(--body-font-family);
        font-size: 20px; font-weight: 800; line-height: 1;
      }
      .learnova-mini-heading {
        color: var(--ink); font-family: var(--heading-font-family); font-size: 19px; font-weight: 700;
        line-height: 1.15; white-space: nowrap; overflow: hidden;
      }
      .learnova-mini-body {
        color: var(--text-muted); font-family: var(--body-font-family); font-size: 14px; font-weight: 500;
        line-height: 1.15; white-space: nowrap; overflow: hidden;
      }
      .learnova-equation-value {
        display: flex; align-items: center; justify-content: center; color: var(--ink);
        font-family: 'Cambria Math', 'Times New Roman', serif; font-size: 56px; font-weight: 500;
        line-height: 1.18; white-space: pre-wrap; overflow: hidden;
      }
      .learnova-problem-statement {
        color: var(--ink); font-family: var(--heading-font-family); font-size: 30px; font-weight: 700;
        line-height: 1.18; white-space: pre; overflow: hidden;
      }
      .learnova-problem-statement[dir='rtl'] { font-family: var(--rtl-font-family); }
      .learnova-problem-choice {
        display: flex; align-items: center; padding: 0 18px; border-radius: 18px;
        background: var(--primary-soft); color: var(--ink-soft); font-family: var(--body-font-family);
        font-size: 19px; font-weight: 600; line-height: 1.2; overflow: hidden;
      }
      .learnova-step-number {
        display: flex; align-items: center; justify-content: center; border-radius: 12px;
        background: rgba(255,255,255,0.14); color: var(--white); font-family: var(--body-font-family);
        font-size: 15px; font-weight: 800;
      }
      .learnova-step-text {
        color: var(--white); font-family: var(--body-font-family); font-size: 21px; font-weight: 600;
        line-height: 1.25; overflow: hidden;
      }
      .learnova-answer-box {
        display: flex; align-items: center; padding: 0 22px; border-radius: 22px;
        background: rgba(16,185,129,0.18); border: 1px solid rgba(16,185,129,0.30);
        color: var(--white); font-family: var(--heading-font-family); font-size: 24px; font-weight: 800;
        line-height: 1.2; overflow: hidden;
      }
      .learnova-empty-card {
        overflow: hidden; border: 1px solid var(--border); border-radius: 26px;
        background: var(--white); box-shadow: 0 12px 26px rgba(16, 42, 86, 0.06);
      }
      .learnova-empty-title {
        color: var(--ink); font-family: var(--heading-font-family); font-size: 24px;
        font-weight: 700; line-height: 1.2; text-align: center; white-space: nowrap;
        overflow: hidden;
      }
      .learnova-footer-divider { background: var(--divider); }
      .learnova-footer-dot { border-radius: 50%; background: var(--primary); }
      .learnova-footer-copy, .learnova-footer-domain {
        color: var(--footer-text); font-family: var(--body-font-family); font-size: 12px;
        font-weight: 600; line-height: 1.2; white-space: nowrap; overflow: hidden;
      }
      .learnova-footer-domain { font-weight: 700; text-align: right; }
      .learnova-legacy-slide { font-family: var(--body-font-family); }
      .learnova-legacy-element {
        position: absolute; overflow: hidden; margin: 0; padding: 0; line-height: 1.16;
      }
      .learnova-legacy-icon {
        display: flex; align-items: center; justify-content: center;
        font-family: var(--body-font-family); font-size: 42px; font-weight: 700;
      }
    `;
    (document.head || document.body).appendChild(style);
  }

  function loadLocalLibrary() {
    return new Promise((resolve, reject) => {
      const existing = document.getElementById(LIBRARY_SCRIPT_ID);
      if (existing) existing.remove();

      const script = document.createElement('script');
      script.id = LIBRARY_SCRIPT_ID;
      script.src = resolveFromBase(LIBRARY_RELATIVE_PATH);
      script.async = true;
      script.defer = true;

      const timeout = global.setTimeout(() => {
        script.remove();
        reject(new Error(`Timed out loading the local PowerPoint engine: ${LIBRARY_RELATIVE_PATH}`));
      }, 30000);

      script.onload = () => {
        global.clearTimeout(timeout);
        if (global.domToPptx && typeof global.domToPptx.exportToPptx === 'function') {
          resolve(global.domToPptx);
        } else {
          script.remove();
          reject(new Error('The local dom-to-pptx bundle loaded, but its browser API was not found.'));
        }
      };
      script.onerror = () => {
        global.clearTimeout(timeout);
        script.remove();
        reject(new Error(
          `Could not load ${LIBRARY_RELATIVE_PATH}. Deploy the complete web/presentation_export folder.`,
        ));
      };

      (document.head || document.body).appendChild(script);
    });
  }

  async function ensureLibrary() {
    if (global.domToPptx && typeof global.domToPptx.exportToPptx === 'function') {
      return global.domToPptx;
    }
    if (libraryPromise) return libraryPromise;

    libraryPromise = loadLocalLibrary();
    try {
      return await libraryPromise;
    } catch (error) {
      libraryPromise = null;
      throw error;
    }
  }

  async function waitForImages(root) {
    const images = Array.from(root.querySelectorAll('img'));
    await Promise.all(images.map((image) => new Promise((resolve, reject) => {
      if (image.complete && image.naturalWidth > 0) {
        resolve();
        return;
      }
      const timeout = global.setTimeout(() => {
        cleanup();
        reject(new Error(`Timed out loading presentation image: ${image.src}`));
      }, 15000);
      const cleanup = () => {
        global.clearTimeout(timeout);
        image.removeEventListener('load', onLoad);
        image.removeEventListener('error', onError);
      };
      const onLoad = () => {
        cleanup();
        resolve();
      };
      const onError = () => {
        cleanup();
        reject(new Error(`Could not load presentation image: ${image.src}`));
      };
      image.addEventListener('load', onLoad, { once: true });
      image.addEventListener('error', onError, { once: true });
    })));
  }

  async function waitForFonts(tokens) {
    if (!document.fonts || typeof document.fonts.load !== 'function') return;
    const checks = [
      document.fonts.load(`400 18px "${tokens.bodyFontFamily}"`, 'Learnova'),
      document.fonts.load(`700 18px "${tokens.bodyFontFamily}"`, 'Learnova'),
      document.fonts.load(`400 24px "${tokens.headingFontFamily}"`, 'Learnova'),
      document.fonts.load(`700 64px "${tokens.headingFontFamily}"`, 'Learnova'),
    ];
    const loaded = await Promise.race([
      Promise.all(checks),
      new Promise((_, reject) => global.setTimeout(
        () => reject(new Error('Timed out loading the local Inter and Lexend fonts.')),
        15000,
      )),
    ]);
    if (Array.isArray(loaded) && loaded.some((result) => !result || result.length === 0)) {
      throw new Error(
        'Inter or Lexend could not be loaded. Deploy the complete assets/fonts folder.',
      );
    }
  }

  function loadLocalMathJax() {
    return new Promise((resolve, reject) => {
      if (global.MathJax && typeof global.MathJax.tex2svg === 'function') {
        resolve(global.MathJax);
        return;
      }

      const existing = document.getElementById(MATHJAX_SCRIPT_ID);
      if (existing) existing.remove();

      global.MathJax = {
        loader: { load: ['input/tex-full', 'output/svg'] },
        startup: { typeset: false },
        svg: { fontCache: 'none' },
        options: { enableMenu: false },
      };

      const script = document.createElement('script');
      script.id = MATHJAX_SCRIPT_ID;
      script.src = resolveFromBase(MATHJAX_RELATIVE_PATH);
      script.async = true;
      script.defer = true;

      const timeout = global.setTimeout(() => {
        script.remove();
        reject(new Error(`Timed out loading the local MathJax engine: ${MATHJAX_RELATIVE_PATH}`));
      }, 30000);

      script.onload = async () => {
        global.clearTimeout(timeout);
        try {
          if (global.MathJax && global.MathJax.startup && global.MathJax.startup.promise) {
            await global.MathJax.startup.promise;
          }
          if (!global.MathJax || typeof global.MathJax.tex2svg !== 'function') {
            throw new Error('MathJax loaded, but tex2svg was not found.');
          }
          resolve(global.MathJax);
        } catch (error) {
          reject(error);
        }
      };
      script.onerror = () => {
        global.clearTimeout(timeout);
        script.remove();
        reject(new Error(
          `Could not load ${MATHJAX_RELATIVE_PATH}. Deploy the complete mathjax vendor folder.`,
        ));
      };
      (document.head || document.body).appendChild(script);
    });
  }

  async function ensureMathJax() {
    if (global.MathJax && typeof global.MathJax.tex2svg === 'function') {
      return global.MathJax;
    }
    if (mathJaxPromise) return mathJaxPromise;
    mathJaxPromise = loadLocalMathJax();
    try {
      return await mathJaxPromise;
    } catch (error) {
      mathJaxPromise = null;
      throw error;
    }
  }

  function svgToDataUri(svg) {
    const clone = svg.cloneNode(true);
    clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    clone.setAttribute('width', '100%');
    clone.setAttribute('height', '100%');
    clone.setAttribute('preserveAspectRatio', 'xMidYMid meet');
    clone.style.width = '100%';
    clone.style.height = '100%';
    clone.style.display = 'block';
    const serialized = new XMLSerializer().serializeToString(clone);
    return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(serialized)}`;
  }

  async function renderEquationNodes(root) {
    const nodes = Array.from(root.querySelectorAll('[data-latex]'));
    if (nodes.length === 0) return;
    const mathJax = await ensureMathJax();

    for (const node of nodes) {
      const latex = asString(node.dataset.latex);
      if (!latex) continue;
      let wrapper;
      try {
        wrapper = mathJax.tex2svg(latex, { display: true });
      } catch (error) {
        node.textContent = latex;
        node.style.fontFamily = 'var(--body-font-family)';
        node.style.fontWeight = '700';
        node.style.fontSize = '30px';
        node.style.color = node.dataset.equationColor || '#071129';
        node.style.textAlign = 'center';
        continue;
      }
      const svg = wrapper && wrapper.querySelector ? wrapper.querySelector('svg') : null;
      if (!svg) {
        node.textContent = latex;
        continue;
      }
      const color = node.dataset.equationColor || '#071129';
      svg.setAttribute('color', color);
      svg.style.color = color;
      svg.querySelectorAll('[fill="currentColor"]').forEach((part) => part.setAttribute('fill', color));

      svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
      svg.setAttribute('width', '100%');
      svg.setAttribute('height', '100%');
      svg.setAttribute('preserveAspectRatio', 'xMidYMid meet');
      svg.setAttribute('role', 'img');
      svg.setAttribute('aria-label', latex);
      svg.style.width = '100%';
      svg.style.height = '100%';
      svg.style.display = 'block';
      svg.style.overflow = 'visible';
      node.replaceChildren(svg);
    }
  }

  async function waitForLayout(root, slides, tokens) {
    await Promise.all([waitForImages(root), waitForFonts(tokens)]);
    if (document.fonts && document.fonts.ready) {
      await document.fonts.ready;
    }
    await new Promise((resolve) => global.requestAnimationFrame(() =>
      global.requestAnimationFrame(resolve)));

    slides.forEach((slide, index) => {
      const rect = slide.getBoundingClientRect();
      assert(rect.width > 0 && rect.height > 0,
        `Slide ${index + 1} could not be measured before export.`);
    });
  }

  function embeddedFonts(tokens) {
    return [
      {
        name: tokens.bodyFontFamily,
        weight: 400,
        style: 'normal',
        url: resolveFromBase(tokens.assets.interRegularWeb),
      },
      {
        name: tokens.bodyFontFamily,
        weight: 700,
        style: 'normal',
        url: resolveFromBase(tokens.assets.interBoldWeb),
      },
      {
        name: tokens.headingFontFamily,
        weight: 400,
        style: 'normal',
        url: resolveFromBase(tokens.assets.lexendRegularWeb),
      },
      {
        name: tokens.headingFontFamily,
        weight: 700,
        style: 'normal',
        url: resolveFromBase(tokens.assets.lexendBoldWeb),
      },
    ];
  }

  async function exportDeck(deckJson, filename) {
    if (activeExport) {
      throw new Error('A PowerPoint export is already running. Please wait for it to finish.');
    }

    activeExport = (async () => {
      const deck = normalizeDeck(deckJson);
      const engine = await ensureLibrary();
      const { root, slides } = buildExportDom(deck);
      const safeName = sanitizeFileName(filename || `${deck.title}.pptx`);

      try {
        await renderEquationNodes(root);
        await waitForLayout(root, slides, deck.tokens);
        await engine.exportToPptx(slides, {
          fileName: safeName,
          width: 13.333333,
          height: 7.5,
          autoEmbedFonts: false,
          fonts: embeddedFonts(deck.tokens),
          svgAsVector: true,
          skipNormalize: false,
          title: deck.title,
          author: 'Learnova',
          company: 'Learnova',
          subject: 'AI-generated editable presentation',
          language: containsRtl(deck.slides
            .map((slide) => `${slide.title} ${slide.kicker} ${slide.cards
              .map((card) => `${card.heading} ${card.body}`).join(' ')} ${slide.elements
              .map((element) => asString(element && element.text))
              .join(' ')}`)
            .join(' ')) ? 'ar-EG' : 'en-US',
        });

        return {
          ok: true,
          slideCount: slides.length,
          fileName: safeName,
          bridgeVersion: BRIDGE_VERSION,
          libraryVersion: LIBRARY_VERSION,
        };
      } finally {
        root.remove();
      }
    })();

    try {
      return await activeExport;
    } finally {
      activeExport = null;
      removeStaleExportRoot();
    }
  }

  global.learnovaPptx = Object.freeze({
    version: BRIDGE_VERSION,
    libraryVersion: LIBRARY_VERSION,
    exportDeck,
  });
})(window);
