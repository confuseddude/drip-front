import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/top_bar.dart';
import '../../routing/main_shell.dart';
import '../settings/settings_controller.dart';

/// "Colour theory" analysis for the signed-in user. The analysis itself comes
/// from the mock below until the analysis API exists.
class ColourTheoryProfileScreen extends ConsumerWidget {
  const ColourTheoryProfileScreen({super.key});

  static const _try = [Color(0xFF39E5A3), Color(0xFF9448FF), Color(0xFFFFF619)];
  static const _avoid = [
    Color(0xFFB28965),
    Color(0xFF625442),
    Color(0xFFAA788F),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(settingsProvider.select((s) => s.username));
    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'COLOUR THEORY',
            leading: const BackGlyph(),
            trailing: GlyphButton(
              '🎨',
              label: 'Palette',
              onTap: () =>
                  showDripToast(context, 'Palette locked to your analysis'),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'ANALYSIS FOR @$username',
                        style: AppText.mono(11, color: AppColors.cyan),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'MIDNIGHT RADAR',
                        textAlign: TextAlign.center,
                        style: AppText.display(22),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your skin tone and style history map to high-contrast cold pigments with saturated electric accents.',
                        textAlign: TextAlign.center,
                        style: AppText.manrope(
                          13,
                          color: AppColors.muted,
                          lineHeight: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.elevated),
                      bottom: BorderSide(color: AppColors.elevated),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel(
                        'PRIMARY HERO HIGHLIGHTS',
                        size: 9,
                        letterSpacing: 0,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _HeroSwatch(
                              label: 'Drip Red',
                              color: AppColors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HeroSwatch(
                              label: 'Future Cyan',
                              color: AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SectionLabel(
                        'YOUR UNDERSTATED NEUTRALS',
                        size: 9,
                        letterSpacing: 0,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _Neutral(
                              name: 'Ink Ground',
                              hex: '#0E1018',
                              fill: AppColors.surface,
                              dark: false,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _Neutral(
                              name: 'Cream Off',
                              hex: '#E8DFC8',
                              fill: AppColors.cream,
                              dark: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: _Recommendation(
                          title: '✓ COLS TO TRY',
                          titleColor: AppColors.cyan,
                          swatches: _try,
                          note: 'High saturation neons offset the dark base fabrics.',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Recommendation(
                          title: '✕ COLS TO AVOID',
                          titleColor: AppColors.red,
                          swatches: _avoid,
                          note: 'Muted earth tones wash out the cyber-futurist contrast.',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: AppButton(
                    label: 'USE MY PALETTE IN STUDIO ✦',
                    color: AppColors.cyan,
                    height: 41,
                    radius: 16,
                    textStyle: AppText.display(11),
                    onPressed: () {
                      showDripToast(context, 'Palette loaded into the Studio');
                      context.push('/studio');
                    },
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

class _HeroSwatch extends StatelessWidget {
  const _HeroSwatch({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppText.mono(10, color: AppColors.base, weight: FontWeight.w500),
      ),
    );
  }
}

class _Neutral extends StatelessWidget {
  const _Neutral({
    required this.name,
    required this.hex,
    required this.fill,
    required this.dark,
  });
  final String name;
  final String hex;
  final Color fill;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: dark ? null : Border.all(color: AppColors.elevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppText.mono(
              9,
              color: dark ? AppColors.base : AppColors.cream,
              weight: dark ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hex,
            style: AppText.mono(
              8,
              color: dark
                  ? AppColors.base.withValues(alpha: 0.6)
                  : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({
    required this.title,
    required this.titleColor,
    required this.swatches,
    required this.note,
  });
  final String title;
  final Color titleColor;
  final List<Color> swatches;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.elevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.mono(9, color: titleColor)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final c in swatches)
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: AppText.manrope(10, color: AppColors.muted, lineHeight: 14),
          ),
        ],
      ),
    );
  }
}
