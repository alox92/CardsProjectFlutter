/// Exception pour les erreurs de parsing CSV
class CsvParserException implements Exception {
  final String message;
  final int? line;
  final String? content;

  CsvParserException(this.message, {this.line, this.content});

  @override
  String toString() {
    String result = 'CsvParserException: $message';
    if (line != null) {
      result += ' (ligne $line)';
    }
    if (content != null) {
      result += '\nContenu: "$content"';
    }
    return result;
  }
}
