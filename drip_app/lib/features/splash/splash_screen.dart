import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../session/session_controller.dart';

/// "Launch sequence": the vibe-seal counter runs to 100%, then routes to the
/// app (returning users) or the welcome screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    _progress
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      })
      ..forward();
  }

  void _next() {
    if (!mounted) return;
    final session = ref.read(sessionProvider);
    context.go(session.signedIn ? '/home' : '/welcome');
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.elevated),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Drip',
                              style: AppText.fredoka(
                                90,
                                letterSpacing: -4,
                                lineHeight: 80,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Text(
                              'ESTD 2077',
                              style: AppText.mono(
                                10,
                                color: AppColors.red,
                                letterSpacing: 4.9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        '✦ LAUNCH SEQUENCE ACTIVE ✦',
                        textAlign: TextAlign.center,
                        style: AppText.mono(
                          11,
                          color: AppColors.cyan,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'STREAMING HIGH-END OUTFIT ARCHIVE...',
                        textAlign: TextAlign.center,
                        style: AppText.manrope(14, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) {
                      final pct =
                          (Curves.easeInOut.transform(_progress.value) * 100)
                              .round();
                      return Text(
                        '$pct%',
                        style: AppText.mono(
                          32,
                          color: AppColors.red,
                          weight: FontWeight.w300,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VIBE SEAL VALIDATED · ESTD 2077',
                    style: AppText.mono(
                      10,
                      color: AppColors.muted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
