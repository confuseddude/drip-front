import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'tap.dart';

/// A glyph rendered as text (the design draws its icons as unicode glyphs).
class GlyphButton extends StatelessWidget {
  const GlyphButton(
    this.glyph, {
    super.key,
    required this.onTap,
    this.size = 20,
    this.color = AppColors.cream,
    this.mono = false,
    this.label,
  });

  final String glyph;
  final VoidCallback? onTap;
  final double size;
  final Color color;

  /// DM Mono glyph (Fit Analysis / Wardrobe headers) vs. Inter.
  final bool mono;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: label ?? glyph,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            glyph,
            style: mono
                ? AppText.mono(size, color: color, weight: FontWeight.w500)
                : AppText.inter(size, color: color),
          ),
        ),
      ),
    );
  }
}

/// Back arrow used by most headers.
class BackGlyph extends StatelessWidget {
  const BackGlyph({super.key, this.mono = false, this.size = 20, this.onTap});
  final bool mono;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlyphButton(
      '◀',
      mono: mono,
      size: size,
      label: 'Back',
      onTap:
          onTap ??
          () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
    );
  }
}

/// Screen header: centred Bungee title with optional leading / trailing.
///
/// [card] gives the surface header with rounded bottom corners used on the
/// Search, Wardrobe and profile screens.
class DripTopBar extends StatelessWidget {
  const DripTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.card = false,
    this.titleSize = 16,
    this.letterSpacing,
    this.cardColor = AppColors.surface,
    this.height = 48,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool card;
  final double titleSize;
  final double? letterSpacing;
  final Color cardColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bar = SizedBox(
      height: height,
      child: NavigationToolbar(
        centerMiddle: true,
        // Icons are 44px hit-targets that visually sit 16px in from the edge.
        leading: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: leading ?? const SizedBox(width: 44),
        ),
        middle: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.bungee(titleSize, letterSpacing: letterSpacing),
        ),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: trailing ?? const SizedBox(width: 44),
        ),
      ),
    );
    if (!card) return bar;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: const Border(bottom: BorderSide(color: AppColors.elevated)),
      ),
      child: bar,
    );
  }
}

/// Mono, letter-spaced caption used above sections ("YOUR STYLE DNA").
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.size = 10,
    this.letterSpacing = 1,
    this.color = AppColors.muted,
  });

  final String text;
  final double size;
  final double letterSpacing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.mono(size, color: color, letterSpacing: letterSpacing),
    );
  }
}
