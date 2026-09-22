import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/wardrobe.dart';
import 'wardrobe_controller.dart';

/// Garment capture: pick a photo, "detect" the garment, name it and add it to
/// the wardrobe.
class AddToWardrobeScreen extends ConsumerStatefulWidget {
  const AddToWardrobeScreen({super.key});

  @override
  ConsumerState<AddToWardrobeScreen> createState() =>
      _AddToWardrobeScreenState();
}

class _AddToWardrobeScreenState extends ConsumerState<AddToWardrobeScreen> {
  final _picker = ImagePicker();
  final _name = TextEditingController();
  bool _camera = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _camera = source == ImageSource.camera);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (file == null) return;
      _name.clear();
      await ref.read(captureProvider.notifier).process(file.path);
    } catch (_) {
      if (mounted) {
        showDripToast(
          context,
          source == ImageSource.camera
              ? 'Camera unavailable — try the library'
              : 'Couldn\'t open your library',
        );
      }
    }
  }

  Future<void> _add(String imagePath, GarmentDetection d) async {
    final name = _name.text.trim().isEmpty ? d.name : _name.text.trim();
    setState(() => _saving = true);
    final item = WardrobeItem(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: d.category,
      image: imagePath,
      status: 'EXTRACTED · 3D READY',
      tags: d.tags,
    );
    await ref.read(wardrobeProvider.notifier).add(item);
    if (!mounted) return;
    showDripToast(context, 'Added to wardrobe');
    context.go('/wardrobe');
  }

  @override
  Widget build(BuildContext context) {
    final capture = ref.watch(captureProvider);
    final accent = context.palette.accent;
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 8.0);
    final detection = capture.detection.value;
    final path = capture.imagePath;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DripTopBar(
              title: 'GARMENT CAPTURE',
              leading: const BackGlyph(),
              trailing: GlyphButton(
                '⚡',
                label: 'Detection engine',
                onTap: () => showDripToast(context, 'Auto-detect is on'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: 'TAKE PHOTO 📸',
                      active: _camera,
                      onTap: () => _pick(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeButton(
                      label: 'CHOOSE FROM LIBRARY',
                      active: !_camera,
                      onTap: () => _pick(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capture.detection.isLoading
                          ? 'CALIBRATING BOUNDING BOX...'
                          : path == null
                          ? 'WAITING FOR A GARMENT PHOTO'
                          : 'BOUNDING BOX LOCKED',
                      style: AppText.mono(9, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    _Canvas(
                      path: path,
                      loading: capture.detection.isLoading,
                      detection: detection,
                    ),
                    const SizedBox(height: 16),
                    if (capture.detection.hasError)
                      ErrorState(
                        message: 'Detection failed. Try another photo.',
                        onRetry: () => path == null
                            ? null
                            : ref.read(captureProvider.notifier).process(path),
                      )
                    else if (detection != null && path != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.elevated),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IS THIS YOUR ${detection.category.toUpperCase() == 'OUTERWEAR' ? 'JACKET' : 'GARMENT'}?',
                              style: AppText.display(14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Taylor has extracted: "${detection.name}". Rename it below if it isn\'t right.',
                              style: AppText.manrope(
                                12,
                                color: AppColors.muted,
                                lineHeight: 17,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.base,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.elevated),
                              ),
                              child: TextField(
                                controller: _name,
                                cursorColor: accent,
                                style: AppText.manrope(13),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText: detection.name,
                                  hintStyle: AppText.manrope(
                                    13,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final t in detection.tags)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.elevated,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t,
                                      style: AppText.mono(
                                        8,
                                        color: AppColors.cyan,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else if (path == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Lay the piece flat in good light, then take a photo or pick one from your library. Taylor will digitize it for the look-builder.',
                          style: AppText.manrope(
                            12,
                            color: AppColors.muted,
                            lineHeight: 18,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
              child: AppButton(
                label: 'ADD TO WARDROBE ✦',
                height: 42,
                radius: 12,
                loading: _saving,
                textStyle: AppText.display(12),
                onPressed: detection != null && path != null
                    ? () => _add(path, detection)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 29,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? context.palette.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: active ? null : Border.all(color: AppColors.elevated),
        ),
        child: Text(
          label,
          style: AppText.mono(
            10,
            color: active ? AppColors.base : AppColors.cream,
          ),
        ),
      ),
    );
  }
}

class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.path,
    required this.loading,
    required this.detection,
  });
  final String? path;
  final bool loading;
  final GarmentDetection? detection;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.elevated),
      ),
      clipBehavior: Clip.antiAlias,
      child: path == null
          ? Center(child: Text('📸', style: AppText.inter(40)))
          : Stack(
              fit: StackFit.expand,
              children: [
                DripImage(path!),
                if (loading)
                  const ColoredBox(
                    color: Color(0x990E1018),
                    child: LoadingState(label: 'ANALYZING GARMENT...'),
                  ),
                if (detection != null)
                  Positioned(
                    left: 32,
                    top: 24,
                    right: 32,
                    bottom: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cyan),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cyan,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DETECTED: ${detection!.label}',
                                style: AppText.mono(8, color: AppColors.base),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.palette.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${detection!.confidence}% CONFIDENCE',
                                style: AppText.mono(8, color: AppColors.base),
                              ),
                            ),
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
