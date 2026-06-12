import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // الوضع الافتراضي هو الفاتح (Light)
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  // التحقق هل التطبيق في وضع الدارك حالياً؟
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // دالة تحويل الثيم وجعلها جاهزة للاستدعاء في أي مكان
  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // إشعار التطبيق بالكامل لتحديث الواجهات فوراً
  }
}