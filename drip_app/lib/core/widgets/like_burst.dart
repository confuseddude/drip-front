import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme/app_colors.dart';

/// A heart that pops from the centre when [trigger] changes (double-tap to
/// like). Short and physical: a quick overshoot in, a soft float-and-fade out.
/// Purely visual; it ignores pointers so it never blocks the gesture.
class LikeBurst extends StatefulWidget {
  const LikeBurst({super.key, required this.trigger, this.size = 96});

  /// Increment to play the burst.
  final int trigger;
  final double size;

  @override
  State<LikeBurst> createState() => _LikeBurstState();
}

class _LikeBurstState extends State<LikeBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void didUpdateWidget(LikeBurst old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          // 0–0.28: overshoot in (0.55 → 1.12 → 1). 0.55–1: drift up + fade.
          final pop = Curves.easeOutBack.transform((t / 0.28).clamp(0, 1));
          final scale = reduced ? 1.0 : 0.55 + 0.5 * pop;
          final fade = t < 0.55 ? 1.0 : 1 - (t - 0.55) / 0.45;
          final lift = reduced
              ? 0.0
              : -28 * Curves.easeOut.transform(((t - 0.3) / 0.7).clamp(0, 1));
          return Opacity(
            opacity: fade.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, lift),
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.favorite_rounded,
                  size: widget.size,
                  color: AppColors.red,
                  shadows: const [
                    Shadow(color: Color(0x88FF2020), blurRadius: 32),
                    Shadow(color: Color(0x55000000), blurRadius: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
