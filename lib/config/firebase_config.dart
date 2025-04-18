import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'dart:convert';

/// Configuration pour Firebase
class FirebaseConfig {
  /// Identifiant de l'application web
  static const String webAppId = 'YOUR_WEB_APP_ID';
  /// Clé API pour web
  static const String webApiKey = 'YOUR_WEB_API_KEY';
  /// ID du projet
  static const String projectId = 'flashcards-app';
  /// ID du messager
  static const String messagingSenderId = 'YOUR_SENDER_ID';
  
  /// Configuration pour Android
  static const String androidAppId = 'YOUR_ANDROID_APP_ID';
  
  /// Configuration pour iOS
  static const String iosAppId = 'YOUR_IOS_APP_ID';
  /// Bundle ID iOS
  static const String iosBundleId = 'com.example.flashcards';
  
  /// Domaine de stockage
  static const String storageBucket = 'flashcards-app.appspot.com';
  
  /// Identifiant du client d'authentification
  static const String authClientId = '';

  /// Obtient les options Firebase selon la plateforme
  static Future<FirebaseOptions?> getPlatformOptions() async {
    try {
      // Charger depuis un fichier de configuration sécurisé
      final configFile = await File('${Directory.current.path}/firebase_config.json')
          .readAsString()
          .catchError((_) => '{}');
      
      final config = jsonDecode(configFile);
      
      if (Platform.isAndroid) {
        return _getAndroidOptions(config);
      } else if (Platform.isIOS) {
        return _getIOSOptions(config);
      } else if (Platform.isMacOS) {
        return _getMacOSOptions(config);
      } else if (Platform.isWindows) {
        return _getWindowsOptions(config);
      }
    } catch (e) {
      print('Erreur lors du chargement de la configuration Firebase: $e');
    }
    return null;
  }

  // Méthodes privées pour extraire les options selon la plateforme
  static FirebaseOptions _getAndroidOptions(Map<String, dynamic> config) {
    return FirebaseOptions(
      appId: config['FIREBASE_ANDROID_APP_ID'] ?? '',
      apiKey: config['FIREBASE_ANDROID_API_KEY'] ?? '',
      projectId: config['FIREBASE_PROJECT_ID'] ?? '',
      messagingSenderId: config['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
    );
  }

  static FirebaseOptions _getIOSOptions(Map<String, dynamic> config) {
    return FirebaseOptions(
      appId: config['FIREBASE_IOS_APP_ID'] ?? '',
      apiKey: config['FIREBASE_IOS_API_KEY'] ?? '',
      projectId: config['FIREBASE_PROJECT_ID'] ?? '',
      messagingSenderId: config['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      iosBundleId: config['FIREBASE_IOS_BUNDLE_ID'] ?? '',
    );
  }

  static FirebaseOptions _getMacOSOptions(Map<String, dynamic> config) {
    return FirebaseOptions(
      appId: config['FIREBASE_MACOS_APP_ID'] ?? '',
      apiKey: config['FIREBASE_MACOS_API_KEY'] ?? '',
      projectId: config['FIREBASE_PROJECT_ID'] ?? '',
      messagingSenderId: config['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
    );
  }

  static FirebaseOptions _getWindowsOptions(Map<String, dynamic> config) {
    return FirebaseOptions(
      appId: config['FIREBASE_WINDOWS_APP_ID'] ?? '',
      apiKey: config['FIREBASE_WINDOWS_API_KEY'] ?? '',
      projectId: config['FIREBASE_PROJECT_ID'] ?? '',
      messagingSenderId: config['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
    );
  }
}
