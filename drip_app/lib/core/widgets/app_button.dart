import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'tap.dart';

enum AppButtonStyle {
  /// Accent-filled (primary call to action). One per screen.
  primary,

  /// Transparent with a hairline border.
  outline,

  /// Elevated dark fill (secondary actions).
  subtle,

  /// Dark surface with an accent-red border (destructive).
  danger,
}

/// The Drip button.
///
/// The button owns its voice: every label is set in DM Mono caps, tracked
/// like the spec-sheet labels around it, so a call to action reads the same on
/// every screen. Headlines keep the poster face; buttons never shout in it.
/// Size follows [height] (36 small, 44 medium, 52 large) and the corner
/// follows the active skin's roundness.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.height = 52,
    this.loading = false,
    this.padding,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final double height;
  final bool loading;

  /// Defaults to a horizontal inset that scales with [height].
  final EdgeInsetsGeometry? padding;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    // A disabled primary goes quiet (dark fill, muted label) instead of
    // turning into a muddy half-transparent slab of accent.
    final (bg, fg, border) = switch (style) {
      _ when onPressed == null => (
        AppColors.elevated.withValues(alpha: 0.6),
        AppColors.muted,
        null,
      ),
      AppButtonStyle.primary => (p.accent, p.onAccent, null),
      AppButtonStyle.outline => (
        AppColors.transparent,
        AppColors.cream,
        AppColors.cream.withValues(alpha: 0.22),
      ),
      AppButtonStyle.subtle => (AppColors.elevated, AppColors.cream, null),
      AppButtonStyle.danger => (
        AppColors.surface,
        AppColors.red,
        AppColors.red.withValues(alpha: 0.6),
      ),
    };
    final small = height < 40;
    final text = AppText.mono(
      small ? 10.5 : 12,
      color: fg,
      weight: FontWeight.w500,
      letterSpacing: small ? 1 : 1.5,
    );
    final radius = (height * 0.3 * p.roundness).clamp(8.0, height / 2);

    return Tap(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: Motion.quick,
        curve: Motion.out,
        height: height,
        width: expand ? double.infinity : null,
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: small ? 12 : (height < 48 ? 16 : 24),
            ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: border == null ? null : Border.all(color: border),
        ),
        child: AnimatedSwitcher(
          duration: Motion.quick,
          child: loading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.6, color: fg),
                )
              : Text(
                  label.toUpperCase(),
                  key: const ValueKey('label'),
                  style: text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
