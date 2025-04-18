import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:projet/services/database_helper.dart';

import '../../features/flashcards/models/flashcard.dart';
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
    if (cards.isEmpty) {
      _logger.warning('Tentative d\'export d\'une liste vide de cartes');
      return null;
    }
    
    try {
      // Générer le contenu CSV
      final csvContent = CsvParser.exportCardsToCsv(
        cards, 
        delimiter: delimiter, 
        includeHeader: includeHeader, 
        fields: fields
      );
      
      // Générer un nom de fichier par défaut si non fourni
      final String effectiveFilename = filename ?? 
          'flashcards_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      // Obtenir le dossier de documents
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, effectiveFilename);
      
      // Écrire le fichier
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
      // Si pas de chemin spécifié, ouvrir le sélecteur de fichier
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
      
      // Lire le contenu du fichier
      final file = File(effectiveFilePath);
      final content = await file.readAsString();
      
      // Valider le contenu CSV avant import
      final validationWarnings = CsvParser.validateCsvContent(content);
      if (validationWarnings.isNotEmpty) {
        _logger.warning('Validation CSV: ${validationWarnings.join(', ')}');
        // On continue malgré les avertissements, mais on les log pour le rapport d'erreur
      }
      
      // Parser le fichier CSV en cartes
      final importResult = await CsvParser.parseCsvToCards(
        content,
        delimiter: delimiter,
        hasHeader: hasHeader,
        frontColumnIndex: frontColumn,
        backColumnIndex: backColumn,
        categoryColumnIndex: categoryColumn,
      );
      
      // Insérer les cartes dans la base de données
      if (importResult.cards.isNotEmpty) {
        for (final card in importResult.cards) {
          await db.saveCard(card);
        }
      }
      
      // Générer des messages d'erreur lisibles pour l'utilisateur
      final errorMessages = importResult.errors.map((e) => e.toString()).toList();
      
      // Ajouter les avertissements de validation si présents
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
      
      // Détection du délimiteur
      final delimiter = CsvParser.detectDelimiter(content);
      
      // Extraire quelques lignes pour aperçu
      final lines = content.split('\n');
      final totalLines = lines.length;
      final previewLines = totalLines > 5 ? lines.take(5).toList() : lines;
      
      // Extraire les en-têtes si présents (première ligne)
      final headers = totalLines > 0 ? CsvParser.parseLine(lines[0], delimiter: delimiter) : [];
      
      // Validation
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
    int frontColIndex = -1;
    int backColIndex = -1;
    int categoryColIndex = -1;
    
    // Tenter de détecter automatiquement les colonnes
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase();
      if (frontColIndex == -1 && 
          (header.contains('front') || header.contains('question') || header.contains('recto'))) {
        frontColIndex = i;
      }
      if (backColIndex == -1 && 
          (header.contains('back') || header.contains('answer') || header.contains('verso'))) {
        backColIndex = i;
      }
      if (categoryColIndex == -1 && 
          (header.contains('category') || header.contains('catégorie') || 
           header.contains('tag') || header.contains('tags'))) {
        categoryColIndex = i;
      }
    }
    
    // Si on n'a pas trouvé les colonnes, utiliser les deux premières
    if (frontColIndex == -1 && headers.length > 0) frontColIndex = 0;
    if (backColIndex == -1 && headers.length > 1) backColIndex = 1;
    if (categoryColIndex == -1 && headers.length > 2) categoryColIndex = 2;
    
    // Afficher la boîte de dialogue
    final result = await showDialog<Map<String, int>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Sélection des colonnes'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Veuillez sélectionner les colonnes à importer:'),
                  SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Colonne recto (question)'),
                    value: frontColIndex >= 0 ? frontColIndex : null,
                    items: List.generate(
                      headers.length,
                      (i) => DropdownMenuItem(value: i, child: Text('${i+1}: ${headers[i]}')),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => frontColIndex = value);
                      }
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Colonne verso (réponse)'),
                    value: backColIndex >= 0 ? backColIndex : null,
                    items: List.generate(
                      headers.length,
                      (i) => DropdownMenuItem(value: i, child: Text('${i+1}: ${headers[i]}')),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => backColIndex = value);
                      }
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Colonne catégorie (optionnel)'),
                    value: categoryColIndex >= 0 ? categoryColIndex : null,
                    items: [
                      DropdownMenuItem(value: -1, child: Text('Aucune')),
                      ...List.generate(
                        headers.length,
                        (i) => DropdownMenuItem(value: i, child: Text('${i+1}: ${headers[i]}')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => categoryColIndex = value ?? -1);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (frontColIndex >= 0 && backColIndex >= 0) {
                      Navigator.pop(context, {
                        'front': frontColIndex,
                        'back': backColIndex,
                        'category': categoryColIndex >= 0 ? categoryColIndex : null,
                      });
                    }
                  },
                  child: Text('Importer'),
                ),
              ],
            );
          },
        );
      },
    );
    
    return result;
  }
}
