import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/drip_skin.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/tap.dart';
import 'settings_controller.dart';

/// The customization bar: every theme as a poster thumbnail. One tap switches
/// the whole app immediately (and persists); "All themes" opens the full
/// poster carousel. Lives on the profile and in Appearance settings.
class ThemeBar extends ConsumerStatefulWidget {
  const ThemeBar({super.key});

  @override
  ConsumerState<ThemeBar> createState() => _ThemeBarState();
}

class _ThemeBarState extends ConsumerState<ThemeBar> {
  static const _dot = 44.0;
  static const _gap = 12.0;
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final i = DripSkin.values.indexOf(ref.read(savedSkinProvider));
    // Start with the selected theme in view.
    _scroll = ScrollController(
      initialScrollOffset: math.max(0, i * (_dot + _gap) - 90),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(savedSkinProvider);
    return Glass(
      radius: 24,
      thickness: GlassThickness.thin,
      shadow: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR WORLD',
                        style: AppText.mono(
                          9,
                          color: AppColors.muted,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: Motion.quick,
                        child: Text(
                          current.label,
                          key: ValueKey(current),
                          style: AppText.manrope(14, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Tap(
                  onTap: () => context.push('/themes'),
                  semanticLabel: 'Browse all themes',
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'ALL THEMES →',
                      style: AppText.mono(
                        10,
                        color: current.accent,
                        weight: FontWeight.w500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _dot + 6,
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              itemCount: DripSkin.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: _gap),
              itemBuilder: (context, i) {
                final s = DripSkin.values[i];
                return _ThemeDot(
                  skin: s,
                  selected: s == current,
                  onTap: () {
                    if (s == current) return;
                    Haptics.commit();
                    ref.read(settingsProvider.notifier).setSkin(s);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A theme as a small, quiet swatch: its poster wash fading into its ground,
/// with the accent as a single dot. (The full posters live in the picker.)
class _ThemeDot extends StatelessWidget {
  const _ThemeDot({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final DripSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const box = _ThemeBarState._dot + 6;
    return Tap(
      onTap: onTap,
      scale: 0.92,
      semanticLabel: '${skin.label}${selected ? ', current theme' : ''}',
      child: SizedBox(
        width: box,
        height: box,
        child: Center(
          child: AnimatedContainer(
            duration: Motion.quick,
            curve: Motion.out,
            width: selected ? box : _ThemeBarState._dot,
            height: selected ? box : _ThemeBarState._dot,
            padding: EdgeInsets.all(selected ? 3 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.cream.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.12),
                width: selected ? 1.5 : 0.75,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(skin.ground, skin.wash, 0.75)!,
                    skin.ground,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: skin.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
