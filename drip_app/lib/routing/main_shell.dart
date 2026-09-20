import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/bottom_nav.dart';

/// Which tab / bar style each route shows. The Figma file marks the active tab
/// per screen, so this table mirrors it.
NavSpec navSpecFor(String path) {
  bool starts(String p) => path == p || path.startsWith('$p/');

  if (starts('/home')) return const NavSpec(active: NavTab.drip);
  if (starts('/discover')) {
    return const NavSpec(active: NavTab.discover, pill: true);
  }
  if (starts('/search')) return const NavSpec(active: NavTab.discover);
  if (starts('/studio')) return const NavSpec(creamPlus: true);
  if (starts('/wardrobe') || starts('/saved') || starts('/outfit')) {
    return const NavSpec(active: NavTab.wardrobe);
  }
  if (starts('/photoshoot')) return const NavSpec(active: NavTab.drip);
  if (starts('/me') ||
      starts('/u') ||
      starts('/followers') ||
      starts('/following') ||
      starts('/activity') ||
      starts('/settings')) {
    return const NavSpec(active: NavTab.you);
  }
  return const NavSpec();
}

/// Hosts every screen that shows the bottom navigation bar.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.path});

  final Widget child;
  final String path;

  static const _tabRoutes = {
    NavTab.drip: '/home',
    NavTab.discover: '/discover',
    NavTab.wardrobe: '/wardrobe',
    NavTab.you: '/me',
  };

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: AppColors.base,
      resizeToAvoidBottomInset: true,
      body: child,
      bottomNavigationBar: keyboardOpen
          ? null
          : DripBottomNav(
              spec: navSpecFor(path),
              onTab: (tab) {
                final target = _tabRoutes[tab]!;
                if (!path.startsWith(target)) context.go(target);
              },
              onCreate: () {
                if (!path.startsWith('/create')) context.push('/create');
              },
            ),
    );
  }
}

/// Screen body used inside the shell: dark background, top safe-area padding.
class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.base,
      child: SafeArea(bottom: false, child: child),
    );
  }
}
