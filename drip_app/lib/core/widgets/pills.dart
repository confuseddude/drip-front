import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'tap.dart';

/// Filter / tab pill (Discover categories, Search tabs, notification filters).
///
/// Selection is ink, not accent: the chosen pill fills with the cream "ink"
/// colour, so the skin accent stays reserved for actions and a row of filters
/// never competes with the screen's call to action.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap == null
          ? null
          : () {
              if (!selected) Haptics.tick();
              onTap!();
            },
      semanticLabel: label,
      child: AnimatedContainer(
        duration: Motion.quick,
        curve: Motion.out,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? AppColors.cream : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.cream
                : AppColors.cream.withValues(alpha: 0.10),
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: Motion.quick,
          style: AppText.mono(
            10.5,
            weight: FontWeight.w500,
            letterSpacing: 0.9,
            color: selected ? AppColors.base : AppColors.cream,
          ),
          // Hugs its label; centres it when a parent forces a width (Expanded).
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}

/// Segmented control (notification filters, capture source). One cream thumb
/// slides under the labels, so the choice moves instead of blinking between
/// cells. Tapping the selected segment still calls [onTap] (it may act, e.g.
/// reopen the camera).
class DripSegmented extends StatelessWidget {
  const DripSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cream.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: Motion.dur(context, Motion.nav),
            curve: Motion.out,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * selected / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Tap(
                    scale: 0.96,
                    semanticLabel: labels[i],
                    onTap: () {
                      if (i != selected) Haptics.tick();
                      onTap(i);
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: Motion.quick,
                        style: AppText.mono(
                          10.5,
                          weight: FontWeight.w500,
                          letterSpacing: 1,
                          color: i == selected
                              ? AppColors.base
                              : AppColors.muted,
                        ),
                        child: Text(labels[i], maxLines: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small read-only tag (`#Y2K`, `SLIGHT GLOW`, …).
class TagChip extends StatelessWidget {
  const TagChip(
    this.label, {
    super.key,
    this.color = AppColors.muted,
    this.borderColor,
    this.fill = AppColors.base,
  });

  final String label;
  final Color color;
  final Color? borderColor;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor ?? AppColors.elevated),
      ),
      child: Text(
        label,
        style: AppText.mono(10, color: color, letterSpacing: 0.6),
      ),
    );
  }
}
