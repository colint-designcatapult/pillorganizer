import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Android notification channel used for all medication reminder
/// notifications. Must match the value declared in AndroidManifest.xml
/// and sent by the backend in the FCM payload's
/// `android.notification.channel_id` field.
const String kMedicationChannelId = 'medication_reminders';
const String kMedicationChannelName = 'Medication Reminders';
const String kMedicationChannelDescription =
    'Alerts when it is time to take or when you have missed your medication.';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Initialises [FlutterLocalNotificationsPlugin], creates the high-importance
/// Android notification channel, and enables foreground notification
/// presentation on iOS.
///
/// Must be called once from [main] after [WidgetsFlutterBinding.ensureInitialized].
Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS foreground options are handled via FirebaseMessaging, but the
  // DarwinInitializationSettings are still required to initialise the plugin.
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Create the high-importance Android channel so notifications are shown
  // with sound and as heads-up banners while the app is in the foreground.
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    kMedicationChannelId,
    kMedicationChannelName,
    description: kMedicationChannelDescription,
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// Displays a local notification on [kMedicationChannelId].
///
/// Called from the [FirebaseMessaging.onMessage] stream handler so that
/// foreground FCM messages are surfaced to the user on Android. On iOS the
/// system already presents the notification when foreground options are set.
Future<void> showForegroundNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    kMedicationChannelId,
    kMedicationChannelName,
    channelDescription: kMedicationChannelDescription,
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(0, title, body, details);
}

class BackgroundNotificationTranslator {
  static const String _languageKey = 'selected_language';

  static Future<String> _getSavedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'fr';
  }

  static String _translateKey(
      String key, String languageCode, String? pillBoxName) {
    final Map<String, Map<String, String>> translations = {
      'en': {
        'REMINDER_TITLE': 'Pill Organizer',
        'REMINDER_BODY': 'It\'s time to take your pills for {pillBoxName}!',
      },
      'fr': {
        'REMINDER_TITLE': 'Pilulier',
        'REMINDER_BODY':
            'Il est temps de prendre vos pilules pour {pillBoxName}!',
      },
    };

    String translation = translations[languageCode]?[key] ?? key;
    translation = translation.replaceAll('{pillBoxName}', pillBoxName ?? '');

    return translation;
  }
}

/// Returns the current FCM registration token, or null if unavailable.
Future<String?> getFcmToken() async {
  return FirebaseMessaging.instance.getToken();
}
