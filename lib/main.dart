import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'services/database_helper.dart'; // Correction de l'import
import 'core/theme/theme_manager.dart';
import 'core/accessibility/accessibility_manager.dart';
import 'views/home_view.dart'; // Correction de l'import pour HomeView
import 'config/app_config.dart';
import 'services/firebase_manager.dart'; // Correction de l'import

/// Point d'entrée principal de l'application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser SQLite FFI pour les plateformes desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Configuration du gestionnaire de fenêtre pour desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: const Size(1024, 768),
      center: true,
      backgroundColor: Colors.transparent,
      title: AppConfig.appName, // Utilisation de AppConfig
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialisation de Firebase si configuré
  if (AppConfig.useFirebase) {
    await FirebaseManager().initializeFirebase();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => AccessibilityManager()),
        Provider(create: (_) => DatabaseHelper.instance),
        if (AppConfig.useFirebase) Provider(create: (_) => FirebaseManager()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Application principale
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    
    return MaterialApp(
      title: AppConfig.appName, // Utilisation de AppConfig
      theme: themeManager.lightTheme,
      darkTheme: themeManager.darkTheme,
      themeMode: themeManager.themeMode,
      home: HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}