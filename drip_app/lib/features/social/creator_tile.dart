import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/tap.dart';
import 'social_controller.dart';

/// Compact creator card (search results / featured creator). Resolves the
/// account from its handle; falls back to a placeholder if it isn't known.
class CreatorTile extends ConsumerWidget {
  const CreatorTile({super.key, required this.handle});
  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider(handle)).value;
    return Tap(
      onTap: () => context.push('/u/$handle'),
      semanticLabel: '@$handle',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cream.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: user == null
                    ? ColoredBox(
                        color: AppColors.elevated,
                        child: Center(
                          child: Text(
                            '✦',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      )
                    : DripImage(user.avatar),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@$handle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.manrope(13, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (user?.tagline.isNotEmpty ?? false)
                        ? user!.tagline
                        : 'EST. 2077',
                    style: AppText.mono(9, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cyan,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'VIEW',
                style: AppText.mono(
                  9,
                  color: AppColors.base,
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
