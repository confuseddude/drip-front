import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One shared shimmer clock for every skeleton on a screen.
///
/// Wrap a screen's loading layout in a [ShimmerScope]; each [Skeleton] inside
/// reads the same animation, so the highlight sweeps across the whole layout
/// in one continuous pass instead of N unsynchronised pulses, and only one
/// ticker runs no matter how many boxes there are.
class ShimmerScope extends StatefulWidget {
  const ShimmerScope({super.key, required this.child});
  final Widget child;

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduced motion: hold a still, evenly lit placeholder.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
    return _ShimmerClock(animation: _c, child: widget.child);
  }
}

class _ShimmerClock extends InheritedNotifier<AnimationController> {
  const _ShimmerClock({
    required AnimationController animation,
    required super.child,
  }) : super(notifier: animation);
}

/// A placeholder block with a soft moving highlight.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = 12,
    this.circle = false,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final clock = context
        .dependOnInheritedWidgetOfExactType<_ShimmerClock>()
        ?.notifier;
    final shape = circle ? BoxShape.circle : BoxShape.rectangle;
    final br = circle ? null : BorderRadius.circular(radius);

    Widget box(double t) => DecoratedBox(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment(-1.6 + t * 3.2, -0.3),
          end: Alignment(-0.6 + t * 3.2, 0.3),
          colors: [
            AppColors.elevated.withValues(alpha: 0.55),
            AppColors.cream.withValues(alpha: 0.10),
            AppColors.elevated.withValues(alpha: 0.55),
          ],
        ),
      ),
    );

    final child = clock == null
        ? box(0.5)
        : AnimatedBuilder(
            animation: clock,
            builder: (context, _) => box(clock.value),
          );
    return SizedBox(width: width, height: height, child: child);
  }
}
