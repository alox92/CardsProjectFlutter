import 'csv_exceptions.dart';
import '../features/flashcards/models/flashcard.dart';

/// Résultat d'une opération d'importation CSV
class CsvImportResult {
  final List<Flashcard> cards;
  final List<CsvParserException> errors;
  final int totalLinesProcessed;
  final int successCount;
  final int warningCount;

  CsvImportResult({
    required this.cards,
    required this.errors,
    required this.totalLinesProcessed,
    required this.successCount,
    required this.warningCount,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warningCount > 0;
  
  /// Résumé textuel du résultat de l'import
  String get summary => 
    'Import terminé: $successCount cartes importées sur $totalLinesProcessed lignes' +
    (hasErrors ? ', {errors.length} erreurs' : '') +
    (hasWarnings ? ', $warningCount avertissements' : '');
}
