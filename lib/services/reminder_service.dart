import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local slot reminders. Fire-and-forget from the booking controller:
/// notification failures must never fail a booking.
class ReminderService {
  factory ReminderService() => _instance;
  ReminderService._();
  static final ReminderService _instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  Future<void> _ensurePermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Reminder 30 minutes before [startTime]. No-op when that is not
  /// in the future, or when notifications are unavailable.
  Future<void> scheduleReminder({
    required String bookingId,
    required String title,
    required String body,
    required DateTime startTime,
  }) async {
    final when = startTime.subtract(const Duration(minutes: 30));
    if (!_ready || !when.isAfter(DateTime.now())) return;
    try {
      await _ensurePermission();
      await _plugin.zonedSchedule(
        id: _notificationId(bookingId),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'chargefind_reminders',
            'Slot reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Reminders are best-effort by design.
    }
  }

  Future<void> cancelReminder(String bookingId) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _notificationId(bookingId));
    } catch (_) {
      // Best-effort.
    }
  }

  static int _notificationId(String bookingId) =>
      bookingId.hashCode & 0x7fffffff;
}
