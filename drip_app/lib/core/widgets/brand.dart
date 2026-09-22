import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The DRIP wordmark, traced from the brand artwork: flared lettering with the
/// "i" dot in brand red. Vector, so it stays sharp from a 22px header to the
/// splash. Variants: [dark] for dark surfaces (cream), [light] for light ones
/// (midnight), [mono] for a single flat colour (tint with [color]).
enum WordmarkVariant { dark, light, mono }

class DripWordmark extends StatelessWidget {
  const DripWordmark({
    super.key,
    this.height = 28,
    this.variant = WordmarkVariant.dark,
    this.color,
  });

  final double height;
  final WordmarkVariant variant;

  /// Tints the [WordmarkVariant.mono] variant.
  final Color? color;

  /// Aspect ratio of the traced artwork (width / height).
  static const aspect = 311.9 / 252.8;

  static String _asset(WordmarkVariant v) => switch (v) {
    WordmarkVariant.dark => 'assets/brand/drip_wordmark.svg',
    WordmarkVariant.light => 'assets/brand/drip_wordmark_light.svg',
    WordmarkVariant.mono => 'assets/brand/drip_wordmark_mono.svg',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Drip',
      image: true,
      child: SvgPicture.asset(
        _asset(variant),
        height: height,
        width: height * aspect,
        excludeFromSemantics: true,
        colorFilter: variant == WordmarkVariant.mono && color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
      ),
    );
  }
}
