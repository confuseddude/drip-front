import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/tap.dart';
import '../../data/mock/mock_content.dart';
import '../../data/models/stylist.dart';
import '../session/session_controller.dart';
import 'onboarding_scaffold.dart';

class StyleQuizScreen extends ConsumerWidget {
  const StyleQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).moodIds;
    return OnboardingScaffold(
      step: 1,
      eyebrow: 'ESTABLISH YOUR ERA',
      title: 'STYLE QUIZ',
      subtitle: 'Choose your dominant aesthetics to prime the feed.',
      contentGap: 20,
      footer: AppButton(
        label: 'CONFIRM ERA →',
        onPressed: () async {
          if (selected.isEmpty) {
            showDripToast(context, 'Pick at least one era');
            return;
          }
          await ref.read(onboardingProvider.notifier).saveMoods();
          if (context.mounted) context.push('/onboarding/colour');
        },
      ),
      children: [
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final mood in MockContent.moods)
              _MoodTile(
                mood: mood,
                selected: selected.contains(mood.id),
                onTap: () =>
                    ref.read(onboardingProvider.notifier).toggleMood(mood.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.mood,
    required this.selected,
    required this.onTap,
  });
  final MoodTile mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: '${mood.label}${selected ? ', selected' : ''}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.cyan : AppColors.elevated,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DripImage(mood.image),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                color: AppColors.base.withValues(alpha: selected ? 0.4 : 0.6),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: selected
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cyan,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '✓ ACTIVE',
                                style: AppText.mono(
                                  9,
                                  color: AppColors.base,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            )
                          : Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cream.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                    ),
                    const Spacer(),
                    Text(mood.label, style: AppText.display(14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
