import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../data/mock/mock_content.dart';
import '../session/session_controller.dart';
import '../settings/settings_controller.dart';
import 'colour_theory_screen.dart' show hexLabel;
import 'onboarding_scaffold.dart';

/// Final onboarding step: the "DRIP LIST PASS" built from the user's picks.
class YoureInScreen extends ConsumerWidget {
  const YoureInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picks = ref.watch(onboardingProvider);
    final username = ref.watch(settingsProvider.select((s) => s.username));

    final dna = [
      for (final m in MockContent.moods)
        if (picks.moodIds.contains(m.id)) m.label.toUpperCase(),
    ].join(' · ');
    final colours = [
      for (final p in MockContent.palette)
        if (picks.paletteIds.contains(p.id)) hexLabel(p.hex),
    ].join(' · ');

    return OnboardingScaffold(
      step: 5,
      eyebrow: 'CALIBRATION SECURED',
      title: 'WELCOME TO THE VIBE.',
      centerHeader: true,
      contentGap: 32,
      footer: AppButton(
        label: 'ENTER DRIP ✦',
        onPressed: () async {
          await ref.read(sessionProvider.notifier).completeOnboarding();
          if (context.mounted) context.go('/home');
        },
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.red),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DRIP LIST PASS', style: AppText.fredoka(18)),
                  Text(
                    'ESTD 2077',
                    style: AppText.mono(9, color: AppColors.red),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _Row(
                'USER ID:',
                '@$username',
                valueStyle: AppText.mono(13, weight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _Row(
                'STYLE DNA:',
                dna.isEmpty ? '—' : dna,
                valueStyle: AppText.mono(11, color: AppColors.cyan),
              ),
              const SizedBox(height: 12),
              _Row(
                'COLOUR BASE:',
                colours.isEmpty ? '—' : colours,
                valueStyle: AppText.mono(11),
              ),
              const SizedBox(height: 12),
              _Row(
                'ACCESS NO:',
                '#77-DRIP-9082',
                valueStyle: AppText.mono(
                  13,
                  color: AppColors.red,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const _Barcode(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {required this.valueStyle});
  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.manrope(13, color: AppColors.muted)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value, textAlign: TextAlign.right, style: valueStyle),
        ),
      ],
    );
  }
}

class _Barcode extends StatelessWidget {
  const _Barcode();

  // Bar pattern taken from the Figma card (1 = cream, 0 = elevated).
  static const _bars = [
    1,
    0,
    0,
    1,
    0,
    0,
    1,
    1,
    0,
    1,
    0,
    0,
    1,
    0,
    1,
    1,
    0,
    0,
    1,
    0,
    0,
    1,
    0,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _bars.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _bars[i] == 1
                      ? AppColors.cream.withValues(alpha: 0.8)
                      : AppColors.elevated.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
