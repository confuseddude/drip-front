import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Loading indicator in the Drip visual language: the brand's red drop (the
/// dot of the wordmark's "i") swells and settles, with a soft ripple. One
/// element, one rhythm, so every wait reads as the same product.
class LoadingState extends StatefulWidget {
  const LoadingState({
    super.key,
    this.label = 'CALIBRATING...',
    this.compact = false,
  });
  final String label;
  final bool compact;

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final reduced = Motion.reduced(context);
    final size = widget.compact ? 10.0 : 14.0;
    final drop = SizedBox(
      width: size * 3,
      height: size * 3,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = reduced ? 0.5 : _c.value;
          // Swell fast, settle slow: ease-out on the rise.
          final swell = Curves.easeOutCubic.transform(t < 0.4 ? t / 0.4 : 1);
          final settle = t < 0.4 ? 0.0 : (t - 0.4) / 0.6;
          final scale = 0.78 + 0.22 * swell - 0.06 * settle;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t) * 0.5,
                child: Container(
                  width: size * (1 + t * 1.8),
                  height: size * (1 + t * 1.8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 1),
                  ),
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: size,
                  height: size * 0.86,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(size),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (widget.compact) return Center(child: drop);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          drop,
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: AppText.mono(9, color: AppColors.muted, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

/// Nothing-to-show placeholder with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.glyph = '✦',
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String glyph;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.elevated),
              ),
              child: Text(
                glyph,
                style: AppText.inter(22, color: context.palette.secondary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.display(14),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.manrope(
                12,
                color: AppColors.muted,
                lineHeight: 18,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
                height: 40,
                radius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Failure state with a retry action.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.onRetry,
    this.message = 'Signal lost. Check your connection and try again.',
  });
  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      glyph: '⚠',
      title: 'SIGNAL LOST',
      message: message,
      actionLabel: 'RETRY ⟳',
      onAction: onRetry,
    );
  }
}

/// Renders an [AsyncValue] with the Drip loading / error states.
extension AsyncValueUi<T> on AsyncValue<T> {
  Widget whenDrip({
    required Widget Function(T data) data,
    required VoidCallback onRetry,
    String loadingLabel = 'CALIBRATING...',
    String? errorMessage,
  }) {
    return when(
      data: data,
      loading: () => LoadingState(label: loadingLabel),
      error: (e, _) => errorMessage == null
          ? ErrorState(onRetry: onRetry)
          : ErrorState(onRetry: onRetry, message: errorMessage),
    );
  }
}
