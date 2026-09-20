import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Resolves an image reference to an [ImageProvider]:
/// bundled asset (`assets/...`), remote / blob URL, or a local file path
/// (photos picked from the camera or gallery).
ImageProvider dripImageProvider(String source) {
  if (source.startsWith('assets/')) return AssetImage(source);
  if (kIsWeb ||
      source.startsWith('http') ||
      source.startsWith('blob:') ||
      source.startsWith('data:')) {
    return NetworkImage(source);
  }
  return FileImage(File(source));
}

/// Cover-fit image with a dark placeholder while decoding / on failure.
class DripImage extends StatelessWidget {
  const DripImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.semanticLabel,
  });

  final String source;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: dripImageProvider(source),
      fit: fit,
      alignment: alignment,
      semanticLabel: semanticLabel,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) {
        if (sync) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stack) => const ColoredBox(
        color: AppColors.elevated,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.muted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Circular avatar with an optional ring, matching the story / profile avatars.
class DripAvatar extends StatelessWidget {
  const DripAvatar(
    this.source, {
    super.key,
    required this.size,
    this.ringColor,
    this.ringWidth = 2,
    this.radius,
    this.shadowColor,
  });

  final String source;
  final double size;
  final Color? ringColor;
  final double ringWidth;

  /// Corner radius; defaults to a full circle.
  final double? radius;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size / 2;
    final ring = ringColor != null;
    return Container(
      width: size,
      height: size,
      padding: ring ? EdgeInsets.all(ringWidth) : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ring ? r : r),
        border: ring ? Border.all(color: ringColor!, width: ringWidth) : null,
        boxShadow: shadowColor == null
            ? null
            : [
                BoxShadow(
                  color: shadowColor!,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ring ? (r - ringWidth).clamp(0, r) : r,
        ),
        child: DripImage(source),
      ),
    );
  }
}
