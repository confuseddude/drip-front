import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import 'onboarding_scaffold.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  static const _steps = [
    ('01', 'SCROLL', 'Browse handpicked editorial looks customized daily.'),
    (
      '02',
      'SAVE',
      'Double-tap to save looks to your permanent personal vault.',
    ),
    ('03', 'BUILD', 'Mix and match accessories, outerwear, and footwear.'),
    ('04', 'WEAR', 'Experience your virtual try-on and step into the vibe.'),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 0,
      eyebrow: 'THE CORE MECHANICS',
      title: 'WHAT IS DRIP?',
      titleSize: 32,
      contentGap: 32,
      footer: AppButton(
        label: 'UNDERSTOOD. NEXT →',
        onPressed: () => context.push('/onboarding/quiz'),
      ),
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _StepCard(
            number: _steps[i].$1,
            title: _steps[i].$2,
            body: _steps[i].$3,
          ),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.body,
  });
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.elevated),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: AppText.mono(
                14,
                color: AppColors.cyan,
                weight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bungee(16)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppText.manrope(
                    13,
                    color: AppColors.muted,
                    lineHeight: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
