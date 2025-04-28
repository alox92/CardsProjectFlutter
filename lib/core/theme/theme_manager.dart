import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestionnaire des thèmes de l'application
class ThemeManager with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _fontSizeKey = 'font_size';
  static const String _customBackgroundKey = 'custom_background';

  // Valeurs par défaut
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  double _fontSize = 16.0;
  String? _customBackground;

  // Liste des couleurs d'accent disponibles
  final List<Color> _availableColors = [
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.deepOrange,
    Colors.indigo,
    Colors.green,
  ];

  ThemeManager() {
    _loadPreferences();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  double get fontSize => _fontSize;
  String? get customBackground => _customBackground;
  List<Color> get availableColors => _availableColors;

  /// Définit si le thème est sombre, clair ou système
  void setThemeMode(ThemeMode mode) {
    if (mode != _themeMode) {
      _themeMode = mode;
      _savePreference(_themeModeKey, mode.index);
      notifyListeners();
    }
  }

  /// Définit la couleur d'accent principale de l'application
  void setAccentColor(Color color) {
    if (color != _accentColor) {
      _accentColor = color;
      _savePreference(_accentColorKey, color.toARGB32());
      notifyListeners();
    }
  }

  /// Définit la taille de police personnalisée
  void setFontSize(double size) {
    if (size < 12.0) size = 12.0;
    if (size > 24.0) size = 24.0;
    
    if (size != _fontSize) {
      _fontSize = size;
      _savePreference(_fontSizeKey, size);
      notifyListeners();
    }
  }

  /// Définit l'image de fond personnalisée
  void setCustomBackground(String? imagePath) {
    if (imagePath != _customBackground) {
      _customBackground = imagePath;
      if (imagePath == null) {
        _removePreference(_customBackgroundKey);
      } else {
        _savePreference(_customBackgroundKey, imagePath);
      }
      notifyListeners();
    }
  }

  /// Charge les préférences sauvegardées
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Charger le mode de thème
      final themeModeIndex = prefs.getInt(_themeModeKey);
      if (themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex <= 2) {
        _themeMode = ThemeMode.values[themeModeIndex];
      }
      
      // Charger la couleur d'accent
      final colorValue = prefs.getInt(_accentColorKey);
      if (colorValue != null) {
        _accentColor = Color(colorValue);
      }
      
      // Charger la taille de police
      final fontSize = prefs.getDouble(_fontSizeKey);
      if (fontSize != null && fontSize >= 12.0 && fontSize <= 24.0) {
        _fontSize = fontSize;
      }
      
      // Charger l'image de fond
      _customBackground = prefs.getString(_customBackgroundKey);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des préférences de thème: $e');
    }
  }

  /// Enregistre une préférence
  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la préférence $key: $e');
    }
  }

  /// Supprime une préférence
  Future<void> _removePreference(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la préférence $key: $e');
    }
  }

  /// Ajout des getters manquants pour compatibilité
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
  
  // Rayon des cartes (pour la compatibilité UI)
  double get cardRadius => 16.0;
  // Flou pour les effets de glassmorphism
  double get glassBlurSigma => 16.0;

  // Pour compatibilité avec certains widgets
  ThemeData get lightTheme => getLightTheme();
  ThemeData get darkTheme => getDarkTheme();

  /// Obtient le thème lumineux
  ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _accentColor,
      colorScheme: ColorScheme.light(
        primary: _accentColor,
        secondary: _accentColor.withAlpha(204), // Remplacement de withOpacity(0.8)
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: _getTextTheme(isDark: false),
      iconTheme: IconThemeData(color: _accentColor),
    );
  }

  /// Obtient le thème sombre
  ThemeData getDarkTheme() {
    final darkAccent = _brightenColor(_accentColor, 0.2);
    
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkAccent,
      colorScheme: ColorScheme.dark(
        primary: darkAccent,
        secondary: darkAccent.withAlpha(204), // Remplacement de withOpacity(0.8)
        surface: const Color(0xFF212121),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF212121),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF212121),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: _getTextTheme(isDark: true),
      iconTheme: IconThemeData(color: darkAccent),
    );
  }

  /// Obtient le thème de texte avec la taille de police personnalisée
  TextTheme _getTextTheme({required bool isDark}) {
    final baseTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    
    // Applique un facteur d'échelle à tous les styles de texte
    final scaleFactor = _fontSize / 16.0; // 16.0 est la taille par défaut
    
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(fontSize: 34 * scaleFactor),
      displayMedium: baseTheme.displayMedium?.copyWith(fontSize: 28 * scaleFactor),
      displaySmall: baseTheme.displaySmall?.copyWith(fontSize: 24 * scaleFactor),
      headlineLarge: baseTheme.headlineLarge?.copyWith(fontSize: 22 * scaleFactor),
      headlineMedium: baseTheme.headlineMedium?.copyWith(fontSize: 20 * scaleFactor),
      headlineSmall: baseTheme.headlineSmall?.copyWith(fontSize: 18 * scaleFactor),
      titleLarge: baseTheme.titleLarge?.copyWith(fontSize: 18 * scaleFactor),
      titleMedium: baseTheme.titleMedium?.copyWith(fontSize: 16 * scaleFactor),
      titleSmall: baseTheme.titleSmall?.copyWith(fontSize: 14 * scaleFactor),
      bodyLarge: baseTheme.bodyLarge?.copyWith(fontSize: 16 * scaleFactor),
      bodyMedium: baseTheme.bodyMedium?.copyWith(fontSize: 14 * scaleFactor),
      bodySmall: baseTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor),
      labelLarge: baseTheme.labelLarge?.copyWith(fontSize: 16 * scaleFactor),
      labelMedium: baseTheme.labelMedium?.copyWith(fontSize: 14 * scaleFactor),
      labelSmall: baseTheme.labelSmall?.copyWith(fontSize: 12 * scaleFactor),
    );
  }

  /// Éclaircit une couleur pour une meilleure visibilité en mode sombre
  Color _brightenColor(Color color, double factor) {
    if (factor <= 0) return color;
    if (factor > 1) factor = 1;
    
    // Extraire les composantes de la couleur
    final r = color.r;
    final g = color.g;
    final b = color.b;
    
    // Éclaircir les composantes
    final newR = r + ((255 - r) * factor).round();
    final newG = g + ((255 - g) * factor).round();
    final newB = b + ((255 - b) * factor).round();
    
    return Color.fromARGB(color.a, newR, newG, newB);
  }
}
