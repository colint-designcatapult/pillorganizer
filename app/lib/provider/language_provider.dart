import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('fr');
  static const String _languageKey = 'selected_language';

  Locale get locale => _locale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage != null) {
      _locale = Locale(savedLanguage);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == _locale.languageCode) return;

    _locale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    notifyListeners();
  }

  List<Map<String, String>> get supportedLanguages => [
        {'code': 'en', 'name': 'English'},
        {'code': 'fr', 'name': 'Français'},
      ];
}
