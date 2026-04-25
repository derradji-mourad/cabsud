import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton that owns flutter_local_notifications.
/// Call [init] once from main before scheduling any notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'cabsud_reservations';
  static const _channelName = 'Reservation Reminders';
  static const _channelDesc =
      'Reminders for your CABSUD chauffeur reservations';

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      debugPrint('Timezone init failed, falling back to UTC: $e');
    }

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Android 13+ notification permission
    await androidPlugin?.requestNotificationsPermission();
    // Android 12+ exact alarm permission
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// Schedule a single notification. Silently skips if [scheduledDate] is in the past.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Remote push placeholder ───────────────────────────────────────────────
  // Implement when the backend push system is ready:
  //   1. Store FCM device tokens in Supabase when the user logs in.
  //   2. Create a Supabase Edge Function that calls the FCM HTTP v1 API.
  //   3. Call that Edge Function from here.
  Future<void> sendDriverCallingNotification({
    required String bookingId,
    required String passengerName,
  }) async {
    throw UnimplementedError(
      'Remote push not yet implemented. '
      'Store FCM tokens in Supabase at login, '
      'then trigger a push Edge Function from this method.',
    );
  }
}
