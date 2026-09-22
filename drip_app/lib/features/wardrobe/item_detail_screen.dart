import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/wardrobe.dart';
import '../../data/providers.dart';
import '../../routing/main_shell.dart';
import '../outfits/outfit_controller.dart';
import '../studio/studio_controller.dart';
import 'wardrobe_controller.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    WardrobeItem item,
  ) async {
    final name = TextEditingController(text: item.name);
    final brand = TextEditingController(text: item.brand);
    final colorway = TextEditingController(text: item.colorway);
    final price = TextEditingController(
      text: item.price == 0 ? '' : item.price.toStringAsFixed(0),
    );
    var category = item.category;
    final result = await showDripSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SheetContent(
          title: 'EDIT ITEM',
          children: [
            DripField(controller: name, hint: 'Name', radius: 14),
            const SizedBox(height: 10),
            DripField(controller: brand, hint: 'Brand', radius: 14),
            const SizedBox(height: 10),
            DripField(controller: colorway, hint: 'Colorway', radius: 14),
            const SizedBox(height: 10),
            DripField(
              controller: price,
              hint: 'Price',
              radius: 14,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in const [
                  'Outerwear',
                  'Tops',
                  'Bottoms',
                  'Boots',
                  'Accessories',
                ])
                  Tap(
                    onTap: () => setSheet(() => category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: category == c
                            ? ctx.palette.accent
                            : AppColors.elevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c,
                        style: AppText.manrope(
                          12,
                          weight: FontWeight.w600,
                          color: category == c
                              ? AppColors.base
                              : AppColors.cream,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'SAVE CHANGES',
              height: 44,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    if (result == true && name.text.trim().isNotEmpty) {
      await ref
          .read(wardrobeProvider.notifier)
          .edit(
            item.copyWith(
              name: name.text.trim(),
              brand: brand.text.trim(),
              colorway: colorway.text.trim(),
              category: category,
              price: double.tryParse(price.text.trim()) ?? item.price,
            ),
          );
      if (context.mounted) showDripToast(context, 'Item updated');
    }
    name.dispose();
    brand.dispose();
    colorway.dispose();
    price.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobe = ref.watch(wardrobeProvider);
    final item = ref.watch(wardrobeItemProvider(itemId));
    final rotation = ref.watch(rotationProvider).value ?? const <String>[];
    final inRotation = rotation.contains(itemId);
    final accent = context.palette.accent;

    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'WARDROBE ITEM',
            leading: const BackGlyph(),
            trailing: GlyphButton(
              '⚡',
              mono: true,
              color: inRotation ? accent : AppColors.cream,
              label: inRotation ? 'Remove from rotation' : 'Add to rotation',
              onTap: item == null
                  ? null
                  : () async {
                      await ref
                          .read(wardrobeRepositoryProvider)
                          .setRotation(itemId, inRotation: !inRotation);
                      ref.invalidate(rotationProvider);
                      if (context.mounted) {
                        showDripToast(
                          context,
                          inRotation ? 'Out of rotation' : 'Added to rotation',
                        );
                      }
                    },
            ),
          ),
          Expanded(
            child: wardrobe.whenDrip(
              onRetry: () => ref.invalidate(wardrobeProvider),
              data: (_) {
                if (item == null) {
                  return EmptyState(
                    title: 'ITEM NOT FOUND',
                    message: 'This garment is no longer in your closet.',
                    actionLabel: 'BACK TO WARDROBE',
                    onAction: () => context.go('/wardrobe'),
                  );
                }
                return _Body(
                  item: item,
                  onEdit: () => _edit(context, ref, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.item, required this.onEdit});
  final WardrobeItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.palette.accent;
    final catalog = ref.watch(outfitCatalogProvider).value ?? const [];
    // Looks that share a tag with this garment, otherwise the trending ones.
    final tags = item.tags.map((t) => t.toLowerCase()).toSet();
    final related = catalog
        .where(
          (o) =>
              o.tags.any((t) => tags.any((x) => x.contains(t.toLowerCase()))),
        )
        .take(2)
        .toList();
    final featuring = related.length == 2 ? related : catalog.take(2).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: DripImage(item.image),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.elevated)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.name.toUpperCase(),
                        style: AppText.display(18),
                      ),
                    ),
                    if (item.price > 0)
                      Text(
                        formatPrice(item.price),
                        style: AppText.mono(14, color: accent),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Prop(
                        'KNOW BRAND',
                        item.brand.isEmpty ? '—' : item.brand,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _Prop(
                        'COLORWAY',
                        item.colorway.isEmpty ? '—' : item.colorway,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _Prop('CATEGORY', item.category)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < item.tags.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: i == 0 ? AppColors.cream : AppColors.cyan,
                          ),
                        ),
                        child: Text(
                          item.tags[i],
                          style: AppText.mono(
                            9,
                            color: i == 0 ? AppColors.cream : AppColors.cyan,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('OUTFITS FEATURING THIS FIT'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < featuring.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: Tap(
                          onTap: () =>
                              context.push('/outfit/${featuring[i].id}'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.elevated),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 120,
                                    width: double.infinity,
                                    child: DripImage(featuring[i].image),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  featuring[i].title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.manrope(
                                    11,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                AppButton(
                  label: 'CREATE FIT WITH THIS ✦',
                  height: 44,
                  onPressed: () {
                    final studio = ref.read(studioProvider.notifier)
                      ..useSource(wardrobe: true);
                    studio.select(studioPieceFromWardrobe(item));
                    context.push('/studio/builder');
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Outlined(
                        label: 'EDIT ITEM',
                        color: AppColors.cream,
                        border: AppColors.muted,
                        onTap: onEdit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Outlined(
                        label: 'REMOVE CLOSET',
                        color: AppColors.red,
                        border: AppColors.red,
                        onTap: () async {
                          final ok = await showDripConfirm(
                            context,
                            title: 'REMOVE ITEM?',
                            message:
                                '${item.name} will be removed from your closet.',
                            confirmLabel: 'REMOVE',
                            destructive: true,
                          );
                          if (!ok) return;
                          await ref
                              .read(wardrobeProvider.notifier)
                              .remove(item.id);
                          if (context.mounted) {
                            showDripToast(context, 'Removed ${item.name}');
                            context.go('/wardrobe');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Prop extends StatelessWidget {
  const _Prop(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.mono(9, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.manrope(13, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Outlined extends StatelessWidget {
  const _Outlined({
    required this.label,
    required this.color,
    required this.border,
    required this.onTap,
  });
  final String label;
  final Color color;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Text(label, style: AppText.mono(11, color: color)),
      ),
    );
  }
}
