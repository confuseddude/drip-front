import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/settings_controller.dart';
import 'routing/app_router.dart';

class DripApp extends ConsumerWidget {
  const DripApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Drip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(skin),
      routerConfig: router,
    );
  }
}
