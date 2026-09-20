import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Pulsing "calibrating" indicator in the Drip visual language.
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
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = ((_c.value - i * 0.18) % 1.0);
              final k = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Color.lerp(AppColors.elevated, accent, k),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
      ],
    );
    if (widget.compact) return Center(child: dots);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          dots,
          const SizedBox(height: 14),
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
            Text(title, textAlign: TextAlign.center, style: AppText.bungee(14)),
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
