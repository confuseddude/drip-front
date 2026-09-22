import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../data/mock/mock_content.dart';
import '../../data/models/outfit.dart';
import '../../routing/main_shell.dart';
import '../outfits/outfit_card.dart';
import '../outfits/outfit_controller.dart';

final discoverCategoryProvider = NotifierProvider<_CategoryNotifier, String>(
  _CategoryNotifier.new,
);

class _CategoryNotifier extends Notifier<String> {
  @override
  String build() => MockContent.discoverCategories.first;
  void set(String c) => state = c;
}

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(discoverCategoryProvider);
    final catalog = ref.watch(outfitCatalogProvider);

    return ShellPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DISCOVER', style: AppText.display(22)),
                    Tap(
                      onTap: () => context.push('/settings'),
                      semanticLabel: 'Settings',
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('⚙', style: AppText.inter(18)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Tap(
                  onTap: () => context.push('/search'),
                  semanticLabel: 'Search fits, vibes, eras',
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.elevated),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '⌕',
                          style: AppText.inter(14, color: AppColors.muted),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Search fits, vibes, eras...',
                          style: AppText.manrope(13, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              itemCount: MockContent.discoverCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = MockContent.discoverCategories[i];
                return FilterPill(
                  label: c,
                  selected: c == category,
                  onTap: () =>
                      ref.read(discoverCategoryProvider.notifier).set(c),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: catalog.whenDrip(
              onRetry: () => ref.invalidate(outfitCatalogProvider),
              data: (all) {
                final list = all
                    .where((o) => o.categories.contains(category))
                    .toList();
                if (list.isEmpty) {
                  return EmptyState(
                    title: 'NO FITS IN $category',
                    message: 'Nothing has been tagged with this era yet. Try another vibe.',
                  );
                }
                return _DiscoverGrid(outfits: list);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverGrid extends StatelessWidget {
  const _DiscoverGrid({required this.outfits});
  final List<Outfit> outfits;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [OutfitMasonry(outfits: outfits)],
    );
  }
}
