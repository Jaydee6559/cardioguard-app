import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Phone notifications for emergencies, so the caregiver is alerted even
/// when CardioGuard is in the background or the screen is off.
///
/// One notification at a time (id 1): a fall check is replaced by the
/// emergency alert, and both are removed when someone responds.
class NotificationService {
  NotificationService._();

  /// Turned off in widget tests, where there is no notification system.
  static bool enabled = true;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _emergencyId = 1;

  static const _channel = AndroidNotificationDetails(
    'cardioguard_emergency',
    'Emergency alerts',
    channelDescription: 'Falls, SOS and other alerts about the person you care for',
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true, // shows over the lock screen when allowed
    playSound: true,
    enableVibration: true,
    ticker: 'CardioGuard emergency',
  );

  /// Call once at app start.
  static Future<void> init() async {
    if (!enabled) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Asks for the "Allow notifications" permission (Android 13 and newer).
  static Future<void> requestPermission() async {
    if (!enabled || !_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  static Future<void> showEmergency(String title, String body) async {
    if (!enabled || !_ready) return;
    try {
      await _plugin.show(
        id: _emergencyId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: _channel),
      );
    } catch (e) {
      debugPrint('Could not show notification: $e');
    }
  }

  /// Removes the emergency notification once someone has responded.
  static Future<void> clear() async {
    if (!enabled || !_ready) return;
    try {
      await _plugin.cancel(id: _emergencyId);
    } catch (e) {
      debugPrint('Could not clear notification: $e');
    }
  }
}
