import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/top_bar.dart';
import '../../routing/main_shell.dart';
import '../outfits/outfit_card.dart';
import '../outfits/outfit_controller.dart';
import 'wardrobe_controller.dart';

/// Saved looks: complete outfits the user bookmarked or generated.
class SavedOutfitsScreen extends ConsumerWidget {
  const SavedOutfitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedOutfitsProvider);
    final closet = ref.watch(wardrobeProvider).value?.length;

    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'SAVED LOOKS',
            leading: const BackGlyph(),
            trailing: GlyphButton(
              '📁',
              label: 'Closet',
              onTap: () => context.go('/wardrobe'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilterPill(
                    label: 'MY CLOSET${closet == null ? '' : ' ($closet)'}',
                    selected: false,
                    onTap: () => context.go('/wardrobe'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterPill(
                    label:
                        'SAVED STYLES${saved.value == null ? '' : ' (${saved.value!.length})'}',
                    selected: true,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: saved.whenDrip(
              onRetry: () => ref.invalidate(savedOutfitsProvider),
              data: (looks) => ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Complete aesthetics you have bookmarked, generated, or want to purchase. Distinct from individual garments.',
                      style: AppText.manrope(
                        12,
                        color: AppColors.muted,
                        lineHeight: 16,
                      ),
                    ),
                  ),
                  if (looks.isEmpty)
                    const EmptyState(
                      title: 'NO SAVED LOOKS',
                      message: 'Tap ✦ on a fit analysis to bookmark it here.',
                    )
                  else
                    OutfitMasonry(
                      outfits: looks,
                      style: OutfitCardStyle.saved,
                      gap: 12,
                      tall: 220,
                      short: 180,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
