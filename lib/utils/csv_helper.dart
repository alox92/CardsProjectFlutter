import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/services/database_helper.dart';
import 'csv_parser.dart';
import 'logger.dart';

/// Utilitaire pour faciliter l'import/export de fichiers CSV
class CsvHelper {
  static final Logger _logger = Logger();

  /// Exporte les cartes vers un fichier CSV et retourne le chemin du fichier
  static Future<String?> exportCardsToFile(
    List<Flashcard> cards, {
    String? filename,
    String delimiter = ',',
    bool includeHeader = true,
    List<String>? fields,
  }) async {
    try {
      if (cards.isEmpty) {
        throw Exception('No cards to export');
      }

      final csvContent = CsvParser.exportCardsToCsv(
        cards, 
        delimiter: delimiter, 
        includeHeader: includeHeader, 
        fields: fields,
      );
      
      final String effectiveFilename = filename ?? 
          'flashcards_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, effectiveFilename);
      
      final file = File(filePath);
      await file.writeAsString(csvContent);
      
      _logger.info('${cards.length} cartes exportées vers $filePath');
      return filePath;
    } catch (e) {
      _logger.error('Erreur lors de l\'export CSV: $e');
      return null;
    }
  }

  /// Partage le fichier CSV généré avec d'autres applications
  static Future<void> shareExportedFile(String filePath) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Partager les cartes mémoire',
      );
      
      _logger.info('Fichier partagé: ${result.status}');
    } catch (e) {
      _logger.error('Erreur lors du partage du fichier: $e');
    }
  }

  /// Importe des cartes depuis un fichier CSV
  /// Retourne un tuple (nombre de cartes importées, erreurs)
  static Future<(int, List<String>)> importCardsFromFile(
    DatabaseHelper db, {
    String? filePath,
    String? delimiter,
    bool hasHeader = true,
    int? frontColumn,
    int? backColumn,
    int? categoryColumn,
  }) async {
    try {
      final String effectiveFilePath;
      if (filePath == null) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'txt'],
        );
        
        if (result == null || result.files.isEmpty) {
          return (0, ['Aucun fichier sélectionné']);
        }
        
        effectiveFilePath = result.files.single.path!;
      } else {
        effectiveFilePath = filePath;
      }
      
      final file = File(effectiveFilePath);
      final content = await file.readAsString();
      
      final validationWarnings = CsvParser.validateCsvContent(content);
      if (validationWarnings.isNotEmpty) {
        _logger.warning('Validation CSV: ${validationWarnings.join(', ')}');
      }
      
      final importResult = await CsvParser.parseCsvToCards(
        content,
        delimiter: delimiter,
        hasHeader: hasHeader,
        frontColumnIndex: frontColumn,
        backColumnIndex: backColumn,
        categoryColumnIndex: categoryColumn,
      );
      
      if (importResult.cards.isNotEmpty) {
        for (final card in importResult.cards) {
          await db.saveCard(card);
        }
      }
      
      final errorMessages = importResult.errors.map((e) => e.toString()).toList();
      
      if (validationWarnings.isNotEmpty) {
        errorMessages.addAll(validationWarnings.map((w) => 'Avertissement: $w'));
      }
      
      _logger.info(importResult.summary);
      
      return (importResult.successCount, errorMessages);
    } catch (e) {
      _logger.error('Erreur lors de l\'import CSV: $e');
      return (0, ['Erreur lors de l\'import: $e']);
    }
  }
  
  /// Analyse le contenu du fichier CSV et retourne des statistiques
  /// Utile pour l'aperçu avant import
  static Future<Map<String, dynamic>> analyzeFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'error': 'Fichier introuvable'};
      }
      
      final content = await file.readAsString();
      
      final delimiter = CsvParser.detectDelimiter(content);
      
      final lines = content.split('\n');
      final totalLines = lines.length;
      final previewLines = totalLines > 5 ? lines.take(5).toList() : lines;
      
      final headers = totalLines > 0 ? CsvParser.parseLine(lines[0], delimiter: delimiter) : [];
      
      final warnings = CsvParser.validateCsvContent(content);
      
      return {
        'filename': path.basename(filePath),
        'filesize': await file.length(),
        'totalLines': totalLines,
        'delimiter': delimiter,
        'headers': headers,
        'previewLines': previewLines,
        'warnings': warnings,
        'hasWarnings': warnings.isNotEmpty,
      };
    } catch (e) {
      _logger.error('Erreur lors de l\'analyse du fichier CSV: $e');
      return {'error': 'Erreur lors de l\'analyse: $e'};
    }
  }

  /// Affiche une boîte de dialogue de sélection de colonnes pour l'import
  static Future<Map<String, int>?> showColumnSelectionDialog(
    BuildContext context, {
    required List<String> headers,
  }) async {
    return await showColumnSelectionDialog(context, headers: headers);
  }
}
