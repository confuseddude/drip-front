import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/tap.dart';
import '../../data/mock/mock_content.dart';
import '../../data/mock/mock_users.dart';
import '../../data/models/outfit.dart';
import '../../data/models/stylist.dart';
import '../../routing/main_shell.dart';
import '../outfits/outfit_controller.dart';
import '../wardrobe/wardrobe_controller.dart';
import 'studio_controller.dart';

class OutfitBuilderScreen extends ConsumerStatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  ConsumerState<OutfitBuilderScreen> createState() =>
      _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends ConsumerState<OutfitBuilderScreen> {
  bool _publishing = false;

  Future<void> _pickCategory() async {
    final current = ref.read(studioProvider).category;
    final chosen = await showDripSheet<String>(
      context,
      builder: (ctx) => SheetContent(
        title: 'SWAP CATEGORY',
        children: [
          for (final c in MockContent.studioCategories)
            Tap(
              onTap: () => Navigator.of(ctx).pop(c),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.elevated)),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(c, style: AppText.mono(13))),
                    if (c == current)
                      Text(
                        '✓',
                        style: AppText.mono(14, color: context.palette.accent),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (chosen != null) ref.read(studioProvider.notifier).setCategory(chosen);
  }

  Future<void> _publish() async {
    final studio = ref.read(studioProvider);
    if (studio.worn.isEmpty) {
      showDripToast(context, 'Add at least one piece first');
      return;
    }
    setState(() => _publishing = true);
    final rate = ref.read(studioDripRateProvider);
    final n = (ref.read(outfitCatalogProvider).value?.length ?? 0) + 1;
    final look = Outfit(
      id: 'o_studio_${DateTime.now().millisecondsSinceEpoch}',
      title: 'STUDIO FIT #$n',
      image: MockContent.builderModel,
      price: studio.total,
      rate: rate,
      creatorHandle: MockUsers.meHandle,
      tags: const ['STUDIO', 'CUSTOM'],
      categories: const ['Y2K', 'STREET'],
      pieces: [
        for (final e in studio.worn.entries)
          OutfitPiece(
            slot: e.key == 'FOOTWEAR' ? 'SHOES' : e.key,
            name: e.value.name,
            brand: 'Drip Studio',
            price: e.value.price,
          ),
      ],
    );
    await ref.read(outfitCatalogProvider.notifier).add(look);
    if (!mounted) return;
    setState(() => _publishing = false);
    showDripToast(context, 'Look published');
    context.push('/outfit/${look.id}');
  }

  @override
  Widget build(BuildContext context) {
    final studio = ref.watch(studioProvider);
    final controller = ref.read(studioProvider.notifier);
    final rate = ref.watch(studioDripRateProvider);
    final accent = context.palette.accent;
    ref.watch(wardrobeProvider); // keep wardrobe pieces warm for the picker
    final pieces = controller.piecesFor(studio.category);

    return ShellPage(
      child: Column(
        children: [
          SizedBox(
            height: 47,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tap(
                    onTap: () {
                      if (controller.canUndo) {
                        controller.undo();
                      } else if (context.canPop()) {
                        context.pop();
                      }
                    },
                    child: Text('◀ UNDO', style: AppText.inter(16)),
                  ),
                  Text('STUDIO CANVAS', style: AppText.display(13)),
                  Tap(
                    onTap: controller.reset,
                    child: Text(
                      'RESET ⟳',
                      style: AppText.inter(13, color: AppColors.cyan),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 360,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DripImage(
                            MockContent.builderModel,
                            alignment: Alignment.topCenter,
                          ),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.base.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: accent),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  'DRIP RATE: $rate%',
                                  key: ValueKey(rate),
                                  style: AppText.mono(8, color: accent),
                                ),
                              ),
                            ),
                          ),
                          // Currently worn pieces (layers on the model).
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Column(
                              children: [
                                for (final p in studio.worn.values)
                                  Container(
                                    width: 36,
                                    height: 36,
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.cream.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: DripImage(p.image),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 12,
                            child: Center(
                              child: Tap(
                                onTap: controller.randomize,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '✦ RANDOMIZE FIT ✦',
                                    style: AppText.display(
                                      10,
                                      color: AppColors.base,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SWAP PIECES',
                              style: AppText.mono(10, color: AppColors.muted),
                            ),
                            Tap(
                              onTap: _pickCategory,
                              child: Text(
                                '${studio.category} ▼',
                                style: AppText.mono(10, color: AppColors.cyan),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: pieces.isEmpty
                              ? Center(
                                  child: Text(
                                    studio.fromWardrobe
                                        ? 'NO ${studio.category} IN YOUR WARDROBE YET'
                                        : 'NOTHING IN ${studio.category}',
                                    style: AppText.mono(
                                      9,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: pieces.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, i) => _PieceTile(
                                    piece: pieces[i],
                                    selected:
                                        studio.worn[pieces[i].category]?.id ==
                                        pieces[i].id,
                                    onTap: () => controller.select(pieces[i]),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'PHOTOSHOOT 📸',
                    style: AppButtonStyle.subtle,
                    height: 36,
                    radius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: AppText.display(10),
                    onPressed: () => context.push('/photoshoot'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'PUBLISH LOOK ✦',
                    height: 36,
                    radius: 18,
                    loading: _publishing,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: AppText.display(10),
                    onPressed: _publish,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PieceTile extends StatelessWidget {
  const _PieceTile({
    required this.piece,
    required this.selected,
    required this.onTap,
  });
  final StudioPiece piece;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: piece.name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? context.palette.accent : AppColors.elevated,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DripImage(piece.image),
        ),
      ),
    );
  }
}
