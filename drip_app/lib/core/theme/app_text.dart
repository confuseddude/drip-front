import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Typography helpers matching the Figma type ramp.
///
/// Figma "100%" line-height is the font's natural line-height, so [height] is
/// left null by default. A pixel line-height from the design is passed as
/// [lineHeight] and converted to a Flutter height multiplier.
abstract final class AppText {
  static const _even = TextLeadingDistribution.even;

  /// The Figma file draws icons as unicode glyphs (✦ ◀ ⌕ ✕ ♥ …) that the brand
  /// fonts lack, so bundled symbol fonts back every style up.
  static const fallback = [
    'Noto Sans Symbols',
    'Noto Sans Symbols 2',
    'Noto Emoji',
  ];

  static TextStyle _base(
    String family,
    double size,
    Color color,
    FontWeight weight,
    double? letterSpacing,
    double? lineHeight,
    List<FontVariation>? variations,
  ) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: lineHeight == null ? null : lineHeight / size,
      leadingDistribution: _even,
      fontVariations: variations,
    );
  }

  /// DM Mono — labels, meta, numbers.
  static TextStyle mono(
    double size, {
    Color color = AppColors.cream,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    double? lineHeight,
  }) => _base('DM Mono', size, color, weight, letterSpacing, lineHeight, null);

  /// Bungee — headlines.
  static TextStyle bungee(
    double size, {
    Color color = AppColors.cream,
    double? letterSpacing,
    double? lineHeight,
  }) => _base(
    'Bungee',
    size,
    color,
    FontWeight.w400,
    letterSpacing,
    lineHeight,
    null,
  );

  /// Manrope — body copy and buttons.
  static TextStyle manrope(
    double size, {
    Color color = AppColors.cream,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    double? lineHeight,
  }) => _base('Manrope', size, color, weight, letterSpacing, lineHeight, [
    FontVariation('wght', weight.value.toDouble()),
  ]);

  /// Inter — glyph icons and a few UI strings.
  static TextStyle inter(
    double size, {
    Color color = AppColors.cream,
    FontWeight weight = FontWeight.w400,
    double? letterSpacing,
    double? lineHeight,
  }) => _base('Inter', size, color, weight, letterSpacing, lineHeight, [
    FontVariation('wght', weight.value.toDouble()),
  ]);

  /// Fredoka — the "drip" wordmark.
  static TextStyle fredoka(
    double size, {
    Color color = AppColors.cream,
    double? letterSpacing,
    double? lineHeight,
  }) => _base(
    'Fredoka',
    size,
    color,
    FontWeight.w400,
    letterSpacing,
    lineHeight,
    [FontVariation('wght', 400)],
  );
}
