import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'tap.dart';

/// Onboarding progress: the active step is a 24×6 accent pill, the rest 6×6.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.current, this.count = 6});
  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: i == current ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == current ? accent : AppColors.elevated,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 44×24 toggle from the Settings screen.
class DripSwitch extends StatelessWidget {
  const DripSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      semanticLabel: value ? 'On' : 'Off',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? context.palette.accent : AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Filled text field in the Drip style (search bars, captions, sheets).
class DripField extends StatelessWidget {
  const DripField({
    super.key,
    this.controller,
    this.hint,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.radius = 16,
    this.autofocus = false,
    this.borderColor = AppColors.elevated,
    this.hintColor = AppColors.muted,
    this.textStyle,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.errorText,
  });

  final TextEditingController? controller;
  final String? hint;
  final Widget? leading;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final double radius;
  final bool autofocus;
  final Color borderColor;
  final Color hintColor;
  final TextStyle? textStyle;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final EdgeInsetsGeometry padding;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? AppText.manrope(13);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: errorText != null ? AppColors.red : borderColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: maxLines == 1
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  obscureText: obscureText,
                  cursorColor: context.palette.accent,
                  style: style,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: style.copyWith(color: hintColor),
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: AppText.mono(10, color: AppColors.red),
            ),
          ),
      ],
    );
  }
}
