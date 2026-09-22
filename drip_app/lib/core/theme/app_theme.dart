import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';
import 'drip_skin.dart';

/// Skin-dependent colours, readable anywhere via `context.palette`.
@immutable
class DripPalette extends ThemeExtension<DripPalette> {
  const DripPalette({
    required this.accent,
    required this.secondary,
    required this.wash,
    required this.ground,
    required this.clarity,
    required this.roundness,
  });

  final Color accent;
  final Color secondary;

  /// Saturated poster mid-tone: tints glass surfaces and the ambient scrim.
  final Color wash;

  /// The theme's tinted near-black; glass is built from it.
  final Color ground;

  /// Glass feel, 0 (frosted paper) … 1 (clear crystal).
  final double clarity;

  /// Glass corner scale (below 1 squarer, above 1 softer).
  final double roundness;

  /// Text/icon colour that sits on top of [accent].
  Color get onAccent => AppColors.base;

  @override
  DripPalette copyWith({
    Color? accent,
    Color? secondary,
    Color? wash,
    Color? ground,
    double? clarity,
    double? roundness,
  }) => DripPalette(
    accent: accent ?? this.accent,
    secondary: secondary ?? this.secondary,
    wash: wash ?? this.wash,
    ground: ground ?? this.ground,
    clarity: clarity ?? this.clarity,
    roundness: roundness ?? this.roundness,
  );

  @override
  DripPalette lerp(DripPalette? other, double t) {
    if (other == null) return this;
    return DripPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      wash: Color.lerp(wash, other.wash, t)!,
      ground: Color.lerp(ground, other.ground, t)!,
      clarity: clarity + (other.clarity - clarity) * t,
      roundness: roundness + (other.roundness - roundness) * t,
    );
  }
}

extension DripThemeContext on BuildContext {
  DripPalette get palette => Theme.of(this).extension<DripPalette>()!;
}

abstract final class AppTheme {
  static ThemeData build(DripSkin skin) {
    final scheme = ColorScheme.dark(
      surface: skin.ground,
      onSurface: AppColors.cream,
      primary: skin.accent,
      onPrimary: AppColors.base,
      secondary: skin.secondary,
      onSecondary: AppColors.base,
      error: AppColors.red,
      outline: AppColors.elevated,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: skin.ground,
      canvasColor: skin.ground,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.transparent,
      fontFamily: 'Manrope',
      textTheme: TextTheme(
        bodyMedium: AppText.manrope(14),
        bodyLarge: AppText.manrope(16),
        labelLarge: AppText.manrope(13, weight: FontWeight.w700),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: skin.accent,
        selectionColor: skin.accent.withValues(alpha: 0.3),
        selectionHandleColor: skin.accent,
      ),
      dividerColor: AppColors.elevated,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.elevated),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.elevated,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: AppText.mono(11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [
        DripPalette(
          accent: skin.accent,
          secondary: skin.secondary,
          wash: skin.wash,
          ground: skin.ground,
          clarity: skin.clarity,
          roundness: skin.roundness,
        ),
      ],
    );
  }
}
