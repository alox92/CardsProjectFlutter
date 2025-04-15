import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_helper.dart';
import 'theme_manager.dart';
import 'accessibility_manager.dart';
import 'views/home_view.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'config/app_config.dart'; // Importer AppConfig
import 'services/firebase_manager.dart'; // Importer FirebaseManager
import 'package:flutter/foundation.dart' show kIsWeb;

// Point d'entrée principal de l'application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for sqflite on desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Window Manager Setup for desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(900, 700),
      center: true,
      backgroundColor: Colors.transparent,
      title: "Flashcards",
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize local database - Ensure correct method name
  await DatabaseHelper.instance.initDb();

  // Initialize Firebase if configured
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
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return MaterialApp(
      title: 'Flashcards',
      theme: ThemeData.light().copyWith(
        // Personnaliser les thèmes pour un look plus desktop
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.blue,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        // Version sombre pour desktop
        primaryColor: Colors.blue.shade700,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade700,
          secondary: Colors.blueAccent.shade700,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.blue.shade800,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      themeMode: themeManager.themeMode,
      home: HomeView(),
      debugShowCheckedModeBanner: false, // Enlever la bannière de debug
    );
  }
}