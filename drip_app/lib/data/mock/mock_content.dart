import '../../core/constants/assets.dart';
import '../models/notification.dart';
import '../models/ootd.dart';
import '../models/outfit.dart';
import '../models/stylist.dart';
import '../models/user.dart';
import '../models/wardrobe.dart';
import 'mock_users.dart';

/// Mock catalogue: outfits, feed posts, wardrobe, activity and stylist data.
/// Everything here is development seed data and is only ever read through the
/// repositories in `lib/data/repositories`.
abstract final class MockContent {
  static String _img(String n) => Assets.image(n);

  // ---------------------------------------------------------------- outfits

  static const _cyberFlarePieces = [
    OutfitPiece(
      slot: 'TOP',
      name: 'Cyber Shell Waterproof Overcoat',
      brand: 'Preppy Apocalypse',
      price: 189,
    ),
    OutfitPiece(
      slot: 'BOTTOM',
      name: 'Chrome Cargo Loose Track Pants',
      brand: 'Neo-Street',
      price: 110,
    ),
    OutfitPiece(
      slot: 'SHOES',
      name: 'Platform Heavy Boots v2',
      brand: 'Calibrate Estd',
      price: 220,
    ),
  ];

  static const _defaultHotspots = [
    Hotspot(label: 'CYBER SHELL JACKET', x: 0.41, y: 0.25, filled: true),
    Hotspot(label: 'CHROME CARGOS', x: 0.26, y: 0.63, highlighted: true),
  ];

  static List<OutfitPiece> _piecesFor(
    String top,
    String bottom,
    String shoes,
    int total,
  ) => [
    OutfitPiece(
      slot: 'TOP',
      name: top,
      brand: 'Preppy Apocalypse',
      price: (total * 0.45).round(),
    ),
    OutfitPiece(
      slot: 'BOTTOM',
      name: bottom,
      brand: 'Neo-Street',
      price: (total * 0.25).round(),
    ),
    OutfitPiece(
      slot: 'SHOES',
      name: shoes,
      brand: 'Calibrate Estd',
      price: total - (total * 0.45).round() - (total * 0.25).round(),
    ),
  ];

  static final List<Outfit> outfits = [
    Outfit(
      id: 'o_baggy',
      title: 'BAGGY ERA FIT',
      image: _img('discover_baggy_era'),
      price: 310,
      rate: 92,
      creatorHandle: 'zayidk',
      tags: const ['GRUNGE', 'BAGGY', 'Y2K'],
      categories: const ['Y2K', 'GRUNGE', 'STREET'],
      pieces: _piecesFor(
        'Washed Boxy Bomber',
        'Baggy Era Denim',
        'Distressed Combat Boots',
        310,
      ),
      isLiked: true,
    ),
    Outfit(
      id: 'o_pastel',
      title: 'PASTEL SHOCK',
      image: _img('discover_pastel_shock'),
      price: 215,
      rate: 89,
      creatorHandle: 'sofiamae',
      tags: const ['PASTEL', 'Y2K', 'MINIMAL'],
      categories: const ['Y2K', 'MINIMAL', 'VINTAGE'],
      pieces: _piecesFor(
        'Knit Stripe Cardigan',
        'Pleated Trouser',
        'Suede Derby',
        215,
      ),
    ),
    Outfit(
      id: 'o_gray',
      title: 'GRAY OVERCOAT',
      image: _img('discover_gray_overcoat'),
      price: 440,
      rate: 95,
      creatorHandle: 'lxna.fits',
      tags: const ['MINIMAL', 'TAILORED'],
      categories: const ['Y2K', 'MINIMAL', 'VINTAGE'],
      pieces: _piecesFor(
        'Gray Wool Overcoat',
        'Slate Slim Trouser',
        'Leather Chelsea',
        440,
      ),
    ),
    Outfit(
      id: 'o_tokyo',
      title: 'TOKYO NEON GRID',
      image: _img('discover_tokyo_neon'),
      price: 390,
      rate: 97,
      creatorHandle: 'zayidk',
      tags: const ['CYBERPUNK', 'TOKYO', 'NEON'],
      categories: const ['Y2K', 'STREET', 'GRUNGE'],
      pieces: _piecesFor(
        'Holo Coach Jacket',
        'Grid Cargo Pant',
        'Tech Runner',
        390,
      ),
      isLiked: true,
    ),
    Outfit(
      id: 'o_cyber_flare',
      title: 'CYBER FLARE v2',
      image: _img('outfit_cyber_flare_hero'),
      price: 519,
      rate: 98,
      creatorHandle: 'neo_grunge_77',
      tags: const ['TECHWEAR', 'Y2K', 'STREET'],
      categories: const ['Y2K', 'STREET'],
      pieces: _cyberFlarePieces,
      hotspots: _defaultHotspots,
    ),
    Outfit(
      id: 'o_cyber_shell',
      title: 'CYBER SHELL V1',
      image: _img('result_cyber_shell'),
      price: 320,
      rate: 94,
      creatorHandle: 'k1ra',
      tags: const ['CYBERPUNK', 'TECHWEAR'],
      categories: const ['STREET', 'Y2K'],
      pieces: _piecesFor(
        'Cyber Shell Jacket',
        'Reflective Track Pant',
        'Neon Sole Sneaker',
        320,
      ),
      isLiked: true,
    ),
    Outfit(
      id: 'o_neo_cargo',
      title: 'NEO CARGO PANTS',
      image: _img('result_neo_cargo'),
      price: 150,
      rate: 90,
      creatorHandle: 'zay',
      tags: const ['CARGO', 'CYBERPUNK', 'TECHWEAR'],
      categories: const ['STREET', 'GRUNGE'],
      pieces: _piecesFor(
        'Utility Harness Top',
        'Neo Cargo Pants',
        'Lug Sole Boots',
        150,
      ),
    ),
    Outfit(
      id: 'o_chrome',
      title: 'CHROME HEAVYWEIGHTS',
      image: _img('ootd_chrome_heavyweights'),
      price: 390,
      rate: 98,
      creatorHandle: 'neo_grunge_77',
      tags: const ['Y2K', 'STREETWEAR', 'CYBER'],
      categories: const ['Y2K', 'STREET'],
      pieces: _piecesFor(
        'Heavyweight Puffer',
        'Chrome Cargo Pants',
        'Platform Boots',
        390,
      ),
      isLiked: true,
    ),
    Outfit(
      id: 'o_parachute',
      title: 'MILITARY PARACHUTE',
      image: _img('sofia_fit_1'),
      price: 280,
      rate: 93,
      creatorHandle: 'sofiamae',
      tags: const ['MILITARY', 'GRUNGE', 'STREET'],
      categories: const ['GRUNGE', 'STREET'],
      pieces: _piecesFor(
        'Parachute Field Jacket',
        'Ripstop Cargo',
        'Combat Boot',
        280,
      ),
      isLiked: true,
    ),
    Outfit(
      id: 'o_cyber_era',
      title: 'CYBERPUNK ERA FIT',
      image: _img('profile_fit_1'),
      price: 490,
      rate: 96,
      creatorHandle: 'lxna.fits',
      tags: const ['CYBERPUNK', 'Y2K'],
      categories: const ['Y2K', 'STREET'],
      pieces: _piecesFor(
        'Era Neon Bomber',
        'Cyber Skirt Cargo',
        'Chrome Platform',
        490,
      ),
    ),
    Outfit(
      id: 'o_cobalt',
      title: 'COBALT BIKER LOOK',
      image: _img('look_cobalt_biker'),
      price: 460,
      rate: 91,
      creatorHandle: 'sofiamae',
      tags: const ['BIKER', 'COBALT', 'VINTAGE'],
      categories: const ['VINTAGE', 'STREET'],
      pieces: _piecesFor(
        'Cobalt Biker Jacket',
        'Black Straight Denim',
        'Moto Boots',
        460,
      ),
    ),
    Outfit(
      id: 'o_moto',
      title: 'MOTO CYBERPUNK',
      image: _img('look_moto_cyberpunk'),
      price: 520,
      rate: 94,
      creatorHandle: 'parismoto',
      tags: const ['MOTO', 'CYBERPUNK', 'GRUNGE'],
      categories: const ['GRUNGE', 'STREET'],
      pieces: _piecesFor(
        'Moto Race Jacket',
        'Armor Knee Pants',
        'Track Boots',
        520,
      ),
    ),
    Outfit(
      id: 'o_vintage_oversize',
      title: 'VINTAGE OVERSIZE',
      image: _img('profile_fit_2'),
      price: 340,
      rate: 88,
      creatorHandle: 'editorial_era',
      tags: const ['VINTAGE', 'OVERSIZED', 'EDITORIAL'],
      categories: const ['VINTAGE', 'MINIMAL'],
      pieces: _piecesFor(
        'Oversize Tweed Blazer',
        'Wide Leg Wool Pant',
        'Penny Loafer',
        340,
      ),
    ),
    Outfit(
      id: 'o_raw_hoodie',
      title: 'RAW EDGE GREY HOODIE',
      image: _img('sofia_fit_2'),
      price: 175,
      rate: 86,
      creatorHandle: 'sofiamae',
      tags: const ['MINIMAL', 'STREET', 'RAW'],
      categories: const ['MINIMAL', 'STREET', 'GRUNGE'],
      pieces: _piecesFor(
        'Raw Edge Zip Hoodie',
        'Concrete Sweat Pant',
        'Court Sneaker',
        175,
      ),
    ),
    Outfit(
      id: 'o_moto_night',
      title: 'MOTO NIGHT FLARE',
      image: _img('ootd_moto_night_flare'),
      price: 480,
      rate: 94,
      creatorHandle: 'zayidk',
      tags: const ['TECHWEAR', 'MOTO', 'NIGHT'],
      categories: const ['STREET', 'GRUNGE'],
      pieces: _piecesFor(
        'Reflective Tactical Hood',
        'Tech Pants',
        'Tactical Gloves Set',
        480,
      ),
    ),
  ];

  /// Ids of looks the signed-in user has saved (Saved Looks screen).
  static const savedOutfitIds = [
    'o_chrome',
    'o_tokyo',
    'o_parachute',
    'o_cyber_era',
    'o_cyber_shell',
    'o_cobalt',
  ];

  static const discoverCategories = [
    'Y2K',
    'STREET',
    'GRUNGE',
    'MINIMAL',
    'VINTAGE',
  ];

  static const trendingVibes = [
    'Y2K OUTFITS',
    'TOKYO STREET',
    'MOTO CORE',
    'PREPPY APOCALYPSE',
    'HEAVY METAL GLAM',
  ];

  static const seedRecentSearches = [
    '@neo_grunge_77',
    'Baggy Cargo Pants',
    'Vintage Cyber Goggles',
    'Oversized Leather Coat',
  ];

  /// Curated collections shown in the Search Results "COLLECTIONS" tab.
  static const collections = [
    (id: 'c_neon', title: 'NEON SECTOR 77', count: 24, tag: 'CYBERPUNK'),
    (id: 'c_shell', title: 'SHELL & CARGO', count: 18, tag: 'TECHWEAR'),
    (id: 'c_night', title: 'TOKYO AFTER DARK', count: 31, tag: 'TOKYO'),
  ];

  // -------------------------------------------------------------- feed

  static final List<Ootd> feed = [
    Ootd(
      id: 'ootd_chrome',
      creatorHandle: 'neo_grunge_77',
      creatorAvatar: _img('avatar_neo_grunge'),
      image: _img('ootd_chrome_heavyweights'),
      title: 'Chrome Heavyweights Fit',
      era: 'CYBER',
      score: 98,
      likes: 12400,
      saves: 8900,
      tags: const ['#Y2K', '#STREETWEAR', '#CYBER'],
      postedAgo: '1H AGO',
      outfitId: 'o_chrome',
      isLiked: true,
    ),
    Ootd(
      id: 'ootd_moto',
      creatorHandle: 'zayidk',
      creatorAvatar: _img('avatar_zayidk_small'),
      image: _img('ootd_moto_night_flare'),
      title: 'MOTO NIGHT FLARE',
      era: 'MOTO',
      score: 94,
      likes: 9300,
      saves: 4100,
      tags: const ['#TECHWEAR', '#MOTO', '#NIGHT'],
      postedAgo: '3H AGO',
      outfitId: 'o_moto_night',
      caption: 'Calibrated with tech pants, premium tactical gloves and waterproof reflective hood.',
    ),
    Ootd(
      id: 'ootd_cobalt',
      creatorHandle: 'sofiamae',
      creatorAvatar: _img('story_sofiamae'),
      image: _img('look_cobalt_biker'),
      title: 'Cobalt Biker Look',
      era: 'Y2K',
      score: 91,
      likes: 7800,
      saves: 3200,
      tags: const ['#BIKER', '#COBALT', '#VINTAGE'],
      postedAgo: '5H AGO',
      outfitId: 'o_cobalt',
      caption: 'Cobalt leather over everything. Layers first, questions later.',
    ),
    Ootd(
      id: 'ootd_tokyo',
      creatorHandle: 'lxna.fits',
      creatorAvatar: _img('story_lxnafits'),
      image: _img('discover_tokyo_neon'),
      title: 'Tokyo Neon Grid',
      era: 'CYBER',
      score: 97,
      likes: 15600,
      saves: 9700,
      tags: const ['#TOKYO', '#NEON', '#CYBERPUNK'],
      postedAgo: '8H AGO',
      outfitId: 'o_tokyo',
      caption: 'Grid lights, holo coach jacket. Last night in Shibuya.',
    ),
    Ootd(
      id: 'ootd_paris',
      creatorHandle: 'parismoto',
      creatorAvatar: _img('story_parismoto'),
      image: _img('look_moto_cyberpunk'),
      title: 'Moto Cyberpunk',
      era: 'GRUNGE',
      score: 94,
      likes: 6100,
      saves: 2500,
      tags: const ['#MOTO', '#CYBERPUNK', '#GRUNGE'],
      postedAgo: '11H AGO',
      outfitId: 'o_moto',
      caption: 'Paris Moto Club Sunday ride fit.',
    ),
  ];

  static final List<Story> stories = [
    Story(
      handle: 'sofiamae',
      avatar: _img('story_sofiamae'),
      unseen: true,
      ootdId: 'ootd_cobalt',
    ),
    Story(handle: 'zayidk', avatar: _img('story_zayidk'), ootdId: 'ootd_moto'),
    Story(
      handle: 'lxna.fits',
      avatar: _img('story_lxnafits'),
      ootdId: 'ootd_tokyo',
    ),
    Story(
      handle: 'parismoto',
      avatar: _img('story_parismoto'),
      ootdId: 'ootd_paris',
    ),
  ];

  // ------------------------------------------------------------ wardrobe

  static final List<WardrobeItem> wardrobe = [
    WardrobeItem(
      id: 'w_puff',
      name: 'Crop Puff Jacket',
      category: 'Outerwear',
      image: _img('wardrobe_crop_puff'),
      status: 'EXTRACTED · 3D READY',
      brand: 'Neo-Street',
      colorway: 'Onyx Black',
      price: 260,
      tags: const ['CROPPED', 'PUFFER', 'HEAVYWEIGHT'],
    ),
    WardrobeItem(
      id: 'w_hoodie',
      name: 'Vintage Hoodie',
      category: 'Tops',
      image: _img('wardrobe_vintage_hoodie'),
      status: 'EXTRACTED · 3D READY',
      brand: 'Era Lookbook',
      colorway: 'Washed Grey',
      price: 120,
      tags: const ['VINTAGE', 'COTTON', 'Y2K'],
    ),
    WardrobeItem(
      id: 'w_boots',
      name: 'Chunky Platform Boots',
      category: 'Boots',
      image: _img('wardrobe_chunky_boots'),
      status: 'BOOTS · UPLOADED',
      brand: 'Calibrate Estd',
      colorway: 'Black Chrome',
      price: 220,
      tags: const ['PLATFORM', 'HEAVYWEIGHT'],
      section: 'BOOTS',
    ),
    WardrobeItem(
      id: 'w_biker',
      name: 'Tough Leather Biker',
      category: 'Outerwear',
      image: _img('item_leather_biker'),
      status: 'EXTRACTED · 3D READY',
      brand: 'Acne Studios',
      colorway: 'Midnight Black',
      price: 420,
      tags: const [
        'CLASSIC LEATHER',
        'Y2K STREET',
        'SLIGHT GLOW',
        'HEAVYWEIGHT',
      ],
    ),
    WardrobeItem(
      id: 'w_cobalt',
      name: 'Cobalt Oversized',
      category: 'Outerwear',
      image: _img('shoot_cobalt_oversized'),
      status: 'EXTRACTED · 3D READY',
      brand: 'Neo-Street',
      colorway: 'Cobalt Blue',
      price: 390,
      tags: const ['OVERSIZED', 'PUFFER', 'COBALT'],
    ),
    WardrobeItem(
      id: 'w_vest',
      name: 'Tactical Vest',
      category: 'Outerwear',
      image: _img('piece_tactical_vest'),
      status: 'EXTRACTED · 3D READY',
      brand: 'Neo-Street',
      colorway: 'Carbon',
      price: 180,
      tags: const ['TACTICAL', 'UTILITY'],
    ),
    WardrobeItem(
      id: 'w_shell',
      name: 'Shell Jacket',
      category: 'Outerwear',
      image: _img('piece_shell_jacket'),
      status: 'EXTRACTED · 3D READY',
      brand: 'Preppy Apocalypse',
      colorway: 'Navy',
      price: 210,
      tags: const ['WATERPROOF', 'OVERSIZED'],
    ),
  ];

  /// Ids in the "rotation" tab (most-worn pieces).
  static const rotationIds = ['w_biker', 'w_boots', 'w_puff'];

  static const wardrobeCategories = [
    'Outerwear',
    'Tops',
    'Bottoms',
    'Boots',
    'Accessories',
  ];

  /// What the garment-capture screen "detects" once a photo is taken.
  static const detection = GarmentDetection(
    label: 'TOUGH COAT',
    confidence: 99,
    name: 'Classic Leather Biker Jacket',
    category: 'Outerwear',
    description: 'Classic Leather Biker Jacket with hardware accents. Ready to digitize for your look-builder.',
    tags: ['OUTERWEAR', 'LEATHER', 'BLACK', 'Y2K', 'SLIGHT GLOW'],
  );

  static String get captureImage => _img('capture_leather_jacket');

  // ---------------------------------------------------------- activity

  static final List<ActivityItem> activity = [
    ActivityItem(
      id: 'a1',
      kind: NotificationKind.like,
      actor: '@alex_retro',
      avatar: _img('avatar_alex_retro'),
      action: 'liked your OOTD',
      detail: 'Moto Night Fit',
      timeAgo: '2m ago',
    ),
    ActivityItem(
      id: 'a2',
      kind: NotificationKind.follow,
      actor: '@sam_grng',
      avatar: _img('avatar_sam_grng'),
      action: 'started following you',
      detail: 'Sector 77 DNA matched',
      timeAgo: '15m ago',
    ),
    ActivityItem(
      id: 'a3',
      kind: NotificationKind.save,
      actor: '@rai.core',
      avatar: _img('avatar_rai_core'),
      action: 'saved your fit',
      detail: 'Tough Leather Biker',
      timeAgo: '1h ago',
      isRead: true,
    ),
    ActivityItem(
      id: 'a4',
      kind: NotificationKind.drip,
      actor: 'Taylor Vance',
      avatar: _img('avatar_taylor_activity'),
      action: 'created a new fit for you:',
      detail: 'Cobalt Overcoat core',
      timeAgo: '3h ago',
      isRead: true,
    ),
  ];

  // ------------------------------------------------------------ social

  static const followersTotal = 12420;
  static const followingTotal = 512;

  static final List<DripUser> followers = [
    MockUsers.neo,
    MockUsers.zayid,
    MockUsers.luna,
    MockUsers.kenji,
  ];

  static final List<DripUser> following = [
    MockUsers.acne,
    MockUsers.sofia,
    MockUsers.ghost,
    MockUsers.era,
  ];

  /// Handles the signed-in user follows on first launch (drives the mutual /
  /// unfollow state on the Followers and Following screens).
  static const seedFollowing = {
    'acne_studios',
    'sofiamae',
    'ghost_tech',
    'editorial_era',
    'neo_grunge_77',
    'zayidk',
  };

  static final List<DripUser> suggestedCreators = [
    DripUser(
      id: 's_sofia',
      name: 'Sofia Mae',
      handle: 'sofiamae',
      avatar: _img('avatar_sofiamae'),
      tagline: 'Y2K · Paris Editorial',
    ),
    DripUser(
      id: 's_zayid',
      name: 'Zayid Khan',
      handle: 'zayidk',
      avatar: _img('avatar_zayid'),
      tagline: 'Technical · Tokyo Grunge',
    ),
    DripUser(
      id: 's_elena',
      name: 'Elena Rostova',
      handle: 'lxna.fits',
      avatar: _img('avatar_elena'),
      tagline: 'Vintage · Cozy Preppy',
    ),
    DripUser(
      id: 's_paris',
      name: 'Paris Moto Club',
      handle: 'parismoto',
      avatar: _img('avatar_parismoto'),
      tagline: 'Curated Brands · Archive',
    ),
  ];

  /// Posts shown in each profile tab. Falls back to these pools for handles that
  /// have no bespoke content.
  static Map<String, List<Outfit>> profileFits = {
    MockUsers.meHandle: [
      outfits.firstWhere((o) => o.id == 'o_cyber_era'),
      outfits.firstWhere((o) => o.id == 'o_vintage_oversize'),
    ],
    'sofiamae': [
      outfits.firstWhere((o) => o.id == 'o_parachute'),
      outfits.firstWhere((o) => o.id == 'o_raw_hoodie'),
    ],
  };

  // ------------------------------------------------------------- onboarding

  static final List<MoodTile> moods = [
    MoodTile(id: 'y2k', label: 'Y2K', image: _img('mood_y2k')),
    MoodTile(
      id: 'streetwear',
      label: 'Streetwear',
      image: _img('mood_streetwear'),
    ),
    MoodTile(id: 'minimal', label: 'Minimal', image: _img('mood_minimal')),
    MoodTile(id: 'grunge', label: 'Grunge', image: _img('mood_grunge')),
    MoodTile(id: 'vintage', label: 'Vintage', image: _img('mood_vintage')),
    MoodTile(id: 'preppy', label: 'Preppy', image: _img('mood_preppy')),
    MoodTile(id: 'techwear', label: 'Techwear', image: _img('mood_techwear')),
  ];

  static const seedMoodIds = {'y2k', 'streetwear', 'techwear'};

  static const palette = [
    PaletteSwatch(
      id: 'cream',
      name: 'Cream',
      role: 'Aesthetic',
      hex: 0xFFE8DFC8,
    ),
    PaletteSwatch(
      id: 'red',
      name: 'Drip Red',
      role: 'Primary Accent',
      hex: 0xFFFF2020,
    ),
    PaletteSwatch(
      id: 'cyan',
      name: 'Future Cyan',
      role: 'Secondary Link',
      hex: 0xFF48C8FF,
    ),
    PaletteSwatch(
      id: 'slate',
      name: 'Slate',
      role: 'Elevated Outline',
      hex: 0xFF1C2335,
    ),
    PaletteSwatch(
      id: 'vault',
      name: 'Vault',
      role: 'Warm Panel',
      hex: 0xFF141824,
    ),
    PaletteSwatch(
      id: 'midnight',
      name: 'Midnight',
      role: 'Base Dark Ground',
      hex: 0xFF0E1018,
    ),
  ];

  static const seedPaletteIds = {'cream', 'red', 'cyan'};

  // ------------------------------------------------------------ stylist

  static const occasions = [
    'Concert',
    'Date Night',
    'Late Party',
    'Cyber Grid Run',
    'Tokyo Travel',
    'Minimal Daily',
  ];

  static const attireVibes = [
    'Y2K Goth',
    'Minimal Utility',
    'Experimental Cyber',
    'Tokyo Streetwear',
    'Oversized Retro',
  ];

  static const stylistGreeting =
      'Ready to calibrate a brand new silhouette. First, what is the occasion we are targeting?';

  static final List<StudioPiece> studioPieces = [
    StudioPiece(
      id: 'sp_vest',
      name: 'Tactical Vest',
      category: 'OUTERWEAR',
      image: _img('piece_tactical_vest'),
      price: 180,
    ),
    StudioPiece(
      id: 'sp_shell',
      name: 'Shell Jacket',
      category: 'OUTERWEAR',
      image: _img('piece_shell_jacket'),
      price: 210,
    ),
    StudioPiece(
      id: 'sp_bomber',
      name: 'Flight Bomber',
      category: 'OUTERWEAR',
      image: _img('piece_bomber'),
      price: 240,
    ),
    StudioPiece(
      id: 'sp_puff',
      name: 'Puff Vest',
      category: 'OUTERWEAR',
      image: _img('piece_puff_vest'),
      price: 160,
    ),
    StudioPiece(
      id: 'sp_crop',
      name: 'Crop Puff',
      category: 'TOPS',
      image: _img('wardrobe_crop_puff'),
      price: 260,
    ),
    StudioPiece(
      id: 'sp_hoodie',
      name: 'Vintage Hoodie',
      category: 'TOPS',
      image: _img('wardrobe_vintage_hoodie'),
      price: 120,
    ),
    StudioPiece(
      id: 'sp_biker',
      name: 'Leather Biker',
      category: 'TOPS',
      image: _img('item_leather_biker'),
      price: 420,
    ),
    StudioPiece(
      id: 'sp_overcoat',
      name: 'Cyber Overcoat',
      category: 'TOPS',
      image: _img('piece_cyber_overcoat'),
      price: 189,
    ),
    StudioPiece(
      id: 'sp_boots',
      name: 'Platform Boots',
      category: 'FOOTWEAR',
      image: _img('wardrobe_chunky_boots'),
      price: 220,
    ),
  ];

  static const studioCategories = ['OUTERWEAR', 'TOPS', 'FOOTWEAR'];

  static String get builderModel => _img('builder_model');
  static String get studioHero => _img('studio_hero');
  static String get taylorAvatar => _img('avatar_taylor_ai');
  static String get taylorAvatarSmall => _img('avatar_taylor_ai_small');
  static String get taylorBanner => _img('taylor_result_banner');
  static String get taylorOvercoat => _img('piece_cyber_overcoat');

  // --------------------------------------------------------- photoshoot

  static final List<ShootScene> scenes = [
    ShootScene(id: 'studio', label: 'STUDIO', image: _img('scene_studio')),
    ShootScene(id: 'tokyo', label: 'TOKYO NIGHT', image: _img('scene_tokyo')),
    ShootScene(id: 'campus', label: 'CAMPUS', image: _img('scene_campus')),
    ShootScene(
      id: 'editorial',
      label: 'EDITORIAL',
      image: _img('scene_editorial'),
    ),
    ShootScene(
      id: 'metaverse',
      label: 'METAVERSE',
      image: _img('scene_metaverse'),
    ),
    const ShootScene(id: 'custom', label: 'CUSTOM ✦'),
  ];

  static String get shootResult => _img('shoot_result');
  static String get shootCobalt => _img('shoot_cobalt_oversized');

  // -------------------------------------------------------- create OOTD

  static String get createPreview => _img('create_preview');
  static const defaultCaption =
      'Chrome vibes for the mid-season drop. Heavy layers meet fluid silver hardware.';
  static const seedCreateTags = ['#Y2K', '#STREETWEAR', '#GRUNGE'];
}
