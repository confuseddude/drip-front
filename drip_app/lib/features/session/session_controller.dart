import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_content.dart';
import '../../data/providers.dart';

class SessionState {
  const SessionState({required this.signedIn, required this.onboarded});
  final bool signedIn;
  final bool onboarded;

  SessionState copyWith({bool? signedIn, bool? onboarded}) => SessionState(
    signedIn: signedIn ?? this.signedIn,
    onboarded: onboarded ?? this.onboarded,
  );
}

/// Session flags. There is no real auth yet: "signed in" is a persisted local
/// flag that the future auth repository will replace.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final store = ref.watch(localStoreProvider);
    return SessionState(signedIn: store.signedIn, onboarded: store.onboarded);
  }

  /// "I already have an account" — jumps straight into the app.
  Future<void> signInExisting() async {
    final store = ref.read(localStoreProvider);
    await store.setSignedIn(true);
    await store.setOnboarded(true);
    state = const SessionState(signedIn: true, onboarded: true);
  }

  /// Finishes onboarding ("ENTER DRIP").
  Future<void> completeOnboarding() async {
    final store = ref.read(localStoreProvider);
    await store.setSignedIn(true);
    await store.setOnboarded(true);
    state = const SessionState(signedIn: true, onboarded: true);
  }

  Future<void> logout() async {
    await ref.read(localStoreProvider).clearAccount();
    state = const SessionState(signedIn: false, onboarded: false);
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class OnboardingState {
  const OnboardingState({required this.moodIds, required this.paletteIds});
  final Set<String> moodIds;
  final Set<String> paletteIds;

  OnboardingState copyWith({Set<String>? moodIds, Set<String>? paletteIds}) =>
      OnboardingState(
        moodIds: moodIds ?? this.moodIds,
        paletteIds: paletteIds ?? this.paletteIds,
      );
}

/// Style-quiz and colour-theory picks made during onboarding.
class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final store = ref.watch(localStoreProvider);
    return OnboardingState(
      moodIds: store.moodIds ?? {...MockContent.seedMoodIds},
      paletteIds: store.paletteIds ?? {...MockContent.seedPaletteIds},
    );
  }

  void toggleMood(String id) {
    final next = {...state.moodIds};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(moodIds: next);
  }

  void togglePalette(String id) {
    final next = {...state.paletteIds};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(paletteIds: next);
  }

  Future<void> saveMoods() =>
      ref.read(localStoreProvider).setMoodIds(state.moodIds);
  Future<void> savePalette() =>
      ref.read(localStoreProvider).setPaletteIds(state.paletteIds);
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
