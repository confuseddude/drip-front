import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../data/models/user.dart';
import '../social/social_controller.dart';
import 'onboarding_scaffold.dart';

class FollowPeopleScreen extends ConsumerWidget {
  const FollowPeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggested = ref.watch(suggestedCreatorsProvider);
    final following = ref.watch(followingSetProvider).value ?? const <String>{};

    return OnboardingScaffold(
      step: 3,
      eyebrow: 'VIBE SYNCHRONIZATION',
      title: 'FOLLOW THE CORE',
      subtitle: 'Connect with creators already charting the 2077 archive.',
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'SKIP',
              style: AppButtonStyle.outline,
              onPressed: () => context.push('/onboarding/done'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'SYNC ALL →',
              onPressed: suggested.hasValue
                  ? () async {
                      await ref
                          .read(followingSetProvider.notifier)
                          .apply(
                            follow: suggested.requireValue.map((u) => u.handle),
                          );
                      if (context.mounted) context.push('/onboarding/done');
                    }
                  : null,
            ),
          ),
        ],
      ),
      children: [
        suggested.when(
          data: (users) => Column(
            children: [
              for (final u in users) ...[
                _CreatorRow(
                  user: u,
                  added: following.contains(u.handle),
                  onToggle: () =>
                      ref.read(followingSetProvider.notifier).toggle(u.handle),
                ),
                if (u != users.last) const SizedBox(height: 12),
              ],
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: LoadingState(compact: true),
          ),
          error: (e, _) => ErrorState(
            onRetry: () => ref.invalidate(suggestedCreatorsProvider),
          ),
        ),
      ],
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({
    required this.user,
    required this.added,
    required this.onToggle,
  });
  final DripUser user;
  final bool added;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.elevated),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cream),
            ),
            child: ClipOval(child: DripImage(user.avatar)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppText.display(12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(user.at, style: AppText.mono(11, color: AppColors.cyan)),
                const SizedBox(height: 2),
                Text(
                  user.tagline,
                  style: AppText.manrope(11, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Tap(
            onTap: onToggle,
            semanticLabel: added ? 'Added ${user.name}' : 'Follow ${user.name}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: added ? AppColors.cream : AppColors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: added ? AppColors.transparent : AppColors.cream,
                ),
              ),
              child: Text(
                added ? 'ADDED' : 'FOLLOW',
                style: AppText.manrope(
                  11,
                  weight: FontWeight.w700,
                  color: added ? AppColors.base : AppColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
