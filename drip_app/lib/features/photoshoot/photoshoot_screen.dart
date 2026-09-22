import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/mock/mock_content.dart';
import '../../data/models/stylist.dart';
import '../../routing/main_shell.dart';
import '../wardrobe/wardrobe_controller.dart';
import 'photoshoot_controller.dart';

class PhotoshootScreen extends ConsumerStatefulWidget {
  const PhotoshootScreen({super.key});

  @override
  ConsumerState<PhotoshootScreen> createState() => _PhotoshootScreenState();
}

class _PhotoshootScreenState extends ConsumerState<PhotoshootScreen> {
  final _picker = ImagePicker();

  Future<void> _customScene(PhotoshootController c) async {
    final t = TextEditingController();
    final label = await showDripSheet<String>(
      context,
      builder: (ctx) => SheetContent(
        title: 'CUSTOM SCENE',
        subtitle: 'Describe the environment for this shoot.',
        children: [
          DripField(
            controller: t,
            hint: 'e.g. Rooftop at dawn',
            radius: 14,
            autofocus: true,
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'USE SCENE',
            height: 44,
            onPressed: () => Navigator.of(ctx).pop(t.text),
          ),
        ],
      ),
    );
    t.dispose();
    if (label != null && label.trim().isNotEmpty) {
      c.setScene('custom', customLabel: label.trim());
    }
  }

  Future<void> _generate() async {
    final s = ref.read(photoshootProvider);
    final controller = ref.read(photoshootProvider.notifier);
    final items = ref.read(wardrobeProvider).value ?? const [];
    final fit =
        items.where((i) => i.id == s.fitId).firstOrNull ?? items.firstOrNull;
    if (fit == null) {
      showDripToast(context, 'Add a garment to your wardrobe first');
      return;
    }

    String? real;
    if (s.mode == ShootMode.real) {
      try {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          imageQuality: 88,
        );
        if (file == null) return;
        real = file.path;
      } catch (_) {
        if (mounted) {
          showDripToast(context, 'Camera unavailable — switch to AI GEN');
        }
        return;
      }
    }
    await controller.generate(fitName: fit.name, realImage: real);
    if (!mounted) return;
    if (ref.read(photoshootProvider).render.hasError) {
      showDripToast(context, 'The render failed — try again');
    } else {
      context.push('/photoshoot/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(photoshootProvider);
    final c = ref.read(photoshootProvider.notifier);
    final wardrobe = ref.watch(wardrobeProvider);
    final accent = context.palette.accent;

    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'STUDIO SHOT',
            leading: const BackGlyph(),
            trailing: GlyphButton(
              '⚡',
              label: 'Render engine',
              onTap: () => showDripToast(context, 'Render engine ready'),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                const SectionLabel('SELECT SHOOT MODE'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ModeTab(
                        label: 'REAL LOOK',
                        selected: s.mode == ShootMode.real,
                        onTap: () => c.setMode(ShootMode.real),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeTab(
                        label: 'AI GEN ✦',
                        selected: s.mode == ShootMode.ai,
                        onTap: () => c.setMode(ShootMode.ai),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: _ModeTab(
                        label: 'EDITS (SOON)',
                        selected: false,
                        onTap: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionLabel('SELECT THE FIT TO SHOOT'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 154,
                  child: wardrobe.when(
                    data: (items) => items.isEmpty
                        ? const EmptyState(
                            title: 'NO GARMENTS',
                            message:
                                'Add a garment to your wardrobe to shoot it.',
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final item = items[i];
                              final activeId = items.any((i) => i.id == s.fitId)
                                  ? s.fitId
                                  : items.first.id;
                              final selected = item.id == activeId;
                              return Tap(
                                onTap: () => c.setFit(item.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 160,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.cyan
                                          : AppColors.elevated,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          height: 100,
                                          width: double.infinity,
                                          child: DripImage(item.image),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.name.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.display(
                                          10,
                                          lineHeight: 12,
                                          color: selected
                                              ? AppColors.cream
                                              : AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selected
                                            ? 'ACTIVE SELECTION'
                                            : '\$${item.price.round()} · READY',
                                        style: AppText.mono(
                                          8,
                                          lineHeight: 10,
                                          color: selected
                                              ? AppColors.cyan
                                              : AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    loading: () => const LoadingState(compact: true),
                    error: (_, _) => ErrorState(
                      onRetry: () => ref.invalidate(wardrobeProvider),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionLabel('SELECT SCENE ENVIRONMENT'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 112 / 90,
                  children: [
                    for (final scene in MockContent.scenes)
                      _SceneCard(
                        scene: scene,
                        label: scene.id == 'custom' && s.customLabel != null
                            ? s.customLabel!.toUpperCase()
                            : scene.label,
                        selected: s.sceneId == scene.id,
                        accent: accent,
                        onTap: () => scene.id == 'custom'
                            ? _customScene(c)
                            : c.setScene(scene.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AppButton(
              label: 'GENERATE SCENE LOOK ✦',
              height: 44,
              loading: s.render.isLoading,
              onPressed: _generate,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Tap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 29,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: selected || onTap == null
                ? null
                : Border.all(color: AppColors.elevated),
          ),
          child: Text(
            label,
            style: AppText.mono(
              10,
              color: selected ? AppColors.base : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.scene,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });
  final ShootScene scene;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? accent : AppColors.elevated),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  child: scene.image == null
                      ? ColoredBox(color: AppColors.elevated)
                      : DripImage(scene.image!),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.mono(
                9,
                lineHeight: 12,
                color: selected ? accent : AppColors.cream,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
