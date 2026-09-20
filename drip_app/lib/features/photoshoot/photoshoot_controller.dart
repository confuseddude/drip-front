import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_content.dart';
import '../../data/models/stylist.dart';
import '../../data/providers.dart';
import '../../data/repositories/studio_repository.dart';

class PhotoshootState {
  const PhotoshootState({
    this.mode = ShootMode.ai,
    this.fitId = 'w_puff',
    this.sceneId = 'tokyo',
    this.customLabel,
    this.render = const AsyncData(null),
  });

  final ShootMode mode;
  final String fitId;
  final String sceneId;

  /// Name typed for the "CUSTOM ✦" scene.
  final String? customLabel;
  final AsyncValue<ShootRender?> render;

  PhotoshootState copyWith({
    ShootMode? mode,
    String? fitId,
    String? sceneId,
    String? customLabel,
    AsyncValue<ShootRender?>? render,
  }) => PhotoshootState(
    mode: mode ?? this.mode,
    fitId: fitId ?? this.fitId,
    sceneId: sceneId ?? this.sceneId,
    customLabel: customLabel ?? this.customLabel,
    render: render ?? this.render,
  );

  String get sceneLabel {
    if (sceneId == 'custom') return (customLabel ?? 'CUSTOM').toUpperCase();
    return MockContent.scenes.firstWhere((s) => s.id == sceneId).label;
  }
}

class PhotoshootController extends Notifier<PhotoshootState> {
  @override
  PhotoshootState build() => const PhotoshootState();

  void setMode(ShootMode m) => state = state.copyWith(mode: m);
  void setFit(String id) => state = state.copyWith(fitId: id);
  void setScene(String id, {String? customLabel}) =>
      state = state.copyWith(sceneId: id, customLabel: customLabel);

  /// Renders the shoot. In "real look" mode [realImage] is the photo the user
  /// took; otherwise the studio service generates the scene.
  Future<void> generate({required String fitName, String? realImage}) async {
    final scene = MockContent.scenes.firstWhere((s) => s.id == state.sceneId);
    final label = state.sceneLabel;
    state = state.copyWith(render: const AsyncLoading());
    final result = await AsyncValue.guard<ShootRender?>(() async {
      if (realImage != null) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return ShootRender(
          image: realImage,
          title: '$fitName · $label'.toUpperCase(),
          scene: label,
          score: 96,
        );
      }
      return ref
          .read(studioRepositoryProvider)
          .generateShoot(
            fitName: fitName,
            scene: ShootScene(id: scene.id, label: label, image: scene.image),
            mode: state.mode,
          );
    });
    if (!ref.mounted) return;
    state = state.copyWith(render: result);
  }

  void clearRender() => state = state.copyWith(render: const AsyncData(null));
}

final photoshootProvider =
    NotifierProvider<PhotoshootController, PhotoshootState>(
      PhotoshootController.new,
    );

/// Photos generated in the studio and saved to the profile "PHOTOS" tab.
class MyPhotosController extends Notifier<List<String>> {
  @override
  List<String> build() => [MockContent.shootResult];

  void add(String image) {
    if (!state.contains(image)) state = [image, ...state];
  }
}

final myPhotosProvider = NotifierProvider<MyPhotosController, List<String>>(
  MyPhotosController.new,
);
