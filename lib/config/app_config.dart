/// Classe de configuration globale de l'application
/// Centralise tous les paramètres de configuration pour faciliter les modifications
class AppConfig {
  // Informations sur l'application
  static const String appName = 'Flashcards';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';
  
  // Configurations spécifiques à la plateforme
  static const Map<String, dynamic> platformDefaults = {
    'windows': {
      'minWindowWidth': 800,
      'minWindowHeight': 600,
      'defaultFontSize': 14.0,
      'defaultAccentColor': 0xFF3D5AFE, // Bleu vif
    },
    'macos': {
      'minWindowWidth': 800,
      'minWindowHeight': 600,
      'defaultFontSize': 13.0,
      'defaultAccentColor': 0xFF3D5AFE,
    },
    'linux': {
      'minWindowWidth': 800,
      'minWindowHeight': 600,
      'defaultFontSize': 14.0,
      'defaultAccentColor': 0xFF3D5AFE,
    },
    'web': {
      'defaultFontSize': 14.0,
      'defaultAccentColor': 0xFF3D5AFE,
    },
    'mobile': {
      'defaultFontSize': 16.0,
      'defaultAccentColor': 0xFF3D5AFE,
    }
  };
  
  // Fonctionnalités
  static const bool useFirebase = false;
  static const bool enableAudioFeatures = true;
  static const bool enableStatistics = true;
  static const bool enableQuizMode = true;
  static const bool enableCloudSync = false; // Nécessite que useFirebase = true
  
  // Paramètres techniques
  static const int dbTimeout = 5000; // Délai d'attente pour les opérations de base de données (millisecondes)
  static const int maxExportItems = 1000; // Limite pour les exportations CSV
  
  // Clés de stockage
  static const String dbName = 'flashcards.db';
  static const String prefsKey = 'flashcards_prefs';
}
