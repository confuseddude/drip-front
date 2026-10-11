import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import 'hints.dart';

/// Just-in-time tips, laid over the shell. When the user lands on a screen
/// with a tip they haven't seen and its feature is on screen, a soft ring
/// pulses round the feature and a one-line bubble sits beside it. Nothing is
/// dimmed or blocked: any touch anywhere puts the tip away (and still does
/// what it touched), so people find their way by using the app, and the tip
/// only names what they're looking at.
///
/// Pacing: a screen shows at most one tip per visit, only after the user has
/// been on it a moment, never within a few seconds of the last one, and a
/// tip left alone fades away by itself.
class HintOverlay extends ConsumerStatefulWidget {
  const HintOverlay({super.key, required this.path});

  /// The shell's current location.
  final String path;

  @override
  ConsumerState<HintOverlay> createState() => _HintOverlayState();
}

class _HintOverlayState extends ConsumerState<HintOverlay>
    with TickerProviderStateMixin {
  /// How often it looks for a tip to show. Time below is counted in these
  /// ticks (so it runs on the app's clock, paused with it).
  static const _tick = Duration(milliseconds: 400);

  /// On a screen this many ticks (~1.6 s) before its tip shows.
  static const _settle = 4;

  /// At least this many ticks (~6 s) between two tips.
  static const _gap = 15;

  /// A tip nobody touches goes away after this.
  static const _linger = Duration(seconds: 9);

  final _root = GlobalKey();
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// Follows the feature every frame while a tip is up (scrolling, images
  /// loading in).
  late final Ticker _follow = createTicker((_) => _measure());

  Timer? _poll;
  Timer? _timeout;
  int _ticks = 0;
  int _arrived = 0;
  int? _lastShown;
  bool _shownThisVisit = false;

  /// Where the candidate feature was at the last check: it has to hold still
  /// (no page transition or scroll fling) before its tip shows.
  Rect? _candidate;
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    if (ref.read(hintsEnabledProvider)) {
      _poll = Timer.periodic(_tick, (_) {
        _ticks++;
        _check();
      });
    }
  }

  @override
  void didUpdateWidget(HintOverlay old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      // Moving on counts as having seen the tip that was up.
      if (ref.read(hintsProvider) != null) _dismiss();
      _arrived = _ticks;
      _shownThisVisit = false;
      _candidate = null;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _timeout?.cancel();
    _follow.dispose();
    _pulse.dispose();
    super.dispose();
  }

  RenderBox? get _box {
    final box = _root.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  void _check() {
    if (!mounted || ref.read(hintsProvider) != null || _shownThisVisit) return;
    if (_ticks - _arrived < _settle) return;
    final last = _lastShown;
    if (last != null && _ticks - last < _gap) return;
    // A full-screen page pushed over the shell (the quiz, the camera).
    if (!(ModalRoute.isCurrentOf(context) ?? true)) return;
    final box = _box;
    if (box == null) return;
    final controller = ref.read(hintsProvider.notifier);
    final bounds = Offset.zero & box.size;
    for (final hint in hints) {
      if (hint.route != widget.path || controller.isSeen(hint)) continue;
      final found = HintAnchor.find(hint.anchor, box, bounds);
      if (found == null || found.$2 < 0.6) continue;
      final rect = found.$1;
      final was = _candidate;
      final still =
          was != null &&
          (rect.topLeft - was.topLeft).distance < 1 &&
          (rect.bottomRight - was.bottomRight).distance < 1;
      _candidate = rect;
      if (!still) return; // look again next tick
      _show(hint, rect);
      return;
    }
    _candidate = null;
  }

  void _show(Hint hint, Rect rect) {
    _shownThisVisit = true;
    _lastShown = _ticks;
    _rect = rect;
    ref.read(hintsProvider.notifier).show(hint);
    if (!Motion.reduced(context)) _pulse.repeat();
    if (!_follow.isActive) _follow.start();
    _timeout?.cancel();
    _timeout = Timer(_linger, _dismiss);
  }

  void _dismiss() {
    _timeout?.cancel();
    if (_follow.isActive) _follow.stop();
    _pulse.stop();
    ref.read(hintsProvider.notifier).dismiss();
  }

  void _measure() {
    final hint = ref.read(hintsProvider);
    final box = _box;
    if (hint == null || box == null) return;
    final found = HintAnchor.find(hint.anchor, box, Offset.zero & box.size);
    if (found == null) {
      _dismiss(); // the feature went away (scrolled off, page closed)
      return;
    }
    final rect = found.$1;
    final now = _rect;
    if (now == null ||
        (rect.topLeft - now.topLeft).distance > 0.5 ||
        (rect.bottomRight - now.bottomRight).distance > 0.5) {
      setState(() => _rect = rect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = ref.watch(hintsProvider);
    final rect = _rect;
    return LayoutBuilder(
      key: _root,
      builder: (context, box) {
        if (hint == null || rect == null) return const SizedBox.shrink();
        final size = box.biggest;
        // A feature filling most of the screen (the Scroll's fit) gets a
        // pulsing dot in its middle rather than a ring round the screen.
        final big = rect.width * rect.height > size.width * size.height * 0.35;
        final pad = MediaQuery.paddingOf(context);
        return Stack(
          children: [
            // Sees every touch without taking it: the first one anywhere
            // outside the bubble puts the tip away.
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _dismiss(),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => CustomPaint(
                    painter: _BeaconPainter(
                      rect: rect,
                      big: big,
                      t: _pulse.value,
                      color: context.palette.accent,
                    ),
                  ),
                ),
              ),
            ),
            CustomSingleChildLayout(
              delegate: _BubbleLayout(
                target: big
                    ? Rect.fromCenter(
                        center: rect.center,
                        width: 44,
                        height: 44,
                      )
                    : rect,
                insets: EdgeInsets.fromLTRB(16, pad.top + 8, 16, 12),
              ),
              child: _Bubble(
                key: ValueKey(hint.id),
                text: hint.text,
                onTap: _dismiss,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Puts the bubble just below the feature, or above it when there's no room
/// below, centred on it and kept on screen.
class _BubbleLayout extends SingleChildLayoutDelegate {
  _BubbleLayout({required this.target, required this.insets});
  final Rect target;
  final EdgeInsets insets;

  static const _space = 12.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.min(300, constraints.maxWidth - insets.horizontal),
      );

  @override
  Offset getPositionForChild(Size size, Size child) {
    final below = target.bottom + _space;
    final fitsBelow = below + child.height <= size.height - insets.bottom;
    final y = fitsBelow ? below : target.top - _space - child.height;
    final x = (target.center.dx - child.width / 2).clamp(
      insets.left,
      math.max(insets.left, size.width - insets.right - child.width),
    );
    return Offset(
      x.toDouble(),
      y.clamp(insets.top, size.height - child.height).toDouble(),
    );
  }

  @override
  bool shouldRelayout(_BubbleLayout old) =>
      old.target != target || old.insets != insets;
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.dur(context, Motion.content),
      curve: Motion.out,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
      ),
      child: Semantics(
        liveRegion: true,
        button: true,
        label: 'Tip: $text. Tap to close.',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.55)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x59000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(text, style: AppText.manrope(13, lineHeight: 18)),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A ring that breathes round the feature, or for a big one a dot that
/// ripples in its middle.
class _BeaconPainter extends CustomPainter {
  _BeaconPainter({
    required this.rect,
    required this.big,
    required this.t,
    required this.color,
  });
  final Rect rect;
  final bool big;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(t * math.pi * 2) * 0.5 + 0.5;
    if (big) {
      final c = rect.center;
      canvas.drawCircle(c, 7, Paint()..color = color);
      canvas.drawCircle(
        c,
        10 + 22 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.7 * (1 - t)),
      );
      return;
    }
    final r = rect.inflate(4 + 3 * wave);
    final radius = Radius.circular(math.min(22, r.shortestSide / 2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.45 + 0.4 * wave),
    );
  }

  @override
  bool shouldRepaint(_BeaconPainter old) =>
      old.rect != rect || old.t != t || old.big != big || old.color != color;
}
