import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'tap.dart';

enum NavTab { drip, discover, wardrobe, you }

/// How the shell renders the bar for the current route (the Figma file varies
/// the active tab, the plus-button colour and, on Discover, the bar style).
class NavSpec {
  const NavSpec({this.active, this.pill = false, this.creamPlus = false});

  final NavTab? active;

  /// Discover's bordered-tab variant.
  final bool pill;

  /// Studio screens tint the plus button cream.
  final bool creamPlus;

  @override
  bool operator ==(Object other) =>
      other is NavSpec &&
      other.active == active &&
      other.pill == pill &&
      other.creamPlus == creamPlus;

  @override
  int get hashCode => Object.hash(active, pill, creamPlus);
}

class DripBottomNav extends StatelessWidget {
  const DripBottomNav({
    super.key,
    required this.spec,
    required this.onTab,
    required this.onCreate,
  });

  final NavSpec spec;
  final ValueChanged<NavTab> onTab;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    // Matches the 32px home-indicator zone under the bar in the design.
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 32.0);
    final pill = spec.pill;

    Widget tab(NavTab t, String label, String icon) => _NavTabItem(
      label: label,
      icon: icon,
      selected: spec.active == t,
      pill: pill,
      onTap: () => onTab(t),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.base,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(pill ? 24 : 28),
        ),
        border: const Border(top: BorderSide(color: AppColors.elevated)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: pill ? 80 : 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(pill ? 24 : 28),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.elevated),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: tab(NavTab.drip, 'DRIP', Assets.navSparkles),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: tab(NavTab.discover, 'DISCOVER', Assets.navSearch),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _PlusTab(
                      pill: pill,
                      cream: spec.creamPlus,
                      onTap: onCreate,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: tab(
                      NavTab.wardrobe,
                      'WARDROBE',
                      Assets.navBriefcase,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(child: tab(NavTab.you, 'YOU', Assets.navUser)),
                ),
              ],
            ),
          ),
          SizedBox(height: bottom),
        ],
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.pill,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final bool pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.cream : AppColors.muted;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          icon,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          style: AppText.mono(
            9,
            color: color,
            weight: selected ? FontWeight.w500 : FontWeight.w400,
            lineHeight: 12,
          ),
        ),
      ],
    );
    return Tap(
      onTap: onTap,
      semanticLabel: label,
      child: SizedBox(
        width: 64,
        height: pill ? 52 : 36,
        child: pill
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? context.palette.accent : AppColors.base,
                  borderRadius: BorderRadius.circular(16),
                  border: selected
                      ? null
                      : Border.all(color: AppColors.elevated),
                ),
                child: Center(child: content),
              )
            : Center(child: content),
      ),
    );
  }
}

class _PlusTab extends StatelessWidget {
  const _PlusTab({
    required this.pill,
    required this.cream,
    required this.onTap,
  });
  final bool pill;
  final bool cream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = cream ? AppColors.cream : context.palette.accent;
    final button = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        boxShadow: pill
            ? null
            : [
                BoxShadow(
                  color: fill.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: SvgPicture.asset(
        Assets.navPlus,
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(AppColors.base, BlendMode.srcIn),
      ),
    );
    return Tap(
      onTap: onTap,
      semanticLabel: 'Create',
      child: SizedBox(
        width: 64,
        height: pill ? 56 : 44,
        child: pill
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.base,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.elevated),
                ),
                child: Center(child: button),
              )
            : Center(child: button),
      ),
    );
  }
}
