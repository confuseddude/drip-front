import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/repositories/local_store.dart';
import '../../data/repositories/report_repository.dart';
import '../config/env.dart';

/// Where automatic error reports go: `POST /reports`, as the signed-in user.
abstract interface class AutoReportSink {
  bool get signedIn;
  Future<void> post(Map<String, dynamic> body);
}

/// `POST /reports` through the app's [ApiClient].
class ApiAutoReportSink implements AutoReportSink {
  ApiAutoReportSink(this._api, {required this._signedIn});
  final ApiClient _api;
  final bool Function() _signedIn;

  @override
  bool get signedIn => _signedIn();

  @override
  Future<void> post(Map<String, dynamic> body) => _api.post('/reports', body);
}

/// The app's own error reporting for the beta: what breaks on testers' phones
/// reaches Drip as a bug report marked `[auto]`, through the same
/// `POST /reports` the "Report a bug" sheet uses. No third-party SDK: these
/// reports only ever go to our own backend.
///
/// - **Captures** uncaught Dart errors (Flutter, the platform dispatcher and
///   the zone around `runApp`) and API calls that failed on the server (5xx)
///   or never reached it. A failed call is recorded as its method, route
///   template and status only, never its body.
/// - **Throttles hard**, so the user's own reports always fit in the shared
///   30-an-hour limit: the same error once per 10 minutes, at most 5 per app
///   session and 10 sent an hour, in a queue of their own.
/// - **Scrubs** emails, handles, tokens, ids, file and photo paths, URLs and
///   quoted text from the message and the stack. Never screenshots or photos.
/// - Sends only when signed in, and waits on the phone while offline. Debug
///   builds only print to the console.
class ErrorReporter {
  ErrorReporter({bool? sends, DateTime Function()? clock})
    : sends = sends ?? !kDebugMode,
      _clock = clock ?? DateTime.now;

  /// The app's reporter. Installed in `main()`, attached once the app is up.
  static final instance = ErrorReporter();

  /// False in debug builds: reports are printed, never sent.
  final bool sends;
  final DateTime Function() _clock;

  static const perSession = 5;
  static const perHour = 10;
  static const repeatAfter = Duration(minutes: 10);
  static const maxQueued = 10;
  static const maxMessage = 1000;
  static const maxScreen = 40;
  static const frames = 5;

  AutoReportSink? _sink;
  LocalStore? _store;
  String Function()? _screen;

  /// Reports made before [attach] (an error during start-up).
  final _early = <Map<String, dynamic>>[];
  final _lastSeen = <String, DateTime>{};
  var _taken = 0;
  var _flushing = false;
  var _again = false;

  /// Routes every uncaught Flutter and platform error here. Call before
  /// `runApp`, inside the zone whose `onError` calls [recordError].
  void install() {
    final present = FlutterError.onError;
    FlutterError.onError = (details) {
      present?.call(details);
      if (!details.silent) recordError(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack);
      return true;
    };
  }

  /// Starts sending: [sink] posts, [store] keeps the queue, [screen] names
  /// the route on screen (its template, `/outfit/:id`, never real ids).
  Future<void> attach(
    AutoReportSink sink,
    LocalStore store, {
    required String Function() screen,
  }) async {
    _sink = sink;
    _store = store;
    _screen = screen;
    if (_early.isNotEmpty) {
      final early = [..._early];
      _early.clear();
      for (final body in early) {
        await _enqueue(body);
      }
    }
    await flush();
  }

  /// An uncaught error. API errors are left to [recordApiFailure], which
  /// sees them first and knows which ones matter.
  void recordError(Object error, StackTrace? stack) {
    if (error is ApiException) return;
    try {
      final type = error.runtimeType.toString();
      final lines = (stack ?? StackTrace.empty)
          .toString()
          .split('\n')
          .map((l) => l.trim().replaceAll(RegExp(r'\s+'), ' '))
          .where((l) => l.isNotEmpty)
          .take(frames)
          .map(scrubForReport)
          .toList();
      final first = error.toString().split('\n').first;
      final short = scrubForReport(
        first.length > 200 ? '${first.substring(0, 200)}…' : first,
      );
      _record(
        key: '$type|${lines.isEmpty ? '' : lines.first}',
        text: ['$type: $short', ...lines].join('\n'),
      );
    } catch (_) {
      // Reporting must never be the next error.
    }
  }

  /// An API call that failed on the server (5xx) or never got there.
  /// Expected answers (401, 404, other 4xx) are not errors.
  void recordApiFailure(String method, String path, int status) {
    if (status != 0 && status < 500) return;
    // A failing /reports would report itself.
    if (path.startsWith('/reports')) return;
    final route = routeTemplate(path);
    final what = status == 0 ? 'no connection' : '$status';
    _record(
      key: 'api|$method|$route|$status',
      text: 'ApiFailure: $method $route → $what',
    );
  }

  void _record({required String key, required String text}) {
    final message = '[auto] $text';
    final clipped = message.length > maxMessage
        ? message.substring(0, maxMessage)
        : message;
    if (!sends) {
      debugPrint('[error-report] $clipped');
      return;
    }
    final now = _clock();
    final seen = _lastSeen[key];
    if (seen != null && now.difference(seen) < repeatAfter) return;
    _lastSeen[key] = now;
    if (_taken >= perSession) return;
    _taken++;

    final screen = _screen?.call() ?? 'app';
    final body = BugReport(
      kind: 'broken',
      message: clipped,
      screen: screen.isEmpty
          ? 'app'
          : screen.length > maxScreen
          ? screen.substring(0, maxScreen)
          : screen,
      appVersion: Env.appVersion,
      platform: BugReport.thisPlatform(),
      createdAt: now,
    ).toJson();
    if (_store == null) {
      if (_early.length < maxQueued) _early.add(body);
      return;
    }
    unawaited(_enqueue(body).then((_) => flush()));
  }

  Future<void> _enqueue(Map<String, dynamic> body) async {
    final store = _store!;
    final next = [...store.queuedAutoReports, jsonEncode(body)];
    await store.setQueuedAutoReports(
      next.length > maxQueued ? next.sublist(next.length - maxQueued) : next,
    );
  }

  /// Sends what's waiting, within the hourly limit. Safe to call any time
  /// (on sign-in, after an error); does nothing signed out.
  Future<void> flush() async {
    final sink = _sink;
    final store = _store;
    if (sink == null || store == null || !sink.signedIn) return;
    if (_flushing) {
      // A report came in mid-send: go round once more when this one ends.
      _again = true;
      return;
    }
    _flushing = true;
    _again = false;
    try {
      final now = _clock().millisecondsSinceEpoch;
      final hourAgo = now - const Duration(hours: 1).inMilliseconds;
      final sent = [
        for (final t in store.autoReportsSent)
          if (t > hourAgo) t,
      ];
      final waiting = store.queuedAutoReports;
      var i = 0;
      for (; i < waiting.length && sent.length < perHour; i++) {
        try {
          await sink.post(jsonDecode(waiting[i]) as Map<String, dynamic>);
          sent.add(now);
        } on ApiException catch (e) {
          // Offline, the server down or over the limit: try again later.
          if (e.isNetwork || e.isRateLimited || e.status >= 500) break;
          // Refused for good (400, 401, 413): drop it.
        } on FormatException {
          // A corrupt entry: drop it.
        }
      }
      // Reports queued while these were sending sit after them: keep those.
      await store.setQueuedAutoReports([...store.queuedAutoReports.skip(i)]);
      await store.setAutoReportsSent(sent);
    } catch (_) {
      // Reporting must never be the next error.
    } finally {
      _flushing = false;
    }
    if (_again) await flush();
  }
}

/// [path] with its ids swapped for `:id`, so `/outfits/8f1c…/like` reports
/// as `/outfits/:id/like`.
String routeTemplate(String path) {
  final bare = path.split('?').first;
  final id = RegExp(r'^[0-9a-fA-F-]{16,}$|^\d+$|^[\w-]{20,}$');
  return bare
      .split('/')
      .map(
        (s) => id.hasMatch(s) || (s.length >= 8 && s.contains(RegExp(r'\d')))
            ? ':id'
            : s,
      )
      .join('/');
}

final _scrubs = <(RegExp, String)>[
  (RegExp(r'\b(?:https?|file|content)://\S+'), '<url>'),
  (RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '<email>'),
  (RegExp(r'Bearer\s+\S+', caseSensitive: false), 'Bearer <token>'),
  (RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]+'), '<token>'),
  (
    RegExp(
      r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
    ),
    '<id>',
  ),
  (RegExp(r'\b[A-Za-z0-9_-]{32,}\b'), '<token>'),
  (
    RegExp(
      r'(?:[A-Za-z]:\\|/(?:data|storage|sdcard|private|var|Users|tmp|'
      r'mnt|cache)/)\S*',
    ),
    '<path>',
  ),
  (
    RegExp(
      r'[\w./-]+\.(?:jpe?g|png|heic|heif|webp|gif)\b',
      caseSensitive: false,
    ),
    '<photo>',
  ),
  (RegExp(r'(?<![\w.])@[\w.]{2,}'), '<user>'),
  (RegExp(r'\b\d{6,}\b'), '<n>'),
];

final _quoted = RegExp(r'''(["'])([^"'\n]*)\1''');

/// A Dart type name (`'Null'`, `'List<String>'`), which errors quote and
/// which is worth keeping.
final _typeName = RegExp(r'^_?[A-Z][\w$]*(<[\w$<>?, ]*>)?\??$');

/// [text] with anything that could identify the user or carry what they
/// wrote taken out: emails, `@handles`, tokens, ids, URLs, file and photo
/// paths, and quoted text (type names stay).
String scrubForReport(String text) {
  var out = text;
  for (final (pattern, replacement) in _scrubs) {
    out = out.replaceAll(pattern, replacement);
  }
  return out.replaceAllMapped(
    _quoted,
    (m) => _typeName.hasMatch(m[2]!) ? m[0]! : '${m[1]}<text>${m[1]}',
  );
}
