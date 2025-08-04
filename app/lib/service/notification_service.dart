import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundNotificationTranslator {
  static const String _languageKey = 'selected_language';

  static Future<String> _getSavedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'fr';
  }

  static String _translateKey(String key, String languageCode) {
    final Map<String, Map<String, String>> translations = {
      'en': {
        'REMINDER_TITLE': 'Pill Organizer',
        'REMINDER_BODY': 'It\'s time to take your pills!',
      },
      'fr': {
        'REMINDER_TITLE': 'Pilulier',
        'REMINDER_BODY': 'Il est temps de prendre vos pilules!',
      },
    };

    return translations[languageCode]?[key] ?? key;
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    final languageCode = await _getSavedLanguageCode();

    String? titleKey;
    String? bodyKey;

    if (message.data.containsKey('data')) {
      try {
        final String dataString = message.data['data']!;
        final Map<String, dynamic> parsedData = json.decode(dataString);

        titleKey = parsedData['titleKey'];
        bodyKey = parsedData['bodyKey'];
      } catch (e) {
        print("---Error parsing nested data: $e");
      }
    }

    if (titleKey == null || bodyKey == null) {
      return;
    }

    final translatedTitle = _translateKey(titleKey, languageCode);
    final translatedBody = _translateKey(bodyKey, languageCode);

    // Initialize local notifications plugin
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Show the translated notification
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'cabinet_notifications',
      'CabiNET Notifications',
      channelDescription: 'Notifications for CabiNET pill organizer',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      translatedTitle,
      translatedBody,
      platformChannelSpecifics,
    );
  }
}

Future<String> enablePushNotifications() async {
  await FirebaseMessaging.instance.requestPermission();
  final fcmToken = await FirebaseMessaging.instance.getToken();

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();

  return fcmToken!;
}
