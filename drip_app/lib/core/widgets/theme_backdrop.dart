import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme/drip_skin.dart';

/// The ambient world behind every shell screen. Deliberately quiet: the
/// theme's tinted ground, a whisper of the poster as texture, and one soft
/// pool of the poster's light whose position is different for every theme.
/// Content is the hero; this only sets the mood.
///
/// Switching skins cross-fades over [Motion.theme]. The texture is a 192px,
/// pre-blurred image, so drawing it costs one cheap texture and there is no
/// runtime blur.
class ThemeBackdrop extends StatelessWidget {
  const ThemeBackdrop({super.key, required this.skin, required this.child});

  final DripSkin skin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: skin.ground),
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedSwitcher(
              duration: Motion.dur(context, Motion.theme),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _Backdrop(key: ValueKey(skin), skin: skin),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({super.key, required this.skin});
  final DripSkin skin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: skin.ground),
        // The poster, barely there: texture, not picture.
        Image.asset(
          skin.backdropAsset,
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.20), // no offscreen layer
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        ),
        // One pool of light from the poster's wash, placed per theme.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: skin.aura,
              radius: 0.95,
              colors: [
                skin.wash.withValues(alpha: 0.16),
                skin.wash.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        // Settle everything toward the ground, most where the nav floats.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                skin.ground.withValues(alpha: 0.10),
                skin.ground.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
