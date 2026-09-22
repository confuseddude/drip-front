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
import '../../core/widgets/pills.dart';
import '../../core/widgets/tap.dart';
import '../../data/mock/mock_content.dart';
import '../../routing/main_shell.dart';
import 'create_ootd_controller.dart';

const _audiences = ['Public', 'Followers', 'Only me'];

class CreateOotdScreen extends ConsumerStatefulWidget {
  const CreateOotdScreen({super.key});

  @override
  ConsumerState<CreateOotdScreen> createState() => _CreateOotdScreenState();
}

class _CreateOotdScreenState extends ConsumerState<CreateOotdScreen> {
  late final TextEditingController _caption;
  late final TextEditingController _location;
  final _picker = ImagePicker();
  bool _camera = true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(createOotdProvider);
    _caption = TextEditingController(text: s.caption);
    _location = TextEditingController(text: s.location);
  }

  @override
  void dispose() {
    _caption.dispose();
    _location.dispose();
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
      if (file != null) {
        ref.read(createOotdProvider.notifier).setImage(file.path);
      }
    } catch (_) {
      if (mounted) {
        showDripToast(
          context,
          source == ImageSource.camera
              ? 'Camera unavailable — try the vault'
              : 'Couldn\'t open your gallery',
        );
      }
    }
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDripSheet<String>(
      context,
      builder: (ctx) => SheetContent(
        title: 'ADD VIBE',
        subtitle: 'Tags help the feed match your fit to the right eras.',
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
            style: AppText.mono(13),
            cursorColor: context.palette.accent,
            decoration: InputDecoration(
              prefixText: '#',
              prefixStyle: AppText.mono(13, color: AppColors.cyan),
              hintText: 'TECHWEAR',
              hintStyle: AppText.mono(13, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.base,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.elevated),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.elevated),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'ADD TAG',
            height: 44,
            onPressed: () => Navigator.of(ctx).pop(controller.text),
          ),
        ],
      ),
    );
    controller.dispose();
    if (tag != null) ref.read(createOotdProvider.notifier).addTag(tag);
  }

  Future<void> _pickAudience() async {
    final current = ref.read(createOotdProvider).visibility;
    final v = await showDripSheet<String>(
      context,
      builder: (ctx) => SheetContent(
        title: 'WHO SEES THIS',
        children: [
          for (final a in _audiences)
            Tap(
              onTap: () => Navigator.of(ctx).pop(a),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.elevated)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        a,
                        style: AppText.manrope(14, weight: FontWeight.w500),
                      ),
                    ),
                    if (a == current)
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
    if (v != null) ref.read(createOotdProvider.notifier).setVisibility(v);
  }

  Future<void> _post() async {
    final notifier = ref.read(createOotdProvider.notifier);
    if (_caption.text.trim().isEmpty) {
      showDripToast(context, 'Add a caption first');
      return;
    }
    notifier.setCaption(_caption.text.trim());
    notifier.setLocation(_location.text.trim());
    final post = await notifier.post();
    if (!mounted) return;
    showDripToast(context, 'Posted to your feed');
    context.go('/home');
    if (post != null) {
      // Nothing else to do: the feed provider already holds the new post.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(createOotdProvider);
    final accent = context.palette.accent;

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
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    child: Text(
                      'CANCEL',
                      style: AppText.mono(14, color: AppColors.muted),
                    ),
                  ),
                  Text('CREATE LOOK', style: AppText.display(16)),
                  Tap(
                    onTap: () {
                      ref.read(createOotdProvider.notifier).saveDraft();
                      _caption.text = MockContent.defaultCaption;
                      showDripToast(context, 'Draft saved');
                    },
                    child: Text(
                      'DRAFT (${s.drafts})',
                      style: AppText.mono(14, color: AppColors.cyan),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DripSegmented(
                    labels: const ['CAMERA CAPTURE', 'VAULT GALLERY'],
                    selected: _camera ? 0 : 1,
                    onTap: (i) => _pick(
                      i == 0 ? ImageSource.camera : ImageSource.gallery,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DripImage(s.imagePath ?? MockContent.createPreview),
                        Positioned(
                          left: 16,
                          top: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '✦',
                                  style: AppText.inter(10, color: accent),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${s.tags.length} METADATA TAGS CALIBRATED',
                                  style: AppText.mono(8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('FIT CAPTION'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.elevated),
                    ),
                    child: TextField(
                      controller: _caption,
                      maxLines: 3,
                      minLines: 2,
                      maxLength: 200,
                      cursorColor: accent,
                      style: AppText.manrope(13),
                      onChanged: ref
                          .read(createOotdProvider.notifier)
                          .setCaption,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        counterText: '',
                        hintText: 'Describe the fit...',
                        hintStyle: AppText.manrope(13, color: AppColors.muted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('VIBE CALIBRATIONS'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in s.tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cyan),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t,
                                style: AppText.mono(10, color: AppColors.cyan),
                              ),
                              const SizedBox(width: 4),
                              Tap(
                                onTap: () => ref
                                    .read(createOotdProvider.notifier)
                                    .removeTag(t),
                                semanticLabel: 'Remove $t',
                                child: Text(
                                  '✕',
                                  style: AppText.manrope(
                                    10,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Tap(
                        onTap: _addTag,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.base,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.elevated),
                          ),
                          child: Text(
                            '+ ADD NEW',
                            style: AppText.mono(10, color: AppColors.muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('WHO SEES THIS'),
                            const SizedBox(height: 6),
                            Tap(
                              onTap: _pickAudience,
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.elevated),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      s.visibility,
                                      style: AppText.manrope(12),
                                    ),
                                    Text(
                                      '▼',
                                      style: AppText.inter(
                                        10,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('LOCATION PLACE'),
                            const SizedBox(height: 6),
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.elevated),
                              ),
                              child: Row(
                                children: [
                                  Text('📍', style: AppText.inter(12)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: TextField(
                                      controller: _location,
                                      cursorColor: accent,
                                      style: AppText.manrope(12),
                                      onChanged: ref
                                          .read(createOotdProvider.notifier)
                                          .setLocation,
                                      decoration: const InputDecoration(
                                        isCollapsed: true,
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'POST OOTD ✦',
              height: 44,
              loading: s.posting,
              onPressed: _post,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.mono(9, color: AppColors.muted));
}
