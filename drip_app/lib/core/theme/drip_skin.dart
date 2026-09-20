import 'dart:ui';

import 'app_colors.dart';

/// A selectable "Vibe Skin" (Settings → Appearance). Every skin shares the
/// Drip base palette and only swaps the accent colour used for primary actions,
/// active states and toggles.
enum DripSkin {
  retroCyber('retro-cyber', 'Retro-Cyber 2077', AppColors.red, AppColors.cyan),
  auroraCyan('aurora-cyan', 'Aurora Cyan', AppColors.cyan, AppColors.red),
  vaultCream('vault-cream', 'Vault Cream', AppColors.cream, AppColors.cyan);

  const DripSkin(this.id, this.label, this.accent, this.secondary);

  final String id;
  final String label;

  /// Primary action colour (buttons, active pills, toggles, plus button).
  final Color accent;

  /// Secondary highlight colour shown in the palette preview.
  final Color secondary;

  static DripSkin fromId(String? id) => DripSkin.values.firstWhere(
    (s) => s.id == id,
    orElse: () => DripSkin.retroCyber,
  );
}
