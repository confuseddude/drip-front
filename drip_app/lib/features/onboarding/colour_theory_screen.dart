import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/tap.dart';
import '../../data/mock/mock_content.dart';
import '../../data/models/stylist.dart';
import '../session/session_controller.dart';
import 'onboarding_scaffold.dart';

String hexLabel(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class ColourTheoryScreen extends ConsumerWidget {
  const ColourTheoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).paletteIds;
    return OnboardingScaffold(
      step: 2,
      eyebrow: 'VISUAL PERSONALIZATION',
      title: 'COLOUR THEORY',
      subtitle:
          "Map out your preferred palettes. Let's calibrate your spectral DNA.",
      contentGap: 28,
      footer: AppButton(
        label: 'CALIBRATE SPECTRUM →',
        onPressed: () async {
          if (selected.isEmpty) {
            showDripToast(context, 'Wear at least one colour');
            return;
          }
          await ref.read(onboardingProvider.notifier).savePalette();
          if (context.mounted) context.push('/onboarding/follow');
        },
      ),
      children: [
        for (final swatch in MockContent.palette) ...[
          _ColourStrip(
            swatch: swatch,
            selected: selected.contains(swatch.id),
            onTap: () =>
                ref.read(onboardingProvider.notifier).togglePalette(swatch.id),
          ),
          if (swatch != MockContent.palette.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ColourStrip extends StatelessWidget {
  const _ColourStrip({
    required this.swatch,
    required this.selected,
    required this.onTap,
  });
  final PaletteSwatch swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: '${swatch.name}${selected ? ', wearing' : ''}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.cyan : AppColors.elevated,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(swatch.hex).withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cream),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    swatch.name,
                    style: AppText.manrope(14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${swatch.role} · ${hexLabel(swatch.hex)}',
                    style: AppText.mono(11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'WEAR',
                  style: AppText.mono(
                    9,
                    color: AppColors.cyan,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
