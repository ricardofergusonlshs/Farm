import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FarmReminderService {
  FarmReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();

    // HPJ farmer operations are Jamaica-based.
    // Jamaica uses America/Jamaica and does not observe DST.
    tz.setLocalLocation(
      tz.getLocation('America/Jamaica'),
    );

    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> _requestPermission() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }

    await _ensureInitialized();
    await _requestPermission();

    final localTime = tz.TZDateTime(
      tz.local,
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
      scheduledAt.hour,
      scheduledAt.minute,
    );

    if (!localTime.isAfter(tz.TZDateTime.now(tz.local))) {
      return false;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'hpj_farm_reminders',
        'Farm reminders',
        channelDescription:
            'Harvest, crop, collection and farm calendar reminders.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        threadIdentifier: 'hpj_farm_reminders',
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      localTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'farmer-calendar',
    );

    return true;
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb) return;

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    await _ensureInitialized();
    await _plugin.cancel(id);
  }
}
