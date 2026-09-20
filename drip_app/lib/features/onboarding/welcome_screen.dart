import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/drip_image.dart';
import '../session/session_controller.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = math.max(MediaQuery.paddingOf(context).bottom, 8.0);
    return Scaffold(
      backgroundColor: AppColors.base,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DripImage(Assets.image('welcome_bg')),
          const ColoredBox(color: Color(0xD90E1018)),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const Spacer(flex: 150),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('drip', style: AppText.fredoka(28)),
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'THE FIT FINDS YOU.',
                        style: AppText.bungee(40, lineHeight: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Discover complete outfits curated for your era. Scroll, vibe, and save fits that hit different. No crew required.',
                        style: AppText.manrope(
                          16,
                          color: AppColors.muted,
                          lineHeight: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 110),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        label: 'GET STARTED →',
                        radius: 12,
                        onPressed: () => context.push('/onboarding/intro'),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'I ALREADY HAVE AN ACCOUNT',
                        style: AppButtonStyle.outline,
                        radius: 12,
                        onPressed: () async {
                          await ref
                              .read(sessionProvider.notifier)
                              .signInExisting();
                          if (context.mounted) context.go('/home');
                        },
                      ),
                    ],
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
