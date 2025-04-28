import 'package:get_it/get_it.dart';
import 'package:projet/services/database_helper.dart';
import 'package:projet/repositories/flashcard_repository.dart';
import 'package:projet/services/csv_import_export_service.dart';
import 'package:projet/services/sync_service.dart';
import 'package:projet/utils/logger.dart';
import 'package:projet/core/theme/theme_manager.dart';
import 'package:projet/core/accessibility/accessibility_manager.dart';

/// Instance globale de GetIt
final GetIt getIt = GetIt.instance;

/// Classe responsable de l'initialisation des services et dépendances
class ServiceLocator {
  /// Configure toutes les dépendances nécessaires pour l'application
  static void setupServiceLocator() {
    // Services de base
    getIt.registerLazySingleton<Logger>(() => Logger());
    getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
    
    // Services métier
    getIt.registerLazySingleton<FlashcardRepository>(
      () => FlashcardRepository(getIt<DatabaseHelper>())
    );
    
    getIt.registerLazySingleton<CsvImportExportService>(
      () => CsvImportExportService(getIt<FlashcardRepository>())
    );
    
    getIt.registerLazySingleton<SyncService>(
      () => SyncService(getIt<DatabaseHelper>())
    );
    
    // Managers d'UI
    getIt.registerLazySingleton<ThemeManager>(() => ThemeManager());
    getIt.registerLazySingleton<AccessibilityManager>(() => AccessibilityManager());

    // Configuration de l'instance singleton du FlashcardRepository
    FlashcardRepository.configureInstance(getIt<DatabaseHelper>());
  }
}
