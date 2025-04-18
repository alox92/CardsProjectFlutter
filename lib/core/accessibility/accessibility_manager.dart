import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestionnaire des paramètres d'accessibilité de l'application
class AccessibilityManager with ChangeNotifier {
  static const String _fontSizeKey = 'acc_font_size';
  static const String _highContrastKey = 'acc_high_contrast';
  static const String _reduceAnimationsKey = 'acc_reduce_animations';
  static const String _textToSpeechKey = 'acc_text_to_speech';
  static const String _enableHapticsKey = 'acc_enable_haptics';

  // Paramètres avec valeurs par défaut
  double _textScaleFactor = 1.0;
  bool _highContrastMode = false;
  bool _reduceAnimations = false;
  bool _textToSpeechEnabled = false;
  bool _hapticsEnabled = true;

  // Mode daltonien (colorblind)
  bool _daltonianModeEnabled = false;

  // VoiceOver (screen reader)
  bool _voiceOverEnabled = false;

  // TalkBack (Android screen reader)
  bool _talkBackEnabled = false;

  AccessibilityManager() {
    _loadPreferences();
  }

  // Getters
  double get textScaleFactor => _textScaleFactor;
  bool get highContrastMode => _highContrastMode;
  bool get reduceAnimations => _reduceAnimations;
  bool get textToSpeechEnabled => _textToSpeechEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get daltonianModeEnabled => _daltonianModeEnabled;
  bool get voiceOverEnabled => _voiceOverEnabled;
  bool get talkBackEnabled => _talkBackEnabled;

  /// Charge les préférences d'accessibilité depuis le stockage local
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _textScaleFactor = prefs.getDouble(_fontSizeKey) ?? 1.0;
      _highContrastMode = prefs.getBool(_highContrastKey) ?? false;
      _reduceAnimations = prefs.getBool(_reduceAnimationsKey) ?? false;
      _textToSpeechEnabled = prefs.getBool(_textToSpeechKey) ?? false;
      _hapticsEnabled = prefs.getBool(_enableHapticsKey) ?? true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres d\'accessibilité: $e');
    }
  }

  /// Enregistre une préférence d'accessibilité dans le stockage local
  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la préférence $key: $e');
    }
  }

  /// Modifie le facteur d'échelle du texte
  void setTextScaleFactor(double factor) {
    if (factor < 0.8) factor = 0.8;
    if (factor > 1.6) factor = 1.6;
    
    if (_textScaleFactor != factor) {
      _textScaleFactor = factor;
      _savePreference(_fontSizeKey, factor);
      notifyListeners();
    }
  }

  /// Active ou désactive le mode de contraste élevé
  void setHighContrastMode(bool enabled) {
    if (_highContrastMode != enabled) {
      _highContrastMode = enabled;
      _savePreference(_highContrastKey, enabled);
      notifyListeners();
    }
  }

  /// Active ou désactive la réduction des animations
  void setReduceAnimations(bool enabled) {
    if (_reduceAnimations != enabled) {
      _reduceAnimations = enabled;
      _savePreference(_reduceAnimationsKey, enabled);
      notifyListeners();
    }
  }

  /// Active ou désactive la lecture de texte
  void setTextToSpeech(bool enabled) {
    if (_textToSpeechEnabled != enabled) {
      _textToSpeechEnabled = enabled;
      _savePreference(_textToSpeechKey, enabled);
      notifyListeners();
    }
  }

  /// Active ou désactive le retour haptique
  void setHapticFeedback(bool enabled) {
    if (_hapticsEnabled != enabled) {
      _hapticsEnabled = enabled;
      _savePreference(_enableHapticsKey, enabled);
      notifyListeners();
    }
  }

  /// Active le mode daltonien
  void enableDaltonianMode() {
    if (!_daltonianModeEnabled) {
      _daltonianModeEnabled = true;
      notifyListeners();
    }
  }

  /// Désactive le mode daltonien
  void disableDaltonianMode() {
    if (_daltonianModeEnabled) {
      _daltonianModeEnabled = false;
      notifyListeners();
    }
  }

  /// Active VoiceOver
  void enableVoiceOver() {
    if (!_voiceOverEnabled) {
      _voiceOverEnabled = true;
      notifyListeners();
    }
  }

  /// Désactive VoiceOver
  void disableVoiceOver() {
    if (_voiceOverEnabled) {
      _voiceOverEnabled = false;
      notifyListeners();
    }
  }

  /// Active TalkBack
  void enableTalkBack() {
    if (!_talkBackEnabled) {
      _talkBackEnabled = true;
      notifyListeners();
    }
  }

  /// Désactive TalkBack
  void disableTalkBack() {
    if (_talkBackEnabled) {
      _talkBackEnabled = false;
      notifyListeners();
    }
  }

  /// Déclenche un retour haptique léger si activé
  void lightHapticFeedback() {
    if (_hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Déclenche un retour haptique moyen si activé
  void mediumHapticFeedback() {
    if (_hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Déclenche un retour haptique fort si activé
  void heavyHapticFeedback() {
    if (_hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Retourne les couleurs adaptées au mode contraste élevé si activé
  Color adaptColorForContrast(Color original) {
    if (!_highContrastMode) return original;
    
    // Augmenter le contraste en fonction de la luminosité
    final brightness = original.computeLuminance();
    
    if (brightness > 0.5) {
      // Couleur claire, la rendre plus claire
      return Color.lerp(original, Colors.white, 0.3) ?? original;
    } else {
      // Couleur foncée, la rendre plus foncée
      return Color.lerp(original, Colors.black, 0.3) ?? original;
    }
  }
}