import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/activity_repository.dart';
import 'repositories/feed_repository.dart';
import 'repositories/local_store.dart';
import 'repositories/outfit_repository.dart';
import 'repositories/social_repository.dart';
import 'repositories/studio_repository.dart';
import 'repositories/stylist_repository.dart';
import 'repositories/wardrobe_repository.dart';

/// Overridden in `main()` once [SharedPreferences] has been loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final localStoreProvider = Provider<LocalStore>(
  (ref) => LocalStore(ref.watch(sharedPreferencesProvider)),
);

// ------------------------------------------------------------------------
// Repositories. To connect the real backend, return the API-backed
// implementation from these providers — no UI code needs to change.
// ------------------------------------------------------------------------

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => MockFeedRepository(),
);

final outfitRepositoryProvider = Provider<OutfitRepository>(
  (ref) => MockOutfitRepository(),
);

final wardrobeRepositoryProvider = Provider<WardrobeRepository>(
  (ref) => MockWardrobeRepository(),
);

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => MockSocialRepository(ref.watch(localStoreProvider)),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => MockActivityRepository(),
);

final stylistRepositoryProvider = Provider<StylistRepository>(
  (ref) => MockStylistRepository(),
);

final studioRepositoryProvider = Provider<StudioRepository>(
  (ref) => MockStudioRepository(),
);
