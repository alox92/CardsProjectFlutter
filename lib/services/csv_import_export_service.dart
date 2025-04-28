import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/repositories/flashcard_repository.dart';
import 'package:share_extend/share_extend.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

/// Service responsable de l'importation et exportation des flashcards au format CSV
class CsvImportExportService {
  final FlashcardRepository _repository;
  
  /// Constructeur
  CsvImportExportService(this._repository);
  
  /// Génère un nom de fichier lisible pour les exports avec un horodatage
  String getExportFilename() {
    final now = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    return 'flashcards_export_$now.csv';
  }
  
  /// Convertit les flashcards en format CSV
  Future<String> convertCardsToCSV(List<Flashcard> cards, {List<String>? fields}) async {
    // Champs par défaut à exporter si non spécifiés
    fields ??= ['question', 'answer', 'category', 'is_known', 'tags'];
    
    // Prépare les données CSV avec des en-têtes
    final List<List<dynamic>> rows = [];
    
    // Ajoute d'abord la ligne d'en-tête
    rows.add(fields);
    
    // Ajoute les lignes de données
    for (final card in cards) {
      final row = <dynamic>[];
      for (final field in fields) {
        switch (field) {
          case 'question':
            row.add(card.question);
            break;
          case 'answer':
            row.add(card.answer);
            break;
          case 'category':
            row.add(card.category ?? '');
            break;
          case 'is_known':
            row.add(card.isKnown ? 1 : 0);
            break;
          case 'tags':
            row.add(card.tags?.join(' ') ?? '');
            break;
          default:
            row.add('');
        }
      }
      rows.add(row);
    }
    
    // Convertit en CSV en utilisant le package csv
    const csvConverter = ListToCsvConverter();
    return csvConverter.convert(rows);
  }

  /// Exporte les cartes vers un fichier temporaire et le partage
  Future<String> exportCardsToFile(List<Flashcard> cards) async {
    try {
      // Convertit les cartes en contenu CSV
      final csvContent = await convertCardsToCSV(cards);
      
      // Génère un nom de fichier
      final fileName = getExportFilename();
      
      // Obtient le répertoire temporaire
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // Écrit le contenu CSV dans le fichier
      final file = File(filePath);
      await file.writeAsString(csvContent);
      
      // Partage le fichier
      await ShareExtend.share(filePath, 'file', subject: 'Fichier CSV exporté');
      
      return 'Exportation réussie: $fileName';
    } catch (e) {
      return 'Erreur lors de l\'exportation: $e';
    }
  }
  
  /// Importe les cartes à partir d'un fichier sélectionné
  Future<String> importFromFile(PlatformFile file) async {
    try {
      String csvContent;
      
      if (file.bytes != null) {
        // Plateforme Web
        csvContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        // Autres plateformes (lecture à partir du fichier)
        final fileObj = File(file.path!);
        csvContent = await fileObj.readAsString();
      } else {
        return 'Erreur: impossible de lire le fichier';
      }
      
      // Analyse le contenu CSV en cartes
      final result = await parseCsvToCards(csvContent);
      
      // Vérifie s'il y a des erreurs d'analyse
      if (result.cards.isEmpty) {
        return 'Erreur: aucune carte valide trouvée dans le fichier CSV';
      }
      
      // Insère les cartes dans le dépôt
      final importResult = await _repository.importCards(result.cards);
      
      // Construit un message de résultat significatif
      return 'Importation réussie: ${importResult.successCount} cartes ajoutées, '
          '${importResult.updateCount} cartes mises à jour, '
          '${importResult.errorCount} erreurs';
    } catch (e) {
      return 'Erreur lors de l\'importation: $e';
    }
  }
  
  /// Structure pour stocker le résultat de l'analyse CSV
  class ImportParseResult {
    final List<Flashcard> cards;
    final List<Object> errors;
    
    const ImportParseResult({
      required this.cards,
      required this.errors,
    });
  }
  
  /// Analyse le contenu CSV en objets Flashcard
  Future<ImportParseResult> parseCsvToCards(String csvContent) async {
    final List<Flashcard> cards = [];
    final List<Object> errors = [];
    
    try {
      // Convertit le CSV en Liste
      const csvConverter = CsvToListConverter();
      final rows = csvConverter.convert(csvContent);
      
      // Valide que nous avons au moins une ligne d'en-tête
      if (rows.isEmpty) {
        return const ImportParseResult(cards: [], errors: ['Fichier CSV vide']);
      }
      
      // Extrait la ligne d'en-tête pour déterminer les colonnes
      final headers = rows.first.map((e) => e.toString().toLowerCase()).toList();
      
      // Trouve l'index de chaque colonne (toutes ne sont pas nécessairement présentes)
      final questionIndex = headers.indexOf('question');
      final answerIndex = headers.indexOf('answer');
      final categoryIndex = headers.indexOf('category');
      final isKnownIndex = headers.indexOf('is_known');
      final tagsIndex = headers.indexOf('tags');
      
      // Valide que les colonnes essentielles sont présentes
      if (questionIndex == -1 || answerIndex == -1) {
        return const ImportParseResult(
          cards: [], 
          errors: ['Format CSV invalide: colonnes question et/ou answer manquantes']
        );
      }
      
      // Traite les lignes de données (ignore l'en-tête)
      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          
          // Ignore les lignes vides
          if (row.isEmpty) continue;
          
          // Extrait les valeurs
          final question = row[questionIndex].toString();
          final answer = row[answerIndex].toString();
          
          // Ignore les lignes avec des champs obligatoires vides
          if (question.isEmpty || answer.isEmpty) {
            errors.add('Ligne $i: question ou réponse vide');
            continue;
          }
          
          // Champs optionnels
          String? category;
          bool isKnown = false;
          List<String>? tags;
          
          // Obtient la catégorie si disponible
          if (categoryIndex != -1 && row.length > categoryIndex) {
            category = row[categoryIndex].toString();
            if (category.isEmpty) category = null;
          }
          
          // Obtient isKnown si disponible
          if (isKnownIndex != -1 && row.length > isKnownIndex) {
            final value = row[isKnownIndex];
            if (value is bool) {
              isKnown = value;
            } else if (value is num) {
              isKnown = value > 0;
            } else if (value is String) {
              isKnown = value.toLowerCase() == 'true' || value == '1';
            }
          }
          
          // Obtient les tags si disponibles
          if (tagsIndex != -1 && row.length > tagsIndex) {
            final tagsStr = row[tagsIndex].toString();
            if (tagsStr.isNotEmpty) {
              tags = tagsStr.split(' ').where((tag) => tag.isNotEmpty).toList();
            }
          }
          
          // Crée l'objet Flashcard
          final card = Flashcard(
            question: question,
            answer: answer,
            category: category,
            isKnown: isKnown,
            tags: tags,
          );
          
          cards.add(card);
        } catch (e) {
          errors.add('Erreur à la ligne $i: $e');
        }
      }
      
      return ImportParseResult(cards: cards, errors: errors);
    } catch (e) {
      return ImportParseResult(cards: [], errors: ['Erreur de lecture CSV: $e']);
    }
  }
}