import 'dart:convert';
import '../models/flashcard.dart';
import '../utils/logger.dart';

/// CsvParserException est lancée quand il y a une erreur lors du parsing CSV
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
    (hasErrors ? ', ${errors.length} erreurs' : '') +
    (hasWarnings ? ', $warningCount avertissements' : '');
}

/// Classe statique optimisée pour parser des fichiers CSV
class CsvParser {
  static final Logger _logger = Logger();

  /// Parse une ligne CSV et retourne les champs séparés
  /// La ligne peut contenir des champs entre guillemets, des virgules dans les champs, etc.
  static List<String> parseLine(String line, {String delimiter = ','}) {
    if (line.isEmpty) return [];
    
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer currentField = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      // Gérer les guillemets
      if (char == '"') {
        // Double guillemet à l'intérieur d'un champ entre guillemets
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          currentField.write('"');
          i++; // Sauter le guillemet suivant
        } else {
          // Basculer l'état "dans les guillemets"
          inQuotes = !inQuotes;
        }
      } 
      // Gérer les délimiteurs (virgules par défaut)
      else if (char == delimiter && !inQuotes) {
        result.add(currentField.toString());
        currentField = StringBuffer();
      } 
      // Ajouter le caractère au champ actuel
      else {
        currentField.write(char);
      }
    }
    
    // Vérifier si les guillemets sont bien fermés
    if (inQuotes) {
      _logger.warning('Guillemets non fermés dans la ligne CSV: "$line"');
    }
    
    // Ajouter le dernier champ
    result.add(currentField.toString());
    
    return result;
  }

  /// Encode une liste de champs en ligne CSV
  static String encodeLine(List<String> fields, {String delimiter = ','}) {
    return fields.map((field) {
      // Si le champ contient des délimiteurs, des guillemets ou des sauts de ligne,
      // l'entourer de guillemets et doubler les guillemets internes
      if (field.contains('"') || field.contains(delimiter) || field.contains('\n')) {
        return '"${field.replaceAll('"', '""')}"';
      }
      return field;
    }).join(delimiter);
  }
  
  /// Détecte automatiquement le délimiteur d'un fichier CSV (virgule, point-virgule, tabulation)
  /// Retourne ',' par défaut si ne peut pas être déterminé
  static String detectDelimiter(String csvContent) {
    if (csvContent.isEmpty) return ',';
    
    // Extraire la première ligne du fichier
    final firstLine = csvContent.split('\n').first;
    
    // Liste des délimiteurs courants à tester
    final possibleDelimiters = [',', ';', '\t', '|'];
    int maxCount = 0;
    String detectedDelimiter = ',';
    
    // Compter les occurrences de chaque délimiteur dans la première ligne
    for (final delimiter in possibleDelimiters) {
      // Compter en évitant les délimiteurs dans des champs entre guillemets
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
    
    _logger.info('Délimiteur CSV détecté: "$detectedDelimiter"');
    return detectedDelimiter;
  }
  
  /// Parse le contenu complet d'un fichier CSV et crée des cartes
  /// Retourne un CsvImportResult avec les cartes créées et les erreurs
  static Future<CsvImportResult> parseCsvToCards(String csvContent, {
    String? delimiter,
    bool hasHeader = true,
    int? frontColumnIndex,
    int? backColumnIndex,
    int? categoryColumnIndex,
  }) async {
    final List<Flashcard> cards = [];
    final List<CsvParserException> errors = [];
    int totalLines = 0;
    int successCount = 0;
    int warningCount = 0;
    
    // Utiliser le délimiteur détecté si non spécifié
    final effectiveDelimiter = delimiter ?? detectDelimiter(csvContent);
    
    // Diviser le contenu en lignes
    final lines = LineSplitter.split(csvContent).toList();
    if (lines.isEmpty) {
      errors.add(CsvParserException('Le fichier CSV est vide'));
      return CsvImportResult(
        cards: [],
        errors: errors,
        totalLinesProcessed: 0,
        successCount: 0,
        warningCount: 0,
      );
    }
    
    totalLines = lines.length;
    
    // Analyser l'en-tête si présent
    List<String>? headers;
    int startIndex = 0;
    
    if (hasHeader) {
      try {
        headers = parseLine(lines.first, delimiter: effectiveDelimiter);
        startIndex = 1;  // Commencer après l'en-tête
        
        // Détection automatique des colonnes si indices non spécifiés
        if (frontColumnIndex == null) {
          frontColumnIndex = _findColumnIndex(headers, ['front', 'question', 'recto', 'terme']);
        }
        if (backColumnIndex == null) {
          backColumnIndex = _findColumnIndex(headers, ['back', 'answer', 'verso', 'définition', 'definition']);
        }
        if (categoryColumnIndex == null) {
          categoryColumnIndex = _findColumnIndex(headers, ['category', 'catégorie', 'categorie', 'tag', 'tags']);
        }
        
        _logger.info('Indices des colonnes détectés: front=$frontColumnIndex, back=$backColumnIndex, category=$categoryColumnIndex');
      } catch (e) {
        errors.add(CsvParserException('Erreur lors de l\'analyse de l\'en-tête: $e', line: 0, content: lines.first));
        return CsvImportResult(
          cards: [],
          errors: errors,
          totalLinesProcessed: 0,
          successCount: 0,
          warningCount: 0,
        );
      }
    }
    
    // Si les indices de colonnes ne sont toujours pas définis, utiliser les valeurs par défaut
    frontColumnIndex ??= 0;
    backColumnIndex ??= 1;
    categoryColumnIndex ??= 2;
    
    // Traiter les lignes (en parallèle pour les fichiers volumineux)
    await Future(() async {
      for (int i = startIndex; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        try {
          final fields = parseLine(line, delimiter: effectiveDelimiter);
          
          // Vérifier si nous avons au moins les champs recto et verso
          if (fields.length <= frontColumnIndex! || fields.length <= backColumnIndex!) {
            errors.add(CsvParserException(
              'Nombre de champs insuffisant dans la ligne',
              line: i + 1, 
              content: line
            ));
            continue;
          }
          
          // Récupérer les valeurs des champs
          final front = fields[frontColumnIndex].trim();
          final back = fields[backColumnIndex].trim();
          
          // Vérifier que les champs requis ne sont pas vides
          if (front.isEmpty || back.isEmpty) {
            warningCount++;
            _logger.warning('Ligne $i: Champ vide (front ou back)');
            continue;
          }
          
          // Récupérer la catégorie si elle existe
          String? category;
          if (categoryColumnIndex! < fields.length && fields[categoryColumnIndex].isNotEmpty) {
            category = fields[categoryColumnIndex].trim();
          }
          
          // Créer la carte avec un nouvel UUID et un timestamp
          final card = Flashcard(
            uuid: Flashcard.generateUuid(),
            front: front,
            back: back,
            category: category,
            lastModified: DateTime.now().millisecondsSinceEpoch,
          );
          
          cards.add(card);
          successCount++;
        } catch (e) {
          errors.add(CsvParserException('Erreur lors du parsing de la ligne: $e', line: i + 1, content: line));
        }
      }
    });
    
    return CsvImportResult(
      cards: cards,
      errors: errors,
      totalLinesProcessed: totalLines - (hasHeader ? 1 : 0),
      successCount: successCount,
      warningCount: warningCount,
    );
  }
  
  /// Cherche l'index d'une colonne dans l'en-tête par nom (insensible à la casse)
  static int? _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (final name in possibleNames) {
      for (int i = 0; i < headers.length; i++) {
        if (headers[i].trim().toLowerCase() == name.toLowerCase()) {
          return i;
        }
      }
    }
    return null;
  }

  /// Exporte une liste de cartes au format CSV
  static String exportCardsToCsv(List<Flashcard> cards, {
    String delimiter = ',',
    bool includeHeader = true,
    List<String>? fields,
  }) {
    final StringBuffer buffer = StringBuffer();
    
    // Déterminer les champs à exporter
    final effectiveFields = fields ?? ['front', 'back', 'category', 'is_known', 'review_count'];
    
    // Écrire l'en-tête
    if (includeHeader) {
      buffer.writeln(encodeLine(effectiveFields, delimiter: delimiter));
    }
    
    // Écrire les lignes de données
    for (final card in cards) {
      final List<String> values = [];
      
      for (final field in effectiveFields) {
        switch (field) {
          case 'front':
            values.add(card.front);
            break;
          case 'back':
            values.add(card.back);
            break;
          case 'category':
            values.add(card.category ?? '');
            break;
          case 'is_known':
            values.add(card.isKnown ? '1' : '0');
            break;
          case 'review_count':
            values.add(card.reviewCount.toString());
            break;
          case 'difficulty_score':
            values.add(card.difficultyScore.toString());
            break;
          default:
            values.add(''); // Champ inconnu
            break;
        }
      }
      
      buffer.writeln(encodeLine(values, delimiter: delimiter));
    }
    
    return buffer.toString();
  }
  
  /// Valide le contenu CSV et retourne les erreurs potentielles
  /// Utile pour pré-valider un CSV avant import
  static List<String> validateCsvContent(String csvContent) {
    final List<String> warnings = [];
    
    if (csvContent.trim().isEmpty) {
      warnings.add('Le contenu CSV est vide');
      return warnings;
    }
    
    final lines = LineSplitter.split(csvContent).toList();
    
    if (lines.length < 2) {
      warnings.add('Le fichier CSV doit contenir au moins un en-tête et une ligne de données');
    }
    
    // Détecter le délimiteur
    final delimiter = detectDelimiter(csvContent);
    
    try {
      // Valider l'en-tête
      final headers = parseLine(lines.first, delimiter: delimiter);
      
      if (headers.length < 2) {
        warnings.add('L\'en-tête doit contenir au moins deux colonnes (recto et verso)');
      }
      
      // Vérifier quelques lignes
      final linesToCheck = lines.length > 6 ? 5 : lines.length - 1;
      int lastFieldCount = headers.length;
      
      for (int i = 1; i <= linesToCheck; i++) {
        final fields = parseLine(lines[i], delimiter: delimiter);
        
        if (fields.length != lastFieldCount) {
          warnings.add('La ligne ${i + 1} a un nombre de champs différent (${fields.length}) de l\'en-tête ($lastFieldCount)');
        }
        
        if (fields.length >= 2) {
          if (fields[0].trim().isEmpty) {
            warnings.add('La ligne ${i + 1} a un champ recto vide');
          }
          if (fields[1].trim().isEmpty) {
            warnings.add('La ligne ${i + 1} a un champ verso vide');
          }
        }
      }
    } catch (e) {
      warnings.add('Erreur lors de la validation: $e');
    }
    
    return warnings;
  }
}
