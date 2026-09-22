import 'package:flutter/painting.dart';

/// Colour tokens lifted directly from the Drip Figma file.
abstract final class AppColors {
  /// Screen background (`#0E1018`).
  static const Color base = Color(0xFF0E1018);

  /// Cards, headers, inputs (`#141824` in the default theme). Follows the
  /// active theme: see [useSurfaces].
  static Color get surface => _surface;

  /// Elevated surfaces, borders, chips (`#1C2335` in the default theme).
  /// Follows the active theme: see [useSurfaces].
  static Color get elevated => _elevated;

  static Color _surface = const Color(0xFF141824);
  static Color _elevated = const Color(0xFF1C2335);
  static int _surfaceKey = 0;

  /// Re-derives [surface] and [elevated] from a theme's tinted ground and
  /// poster wash, so cards, inputs, chips and borders belong to the theme
  /// instead of staying navy under every one. The default theme keeps the
  /// original Figma values exactly. Returns whether anything changed (the app
  /// then rebuilds so every screen picks the new colours up).
  static bool useSurfaces({
    required Color ground,
    required Color wash,
    required bool original,
  }) {
    final key = Object.hash(ground, wash, original);
    if (key == _surfaceKey) return false;
    _surfaceKey = key;
    if (original) {
      _surface = const Color(0xFF141824);
      _elevated = const Color(0xFF1C2335);
    } else {
      final tinted = Color.alphaBlend(wash.withValues(alpha: 0.07), ground);
      _surface = Color.alphaBlend(const Color(0x0AFFFFFF), tinted);
      _elevated = Color.alphaBlend(
        const Color(0x12FFFFFF),
        Color.alphaBlend(wash.withValues(alpha: 0.17), ground),
      );
    }
    return true;
  }

  /// Primary text and light fills (`#E8DFC8`).
  static const Color cream = Color(0xFFE8DFC8);

  /// Brand red (`#FF2020`).
  static const Color red = Color(0xFFFF2020);

  /// Secondary accent (`#48C8FF`).
  static const Color cyan = Color(0xFF48C8FF);

  /// Muted text (`#9A9088`).
  static const Color muted = Color(0xFF9A9088);

  /// Dimmest text (`#857B72`): tertiary metadata. Lifted from the Figma
  /// `#6A6058` (3.1:1) so it still reads at 4.6:1 on the ground.
  static const Color dim = Color(0xFF857B72);

  /// Hairline used on some dark cards (`#11151D`).
  static const Color deep = Color(0xFF11151D);

  static const Color transparent = Color(0x00000000);
}
