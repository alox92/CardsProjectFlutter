import 'dart:convert';
import 'package:projet/features/flashcards/models/flashcard.dart';
import '../utils/logger.dart';
import 'csv_exceptions.dart';
import 'csv_import_result.dart';
import 'csv_utils.dart';

/// Classe statique optimisée pour parser des fichiers CSV
class CsvParser {
  static final Logger _logger = Logger();

  /// Parse une ligne CSV et retourne les champs séparés
  static List<String> parseLine(String line, {String delimiter = ','}) {
    return CsvUtils.parseLine(line, delimiter: delimiter);
  }

  /// Encode une liste de champs en ligne CSV
  static String encodeLine(List<String> fields, {String delimiter = ','}) {
    return CsvUtils.encodeLine(fields, delimiter: delimiter);
  }

  /// Détecte automatiquement le délimiteur d'un fichier CSV
  static String detectDelimiter(String csvContent) {
    return CsvUtils.detectDelimiter(csvContent);
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
