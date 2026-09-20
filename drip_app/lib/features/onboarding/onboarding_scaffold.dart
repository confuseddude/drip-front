import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/controls.dart';

/// Shared layout for the onboarding steps: scrolling header + content, then a
/// pinned footer with the step dots and the primary action(s).
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.eyebrow,
    required this.title,
    required this.footer,
    required this.children,
    this.subtitle,
    this.titleSize = 28,
    this.centerHeader = false,
    this.contentGap = 24,
  });

  final int step;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final double titleSize;
  final bool centerHeader;
  final double contentGap;
  final Widget footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 8.0);
    final align = centerHeader
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: align,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      textAlign: centerHeader
                          ? TextAlign.center
                          : TextAlign.start,
                      style: AppText.mono(
                        11,
                        color: centerHeader ? AppColors.cyan : AppColors.red,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: centerHeader
                          ? TextAlign.center
                          : TextAlign.start,
                      style: AppText.bungee(
                        titleSize,
                        lineHeight: titleSize * 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: AppText.manrope(
                          14,
                          color: AppColors.muted,
                          lineHeight: 19,
                        ),
                      ),
                    ],
                    SizedBox(height: contentGap),
                    ...children,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StepDots(current: step),
                  const SizedBox(height: 4),
                  footer,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
