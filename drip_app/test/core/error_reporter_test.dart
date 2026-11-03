import 'dart:convert';

import 'package:drip/core/errors/error_reporter.dart';
import 'package:drip/data/api/api_client.dart';
import 'package:drip/data/repositories/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

/// Records what would be posted; can be signed out or offline.
class _Sink implements AutoReportSink {
  final posted = <Map<String, dynamic>>[];
  bool online = true;
  @override
  bool signedIn = true;

  @override
  Future<void> post(Map<String, dynamic> body) async {
    if (!online) throw const ApiException(0, 'No connection');
    posted.add(body);
  }
}

/// A different stack (top frame) per call, so dedupe doesn't fold them.
StackTrace _stack(int n) =>
    StackTrace.fromString('#0 Widget$n.build (package:drip/x.dart:$n:1)\n');

void main() {
  late LocalStore store;
  late _Sink sink;
  late DateTime now;
  late ErrorReporter reporter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
    sink = _Sink();
    now = DateTime(2026, 11, 3, 12);
    reporter = ErrorReporter(sends: true, clock: () => now);
    await reporter.attach(sink, store, screen: () => '/outfit/:id');
  });

  /// Lets the queued sends run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('scrubForReport', () {
    test('takes out what could identify the user', () {
      final out = scrubForReport(
        'mail a.b@x.com from @zayid.k token eyJhbGc.eyJzdWIi.sig '
        'Bearer abc123 id 0f8fad5b-d9cb-469f-a165-70867728950e '
        'at /data/user/0/com.drip/cache/IMG_2041.jpg and https://x.io/a?t=1 '
        'with "my secret caption" and 99887766',
      );
      expect(out, isNot(contains('a.b@x.com')));
      expect(out, isNot(contains('@zayid')));
      expect(out, isNot(contains('eyJ')));
      expect(out, isNot(contains('abc123')));
      expect(out, isNot(contains('0f8fad5b')));
      expect(out, isNot(contains('IMG_2041')));
      expect(out, isNot(contains('x.io')));
      expect(out, isNot(contains('secret')));
      expect(out, isNot(contains('99887766')));
    });

    test('keeps type names and code locations', () {
      const msg =
          "type 'Null' is not a subtype of type 'List<String>' "
          '(package:drip/features/x.dart:12:5)';
      expect(scrubForReport(msg), msg);
    });
  });

  test('routeTemplate swaps ids for :id', () {
    expect(
      routeTemplate('/outfits/0f8fad5b-d9cb-469f-a165-70867728950e/like'),
      '/outfits/:id/like',
    );
    expect(routeTemplate('/wardrobe/items/42?x=1'), '/wardrobe/items/:id');
    expect(routeTemplate('/feed'), '/feed');
  });

  test('an uncaught error goes out as an [auto] broken report', () async {
    reporter.recordError(StateError('boom'), _stack(1));
    await settle();
    expect(sink.posted, hasLength(1));
    final body = sink.posted.single;
    expect(body['kind'], 'broken');
    expect(body['screen'], '/outfit/:id');
    expect(body['message'], startsWith('[auto] StateError: Bad state: boom'));
    expect(body['message'], contains('Widget1.build'));
    expect(body.keys, containsAll(['appVersion', 'platform', 'createdAt']));
  });

  test('the message is capped at 1000 characters', () async {
    reporter.recordError(Exception('x' * 5000), _stack(1));
    await settle();
    expect((sink.posted.single['message'] as String).length, lessThan(1001));
  });

  test('API failures: only 5xx and no connection, as a template', () async {
    reporter
      ..recordApiFailure('GET', '/feed', 401)
      ..recordApiFailure('GET', '/outfits/abc12345', 404)
      ..recordApiFailure('POST', '/reports', 503)
      ..recordApiFailure(
        'GET',
        '/outfits/0f8fad5b-d9cb-469f-a165-70867728950e',
        503,
      )
      ..recordApiFailure('GET', '/feed', 0);
    await settle();
    expect(sink.posted.map((b) => b['message']), [
      '[auto] ApiFailure: GET /outfits/:id → 503',
      '[auto] ApiFailure: GET /feed → no connection',
    ]);
  });

  test('ApiException is left to the API hook', () async {
    reporter.recordError(const ApiException(500, 'x'), _stack(1));
    await settle();
    expect(sink.posted, isEmpty);
  });

  test('the same error is sent once per 10 minutes', () async {
    reporter.recordError(StateError('a'), _stack(1));
    reporter.recordError(StateError('a'), _stack(1));
    await settle();
    expect(sink.posted, hasLength(1));
    now = now.add(const Duration(minutes: 11));
    reporter.recordError(StateError('a'), _stack(1));
    await settle();
    expect(sink.posted, hasLength(2));
  });

  test('at most 5 a session', () async {
    for (var i = 0; i < 8; i++) {
      reporter.recordError(StateError('e'), _stack(i));
      await settle();
    }
    expect(sink.posted, hasLength(ErrorReporter.perSession));
  });

  test('at most 10 sent an hour, the rest wait', () async {
    // Six sent in the last hour by an earlier session.
    final t = now.millisecondsSinceEpoch;
    await store.setAutoReportsSent([for (var i = 0; i < 6; i++) t - 1000]);
    // And an old one that no longer counts.
    await store.setAutoReportsSent([
      ...store.autoReportsSent,
      t - const Duration(hours: 2).inMilliseconds,
    ]);
    for (var i = 0; i < 5; i++) {
      reporter.recordError(StateError('e'), _stack(i));
      await settle();
    }
    expect(sink.posted, hasLength(4));
    expect(store.queuedAutoReports, hasLength(1));
  });

  test('signed out or offline: queued on the phone, sent later', () async {
    sink.signedIn = false;
    reporter.recordError(StateError('a'), _stack(1));
    await settle();
    sink
      ..signedIn = true
      ..online = false;
    reporter.recordError(StateError('b'), _stack(2));
    await settle();
    expect(sink.posted, isEmpty);
    expect(store.queuedAutoReports, hasLength(2));
    // Never in the user's own report queue.
    expect(store.queuedReports, isEmpty);

    sink.online = true;
    await reporter.flush();
    expect(sink.posted, hasLength(2));
    expect(store.queuedAutoReports, isEmpty);
  });

  test('errors before the app is up are kept and sent on attach', () async {
    final early = ErrorReporter(sends: true, clock: () => now);
    early.recordError(StateError('start-up'), _stack(1));
    final later = _Sink();
    await early.attach(later, store, screen: () => '/home');
    await settle();
    expect(later.posted, hasLength(1));
  });

  test('debug builds only print', () async {
    final debug = ErrorReporter(sends: false, clock: () => now);
    final quiet = _Sink();
    await debug.attach(quiet, store, screen: () => '/home');
    debug.recordError(StateError('a'), _stack(1));
    await settle();
    expect(quiet.posted, isEmpty);
    expect(store.queuedAutoReports, isEmpty);
  });

  test('ApiClient tells the reporter about failed calls', () async {
    final seen = <String>[];
    final api = ApiClient(
      baseUrl: 'https://api.test',
      auth: FakeAuthRepository(signedIn: true),
      client: MockClient(
        (req) async => http.Response(jsonEncode({'error': 'down'}), 503),
      ),
      onFailure: (method, path, status) => seen.add('$method $path $status'),
    );
    await expectLater(api.get('/feed'), throwsA(isA<ApiException>()));
    expect(seen, ['GET /feed 503']);
  });
}
