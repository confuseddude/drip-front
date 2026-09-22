import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Fashion Scroll icon: an elliptical ring (two tapering crescents) with a
/// four-point star between them. Drawn as vector geometry so it stays crisp at
/// any size and can be tinted like every other nav glyph.
///
/// Proportions were fitted numerically against the supplied reference
/// (`reel-navbar-reference/…2785856567.webp`, IoU 0.93):
///
///   outer ellipse  rx 113.7  ry 30.3
///   inner cut-out  rx 81.3   ry 31.5   → crescents that taper to points, with a gap at the star
///   star           reach ~52, curve exponent ~4.3 (concave sides)
///
/// A constant ~0.9px optical outline keeps the thin tips alive at nav size.
///
/// [glow] (0…1) is the selected amount: the star swells and the ring opens
/// slightly, so the selected state reads as "lit" rather than just recoloured.
class ReelGlyph extends StatelessWidget {
  const ReelGlyph({
    super.key,
    required this.color,
    this.size = 26,
    this.glow = 0,
  });

  final Color color;

  /// Width of the glyph (its height follows the ring's aspect).
  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.62),
      painter: _ReelPainter(color, glow),
    );
  }
}

class _ReelPainter extends CustomPainter {
  _ReelPainter(this.color, this.glow);

  final Color color;
  final double glow;

  // Normalised so the outer ring's rx is 1.
  static const _orx = 1.0;
  static const _ory = 30.3 / 113.7;
  static const _irx = 81.3 / 113.7;
  static const _iry = 31.5 / 113.7;
  static const _starReach = 52 / 113.7;
  static const _starN = 4.3;

  static final Path _star = _buildStar();

  static Path _buildStar() {
    final p = Path();
    const steps = 160;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final c = math.cos(t);
      final s = math.sin(t);
      final x = _starReach * c.sign * math.pow(c.abs(), _starN);
      final y = _starReach * s.sign * math.pow(s.abs(), _starN);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 2; // ring rx = 1 → half the width
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(unit);

    final open = 1 + glow * 0.05;
    final ring = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromLTRB(-_orx, -_ory, _orx, _ory)),
      Path()..addOval(Rect.fromLTRB(-_irx * open, -_iry, _irx * open, _iry)),
    );

    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    // Optical weight: a constant ~0.9px outline, so the thin crescent tips and
    // star points don't vanish at nav size. Negligible on large renders.
    final edge = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 0.9 / unit;
    canvas.drawPath(ring, paint);
    canvas.drawPath(ring, edge);

    final k = 0.92 + glow * 0.14;
    canvas.save();
    canvas.scale(k);
    canvas.drawPath(_star, paint);
    canvas.drawPath(_star, edge..strokeWidth = 0.9 / unit / k);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ReelPainter old) =>
      old.color != color || old.glow != glow;
}

/// A house outline in the same stroke weight as the Figma-exported nav icons.
class HomeGlyph extends StatelessWidget {
  const HomeGlyph({
    super.key,
    required this.color,
    this.size = 22,
    this.glow = 0,
  });

  final Color color;
  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _HomePainter(color, glow),
    );
  }
}

class _HomePainter extends CustomPainter {
  _HomePainter(this.color, this.glow);
  final Color color;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final body = Path()
      ..moveTo(4.4, 10.4)
      ..lineTo(12, 3.7)
      ..lineTo(19.6, 10.4)
      ..lineTo(19.6, 18.6)
      ..quadraticBezierTo(19.6, 20.2, 18, 20.2)
      ..lineTo(6, 20.2)
      ..quadraticBezierTo(4.4, 20.2, 4.4, 18.6)
      ..close();
    if (glow > 0) {
      canvas.drawPath(
        body,
        Paint()..color = color.withValues(alpha: 0.16 * glow),
      );
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(body, stroke);
    final door = Path()
      ..moveTo(9.7, 20.2)
      ..lineTo(9.7, 14.6)
      ..quadraticBezierTo(9.7, 13.8, 10.5, 13.8)
      ..lineTo(13.5, 13.8)
      ..quadraticBezierTo(14.3, 13.8, 14.3, 14.6)
      ..lineTo(14.3, 20.2);
    canvas.drawPath(door, stroke);
  }

  @override
  bool shouldRepaint(_HomePainter old) =>
      old.color != color || old.glow != glow;
}
