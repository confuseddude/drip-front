import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The little line drawings on the import tips: what a good photo for Drip
/// looks like.
enum TipArt { solo, mirror, light, loved, group }

class TipDrawing extends StatelessWidget {
  const TipDrawing(
    this.art, {
    super.key,
    required this.ink,
    required this.accent,
    this.height = 84,
  });

  final TipArt art;
  final Color ink;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _TipPainter(art, ink, accent)),
  );
}

class _TipPainter extends CustomPainter {
  _TipPainter(this.art, this.ink, this.accent);
  final TipArt art;
  final Color ink;
  final Color accent;

  late final _line = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  late final _fill = Paint()..color = accent.withValues(alpha: 0.28);

  late final _accentLine = Paint()
    ..color = accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;

  /// A standing figure, feet at [base], [h] tall: head, a filled top and
  /// two legs. [phone] puts a phone in front of the face (a mirror selfie).
  void _figure(
    Canvas c,
    double cx,
    double base,
    double h, {
    bool phone = false,
  }) {
    final r = h * 0.1;
    final headY = base - h + r;
    c.drawCircle(Offset(cx, headY), r, _line);
    final shoulder = headY + r + h * 0.05;
    final waist = base - h * 0.44;
    final top = Path()
      ..moveTo(cx - h * 0.17, shoulder)
      ..lineTo(cx + h * 0.17, shoulder)
      ..lineTo(cx + h * 0.13, waist)
      ..lineTo(cx - h * 0.13, waist)
      ..close();
    c.drawPath(top, _fill);
    c.drawPath(top, _line);
    c.drawLine(
      Offset(cx - h * 0.07, waist),
      Offset(cx - h * 0.09, base),
      _line,
    );
    c.drawLine(
      Offset(cx + h * 0.07, waist),
      Offset(cx + h * 0.09, base),
      _line,
    );
    if (phone) {
      final p = Rect.fromCenter(
        center: Offset(cx + r * 0.6, headY + r * 0.1),
        width: r * 1.1,
        height: r * 1.8,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(p, Radius.circular(r * 0.25)),
        Paint()..color = ink,
      );
      // The arm holding it.
      c.drawLine(
        Offset(cx + h * 0.16, shoulder + h * 0.03),
        Offset(p.center.dx + r * 0.2, p.bottom),
        _line,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final base = size.height - 6;
    final h = size.height - 14;
    switch (art) {
      case TipArt.solo:
        _figure(canvas, cx, base, h);
        // A soft frame: the photo.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, size.height / 2),
              width: h * 0.95,
              height: size.height - 2,
            ),
            const Radius.circular(10),
          ),
          _accentLine,
        );
      case TipArt.mirror:
        final mirror = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, size.height / 2),
            width: h * 0.75,
            height: size.height - 2,
          ),
          Radius.circular(h * 0.37),
        );
        canvas.drawRRect(mirror, _accentLine);
        _figure(canvas, cx, base, h * 0.92, phone: true);
      case TipArt.light:
        _figure(canvas, cx - h * 0.12, base, h);
        final sun = Offset(cx + h * 0.42, size.height * 0.24);
        canvas.drawCircle(sun, h * 0.09, Paint()..color = accent);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(sun + d * h * 0.14, sun + d * h * 0.2, _accentLine);
        }
      case TipArt.loved:
        _figure(canvas, cx, base, h);
        _sparkle(canvas, Offset(cx + h * 0.36, size.height * 0.22), h * 0.11);
        _sparkle(canvas, Offset(cx - h * 0.38, size.height * 0.5), h * 0.07);
      case TipArt.group:
        _figure(canvas, cx - h * 0.34, base, h * 0.86);
        _figure(canvas, cx, base, h);
        _figure(canvas, cx + h * 0.34, base, h * 0.86);
        canvas.drawLine(
          Offset(cx - h * 0.6, size.height * 0.15),
          Offset(cx + h * 0.6, size.height * 0.88),
          Paint()
            ..color = accent
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  void _sparkle(Canvas c, Offset at, double r) {
    final p = Path()
      ..moveTo(at.dx, at.dy - r)
      ..quadraticBezierTo(at.dx, at.dy, at.dx + r, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + r)
      ..quadraticBezierTo(at.dx, at.dy, at.dx - r, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - r)
      ..close();
    c.drawPath(p, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_TipPainter old) =>
      old.art != art || old.ink != ink || old.accent != accent;
}
