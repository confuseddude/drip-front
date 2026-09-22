import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/drip_skin.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/tap.dart';
import 'settings_controller.dart';

/// Poster-based theme selector.
///
/// Swipe the carousel and the *whole app* transforms behind it in real time
/// (a non-persisted preview). "Apply" saves it; leaving without applying puts
/// the saved theme back. The posters are the hero: glass is limited to the
/// label plates and the action bar.
class ThemePickerScreen extends ConsumerStatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  ConsumerState<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends ConsumerState<ThemePickerScreen> {
  static const _skins = DripSkin.values;
  late final PageController _pc;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _skins.indexOf(ref.read(savedSkinProvider));
    _pc = PageController(viewportFraction: 0.78, initialPage: _index);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  DripSkin get _current => _skins[_index];

  void _onPage(int i) {
    setState(() => _index = i);
    Haptics.tick();
    // Live preview: the entire app re-skins behind the picker.
    ref.read(previewSkinProvider.notifier).set(_skins[i]);
  }

  Future<void> _apply() async {
    final skin = _current;
    Haptics.commit();
    await ref.read(settingsProvider.notifier).setSkin(skin);
    ref.read(previewSkinProvider.notifier).set(null);
    if (mounted) showDripToast(context, '${skin.label} applied');
  }

  void _goTo(int i) {
    _pc.animateToPage(i, duration: Motion.content, curve: Motion.out);
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedSkinProvider);
    final skin = _current;
    final inUse = skin == saved;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Leaving without applying puts the saved theme back.
        if (didPop) ref.read(previewSkinProvider.notifier).set(null);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 20, 0),
                child: Row(
                  children: [
                    GlassIconButton(
                      semanticLabel: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('THEMES', style: AppText.display(17)),
                    const Spacer(),
                    Text(
                      '${_index + 1} / ${_skins.length}',
                      style: AppText.mono(11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Swipe to preview. The whole app changes with it.',
                    style: AppText.manrope(12, color: AppColors.muted),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _skins.length,
                  onPageChanged: _onPage,
                  physics: const BouncingScrollPhysics(
                    parent: PageScrollPhysics(),
                  ),
                  itemBuilder: (context, i) => _PosterCard(
                    controller: _pc,
                    index: i,
                    skin: _skins[i],
                    inUse: _skins[i] == saved,
                    onTap: () => i == _index ? _apply() : _goTo(i),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Name + personality: cross-fades with the carousel.
              AnimatedSwitcher(
                duration: Motion.quick,
                child: Column(
                  key: ValueKey(skin),
                  children: [
                    Text(
                      skin.label.toUpperCase(),
                      style: AppText.display(18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skin.tagline,
                      style: AppText.manrope(12, color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Swatch(skin.accent),
                        const SizedBox(width: 8),
                        _Swatch(skin.secondary),
                        const SizedBox(width: 8),
                        _Swatch(skin.wash),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  12 + (bottom > 0 ? bottom : 8),
                ),
                child: Glass(
                  radius: 26,
                  padding: const EdgeInsets.all(8),
                  child: Tap(
                    onTap: inUse ? null : _apply,
                    scale: 0.98,
                    semanticLabel: inUse
                        ? '${skin.label} is your current theme'
                        : 'Apply ${skin.label}',
                    child: AnimatedContainer(
                      duration: Motion.quick,
                      curve: Motion.out,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: inUse
                            ? Colors.white.withValues(alpha: 0.08)
                            : skin.accent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        inUse ? '✓  IN USE' : 'APPLY THEME',
                        style: AppText.mono(
                          13,
                          color: inUse ? AppColors.cream : AppColors.base,
                          weight: FontWeight.w500,
                          letterSpacing: 1.2,
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
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
    ),
  );
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.controller,
    required this.index,
    required this.skin,
    required this.inUse,
    required this.onTap,
  });

  final PageController controller;
  final int index;
  final DripSkin skin;
  final bool inUse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? controller.initialPage.toDouble())
            : controller.initialPage.toDouble();
        final delta = (page - index).clamp(-1.0, 1.0);
        final away = delta.abs();
        final scale = 1 - 0.10 * away;

        return Semantics(
          button: true,
          label: '${skin.label} theme${inUse ? ', current' : ''}',
          child: GestureDetector(
            onTap: onTap,
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: 1 - 0.4 * away,
                  child: AspectRatio(
                    aspectRatio: 0.70,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: skin.wash.withValues(
                              alpha: 0.28 * (1 - away),
                            ),
                            blurRadius: 40,
                            spreadRadius: -6,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Parallax: the artwork drifts against the swipe.
                            Image.asset(
                              skin.posterAsset,
                              fit: BoxFit.cover,
                              alignment: Alignment(delta * 0.7, 0),
                              cacheWidth: 640,
                              frameBuilder: (context, child, frame, sync) =>
                                  Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ColoredBox(
                                        color: skin.wash.withValues(alpha: 0.5),
                                      ),
                                      AnimatedOpacity(
                                        duration: Motion.content,
                                        opacity: (sync || frame != null)
                                            ? 1
                                            : 0,
                                        child: child,
                                      ),
                                    ],
                                  ),
                            ),
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 10,
                              child: Glass(
                                radius: 18,
                                thickness: GlassThickness.thin,
                                shadow: false,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        skin.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.manrope(
                                          12,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (inUse)
                                      Text(
                                        'IN USE',
                                        style: AppText.mono(
                                          9,
                                          color: skin.accent,
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
