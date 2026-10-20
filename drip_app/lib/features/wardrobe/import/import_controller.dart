import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/platform/notifications.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/wardrobe_import.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/wardrobe_import_repository.dart';
import '../wardrobe_controller.dart';
import 'photo_check.dart';

/// Where a gallery import is, from this phone's side.
enum ImportPhase {
  idle,

  /// The phone is looking at the picked photos.
  checking,

  /// Checked; waiting for the user to send them.
  ready,
  uploading,

  /// Uploaded; the server is cutting the clothes out.
  processing,
  done,
  failed,

  /// The server doesn't take imports yet.
  unavailable,
}

/// One photo the user picked, and what the phone made of it.
class PickedPhoto {
  const PickedPhoto({
    required this.path,
    this.verdict = PhotoVerdict.pending,
    this.takenAt,
  });

  /// A copy in the app's cache (the picker hands those out).
  final String path;
  final PhotoVerdict verdict;
  final DateTime? takenAt;

  PickedPhoto judged(PhotoVerdict v, DateTime? at) =>
      PickedPhoto(path: path, verdict: v, takenAt: at);
}

class ImportRun {
  const ImportRun({
    this.phase = ImportPhase.idle,
    this.photos = const [],
    this.uploaded = 0,
    this.server,
    this.error,
    this.preview = false,
  });

  final ImportPhase phase;
  final List<PickedPhoto> photos;

  /// Photos that reached storage so far.
  final int uploaded;

  /// The server's view, once the import exists.
  final WardrobeImport? server;
  final String? error;

  /// Running against the stand-in server: nothing reaches the wardrobe.
  final bool preview;

  List<PickedPhoto> get kept => [
    for (final p in photos)
      if (p.verdict.kept) p,
  ];

  int get checked =>
      photos.where((p) => p.verdict != PhotoVerdict.pending).length;

  /// Skipped photos by reason, most common first.
  List<(PhotoVerdict, int)> get skipped {
    final counts = <PhotoVerdict, int>{};
    for (final p in photos) {
      if (p.verdict != PhotoVerdict.pending && !p.verdict.kept) {
        counts[p.verdict] = (counts[p.verdict] ?? 0) + 1;
      }
    }
    return counts.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
  }

  /// Uploading or processing: the work outlives the screen.
  bool get working =>
      phase == ImportPhase.uploading || phase == ImportPhase.processing;

  ImportRun copyWith({
    ImportPhase? phase,
    List<PickedPhoto>? photos,
    int? uploaded,
    WardrobeImport? server,
    String? error,
    bool? preview,
  }) => ImportRun(
    phase: phase ?? this.phase,
    photos: photos ?? this.photos,
    uploaded: uploaded ?? this.uploaded,
    server: server ?? this.server,
    error: error,
    preview: preview ?? this.preview,
  );
}

/// Most photos per import.
const maxImportPhotos = 50;

/// Runs a gallery import end to end: pick → check on the phone → upload →
/// follow the server until the pieces are in the wardrobe. App-wide (not
/// tied to a screen), so the user can leave and keep using Drip; the
/// progress notification keeps it going in another app.
class WardrobeImportController extends Notifier<ImportRun> {
  /// How often to ask the server while the user is in the app, and while
  /// they're elsewhere.
  static const pollActive = Duration(seconds: 4);
  static const pollAway = Duration(seconds: 15);

  /// Photos uploading at once.
  static const parallel = 3;

  /// Photos confirmed to the server per call.
  static const confirmEvery = 10;

  Timer? _poll;
  WardrobeImportRepository? _previewRepo;
  int _run = 0;

  @override
  ImportRun build() {
    ref.onDispose(() => _poll?.cancel());
    return const ImportRun();
  }

  WardrobeImportRepository get _repo =>
      _previewRepo ?? ref.read(wardrobeImportRepositoryProvider);
  Notifications get _notify => ref.read(notificationsProvider);

  bool get _inApp {
    try {
      return WidgetsBinding.instance.lifecycleState ==
          AppLifecycleState.resumed;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system photo picker (Android's Photo Picker, iOS's picker:
  /// no gallery permission needed) and checks what comes back.
  Future<void> pick({ImagePicker? picker}) async {
    if (state.working) return;
    final List<XFile> files;
    try {
      files = await (picker ?? ImagePicker()).pickMultiImage(
        limit: maxImportPhotos,
        // Big enough for clean cut-outs, small enough to upload quickly. The
        // picker keeps the EXIF date when it resizes.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
    } catch (e) {
      state = state.copyWith(error: "Couldn't open your photos. Try again.");
      return;
    }
    if (files.isEmpty) return;
    await check([for (final f in files.take(maxImportPhotos)) f.path]);
  }

  /// Runs the on-phone checks over [paths], one photo at a time so the grid
  /// fills in as it goes.
  Future<void> check(List<String> paths, {PhotoChecker? checker}) async {
    final run = ++_run;
    _previewRepo = null;
    state = ImportRun(
      phase: ImportPhase.checking,
      photos: [for (final p in paths) PickedPhoto(path: p)],
    );
    final inspector = checker ?? PhotoChecker();
    final keptSignals = <PhotoSignals>[];
    try {
      for (var i = 0; i < paths.length; i++) {
        PhotoVerdict verdict;
        DateTime? takenAt;
        try {
          final bytes = await File(paths[i]).readAsBytes();
          final signals = await inspector.inspect(paths[i], bytes);
          verdict = judge(signals, keptSignals);
          takenAt = signals.takenAt;
          if (verdict.kept) keptSignals.add(signals);
        } catch (_) {
          verdict = PhotoVerdict.unreadable;
        }
        if (run != _run) return; // picked again meanwhile
        final photos = [...state.photos];
        photos[i] = photos[i].judged(verdict, takenAt);
        state = state.copyWith(photos: photos);
      }
    } finally {
      if (checker == null) await inspector.close();
    }
    if (run != _run) return;
    state = state.copyWith(phase: ImportPhase.ready);
  }

  /// Sends the kept photos. Asks for notification permission first (so we
  /// can say when it's done), then uploads a few at a time, confirming them
  /// in small batches so an interrupted upload loses little.
  Future<void> start({bool preview = false}) async {
    final kept = state.kept;
    if (kept.isEmpty || state.working) return;
    if (preview) _previewRepo = MockWardrobeImportRepository();
    final run = ++_run;
    state = state.copyWith(
      phase: ImportPhase.uploading,
      uploaded: 0,
      preview: preview,
    );
    await _notify.requestPermission();
    unawaited(
      _notify.showProgress(
        title: 'Building your wardrobe',
        body: 'Uploading ${kept.length} photos…',
        progress: 0,
      ),
    );

    final ImportTicket ticket;
    try {
      ticket = await _repo.start(kept.length);
    } on ImportUnavailable {
      await _notify.clearProgress();
      state = state.copyWith(phase: ImportPhase.unavailable);
      return;
    } catch (e) {
      await _fail(e);
      return;
    }
    if (!preview) {
      await ref.read(localStoreProvider).setWardrobeImportId(ticket.id);
    }
    state = state.copyWith(
      server: WardrobeImport(
        id: ticket.id,
        status: ImportStatus.processing,
        photosTotal: kept.length,
      ),
    );

    final waiting = <ImportedPhoto>[];
    var next = 0;
    var uploaded = 0;
    var confirmed = 0;
    Future<void> flush({bool last = false}) async {
      if (waiting.isEmpty && !last) return;
      final batch = [...waiting];
      waiting.clear();
      await _repo.confirm(ticket.id, batch, last: last);
      confirmed += batch.length;
    }

    Future<void> worker() async {
      while (next < kept.length && next < ticket.slots.length) {
        final i = next++;
        final photo = kept[i];
        final slot = ticket.slots[i];
        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            final raw = await File(photo.path).readAsBytes();
            final (bytes, type) = await uploadable(
              raw,
              imageContentType(photo.path),
            );
            await _repo.upload(slot, bytes, type);
            waiting.add(ImportedPhoto(path: slot.path, takenAt: photo.takenAt));
            uploaded++;
            break;
          } catch (_) {
            // One retry, then the photo is left out of the import.
          }
        }
        if (run != _run) return;
        state = state.copyWith(uploaded: uploaded);
        unawaited(
          _notify.showProgress(
            title: 'Building your wardrobe',
            body: 'Uploading $uploaded of ${kept.length} photos…',
            progress: uploaded / kept.length * 0.3,
          ),
        );
        if (waiting.length >= confirmEvery) await flush();
      }
    }

    try {
      await Future.wait([for (var w = 0; w < parallel; w++) worker()]);
      if (run != _run) return;
      if (uploaded == 0) {
        throw const ApiException(0, "Your photos didn't upload");
      }
      await flush(last: true);
    } catch (e) {
      if (run != _run) return;
      await _fail(e);
      return;
    }
    state = state.copyWith(
      phase: ImportPhase.processing,
      server: WardrobeImport(
        id: ticket.id,
        status: ImportStatus.processing,
        photosTotal: confirmed,
      ),
    );
    _schedulePoll();
  }

  /// Picks an unfinished import back up after a restart (or finds one
  /// started on another install). Call once signed in.
  Future<void> resume() async {
    if (state.phase != ImportPhase.idle) return;
    final store = ref.read(localStoreProvider);
    final id = store.wardrobeImportId;
    WardrobeImport? server;
    try {
      server = id != null ? await _repo.status(id) : await _repo.active();
    } on ApiException catch (e) {
      if (e.isNotFound) await store.setWardrobeImportId(null);
      return;
    } catch (_) {
      return;
    }
    if (server == null || state.phase != ImportPhase.idle) return;
    if (!server.finished) {
      await store.setWardrobeImportId(server.id);
      state = ImportRun(phase: ImportPhase.processing, server: server);
      _schedulePoll();
    } else if (id != null) {
      // Finished while the app was closed: still worth saying so.
      await _finish(server);
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    _poll = Timer(_inApp ? pollActive : pollAway, _tick);
  }

  Future<void> _tick() async {
    final id = state.server?.id;
    if (id == null || state.phase != ImportPhase.processing) return;
    try {
      final server = await _repo.status(id);
      if (state.phase != ImportPhase.processing) return;
      state = state.copyWith(server: server);
      if (server.finished) {
        await _finish(server);
        return;
      }
      unawaited(
        _notify.showProgress(
          title: 'Building your wardrobe',
          body: server.grouping
              ? 'Sorting out repeats…'
              : 'Cutting out your clothes · ${server.photosDone} of '
                    '${server.photosTotal} photos',
          progress: 0.3 + server.progress * 0.7,
        ),
      );
    } catch (_) {
      // A missed beat (offline, a restart on our side): try again.
    }
    _schedulePoll();
  }

  Future<void> _finish(WardrobeImport server) async {
    _poll?.cancel();
    await _notify.clearProgress();
    await ref.read(localStoreProvider).setWardrobeImportId(null);
    final ok = server.status == ImportStatus.done;
    state = state.copyWith(
      phase: ok ? ImportPhase.done : ImportPhase.failed,
      server: server,
      error: ok ? null : "We couldn't finish this one. Try again in a bit.",
    );
    if (ok && !state.preview) ref.invalidate(wardrobeProvider);
    if (!_inApp) {
      await _notify.showDone(
        title: ok ? 'Your wardrobe is ready' : 'Wardrobe import stopped',
        body: ok ? importSummary(server) : 'Tap to try again.',
        payload: 'wardrobe',
      );
    }
  }

  Future<void> _fail(Object e) async {
    await _notify.clearProgress();
    await ref.read(localStoreProvider).setWardrobeImportId(null);
    state = state.copyWith(
      phase: ImportPhase.failed,
      error: e is ApiException
          ? e.friendly
          : "Something went wrong. Try again.",
    );
  }

  /// Stops an import in progress (and deletes its photos on the server).
  Future<void> cancel() async {
    final id = state.server?.id;
    _run++;
    _poll?.cancel();
    await _notify.clearProgress();
    await ref.read(localStoreProvider).setWardrobeImportId(null);
    if (id != null && state.working) {
      try {
        await _repo.cancel(id);
      } catch (_) {}
    }
    state = const ImportRun();
  }

  /// Stops following the import on this phone (sign-out). The server keeps
  /// working; the next sign-in picks it up again.
  Future<void> forget() async {
    _run++;
    _poll?.cancel();
    _previewRepo = null;
    await _notify.clearProgress();
    await ref.read(localStoreProvider).setWardrobeImportId(null);
    state = const ImportRun();
  }

  /// Clears a finished, failed or abandoned run.
  void dismiss() {
    if (state.working) return;
    _run++;
    _previewRepo = null;
    state = const ImportRun();
  }

  @visibleForTesting
  Future<void> tick() => _tick();
}

final wardrobeImportProvider =
    NotifierProvider<WardrobeImportController, ImportRun>(
      WardrobeImportController.new,
    );

/// "23 new pieces. 6 repeats folded together." for toasts and notifications.
String importSummary(WardrobeImport s) {
  final parts = <String>[
    s.piecesAdded == 1
        ? '1 new piece is in your wardrobe.'
        : '${s.piecesAdded} new pieces are in your wardrobe.',
    if (s.duplicatesMerged > 0)
      '${s.duplicatesMerged} repeat${s.duplicatesMerged == 1 ? '' : 's'} '
          'folded together.',
    if (s.alreadyOwned > 0) '${s.alreadyOwned} you already had.',
  ];
  return parts.join(' ');
}
