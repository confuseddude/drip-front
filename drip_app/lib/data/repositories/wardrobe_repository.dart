import '../mock/mock_content.dart';
import '../models/wardrobe.dart';

abstract interface class WardrobeRepository {
  Future<List<WardrobeItem>> items();
  Future<WardrobeItem?> byId(String id);
  Future<WardrobeItem> add(WardrobeItem item);
  Future<WardrobeItem> update(WardrobeItem item);
  Future<void> remove(String id);

  /// Runs garment detection on a captured photo.
  Future<GarmentDetection> detect(String imagePath);
  Future<List<String>> rotationIds();
  Future<void> setRotation(String id, {required bool inRotation});
}

class MockWardrobeRepository implements WardrobeRepository {
  final List<WardrobeItem> _items = List.of(MockContent.wardrobe);
  final Set<String> _rotation = {...MockContent.rotationIds};

  Future<void> _latency([int ms = 250]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  @override
  Future<List<WardrobeItem>> items() async {
    await _latency();
    return List.unmodifiable(_items);
  }

  @override
  Future<WardrobeItem?> byId(String id) async {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  Future<WardrobeItem> add(WardrobeItem item) async {
    await _latency();
    _items.insert(0, item);
    return item;
  }

  @override
  Future<WardrobeItem> update(WardrobeItem item) async {
    await _latency(150);
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i >= 0) _items[i] = item;
    return item;
  }

  @override
  Future<void> remove(String id) async {
    await _latency(150);
    _items.removeWhere((e) => e.id == id);
    _rotation.remove(id);
  }

  @override
  Future<GarmentDetection> detect(String imagePath) async {
    await _latency(1200);
    return MockContent.detection;
  }

  @override
  Future<List<String>> rotationIds() async => _rotation.toList();

  @override
  Future<void> setRotation(String id, {required bool inRotation}) async {
    inRotation ? _rotation.add(id) : _rotation.remove(id);
  }
}
