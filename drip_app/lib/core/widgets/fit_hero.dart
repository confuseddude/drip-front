import 'package:flutter/material.dart';

import '../motion.dart';
import '../tab_direction.dart';

/// Hero tag shared by a fit's image on Home and in the Fashion Scroll.
String fitHeroTag(String ootdId) => 'fit-$ootdId';

/// Wraps a fit's image so tapping a card on Home makes the *same picture*
/// expand into the immersive Scroll (and shrink back on pop), rather than a
/// cross-fade between two unrelated screens. The corner radius is animated
/// through the flight, so the card's rounded corners open out to full-bleed.
class FitHero extends StatelessWidget {
  const FitHero({
    super.key,
    required this.ootdId,
    required this.radius,
    required this.child,
  });

  final String ootdId;

  /// Corner radius when the image is a card (0 when full-bleed).
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A tab change is a slide, not an image flight: without a matching Hero
    // on both screens Flutter simply doesn't fly one.
    if (Motion.reduced(context) || TabDirection.value != 0) return child;
    return Hero(
      tag: fitHeroTag(ootdId),
      transitionOnUserGestures: true,
      flightShuttleBuilder: (context, animation, direction, from, to) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            // The route animation runs 0→1 on push and 1→0 on pop, and the
            // card side is rounded while the scroll side is square, so one
            // formula serves both directions.
            final t = Curves.easeOut.transform(animation.value);
            final r = radius * (1 - t);
            return ClipRRect(
              borderRadius: BorderRadius.circular(r),
              child: child,
            );
          },
        );
      },
      child: child,
    );
  }
}
