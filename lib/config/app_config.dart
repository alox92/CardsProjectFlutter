class AppConfig {
  // Version de l'application
  static const String appVersion = '1.0.0';
  
  // Configurations spécifiques à la plateforme
  static const Map<String, dynamic> platformDefaults = {
    'windows': {
      'minWindowWidth': 800,
      'minWindowHeight': 600,
      'defaultFontSize': 14.0,
    },
    'macos': {
      'minWindowWidth': 800,
      'minWindowHeight': 600,
      'defaultFontSize': 13.0,
    },
    'linux': {
      'minWindowWidth': 800,
      'minWindowHeight': 600,
      'defaultFontSize': 14.0,
    },
  };
  
  // Déterminer si l'application utilise Firebase
  static const bool useFirebase = false;
  
  // Délai d'attente pour les opérations de base de données (millisecondes)
  static const int dbTimeout = 5000;
}
