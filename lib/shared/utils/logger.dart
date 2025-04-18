import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  
  Logger._internal();
  
  File? _logFile;
  bool _consoleOutput = true;
  LogLevel _minimumLevel = LogLevel.info;

  Future<void> init() async {
    if (_logFile != null) return;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/flashcards_app.log');
    } catch (e) {
      print('Impossible d\'initialiser le fichier de log: $e');
    }
  }
  
  void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
  }
  
  void enableConsoleOutput(bool enable) {
    _consoleOutput = enable;
  }

  Future<void> log(String message, {LogLevel level = LogLevel.info}) async {
    if (level.index < _minimumLevel.index) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] ${level.toString().split('.').last}: $message';
    
    if (_consoleOutput) {
      print(logEntry);
    }
    
    if (_logFile != null) {
      try {
        await _logFile!.writeAsString('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        print('Erreur d\'écriture dans le fichier de log: $e');
      }
    }
  }
  
  void debug(String message) => log(message, level: LogLevel.debug);
  void info(String message) => log(message, level: LogLevel.info);
  void warning(String message) => log(message, level: LogLevel.warning);
  void error(String message) => log(message, level: LogLevel.error);
}
