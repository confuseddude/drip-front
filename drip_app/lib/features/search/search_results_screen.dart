import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/repositories/outfit_repository.dart';
import '../../routing/main_shell.dart';
import '../outfits/outfit_card.dart';
import '../social/creator_tile.dart';
import 'search_controller.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.query});
  final String query;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(widget.query));

    return ShellPage(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.elevated)),
            ),
            child: DripTopBar(
              title: 'SEARCH RESULTS',
              height: 50,
              leading: const BackGlyph(mono: true),
              trailing: GlyphButton(
                '⌕',
                mono: true,
                onTap: () => context.pop(),
                label: 'Edit search',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Tap(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.elevated),
                ),
                child: Row(
                  children: [
                    Text(
                      '⌕',
                      style: AppText.mono(
                        16,
                        color: AppColors.cyan,
                        weight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"${widget.query}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.manrope(13),
                      ),
                    ),
                    Text(
                      '${results.value?.total ?? 0} RESULTS',
                      style: AppText.mono(11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: results.whenDrip(
              onRetry: () =>
                  ref.invalidate(searchResultsProvider(widget.query)),
              data: (r) => _Body(
                results: r,
                tab: _tab,
                onTab: (i) => setState(() => _tab = i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.results, required this.tab, required this.onTab});
  final SearchResults results;
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final r = results;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 8,
            children: [
              FilterPill(
                label: 'FITS (${r.fits.length})',
                selected: tab == 0,
                selectedColor: AppColors.cyan,
                textStyle: AppText.mono(10),
                onTap: () => onTab(0),
              ),
              FilterPill(
                label: 'CREATORS (${r.creatorHandles.length})',
                selected: tab == 1,
                selectedColor: AppColors.cyan,
                textStyle: AppText.mono(10),
                onTap: () => onTab(1),
              ),
              FilterPill(
                label: 'COLLECTIONS',
                selected: tab == 2,
                selectedColor: AppColors.cyan,
                textStyle: AppText.mono(10),
                onTap: () => onTab(2),
              ),
            ],
          ),
        ),
        if (tab == 0) ...[
          if (r.fits.isEmpty)
            const EmptyState(
              title: 'NO FITS FOUND',
              message:
                  'Nothing matches that search. Try another vibe or creator.',
            )
          else
            OutfitMasonry(
              outfits: r.fits,
              style: OutfitCardStyle.plate,
              gap: 12,
              tall: 220,
              short: 190,
            ),
          if (r.creatorHandles.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionLabel(
                'FEATURED CREATOR FOR THIS VIBE',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CreatorTile(handle: r.creatorHandles.first),
            ),
          ],
        ],
        if (tab == 1)
          if (r.creatorHandles.isEmpty)
            const EmptyState(
              title: 'NO CREATORS FOUND',
              message: 'No creators match this search yet.',
            )
          else
            for (final h in r.creatorHandles)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: CreatorTile(handle: h),
              ),
        if (tab == 2)
          if (r.collections.isEmpty)
            const EmptyState(
              title: 'NO COLLECTIONS',
              message: 'No curated collections match this search.',
            )
          else
            for (final c in r.collections)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.cream.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.title, style: AppText.display(13)),
                            const SizedBox(height: 4),
                            Text(
                              '${c.count} FITS · #${c.tag}',
                              style: AppText.mono(9, color: AppColors.cyan),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}
