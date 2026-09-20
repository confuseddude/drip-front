import '../../core/constants/assets.dart';
import '../../core/theme/app_colors.dart';
import '../models/user.dart';

/// Mock accounts. Replace with the users API once the backend exists.
abstract final class MockUsers {
  static const meHandle = 'taylor_drip';

  static final me = DripUser(
    id: 'u_me',
    name: 'Taylor Vance',
    handle: meHandle,
    avatar: Assets.image('avatar_taylor_vance'),
    bio: 'AI Fashion Stylist & Curator based in Sector 77. Coding fits that look premium.',
    badge: 'Verified AI Stylist',
    followers: 4200,
    following: 180,
    styleScore: 98,
    styleDna: const [
      'Y2K ERA',
      'FUTURE CYBER',
      'STREET COUTURE',
      'VINTAGE GRAIN',
    ],
    palette: const [
      AppColors.base,
      AppColors.red,
      AppColors.cyan,
      AppColors.cream,
    ],
    location: 'Sector 77',
  );

  static final sofia = DripUser(
    id: 'u_sofia',
    name: 'Sofia Mae',
    handle: 'sofiamae',
    avatar: Assets.image('avatar_sofia_profile'),
    bio: 'Co-founder of NeoGrunge. Heavy outerwear, layered knits, Y2K core enthusiast.',
    tagline: 'NEO GRUNGE · LAYERED',
    badge: 'Curator',
    followers: 12400,
    following: 512,
    styleScore: 95,
    styleDna: const ['NEO GRUNGE', 'LAYERED COUTURE', 'Y2K CLASSIC'],
    palette: const [
      AppColors.base,
      AppColors.red,
      AppColors.cyan,
      AppColors.cream,
    ],
  );

  static final ghost = DripUser(
    id: 'u_ghost',
    name: 'Ghost_Thread',
    handle: 'ghost_tech',
    avatar: Assets.image('avatar_ghost_thread'),
    tagline: 'CYBER CORE · GLOW',
    badge: 'Creator',
    isPrivate: true,
  );

  static final neo = DripUser(
    id: 'u_neo',
    name: 'Luka Vance',
    handle: 'neo_grunge_77',
    avatar: Assets.image('avatar_luka_vance'),
    bio: 'Chrome heavyweights and tech layers. Sector 77 native.',
    tagline: 'NEO GRUNGE · MOTO',
    followers: 9800,
    following: 240,
    styleScore: 94,
    styleDna: const ['NEO GRUNGE', 'MOTO', 'CHROME'],
    palette: const [AppColors.base, AppColors.cyan, AppColors.cream],
  );

  static final zayid = DripUser(
    id: 'u_zayid',
    name: 'Zayid Khan',
    handle: 'zayidk',
    avatar: Assets.image('avatar_zayid_khan'),
    bio: 'Technical layers. Tokyo grunge.',
    tagline: 'Y2K STREET · OVERSIZED',
    followers: 15200,
    following: 301,
    styleScore: 98,
    styleDna: const ['Y2K STREET', 'OVERSIZED', 'TECHNICAL'],
    palette: const [AppColors.base, AppColors.red, AppColors.cream],
  );

  static final luna = DripUser(
    id: 'u_luna',
    name: 'Luna Void',
    handle: 'lxna.fits',
    avatar: Assets.image('avatar_luna_void'),
    bio: 'Future cyber. Chrome everything.',
    tagline: 'FUTURE CYBER · CHROME',
    followers: 7300,
    following: 410,
    styleScore: 95,
    styleDna: const ['FUTURE CYBER', 'CHROME'],
    palette: const [AppColors.base, AppColors.cyan, AppColors.cream],
  );

  static final kenji = DripUser(
    id: 'u_kenji',
    name: 'Kenji',
    handle: 'tech_nomad',
    avatar: Assets.image('avatar_kenji'),
    bio: 'Goth core with a drip habit.',
    tagline: 'GOTH CORE · DRIP',
    followers: 3100,
    following: 220,
    styleScore: 89,
    styleDna: const ['GOTH CORE', 'DRIP'],
    palette: const [AppColors.base, AppColors.red, AppColors.cream],
  );

  static final acne = DripUser(
    id: 'u_acne',
    name: 'Acne Studios',
    handle: 'acne_studios',
    avatar: Assets.image('avatar_acne_studios'),
    bio: 'Swedish street. Archive pieces.',
    tagline: 'SWEDISH STREET · ARCHIVE',
    badge: 'Off. Brand',
    followers: 210000,
    following: 12,
    styleScore: 97,
    styleDna: const ['SWEDISH STREET', 'ARCHIVE'],
    palette: const [AppColors.base, AppColors.cream],
  );

  static final era = DripUser(
    id: 'u_era',
    name: 'Era Lookbook',
    handle: 'editorial_era',
    avatar: Assets.image('avatar_era_lookbook'),
    bio: 'Editorial. Vintage grain.',
    tagline: 'EDITORIAL · VINTAGE GRAIN',
    badge: 'Style 91',
    followers: 48000,
    following: 90,
    styleScore: 91,
    styleDna: const ['EDITORIAL', 'VINTAGE GRAIN'],
    palette: const [AppColors.base, AppColors.cream],
  );

  static final hologram = DripUser(
    id: 'u_holo',
    name: 'Cyber Hologram',
    handle: 'cyber_hologram',
    avatar: Assets.image('avatar_cyber_hologram'),
    bio: 'EST. 2077 · Tokyo',
    tagline: 'EST. 2077 · TOKYO',
    followers: 5600,
    following: 130,
    styleScore: 93,
    styleDna: const ['CYBERPUNK', 'TECHWEAR'],
    palette: const [AppColors.base, AppColors.cyan, AppColors.red],
    location: 'Tokyo',
  );

  static final parisMoto = DripUser(
    id: 'u_paris',
    name: 'Paris Moto Club',
    handle: 'parismoto',
    avatar: Assets.image('avatar_parismoto'),
    bio: 'Curated brands. Archive.',
    tagline: 'Curated Brands · Archive',
    followers: 22000,
    following: 66,
    styleScore: 92,
    styleDna: const ['MOTO', 'ARCHIVE'],
    palette: const [AppColors.base, AppColors.cream],
  );

  static final elena = DripUser(
    id: 'u_elena',
    name: 'Elena Rostova',
    handle: 'lxna.fits',
    avatar: Assets.image('avatar_elena'),
    tagline: 'Vintage · Cozy Preppy',
  );

  static List<DripUser> get directory => [
    me,
    sofia,
    ghost,
    neo,
    zayid,
    luna,
    kenji,
    acne,
    era,
    hologram,
    parisMoto,
  ];
}
