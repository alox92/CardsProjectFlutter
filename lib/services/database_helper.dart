import 'package:flutter/foundation.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:uuid/uuid.dart';
import 'package:projet/utils/logger.dart';
import 'database/database_provider.dart';
import 'database/sqlite_provider.dart';
import 'database/web_storage_provider.dart';
import 'database/models/import_result.dart';

/// Helper de base de données qui offre une interface unifiée
/// pour les opérations de persistance, indépendamment de la
/// plateforme (SQLite pour mobile/desktop, localStorage pour web)
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  
  /// Singleton pour accéder à l'instance du DatabaseHelper
  static DatabaseHelper get instance => _instance;

  final _logger = Logger('DatabaseHelper');
  late DatabaseProvider _provider;
  final _uuid = Uuid();
  bool _useCache = false;
  final Map<String, dynamic> _cache = {};

  /// Constructeur privé pour singleton
  DatabaseHelper._internal();

  /// Initialise le provider de base de données approprié selon la plateforme
  Future<void> initialize() async {
    _logger.info('Initializing database helper');
    
    if (kIsWeb) {
      _provider = WebStorageProvider(logger: _logger);
    } else {
      _provider = SqliteProvider(
        uuid: _uuid,
        logger: _logger,
      );
    }
    
    await _provider.initialize();
    _logger.info('Database initialized successfully');
  }

  /// Active/désactive le cache pour améliorer les performances
  void enableCache(bool enable) {
    _useCache = enable;
    if (!enable) {
      _invalidateCache();
    }
    _logger.info('Cache ${enable ? 'enabled' : 'disabled'}');
  }

  /// Invalide le cache pour forcer un rechargement des données
  void _invalidateCache() {
    _cache.clear();
    _logger.debug('Cache invalidated');
  }

  /// Récupère une carte par ID ou UUID
  Future<Flashcard?> getCard({int? id, String? uuid}) async {
    return _provider.getCard(id: id, uuid: uuid);
  }

  /// Récupère toutes les cartes de la base de données
  Future<List<Flashcard>> getAllCards({bool includeDeleted = false}) async {
    final cacheKey = 'all_cards_$includeDeleted';
    
    if (_useCache && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<Flashcard>;
    }
    
    final cards = await _provider.getAllCards(includeDeleted: includeDeleted);
    
    if (_useCache) {
      _cache[cacheKey] = cards;
    }
    
    return cards;
  }

  /// Récupère les cartes par catégorie
  Future<List<Flashcard>> getCardsByCategory(String category) async {
    final cacheKey = 'cards_category_$category';
    
    if (_useCache && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<Flashcard>;
    }
    
    final cards = await _provider.getCardsByCategory(category);
    
    if (_useCache) {
      _cache[cacheKey] = cards;
    }
    
    return cards;
  }

  /// Récupère les cartes marquées comme non connues
  Future<List<Flashcard>> getUnknownCards() async {
    final cacheKey = 'unknown_cards';
    
    if (_useCache && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as List<Flashcard>;
    }
    
    final cards = await _provider.getUnknownCards();
    
    if (_useCache) {
      _cache[cacheKey] = cards;
    }
    
    return cards;
  }

  /// Sauvegarde une carte (création ou mise à jour)
  Future<int> saveCard(Flashcard card) async {
    final result = card.id == null 
        ? await _provider.insertCard(card)
        : await _provider.updateCard(card);
    
    _invalidateCache();
    return result;
  }

  /// Met à jour une carte existante
  Future<int> updateCard(Flashcard card) async {
    final result = await _provider.updateCard(card);
    _invalidateCache();
    return result;
  }

  /// Supprime une carte (suppression logique)
  Future<int> deleteCard(int id) async {
    final result = await _provider.deleteCard(id);
    _invalidateCache();
    return result;
  }

  /// Exporte les cartes au format CSV
  Future<String> exportCardsToFile() async {
    return await _provider.exportToCsv();
  }

  /// Importe des cartes depuis une chaîne CSV 
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

  /// Ferme la connexion à la base de données
  Future<void> close() async {
    await _provider.close();
  }
}
