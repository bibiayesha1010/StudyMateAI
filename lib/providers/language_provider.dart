import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const List<String> supportedLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese (Simplified)',
    'Japanese',
    'Hindi',
    'Portuguese',
    'Arabic',
    'Korean',
  ];

  String _selectedLanguage = 'English';

  String get selectedLanguage => _selectedLanguage;

  LanguageProvider() {
    loadLanguage();
  }

  void setLanguage(String language) async {
    if (!supportedLanguages.contains(language)) {
      return;
    }

    _selectedLanguage = language;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  void loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage = prefs.getString('language') ?? 'English';
    notifyListeners();
  }
}
