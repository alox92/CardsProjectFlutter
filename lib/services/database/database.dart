import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../../utils/logger.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';

import 'database_provider.dart';
import 'sqlite_provider.dart';
import 'web_storage_provider.dart';
import 'models/import_result.dart';

/// Gestionnaire de base de données pour les Flashcards
/// Fournit une interface unifiée pour les opérations de base de données sur différentes plateformes
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper({String? databasePath}) => _instance.._customDbPath = databasePath;
  static DatabaseHelper get instance => _instance;

  String? _customDbPath;
  late DatabaseProvider _provider;
  final Uuid uuid = Uuid();
  final Logger _logger = Logger();

  // Cache mémoire pour accélérer les accès en lecture
  bool _useCache = true;
  List<Flashcard>? _cache;

  /// Constructeur privé
  DatabaseHelper._internal() {
    _initializeProvider();
  }

  /// Initialise le provider approprié en fonction de la plateforme
  void _initializeProvider() {
    if (kIsWeb) {
      _provider = WebStorageProvider(logger: _logger);
    } else {
      _provider = SqliteProvider(
        logger: _logger,
        databasePath: _customDbPath,
        uuid: uuid,
      );
    }
  }

  // Propriétés publiques
  String get tableName => 'flashcards';

  /// Active ou désactive le cache mémoire
  void enableCache(bool enable) {
    _useCache = enable;
    if (!enable) {
      clearCache();
    }
  }

  /// Vide le cache
  void clearCache() {
    _cache = null;
    _logger.debug('Cache cleared');
  }

  /// Invalide le cache (à appeler après toute modification)
  void _invalidateCache() {
    if (_useCache) {
      _cache = null;
      _logger.debug('Cache invalidated');
    }
  }

  // OPÉRATIONS CRUD DE BASE

  /// Sauvegarde une carte
  Future<int> saveCard(Flashcard card) async {
    final result = await _provider.insertCard(card);
    _invalidateCache();
    return result;
  }

  /// Récupère une carte par ID
  Future<Flashcard?> getCardById(int id) async {
    return _provider.getCard(id: id);
  }

  /// Récupère une carte par UUID
  Future<Flashcard?> getCardByUuid(String uuid) async {
    return _provider.getCard(uuid: uuid);
  }

  /// Met à jour une carte
  Future<int> updateCard(Flashcard card) async {
    final result = await _provider.updateCard(card);
    _invalidateCache();
    return result;
  }

  /// Supprime logiquement une carte par ID
  Future<int> deleteCard(int id) async {
    final result = await _provider.deleteCard(id);
    _invalidateCache();
    return result;
  }

  /// Supprime logiquement une carte par UUID
  Future<int> deleteCardByUuid(String uuid) async {
    final Flashcard? card = await getCardByUuid(uuid);
    if (card != null && card.id != null) {
      return deleteCard(card.id!);
    }
    return 0;
  }

  /// Supprime définitivement une carte par ID
  Future<int> deleteCardPermanently(int id) async {
    final result = await _provider.permanentlyDeleteCard(id);
    _invalidateCache();
    return result;
  }

  /// Insère ou met à jour une carte (upsert)
  Future<int> upsertCard(Flashcard card) async {
    // Vérifier si la carte existe déjà
    Flashcard? existingCard;
    if (card.uuid != null) {
      existingCard = await getCardByUuid(card.uuid!);
    } else if (card.id != null) {
      existingCard = await getCardById(card.id!);
    }

    if (existingCard != null) {
      // Mise à jour
      return updateCard(card);
    } else {
      // Insertion
      return saveCard(card);
    }
  }

  // OPÉRATIONS EN LOT

  /// Récupère toutes les cartes
  Future<List<Flashcard>> getAllCards({bool includeDeleted = false}) async {
    // Utiliser le cache si disponible et applicable
    if (!includeDeleted && _useCache && _cache != null) {
      _logger.debug('Returning ${_cache!.length} cards from cache');
      return _cache!;
    }

    final cards = await _provider.getAllCards(includeDeleted: includeDeleted);
    
    // Mettre à jour le cache uniquement si on récupère toutes les cartes non supprimées
    if (_useCache && !includeDeleted) {
      _cache = cards;
    }
    
    return cards;
  }

  /// Récupère les cartes non connues
  Future<List<Flashcard>> getUnknownCards() async {
    return _provider.getUnknownCards();
  }

  /// Récupère les cartes par catégorie
  Future<List<Flashcard>> getCardsByCategory(String category) async {
    return _provider.getCardsByCategory(category);
  }

  /// Récupère les cartes supprimées
  Future<List<Flashcard>> getDeletedCards() async {
    return _provider.getAllCards(includeDeleted: true)
        .then((cards) => cards.where((card) => card.isDeleted).toList());
  }

  /// Récupère les cartes modifiées depuis un timestamp
  Future<List<Flashcard>> getCardsModifiedSince(int timestamp) async {
    return _provider.getCardsModifiedSince(timestamp);
  }

  /// Insère plusieurs cartes en même temps
  Future<ImportResult> insertMultipleCards(List<Flashcard> cards) async {
    int successCount = 0;
    int updateCount = 0;
    int errorCount = 0;
    List<String> errors = [];
    
    for (var card in cards) {
      try {
        final result = await saveCard(card);
        if (result > 0) {
          successCount++;
        } else {
          updateCount++;
        }
      } catch (e) {
        errorCount++;
        errors.add(e.toString());
      }
    }
    
    _invalidateCache();
    final message = 'Import terminé: $successCount ajoutées, $updateCount mises à jour, $errorCount erreurs';
    
    return ImportResult(
      message: message,
      successCount: successCount,
      updateCount: updateCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  /// Supprime toutes les cartes (DANGER: opération irréversible)
  Future<int> purgeAllCards() async {
    // Obtenir toutes les cartes
    final allCards = await getAllCards(includeDeleted: true);
    int count = 0;
    
    // Supprimer définitivement chaque carte
    for (var card in allCards) {
      if (card.id != null) {
        final result = await deleteCardPermanently(card.id!);
        count += result;
      }
    }
    
    _invalidateCache();
    return count;
  }

  // MÉTADONNÉES

  /// Récupère une métadonnée par clé
  Future<String?> getMetadata(String key) async {
    return _provider.getMetadataValue(key);
  }

  /// Définit une métadonnée
  Future<void> setMetadata(String key, String value) async {
    await _provider.setMetadataValue(key, value);
  }

  // IMPORT/EXPORT

  /// Exporte les cartes en format CSV
  Future<String> exportToCsv() async {
    return _provider.exportToCsv();
  }

  /// Importe des cartes depuis du contenu CSV
  Future<ImportResult> importFromCsv(String csvContent) async {
    final result = await _provider.importFromCsv(csvContent);
    _invalidateCache();
    return ImportResult(
      message: "Importation terminée", 
      successCount: result, 
      updateCount: 0,
      errorCount: 0,
      errors: []
    );
  }

  /// Importe des cartes à partir d'un fichier CSV
  Future<ImportResult> importCardsFromCsv(File file) async {
    try {
      final content = await file.readAsString();
      return importFromCsvContent(content);
    } catch (e) {
      return ImportResult(
        message: "Erreur lors de l'import du fichier: $e",
        successCount: 0,
        updateCount: 0,
        errorCount: 1,
        errors: [e.toString()],
      );
    }
  }

  /// Importe des cartes à partir du contenu CSV
  Future<ImportResult> importFromCsvContent(String content) async {
    try {
      int successCount = 0;
      int updateCount = 0;
      int errorCount = 0;
      final errors = <String>[];
      
      final rows = const CsvToListConverter().convert(content);
      
      if (rows.isEmpty) {
        return ImportResult(
          message: "Aucune donnée n'a été trouvée dans le fichier CSV",
          successCount: 0,
          updateCount: 0,
          errorCount: 0,
          errors: [],
        );
      }
      
      // Ignore header row
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        
        if (row.length < 2) {
          errors.add('Ligne $i: format invalide (moins de 2 colonnes)');
          errorCount++;
          continue;
        }
        
        try {
          final card = Flashcard(
            uuid: const Uuid().v4(),
            front: row[0].toString(), 
            back: row[1].toString(),
            category: row.length > 2 ? row[2]?.toString() : null,
            isKnown: row.length > 3 ? row[3] == 1 || row[3] == true : false,
          );
          
          // Insérer la carte
          final result = await saveCard(card);
          if (result > 0) {
            successCount++;
          } else {
            updateCount++; // Considérer comme une mise à jour si l'ID retourné est 0 ou -1
          }
        } catch (e) {
          errors.add('Erreur ligne $i: $e');
          errorCount++;
        }
      }
      
      final message = 'Import terminé: $successCount ajoutées, $updateCount mises à jour, $errorCount erreurs';
      
      return ImportResult(
        message: message,
        successCount: successCount, 
        updateCount: updateCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        message: "Erreur lors de l'import: $e",
        successCount: 0,
        updateCount: 0,
        errorCount: 1,
        errors: [e.toString()],
      );
    }
  }
}