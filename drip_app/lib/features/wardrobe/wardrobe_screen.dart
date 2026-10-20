import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/wardrobe.dart';
import '../../routing/main_shell.dart';
import 'import/import_banner.dart';
import 'wardrobe_controller.dart';
import '../hints/hints.dart';

/// Groups garments the way the wardrobe grid labels them. Uploads still
/// being processed (or that failed) sit together at the top.
String sectionFor(WardrobeItem i) {
  if (i.isProcessing) return 'PROCESSING';
  if (i.isFailed) return 'NEEDS A BETTER PHOTO';
  return switch (i.category) {
    'Boots' || 'Shoes' => 'SHOES',
    'Accessories' => 'ACCESSORIES',
    'Bottoms' => 'BOTTOMS',
    'Dresses' => 'DRESSES',
    'Unsorted' => 'UNSORTED',
    _ => 'TOPS & OUTERWEAR',
  };
}

/// How the grid is ordered. Wear counts come from the days of the photos a
/// piece was found in (and the worn calendar).
enum WardrobeSort {
  recent('NEWEST'),
  mostWorn('MOST WORN'),
  leastWorn('LEAST WORN');

  const WardrobeSort(this.label);
  final String label;

  WardrobeSort get next => values[(index + 1) % values.length];
}

/// Categories in the order the filter row shows them.
const _categoryOrder = [
  'Tops',
  'Outerwear',
  'Bottoms',
  'Dresses',
  'Shoes',
  'Accessories',
  'Unsorted',
];

/// A piece not worn in this long goes on the "not worn lately" shelf.
const notWornFor = Duration(days: 180);

List<WardrobeItem> sortWardrobe(List<WardrobeItem> items, WardrobeSort sort) {
  if (sort == WardrobeSort.recent) return items;
  int byLastWorn(WardrobeItem a, WardrobeItem b) {
    final x = a.lastWornAt, y = b.lastWornAt;
    if (x == null) return y == null ? 0 : 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }

  return [...items]..sort(
    (a, b) => switch (sort) {
      WardrobeSort.mostWorn => b.wearCount.compareTo(a.wearCount),
      _ =>
        a.wearCount != b.wearCount
            ? a.wearCount.compareTo(b.wearCount)
            : byLastWorn(a, b),
    },
  );
}

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  bool _rotationTab = false;
  bool _editing = false;
  String? _category;
  WardrobeSort _sort = WardrobeSort.recent;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(wardrobeProvider.notifier).refreshIfStale();
    });
  }

  Future<void> _remove(WardrobeItem item) async {
    final ok = await showDripConfirm(
      context,
      title: 'REMOVE ITEM?',
      message: '${item.name} will be removed from your closet.',
      confirmLabel: 'REMOVE',
      destructive: true,
    );
    if (ok) {
      await ref.read(wardrobeProvider.notifier).remove(item.id);
      if (mounted) showDripToast(context, 'Removed ${item.name}');
    }
  }

  /// Category chips and the sort, once there's enough to narrow down.
  List<Widget> _refineRow(List<WardrobeItem> items) {
    if (_rotationTab) return const [];
    final present = {
      for (final i in items)
        if (i.isReady) i.category,
    };
    final categories = [
      for (final c in _categoryOrder)
        if (present.contains(c)) c,
    ];
    final worn = items.any((i) => i.wearCount > 0);
    if (categories.length < 2 && !worn) return const [];
    const pad = EdgeInsets.symmetric(horizontal: 12, vertical: 7);
    return [
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (worn) ...[
              FilterPill(
                label: '↕ ${_sort.label}',
                selected: _sort != WardrobeSort.recent,
                padding: pad,
                onTap: () => setState(() => _sort = _sort.next),
              ),
              const SizedBox(width: 6),
            ],
            if (categories.length >= 2) ...[
              FilterPill(
                label: 'ALL',
                selected: _category == null,
                padding: pad,
                onTap: () => setState(() => _category = null),
              ),
              for (final c in categories) ...[
                const SizedBox(width: 6),
                FilterPill(
                  label: c.toUpperCase(),
                  selected: _category == c,
                  padding: pad,
                  onTap: () =>
                      setState(() => _category = _category == c ? null : c),
                ),
              ],
            ],
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = ref.watch(wardrobeProvider);
    final rotation = ref.watch(rotationProvider).value ?? const <String>[];
    final count = wardrobe.value?.length;

    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'WARDROBE',
            card: true,
            height: 44,
            leading: const BackGlyph(),
            trailing: HintAnchor(
              id: 'wardrobe.import',
              child: GlyphButton(
                '➕',
                mono: true,
                label: 'Add from your photos',
                onTap: () => context.push('/wardrobe/import'),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: AppColors.elevated)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterPill(
                        label: 'MY WARDROBE${count == null ? '' : ' ($count)'}',
                        selected: !_rotationTab,
                        onTap: () => setState(() => _rotationTab = false),
                      ),
                      const SizedBox(width: 8),
                      FilterPill(
                        label: 'SAVED',
                        selected: false,
                        onTap: () => context.push('/saved'),
                      ),
                      const SizedBox(width: 8),
                      FilterPill(
                        label: 'ROTATION',
                        selected: _rotationTab,
                        onTap: () => setState(() => _rotationTab = true),
                      ),
                    ],
                  ),
                ),
                ..._refineRow(wardrobe.value ?? const []),
              ],
            ),
          ),
          const ImportBanner(),
          Expanded(
            child: wardrobe.whenDrip(
              onRetry: () => ref.invalidate(wardrobeProvider),
              data: (items) {
                final inTab = _rotationTab
                    ? items.where((i) => rotation.contains(i.id)).toList()
                    : items;
                if (inTab.isEmpty) {
                  return EmptyState(
                    title: _rotationTab
                        ? 'NO ROTATION YET'
                        : 'WELCOME TO YOUR WARDROBE',
                    message: _rotationTab
                        ? 'Mark garments with ⚡ on their page to keep your most-worn pieces here.'
                        : 'Share photos of your outfits and Drip builds your '
                              'wardrobe for you: every piece cut out and '
                              'sorted.',
                    actionLabel: _rotationTab ? null : 'BUILD FROM MY PHOTOS',
                    onAction: () => context.push('/wardrobe/import'),
                  );
                }
                final category = _category;
                final visible = sortWardrobe(
                  category == null
                      ? inTab
                      : inTab.where((i) => i.category == category).toList(),
                  _sort,
                );
                // Sorted, or narrowed to one category, the grid is one list;
                // otherwise it's grouped by kind of piece.
                final flat = category != null || _sort != WardrobeSort.recent;
                final sections = <String, List<WardrobeItem>>{};
                for (final i in visible) {
                  final key = flat
                      ? (category?.toUpperCase() ?? _sort.label)
                      : sectionFor(i);
                  sections.putIfAbsent(key, () => []).add(i);
                }
                final now = DateTime.now();
                final unworn = _rotationTab || flat
                    ? const <WardrobeItem>[]
                    : [
                        for (final i in inTab)
                          if (i.isReady &&
                              i.lastWornAt != null &&
                              now.difference(i.lastWornAt!) > notWornFor)
                            i,
                      ];
                return ListView(
                  // Clear the floating nav (the tab root draws under it).
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    if (unworn.isNotEmpty) ...[
                      const SectionLabel('NOT WORN LATELY'),
                      const SizedBox(height: 12),
                      _Shelf(items: unworn),
                      const SizedBox(height: 16),
                    ],
                    for (final entry in sections.entries) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SectionLabel(entry.key),
                          if (entry.key == sections.keys.first)
                            Tap(
                              onTap: () => setState(() => _editing = !_editing),
                              child: Text(
                                _editing ? 'DONE ✓' : 'EDIT GRID ✎',
                                style: AppText.mono(10, color: AppColors.cyan),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Grid(
                        items: entry.value,
                        editing: _editing,
                        onRemove: _remove,
                        addTile:
                            entry.key == sections.keys.last && !_rotationTab,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.items,
    required this.editing,
    required this.onRemove,
    required this.addTile,
  });
  final List<WardrobeItem> items;
  final bool editing;
  final ValueChanged<WardrobeItem> onRemove;
  final bool addTile;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      for (final i in items)
        GarmentCard(item: i, editing: editing, onRemove: () => onRemove(i)),
      if (addTile) const _UploadTile(),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cells[i]),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < cells.length
                  ? cells[i + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < cells.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

/// A sideways row of pieces (the "not worn lately" shelf).
class _Shelf extends StatelessWidget {
  const _Shelf({required this.items});
  final List<WardrobeItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 166,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) =>
            SizedBox(width: 150, child: GarmentCard(item: items[i])),
      ),
    );
  }
}

class GarmentCard extends StatelessWidget {
  const GarmentCard({
    super.key,
    required this.item,
    this.editing = false,
    this.onRemove,
  });
  final WardrobeItem item;
  final bool editing;
  final VoidCallback? onRemove;

  /// "WORN 9× · 12 MAR" for a piece with wear history, else its status.
  String get _subline {
    if (!item.isReady || item.wearCount == 0) return item.status;
    final last = item.lastWornAt;
    return 'WORN ${item.wearCount}×'
        '${last == null ? '' : ' · ${formatDay(last).toUpperCase()}'}';
  }

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: () => editing
          ? onRemove?.call()
          : context.push('/wardrobe/item/${item.id}'),
      semanticLabel: item.name,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: editing ? AppColors.red : AppColors.elevated,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DripImage(item.image),
                        if (item.isProcessing)
                          const ColoredBox(
                            color: Color(0x990E1018),
                            child: LoadingState(compact: true),
                          ),
                      ],
                    ),
                  ),
                ),
                if (editing)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '✕',
                        style: AppText.inter(12, color: AppColors.base),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.manrope(12, weight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              _subline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.mono(
                8,
                color: item.isFailed ? AppColors.red : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile();

  @override
  Widget build(BuildContext context) {
    return HintAnchor(
      id: 'wardrobe.add',
      child: Tap(
        onTap: () => context.push('/wardrobe/import'),
        semanticLabel: 'Add from your photos',
        child: Container(
          height: 158,
          decoration: BoxDecoration(
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cyan),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('➕', style: AppText.inter(24, color: AppColors.cyan)),
              const SizedBox(height: 10),
              Text(
                'ADD FROM PHOTOS',
                style: AppText.mono(9, color: AppColors.cyan),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
