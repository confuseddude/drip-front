import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/wardrobe.dart';
import '../../data/providers.dart';

class WardrobeController extends AsyncNotifier<List<WardrobeItem>> {
  @override
  Future<List<WardrobeItem>> build() =>
      ref.watch(wardrobeRepositoryProvider).items();

  Future<void> add(WardrobeItem item) async {
    await ref.read(wardrobeRepositoryProvider).add(item);
    state = AsyncData([item, ...?state.value]);
  }

  Future<void> edit(WardrobeItem item) async {
    await ref.read(wardrobeRepositoryProvider).update(item);
    state = AsyncData([
      for (final i in state.value ?? const <WardrobeItem>[])
        i.id == item.id ? item : i,
    ]);
  }

  Future<void> remove(String id) async {
    await ref.read(wardrobeRepositoryProvider).remove(id);
    state = AsyncData([
      for (final i in state.value ?? const <WardrobeItem>[])
        if (i.id != id) i,
    ]);
    ref.invalidate(rotationProvider);
  }
}

final wardrobeProvider =
    AsyncNotifierProvider<WardrobeController, List<WardrobeItem>>(
      WardrobeController.new,
    );

final wardrobeItemProvider = Provider.family<WardrobeItem?, String>((ref, id) {
  final list = ref.watch(wardrobeProvider).value;
  if (list == null) return null;
  for (final i in list) {
    if (i.id == id) return i;
  }
  return null;
});

final rotationProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(wardrobeRepositoryProvider).rotationIds(),
);

/// State of the garment-capture flow.
class CaptureState {
  const CaptureState({this.imagePath, this.detection = const AsyncData(null)});
  final String? imagePath;
  final AsyncValue<GarmentDetection?> detection;

  CaptureState copyWith({
    String? imagePath,
    AsyncValue<GarmentDetection?>? detection,
  }) => CaptureState(
    imagePath: imagePath ?? this.imagePath,
    detection: detection ?? this.detection,
  );
}

class CaptureController extends Notifier<CaptureState> {
  @override
  CaptureState build() => const CaptureState();

  Future<void> process(String imagePath) async {
    state = CaptureState(imagePath: imagePath, detection: const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref.read(wardrobeRepositoryProvider).detect(imagePath),
    );
    if (!ref.mounted) return;
    state = CaptureState(imagePath: imagePath, detection: result);
  }

  void reset() => state = const CaptureState();
}

final captureProvider =
    NotifierProvider.autoDispose<CaptureController, CaptureState>(
      CaptureController.new,
    );
