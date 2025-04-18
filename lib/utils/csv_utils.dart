/// Fonctions utilitaires pour le parsing CSV
class CsvUtils {
  /// Parse une ligne CSV et retourne les champs séparés
  static List<String> parseLine(String line, {String delimiter = ','}) {
    if (line.isEmpty) return [];
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer currentField = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          currentField.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        result.add(currentField.toString());
        currentField = StringBuffer();
      } else {
        currentField.write(char);
      }
    }
    if (inQuotes) {
      // Optionnel: log warning
    }
    result.add(currentField.toString());
    return result;
  }

  /// Encode une liste de champs en ligne CSV
  static String encodeLine(List<String> fields, {String delimiter = ','}) {
    return fields.map((field) {
      if (field.contains('"') || field.contains(delimiter) || field.contains('\n')) {
        return '"${field.replaceAll('"', '""')}"';
      }
      return field;
    }).join(delimiter);
  }

  /// Détecte automatiquement le délimiteur d'un fichier CSV
  static String detectDelimiter(String csvContent) {
    if (csvContent.isEmpty) return ',';
    final firstLine = csvContent.split('\n').first;
    final possibleDelimiters = [',', ';', '\t', '|'];
    int maxCount = 0;
    String detectedDelimiter = ',';
    for (final delimiter in possibleDelimiters) {
      bool inQuotes = false;
      int count = 0;
      for (int i = 0; i < firstLine.length; i++) {
        final char = firstLine[i];
        if (char == '"') {
          inQuotes = !inQuotes;
        } else if (char == delimiter && !inQuotes) {
          count++;
        }
      }
      if (count > maxCount) {
        maxCount = count;
        detectedDelimiter = delimiter;
      }
    }
    return detectedDelimiter;
  }
}
