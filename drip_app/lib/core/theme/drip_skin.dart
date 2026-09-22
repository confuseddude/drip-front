import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// The headline typeface a theme speaks in.
enum DisplayFace {
  /// Chunky, poster-like caps (the original DRIP voice).
  bungee,

  /// Soft, rounded and friendly.
  fredoka,

  /// Clean, tight, editorial.
  manrope,
}

/// A selectable "Vibe Skin" (Settings → Appearance).
///
/// Every skin shares the Drip information architecture; a skin is a *world*
/// with its own character, not just a colour swap:
///
///  * **ground** – the tinted near-black the whole app sits on (blue-black,
///    oxblood-black, moss-black …) and that the glass is built from.
///  * **accent / secondary** – used sparingly: active states, the create
///    button, story rings, links.
///  * **wash + aura** – the poster's mid-tone and where its light falls in the
///    backdrop, so every theme has a different composition.
///  * **clarity** – how the glass feels: 0 is frosted paper, 1 is clear crystal.
///  * **roundness** – how soft the glass corners are: archival themes are
///    squarer, bloom themes are pillowy.
///  * **face** – the headline typeface: poster caps, soft rounded, or clean
///    editorial.
///  * **surfaces** – cards, inputs and chips are re-derived from the ground.
///
/// The first three keep their original ids so previously saved choices load.
/// [retroCyber] is the default and uses the black/white/red/blue flare poster.
enum DripSkin {
  retroCyber(
    id: 'retro-cyber',
    label: 'Retro-Cyber 2077',
    tagline: 'The original. Black, white, red and blue.',
    asset: 'retro_cyber',
    accent: AppColors.red,
    secondary: AppColors.cyan,
    wash: Color(0xFF243A7A),
    ground: AppColors.base,
    aura: Alignment(0, -1.05),
    clarity: 0.5,
    roundness: 1.0,
    face: DisplayFace.bungee,
  ),
  auroraCyan(
    id: 'aurora-cyan',
    label: 'Aurora Cyan',
    tagline: 'Deep midnight, cold cyan edge.',
    asset: 'aurora_cyan',
    accent: AppColors.cyan,
    secondary: AppColors.red,
    wash: Color(0xFF15206B),
    ground: Color(0xFF0A1122),
    aura: Alignment(0.8, -1.0),
    clarity: 0.7,
    roundness: 1.0,
    face: DisplayFace.manrope,
  ),
  vaultCream(
    id: 'vault-cream',
    label: 'Vault Cream',
    tagline: 'Archive parchment, ink-blue lines.',
    asset: 'vault_cream',
    accent: AppColors.cream,
    secondary: AppColors.cyan,
    wash: Color(0xFF7A6A46),
    ground: Color(0xFF14120E),
    aura: Alignment(-0.9, -0.95),
    clarity: 0.15,
    roundness: 0.6,
    face: DisplayFace.manrope,
  ),
  indigoMarble(
    id: 'indigo-marble',
    label: 'Indigo Marble',
    tagline: 'Liquid denim-blue veins.',
    asset: 'indigo_marble',
    accent: Color(0xFF9DB9FF),
    secondary: Color(0xFFE3D7BE),
    wash: Color(0xFF223E78),
    ground: Color(0xFF0B1024),
    aura: Alignment(0.9, -0.7),
    clarity: 0.6,
    roundness: 1.0,
    face: DisplayFace.manrope,
  ),
  denimStars(
    id: 'denim-stars',
    label: 'Denim Stars',
    tagline: 'Stitched star patches on raw denim.',
    asset: 'denim_stars',
    accent: Color(0xFF7FB6EE),
    secondary: Color(0xFFE8D8B8),
    wash: Color(0xFF244C7A),
    ground: Color(0xFF0B131F),
    aura: Alignment(-0.85, -1.0),
    clarity: 0.45,
    roundness: 0.85,
    face: DisplayFace.bungee,
  ),
  goldenHour(
    id: 'golden-hour',
    label: 'Golden Hour',
    tagline: 'Blue haze, late-sun gold.',
    asset: 'golden_hour',
    accent: Color(0xFFF3C98B),
    secondary: Color(0xFF7FA6D9),
    wash: Color(0xFF3B5F86),
    ground: Color(0xFF10151F),
    aura: Alignment(0.75, -1.1),
    clarity: 0.6,
    roundness: 1.0,
    face: DisplayFace.fredoka,
  ),
  crimsonTeal(
    id: 'crimson-teal',
    label: 'Crimson Teal',
    tagline: 'Velvet red, verdigris lettering.',
    asset: 'crimson_teal',
    accent: Color(0xFF5CC9B0),
    secondary: Color(0xFFF0D5B5),
    wash: Color(0xFF8C2323),
    ground: Color(0xFF170B0E),
    aura: Alignment(0, -1.1),
    clarity: 0.4,
    roundness: 0.9,
    face: DisplayFace.bungee,
  ),
  violetBloom(
    id: 'violet-bloom',
    label: 'Violet Bloom',
    tagline: 'Stage-light violet, bubblegum pink.',
    asset: 'violet_bloom',
    accent: Color(0xFFFFB3D1),
    secondary: Color(0xFFB99CFF),
    wash: Color(0xFF6A3A82),
    ground: Color(0xFF130C1C),
    aura: Alignment(-0.7, -1.0),
    clarity: 0.75,
    roundness: 1.15,
    face: DisplayFace.fredoka,
  ),
  acidLime(
    id: 'acid-lime',
    label: 'Acid Lime',
    tagline: 'Grain, smoke and volt green.',
    asset: 'acid_lime',
    accent: Color(0xFFB9F03C),
    secondary: Color(0xFFE9B6F0),
    wash: Color(0xFF5A5478),
    ground: Color(0xFF0F110B),
    aura: Alignment(0.8, -0.9),
    clarity: 0.4,
    roundness: 0.8,
    face: DisplayFace.bungee,
  ),
  mossArchive(
    id: 'moss-archive',
    label: 'Moss Archive',
    tagline: 'Plaster green, burnt-orange stamp.',
    asset: 'moss_archive',
    accent: Color(0xFFF58B3A),
    secondary: Color(0xFFE8D8B4),
    wash: Color(0xFF3F5E36),
    ground: Color(0xFF0A120C),
    aura: Alignment(-0.9, -0.8),
    clarity: 0.25,
    roundness: 0.7,
    face: DisplayFace.manrope,
  ),
  verdantBlur(
    id: 'verdant-blur',
    label: 'Verdant Blur',
    tagline: 'Motion-blurred canopy.',
    asset: 'verdant_blur',
    accent: Color(0xFFA6E35A),
    secondary: Color(0xFFF08A3C),
    wash: Color(0xFF356B2C),
    ground: Color(0xFF09130A),
    aura: Alignment(0.6, -1.05),
    clarity: 0.55,
    roundness: 1.0,
    face: DisplayFace.fredoka,
  ),
  oxbloodLinen(
    id: 'oxblood-linen',
    label: 'Oxblood Linen',
    tagline: 'Washed linen, oxblood ink.',
    asset: 'oxblood_linen',
    accent: Color(0xFFE27A5C),
    secondary: Color(0xFFE8DFC8),
    wash: Color(0xFF7A5A48),
    ground: Color(0xFF160E0C),
    aura: Alignment(0.9, -0.95),
    clarity: 0.2,
    roundness: 0.75,
    face: DisplayFace.manrope,
  ),
  holoPink(
    id: 'holo-pink',
    label: 'Holo Pink',
    tagline: 'Iridescent foil, hot magenta.',
    asset: 'holo_pink',
    accent: Color(0xFFF456D4),
    secondary: Color(0xFF6FE0E0),
    wash: Color(0xFF3C3E8C),
    ground: Color(0xFF110D1B),
    aura: Alignment(-0.5, -1.1),
    clarity: 0.9,
    roundness: 1.15,
    face: DisplayFace.fredoka,
  );

  const DripSkin({
    required this.id,
    required this.label,
    required this.tagline,
    required this.asset,
    required this.accent,
    required this.secondary,
    required this.wash,
    required this.ground,
    required this.aura,
    required this.clarity,
    required this.roundness,
    required this.face,
  });

  final String id;
  final String label;

  /// One-line personality shown on the selector card.
  final String tagline;

  /// Basename of the poster / backdrop assets in `assets/themes/`.
  final String asset;

  /// Primary action colour (create button, active states, links).
  final Color accent;

  /// Secondary highlight colour (story rings, palette preview).
  final Color secondary;

  /// A saturated mid-tone from the poster: tints glass and the backdrop glow.
  final Color wash;

  /// The tinted near-black the app sits on; glass is built from it.
  final Color ground;

  /// Where the poster's light falls in the backdrop.
  final Alignment aura;

  /// Glass feel, 0 (frosted paper) … 1 (clear crystal).
  final double clarity;

  /// Glass corner scale: below 1 is squarer, above 1 is softer.
  final double roundness;

  /// Headline typeface.
  final DisplayFace face;

  /// Selector artwork (560px square poster).
  String get posterAsset => 'assets/themes/poster_$asset.jpg';

  /// Pre-blurred, darkened backdrop texture used behind every shell screen.
  String get backdropAsset => 'assets/themes/bg_$asset.jpg';

  static DripSkin fromId(String? id) => DripSkin.values.firstWhere(
    (s) => s.id == id,
    orElse: () => DripSkin.retroCyber,
  );
}
