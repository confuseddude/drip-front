import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// DRIP's translucent material.
///
/// Used deliberately, not everywhere: the floating navigation, contextual
/// controls that sit over imagery, and sheets. Layers, in order:
///
///  1. a soft drop shadow (outside the clip, so it isn't blurred away)
///  2. a backdrop blur of whatever is behind
///  3. a tint: the skin's poster wash over the base colour, so the glass picks
///     up the theme without ever turning into a coloured slab
///  4. a hairline border plus a bright top edge, the "light catching the rim"
///
/// [thickness] scales blur + opacity: chips are thin, the nav is medium, sheets
/// are thick. When the OS asks for high contrast the material goes near-solid
/// and drops the blur, so text on it is always readable.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 24,
    this.thickness = GlassThickness.regular,
    this.padding,
    this.shadow = true,
    this.tintOverride,
    this.borderRadius,
  });

  final Widget child;
  final double radius;
  final GlassThickness thickness;
  final EdgeInsetsGeometry? padding;
  final bool shadow;
  final Color? tintOverride;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final solid = MediaQuery.highContrastOf(context);
    final palette = context.palette;
    final wash = tintOverride ?? palette.wash;
    final t = thickness;
    // The skin's character: clear crystal (1) lets more through and catches
    // more light; frosted paper (0) is denser and calmer. Squarer or softer
    // corners follow the skin's roundness.
    final clarity = palette.clarity;
    final r = borderRadius ?? BorderRadius.circular(radius * palette.roundness);
    // Thin chips skip the live blur: a backdrop blur is a full GPU pass per
    // element, and a dozen of them over scrolling photos is what makes a
    // mid-range phone drop frames. They get a slightly denser tint instead,
    // which reads the same at chip size. Only big surfaces blur for real.
    final blurs = !solid && t != GlassThickness.thin;
    final baseAlpha =
        (t.baseAlpha + (0.5 - clarity) * 0.18 + (blurs ? 0 : 0.16)).clamp(
          0.3,
          0.9,
        );
    final sheen = t.sheen * (0.7 + 0.6 * clarity);

    // ground → wash → white sheen, stacked as one translucent colour.
    final fill = Color.alphaBlend(
      wash.withValues(alpha: t.washAlpha * 0.8),
      palette.ground.withValues(alpha: solid ? 0.96 : baseAlpha),
    );

    final Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        color: fill,
        border: Border.all(
          color: Colors.white.withValues(alpha: solid ? 0.28 : 0.11),
          width: 0.75,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: sheen),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.9],
          ),
        ),
        child: Stack(
          children: [
            Padding(padding: padding ?? EdgeInsets.zero, child: child),
            // Bright top rim.
            Positioned(
              left: 14,
              right: 14,
              top: 0,
              height: 1,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.34),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget clipped = ClipRRect(
      borderRadius: r,
      child: !blurs
          ? body
          : BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: t.blur,
                sigmaY: t.blur,
                tileMode: TileMode.mirror,
              ),
              child: body,
            ),
    );

    if (shadow) {
      clipped = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: t.shadowAlpha),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: clipped,
      );
    }
    return RepaintBoundary(child: clipped);
  }
}

enum GlassThickness {
  /// Chips and small floating controls (tinted only, no live blur).
  thin(
    blur: 10,
    baseAlpha: 0.42,
    washAlpha: 0.16,
    sheen: 0.10,
    shadowAlpha: 0.22,
  ),

  /// The bottom navigation and floating bars.
  regular(
    blur: 16,
    baseAlpha: 0.55,
    washAlpha: 0.20,
    sheen: 0.09,
    shadowAlpha: 0.34,
  ),

  /// Sheets and large overlays: heavier, so text over them is calm.
  thick(
    blur: 22,
    baseAlpha: 0.72,
    washAlpha: 0.20,
    sheen: 0.07,
    shadowAlpha: 0.42,
  );

  const GlassThickness({
    required this.blur,
    required this.baseAlpha,
    required this.washAlpha,
    required this.sheen,
    required this.shadowAlpha,
  });

  final double blur;
  final double baseAlpha;
  final double washAlpha;
  final double sheen;
  final double shadowAlpha;
}

/// A circular glass control (44px hit target, 40px visual) for actions that
/// float over imagery: close, back, more.
class GlassIconButton extends StatefulWidget {
  const GlassIconButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.size = 40,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final hit = widget.size < 44 ? 44.0 : widget.size;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: SizedBox(
            width: hit,
            height: hit,
            child: Center(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Glass(
                  radius: widget.size / 2,
                  thickness: GlassThickness.thin,
                  shadow: false,
                  child: Center(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
