import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'tap.dart';

/// Filter / tab pill: accent-filled when selected, surface + hairline otherwise
/// (Discover categories, Search tabs, notification filters).
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.radius = 12,
    this.selectedColor,
    this.selectedTextColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.textStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double radius;
  final Color? selectedColor;
  final Color? selectedTextColor;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final fill = selectedColor ?? context.palette.accent;
    final base = textStyle ?? AppText.mono(10, weight: FontWeight.w500);
    return Tap(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? fill : AppColors.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? AppColors.transparent : AppColors.elevated,
          ),
        ),
        child: Text(
          label,
          style: base.copyWith(
            color: selected
                ? (selectedTextColor ?? AppColors.base)
                : AppColors.cream,
          ),
        ),
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
    this.borderColor = AppColors.elevated,
    this.fill = AppColors.base,
    this.radius = 6,
    this.size = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  final String label;
  final Color color;
  final Color borderColor;
  final Color fill;
  final double radius;
  final double size;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: Text(label, style: AppText.mono(size, color: color)),
    );
  }
}
