import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'tap.dart';

enum AppButtonStyle {
  /// Accent-filled (primary call to action).
  primary,

  /// Transparent with a hairline border.
  outline,

  /// Elevated dark fill (secondary actions).
  subtle,

  /// Dark surface with an accent-red border (destructive).
  danger,
}

/// The Drip button. Defaults reproduce the onboarding CTA (48px, Manrope Bold
/// 13, tracking .8); pass [textStyle] / [radius] for the Bungee and DM Mono
/// variants used deeper in the app.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.height = 48,
    this.radius = 16,
    this.textStyle,
    this.loading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.expand = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final double height;
  final double radius;
  final TextStyle? textStyle;
  final bool loading;
  final EdgeInsetsGeometry padding;
  final bool expand;

  /// Overrides the fill of a [AppButtonStyle.primary] button (defaults to the skin accent).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final (bg, fg, border) = switch (style) {
      AppButtonStyle.primary => (color ?? accent, AppColors.base, null),
      AppButtonStyle.outline => (
        AppColors.transparent,
        AppColors.cream,
        AppColors.elevated,
      ),
      AppButtonStyle.subtle => (AppColors.elevated, AppColors.cream, null),
      AppButtonStyle.danger => (
        AppColors.surface,
        AppColors.red,
        AppColors.red,
      ),
    };
    final enabled = onPressed != null && !loading;
    // The button owns the label colour; callers only choose the type ramp.
    final text =
        (textStyle ??
                AppText.manrope(
                  13,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                  lineHeight: 20,
                ))
            .copyWith(color: fg);

    return Tap(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.45 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: border == null ? null : Border.all(color: border),
          ),
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Text(label, style: text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
