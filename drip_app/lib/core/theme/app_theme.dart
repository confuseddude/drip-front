import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';
import 'drip_skin.dart';

/// Skin-dependent colours, readable anywhere via `context.palette`.
@immutable
class DripPalette extends ThemeExtension<DripPalette> {
  const DripPalette({required this.accent, required this.secondary});

  final Color accent;
  final Color secondary;

  /// Text/icon colour that sits on top of [accent].
  Color get onAccent => AppColors.base;

  @override
  DripPalette copyWith({Color? accent, Color? secondary}) => DripPalette(
    accent: accent ?? this.accent,
    secondary: secondary ?? this.secondary,
  );

  @override
  DripPalette lerp(DripPalette? other, double t) {
    if (other == null) return this;
    return DripPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
    );
  }
}

extension DripThemeContext on BuildContext {
  DripPalette get palette => Theme.of(this).extension<DripPalette>()!;
}

abstract final class AppTheme {
  static ThemeData build(DripSkin skin) {
    final scheme = ColorScheme.dark(
      surface: AppColors.base,
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
      scaffoldBackgroundColor: AppColors.base,
      canvasColor: AppColors.base,
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
          side: const BorderSide(color: AppColors.elevated),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
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
      extensions: [DripPalette(accent: skin.accent, secondary: skin.secondary)],
    );
  }
}
