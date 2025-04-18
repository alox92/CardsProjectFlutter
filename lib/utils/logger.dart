import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Classe utilitaire pour la journalisation avec différents niveaux de sévérité
class Logger {
  final String _tag;
  
  /// Constructeur avec tag optionnel pour identifier la source des logs
  Logger([this._tag = 'FlashcardsApp']);
  
  /// Log de niveau information
  void info(String message) {
    _log('INFO', message);
  }
  
  /// Log de niveau débogage
  void debug(String message) {
    _log('DEBUG', message);
  }
  
  /// Log de niveau avertissement
  void warning(String message) {
    _log('WARNING', message);
  }
  
  /// Log de niveau erreur
  void error(String message) {
    _log('ERROR', message);
  }
  
  /// Méthode interne pour formater et envoyer les logs
  void _log(String level, String message) {
    final formattedMessage = '[$_tag][$level] $message';
    
    if (kDebugMode) {
      if (level == 'ERROR') {
        print('\x1B[31m$formattedMessage\x1B[0m'); // Rouge pour les erreurs
      } else if (level == 'WARNING') {
        print('\x1B[33m$formattedMessage\x1B[0m'); // Jaune pour les avertissements
      } else if (level == 'DEBUG') {
        print('\x1B[36m$formattedMessage\x1B[0m'); // Cyan pour le débogage
      } else {
        print('\x1B[32m$formattedMessage\x1B[0m'); // Vert pour les infos
      }
      
      // Utiliser également dart:developer pour une meilleure visibilité dans DevTools
      developer.log(
        message,
        name: _tag,
        level: _getLevelValue(level),
      );
    }
  }
  
  /// Convertit le niveau textuel en valeur numérique pour dart:developer
  int _getLevelValue(String level) {
    switch (level) {
      case 'ERROR':
        return 1000;
      case 'WARNING':
        return 800;
      case 'INFO':
        return 500;
      case 'DEBUG':
        return 300;
      default:
        return 500;
    }
  }
}
