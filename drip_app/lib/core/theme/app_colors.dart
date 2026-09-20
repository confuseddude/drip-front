import 'package:flutter/painting.dart';

/// Colour tokens lifted directly from the Drip Figma file.
abstract final class AppColors {
  /// Screen background (`#0E1018`).
  static const Color base = Color(0xFF0E1018);

  /// Cards, headers, inputs (`#141824`).
  static const Color surface = Color(0xFF141824);

  /// Elevated surfaces, borders, chips (`#1C2335`).
  static const Color elevated = Color(0xFF1C2335);

  /// Primary text and light fills (`#E8DFC8`).
  static const Color cream = Color(0xFFE8DFC8);

  /// Brand red (`#FF2020`).
  static const Color red = Color(0xFFFF2020);

  /// Secondary accent (`#48C8FF`).
  static const Color cyan = Color(0xFF48C8FF);

  /// Muted text (`#9A9088`).
  static const Color muted = Color(0xFF9A9088);

  /// Dimmest text (`#6A6058`).
  static const Color dim = Color(0xFF6A6058);

  /// Hairline used on some dark cards (`#11151D`).
  static const Color deep = Color(0xFF11151D);

  static const Color transparent = Color(0x00000000);
}
