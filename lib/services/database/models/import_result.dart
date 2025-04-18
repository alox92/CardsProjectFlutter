/// Modèle de résultat pour les opérations d'importation
class ImportResult {
  final String message;
  final int successCount;
  final int updateCount;
  final int errorCount;
  final List<String> errors;

  const ImportResult({
    required this.message,
    required this.successCount,
    required this.updateCount,
    required this.errorCount,
    required this.errors,
  });
}

/// Exception spécifique pour les erreurs d'importation avec résumé
class ImportSummaryException implements Exception {
  final String message;
  final int successCount;
  final List<String> errors;

  ImportSummaryException(
    this.message, {
    this.successCount = 0,
    this.errors = const [],
  });

  @override
  String toString() => '$message (${errors.join(', ')})';
}