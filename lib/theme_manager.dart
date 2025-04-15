import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String THEME_KEY = 'theme_mode';

  double _fontSize = 16.0;
  static const String FONT_SIZE_KEY = 'font_size';

  Color _accentColor = Colors.blueAccent;
  static const String ACCENT_COLOR_KEY = 'accent_color';

  ThemeManager() {
    _loadThemePreference();
    _loadFontSize();
    _loadAccentColor();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  double get fontSize => _fontSize;
  Color get accentColor => _accentColor;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference();
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    _saveFontSize();
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _saveAccentColor();
    notifyListeners();
  }

  Future<void> _loadThemePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? themeValue = prefs.getString(THEME_KEY);
      _themeMode = themeValue == 'dark' ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des préférences de thème: $e');
    }
  }

  Future<void> _saveThemePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(THEME_KEY, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      print('Erreur lors de la sauvegarde des préférences de thème: $e');
    }
  }

  Future<void> _loadFontSize() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getDouble(FONT_SIZE_KEY) ?? 16.0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveFontSize() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(FONT_SIZE_KEY, _fontSize);
    } catch (_) {}
  }

  Future<void> _loadAccentColor() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? value = prefs.getInt(ACCENT_COLOR_KEY);
      if (value != null) _accentColor = Color(value);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveAccentColor() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int colorValue = (_accentColor.a.toInt() << 24) |
          (_accentColor.r.toInt() << 16) |
          (_accentColor.g.toInt() << 8) |
          _accentColor.b.toInt();
      await prefs.setInt(ACCENT_COLOR_KEY, colorValue);
    } catch (_) {}
  }
}