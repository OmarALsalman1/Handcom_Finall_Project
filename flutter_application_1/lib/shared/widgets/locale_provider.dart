import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale') ?? 'ar';
    _locale = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale.languageCode);
  }

  void toggleLocale() {
    setLocale(isArabic ? const Locale('en') : const Locale('ar'));
  }
}
