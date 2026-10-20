import 'dart:math' as math;
import 'dart:typed_data';

import '../api/api_client.dart';
import '../models/wardrobe_import.dart';

/// The server can't take imports yet (the endpoints aren't deployed).
class ImportUnavailable implements Exception {
  const ImportUnavailable();
}

/// Gallery import: many photos in, sorted wardrobe pieces out
/// (docs/BACKEND_REQUESTS.md, 2026-10-21 #1).
abstract interface class WardrobeImportRepository {
  /// Opens an import for [count] photos and hands back one signed upload
  /// slot per photo. Throws [ImportUnavailable] if the server has no imports.
  Future<ImportTicket> start(int count);

  /// PUTs one photo to its slot.
  Future<void> upload(ImportSlot slot, Uint8List bytes, String contentType);

  /// Confirms photos that reached storage; the server starts on them.
  /// [last] says no more are coming, so the server knows the batch's size
  /// (a photo that failed to upload is simply never confirmed).
  Future<void> confirm(
    String importId,
    List<ImportedPhoto> photos, {
    bool last = false,
  });

  Future<WardrobeImport> status(String importId);

  /// The user's unfinished import, if any (after a reinstall, say).
  Future<WardrobeImport?> active();

  Future<void> cancel(String importId);
}

class ApiWardrobeImportRepository implements WardrobeImportRepository {
  ApiWardrobeImportRepository(this._api);
  final ApiClient _api;

  static WardrobeImport _import(Object? json) =>
      WardrobeImport.fromJson((json as Map).cast<String, dynamic>());

  @override
  Future<ImportTicket> start(int count) async {
    final Map json;
    try {
      json = await _api.post('/wardrobe/imports', {'count': count}) as Map;
    } on ApiException catch (e) {
      if (e.isNotFound) throw const ImportUnavailable();
      rethrow;
    }
    return ImportTicket(
      id: json['id'] as String,
      slots: [
        for (final s in (json['uploads'] as List?) ?? const [])
          ImportSlot(
            uploadUrl: (s as Map)['uploadUrl'] as String,
            path: s['path'] as String,
          ),
      ],
    );
  }

  @override
  Future<void> upload(ImportSlot slot, Uint8List bytes, String contentType) =>
      _api.upload(slot.uploadUrl, bytes, contentType: contentType);

  @override
  Future<void> confirm(
    String importId,
    List<ImportedPhoto> photos, {
    bool last = false,
  }) => _api.post('/wardrobe/imports/$importId/photos', {
    'photos': [for (final p in photos) p.toJson()],
    'last': last,
  });

  @override
  Future<WardrobeImport> status(String importId) async =>
      _import(await _api.get('/wardrobe/imports/$importId'));

  @override
  Future<WardrobeImport?> active() async {
    try {
      final json =
          await _api.get('/wardrobe/imports', query: {'active': 'true'}) as Map;
      final list = (json['imports'] as List?) ?? const [];
      return list.isEmpty ? null : _import(list.first);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<void> cancel(String importId) =>
      _api.delete('/wardrobe/imports/$importId');
}

/// A stand-in server for tests and for previewing the flow before the
/// backend ships: uploads "land" instantly and the photos finish a few
/// seconds apart. Nothing reaches the real wardrobe.
class MockWardrobeImportRepository implements WardrobeImportRepository {
  MockWardrobeImportRepository({this.perPhoto = const Duration(seconds: 2)});

  /// How long each confirmed photo takes to "cut out".
  final Duration perPhoto;

  final _imports = <String, _MockImport>{};
  var _next = 0;

  @override
  Future<ImportTicket> start(int count) async {
    final id = 'preview-${_next++}';
    _imports[id] = _MockImport(count);
    return ImportTicket(
      id: id,
      slots: [
        for (var i = 0; i < count; i++)
          ImportSlot(uploadUrl: 'mock://$id/$i', path: '$id/$i.jpg'),
      ],
    );
  }

  @override
  Future<void> upload(ImportSlot slot, Uint8List bytes, String contentType) =>
      Future<void>.delayed(const Duration(milliseconds: 120));

  @override
  Future<void> confirm(
    String importId,
    List<ImportedPhoto> photos, {
    bool last = false,
  }) async {
    final run = _imports[importId]!;
    run.confirmed += photos.length;
    run.startedAt ??= DateTime.now();
    if (last) run.total = run.confirmed;
  }

  @override
  Future<WardrobeImport> status(String importId) async {
    final run = _imports[importId]!;
    final since = run.startedAt;
    final done = since == null
        ? 0
        : math.min(
            run.confirmed,
            DateTime.now().difference(since).inMilliseconds ~/
                math.max(1, perPhoto.inMilliseconds),
          );
    final finished = done >= run.total;
    final grouping =
        finished &&
        DateTime.now().difference(since!) < perPhoto * (run.total + 2);
    final pieces = (run.total * 1.6).round();
    return WardrobeImport(
      id: importId,
      status: finished && !grouping
          ? ImportStatus.done
          : ImportStatus.processing,
      photosTotal: run.total,
      photosDone: done,
      stage: grouping ? 'grouping' : 'photos',
      piecesAdded: finished && !grouping ? pieces - pieces ~/ 3 : 0,
      duplicatesMerged: finished && !grouping ? pieces ~/ 3 : 0,
    );
  }

  @override
  Future<WardrobeImport?> active() async => null;

  @override
  Future<void> cancel(String importId) async => _imports.remove(importId);
}

class _MockImport {
  _MockImport(this.total);
  int total;
  int confirmed = 0;
  DateTime? startedAt;
}
