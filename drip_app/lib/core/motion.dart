import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// DRIP's motion language. One vocabulary, used everywhere:
///
///  * **press**     90–140ms  — feedback that a touch landed (scale 0.96–0.97)
///  * **quick**     160ms     — state flips: like, save, chips, toggles
///  * **nav**       ≤ 240ms   — tab / route changes. Fast and decisive.
///  * **content**   320ms     — content settling in: expressive but never slow
///  * **theme**     520ms     — a whole world changing: deliberately noticeable
///
/// Enter uses ease-out (immediate response), never ease-in. Anything a finger
/// can grab (nav lens, sheets, pager) is a spring, so it can be interrupted and
/// inherits the release velocity.
abstract final class Motion {
  static const press = Duration(milliseconds: 100);
  static const quick = Duration(milliseconds: 160);
  static const nav = Duration(milliseconds: 240);

  /// Sideways page push between tabs (position only, so it stays cheap).
  static const page = Duration(milliseconds: 300);
  static const content = Duration(milliseconds: 320);
  static const theme = Duration(milliseconds: 520);

  /// Strong ease-out: starts fast, lands soft. The default for UI.
  static const Curve out = Cubic(0.23, 1, 0.32, 1);

  /// On-screen movement (something already visible travelling).
  static const Curve inOut = Cubic(0.77, 0, 0.175, 1);

  /// iOS drawer curve: sheets and panels.
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  /// Critically damped spring: no overshoot. Default for anything touchable.
  static const SpringDescription snap = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 45.6, // 2 * sqrt(stiffness) → damping ratio 1.0
  );

  /// Slightly under-damped: only for gestures that carried momentum (a flick).
  static const SpringDescription flick = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 30, // ratio ≈ 0.73
  );

  /// Whether the OS asked for less motion. Movement becomes a short fade.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d] unless reduced motion is on, in which case it's near-instant.
  static Duration dur(BuildContext context, Duration d) =>
      reduced(context) ? const Duration(milliseconds: 1) : d;
}

/// Haptics, used sparingly and always for a *causal* moment: a selection
/// changing, a commit, a snap. Never on scroll, never on plain taps.
abstract final class Haptics {
  /// A discrete selection moved (tab crossed while scrubbing, chip picked).
  static void tick() => HapticFeedback.selectionClick();

  /// A commit: like, save, follow, theme applied.
  static void commit() => HapticFeedback.lightImpact();

  /// A stronger commit: double-tap like burst.
  static void thump() => HapticFeedback.mediumImpact();
}
