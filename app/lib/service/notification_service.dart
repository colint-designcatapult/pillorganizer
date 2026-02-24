import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

Future<String> enablePushNotifications() async {
  return "not implemented";
}
