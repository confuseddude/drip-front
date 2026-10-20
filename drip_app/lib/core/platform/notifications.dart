import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Phone notifications for long jobs (the gallery import, for now).
///
/// While an import uploads and processes, Android shows an ongoing
/// "Building your wardrobe" notification backed by a foreground service, so
/// the work carries on when the user switches apps. When it's done, a normal
/// notification says so; tapping it opens [onOpen] with the payload.
///
/// These are local notifications: they need the app's process alive, which
/// the foreground service keeps on Android. Server push (Firebase) for when
/// the app was swiped away is a backend request (docs/BACKEND_REQUESTS.md).
/// Everything here fails quietly: a notification must never break the app.
abstract interface class Notifications {
  Future<void> init({required void Function(String payload) onOpen});

  /// Asks to post notifications (Android 13+, iOS). True if allowed.
  Future<bool> requestPermission();

  /// The ongoing progress notification. [progress] 0–1, or null while the
  /// amount of work left is unknown.
  Future<void> showProgress({
    required String title,
    required String body,
    double? progress,
  });

  Future<void> clearProgress();

  /// A one-off "it's done" notification that opens [payload] when tapped.
  Future<void> showDone({
    required String title,
    required String body,
    required String payload,
  });
}

/// The app's notifications (tests override with [NoNotifications]).
final notificationsProvider = Provider<Notifications>(
  (ref) => LocalNotifications(),
);

/// Does nothing. For tests and platforms without notifications.
class NoNotifications implements Notifications {
  const NoNotifications();
  @override
  Future<void> init({required void Function(String payload) onOpen}) async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> showProgress({
    required String title,
    required String body,
    double? progress,
  }) async {}
  @override
  Future<void> clearProgress() async {}
  @override
  Future<void> showDone({
    required String title,
    required String body,
    required String payload,
  }) async {}
}

class LocalNotifications implements Notifications {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _serviceRunning = false;

  static const _progressId = 7001;
  static const _doneId = 7002;

  /// Monochrome status-bar glyph (res/drawable/ic_stat_drip.xml).
  static const _icon = 'ic_stat_drip';

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init({required void Function(String payload) onOpen}) async {
    if (!_supported || _ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_icon),
          // Asked for in context (when an import starts), not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) {
          final payload = r.payload;
          if (payload != null && payload.isNotEmpty) onOpen(payload);
        },
      );
      _ready = true;
      // Opened from a notification while the app wasn't running.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) &&
          payload != null &&
          payload.isNotEmpty) {
        scheduleMicrotask(() => onOpen(payload));
      }
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _android?.requestNotificationsPermission() ?? false;
      }
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showProgress({
    required String title,
    required String body,
    double? progress,
  }) async {
    if (!_ready) return;
    final android = AndroidNotificationDetails(
      'drip.work',
      'Work in progress',
      channelDescription: 'Shows while Drip builds your wardrobe.',
      icon: _icon,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      showProgress: true,
      maxProgress: 100,
      progress: ((progress ?? 0) * 100).round(),
      indeterminate: progress == null,
    );
    try {
      final service = _android;
      if (service != null && !_serviceRunning) {
        // A foreground service keeps the process (and the upload) alive
        // while the user is in another app.
        await service.startForegroundService(
          id: _progressId,
          title: title,
          body: body,
          notificationDetails: android,
          payload: 'wardrobe',
          foregroundServiceTypes: {
            AndroidServiceForegroundType.foregroundServiceTypeDataSync,
          },
        );
        _serviceRunning = true;
        return;
      }
      await _plugin.show(
        id: _progressId,
        title: title,
        body: body,
        payload: 'wardrobe',
        notificationDetails: NotificationDetails(
          android: android,
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentSound: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Progress notification failed: $e');
    }
  }

  @override
  Future<void> clearProgress() async {
    if (!_ready) return;
    try {
      if (_serviceRunning) await _android?.stopForegroundService();
      _serviceRunning = false;
      await _plugin.cancel(id: _progressId);
    } catch (_) {}
  }

  @override
  Future<void> showDone({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: _doneId,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'drip.ready',
            'Ready for you',
            channelDescription: 'When something Drip was working on is done.',
            icon: _icon,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Done notification failed: $e');
    }
  }
}
