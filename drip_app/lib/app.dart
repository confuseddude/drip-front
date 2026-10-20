import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/platform/app_icon.dart';
import 'core/platform/notifications.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/drip_skin.dart';
import 'core/widgets/overlays.dart';
import 'core/widgets/theme_backdrop.dart';
import 'features/session/session_controller.dart';
import 'features/settings/settings_controller.dart';
import 'features/wardrobe/import/import_controller.dart';
import 'routing/app_router.dart';

class DripApp extends ConsumerStatefulWidget {
  const DripApp({super.key});

  @override
  ConsumerState<DripApp> createState() => _DripAppState();
}

class _DripAppState extends ConsumerState<DripApp> {
  bool _built = false;

  @override
  void initState() {
    super.initState();
    // Notifications open where they point (the wardrobe, for an import).
    ref
        .read(notificationsProvider)
        .init(onOpen: (payload) => ref.read(routerProvider).go('/$payload'));
    // A gallery import still running from last time carries on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(sessionProvider).signedIn) {
        ref.read(wardrobeImportProvider.notifier).resume();
      }
    });
  }

  /// "Your wardrobe is ready", unless the screen already says so.
  void _importFinished(GoRouter router) {
    final run = ref.read(wardrobeImportProvider);
    final server = run.server;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (server == null || context == null) return;
    if (path == '/wardrobe' || path == '/wardrobe/import') return;
    showDripToast(context, 'Your wardrobe is ready. ${importSummary(server)}');
  }

  /// Marks every element dirty (what a hot reload does), so screens that don't
  /// otherwise listen to the theme still pick up the new surface colours.
  void _rebuildEverything() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinProvider);
    final router = ref.watch(routerProvider);
    // Launcher icon follows the saved theme (debounced; no-op off-device).
    ref.watch(appIconSyncProvider);
    ref.listen(sessionProvider.select((s) => s.signedIn), (was, signedIn) {
      if (signedIn && was != true) {
        ref.read(wardrobeImportProvider.notifier).resume();
      }
    });
    ref.listen(wardrobeImportProvider.select((r) => r.phase), (was, phase) {
      if (phase == ImportPhase.done && was == ImportPhase.processing) {
        _importFinished(router);
      }
    });

    // Cards, inputs and chips take their colour from the theme, and headlines
    // speak in its typeface.
    final faceChanged = AppText.face != skin.face;
    AppText.face = skin.face;
    final surfacesChanged = AppColors.useSurfaces(
      ground: skin.ground,
      wash: skin.wash,
      original: skin == DripSkin.retroCyber,
    );
    if ((surfacesChanged || faceChanged) && _built) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildEverything());
    }
    _built = true;

    return MaterialApp.router(
      title: 'Drip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(skin),
      routerConfig: router,
      // The skin's poster world sits behind every route; shell screens are
      // transparent and let it through, full-screen routes paint over it.
      builder: (context, child) =>
          ThemeBackdrop(skin: skin, child: child ?? const SizedBox.shrink()),
    );
  }
}
