import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/flashcard.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart'; // Import du logger pour une meilleure gestion des erreurs
import 'package:csv/csv.dart'; // Import the csv package for CSV conversion
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:localstorage/localstorage.dart';

class ImportResult {
  final String message;
  final int successCount;
  final int updateCount;
  final int errorCount;
  final List<String> errors;

  ImportResult({
    required this.message,
    required this.successCount,
    required this.updateCount,
    required this.errorCount,
    required this.errors,
  });

  int get totalProcessed => successCount + updateCount;

  bool get hasErrors => errorCount > 0;

  @override
  String toString() => message;
}

class ImportSummaryException implements Exception {
  final String message;
  final int successCount;
  final List<String> errors;

  ImportSummaryException(this.message, {
    required this.successCount,
    required this.errors
  });

  @override
  String toString() => message;
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;
  static DatabaseHelper get instance => _instance;

  static Database? _db;
  LocalStorage? _webStorage;
  static const _dbVersion = 3;
  static const _tableName = 'flashcards';
  final Uuid uuid = Uuid();
  final Logger _logger = Logger(); // Logger pour une meilleure traçabilité

  // Public getter for the table name
  String get tableName => _tableName;

  // Optionnel : cache mémoire pour accélérer les accès en lecture (désactivé par défaut)
  bool _useCache = true; // Activé par défaut pour le web
  List<Flashcard>? _cache;

  Future<dynamic> get db async {
    if (kIsWeb) {
      if (_webStorage != null) return _webStorage!;
      _webStorage = await _initWebStorage();
      return _webStorage!;
    } else {
      if (_db != null) return _db!;
      _db = await initDb();
      return _db!;
    }
  }

  DatabaseHelper.internal();

  /// Active ou désactive le cache mémoire.
  void enableCache(bool enable) {
    _useCache = enable;
    if (!enable) {
      _invalidateCache();
    }
  }

  /// Vide le cache mémoire.
  void clearCache() {
    _cache = null;
    _logger.debug('Cache cleared');
  }

  /// Invalide le cache mémoire (à appeler après toute modification).
  void _invalidateCache() {
    if (_useCache) {
      _cache = null;
      _logger.debug('Cache invalidated');
    }
  }

  Future<LocalStorage> _initWebStorage() async {
    try {
      _logger.info('Initializing web storage');
      final storage = LocalStorage('flashcards_app');
      await storage.ready;

      if (storage.getItem('cards') == null) {
        storage.setItem('cards', []);
      }

      if (storage.getItem('metadata') == null) {
        storage.setItem('metadata', {});
      }

      _logger.info('Web storage initialized successfully');
      return storage;
    } catch (e) {
      rethrow;
    }
  }

  /// Initialise la base de données et effectue les migrations si besoin.
  Future<Database> initDb() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite database is not supported on web. Use web storage instead.');
    }

    try {
      final Directory documentsDirectory = await getApplicationDocumentsDirectory();
      final String path = '${documentsDirectory.path}/flashcards.db';

      _logger.info('Initializing database at $path');

      final Database theDb = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) => _logger.info('Database opened successfully'),
      );

      return theDb;
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize database: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Crée la table principale et les index.
  Future<void> _onCreate(Database db, int version) async {
    _logger.info('Creating database schema version $version');
    await db.transaction((txn) async {
      await txn.execute("""
        CREATE TABLE $_tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT UNIQUE NOT NULL,
          front TEXT NOT NULL,
          back TEXT NOT NULL,
          is_known BOOLEAN NOT NULL DEFAULT FALSE,
          category TEXT,
          audio_path TEXT,
          last_modified INTEGER NOT NULL,
          is_deleted BOOLEAN NOT NULL DEFAULT FALSE
        )
      """);
      await txn.execute("CREATE INDEX idx_uuid ON $_tableName (uuid)");
      await txn.execute("CREATE INDEX idx_category ON $_tableName (category)");
      await txn.execute("CREATE INDEX idx_deleted ON $_tableName (is_deleted)");
      await txn.execute("CREATE INDEX idx_last_modified ON $_tableName (last_modified)");
      await txn.execute("""
        CREATE TABLE metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      """);
    });
    _logger.info('Database schema created successfully');
  }

  /// Effectue les migrations de schéma.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.info("Upgrading database from version $oldVersion to $newVersion");

    try {
      await db.transaction((txn) async {
        if (oldVersion < 2) {
          _logger.info('Applying migration to version 2...');
          await txn.execute("ALTER TABLE $_tableName ADD COLUMN uuid TEXT");
          await txn.execute("ALTER TABLE $_tableName ADD COLUMN last_modified INTEGER");

          final List<Map<String, Object?>> existingCards = await txn.query(
            _tableName,
            columns: ['id']
          );

          final batch = txn.batch();
          final int nowV2 = DateTime.now().millisecondsSinceEpoch;

          for (final cardMap in existingCards) {
            batch.update(
              _tableName,
              {'uuid': uuid.v4(), 'last_modified': nowV2},
              where: 'id = ?',
              whereArgs: [cardMap['id']],
            );
          }

          await batch.commit(noResult: true);
          await txn.execute("CREATE INDEX idx_uuid ON $_tableName (uuid)");
          await txn.execute("CREATE INDEX idx_category ON $_tableName (category)");
          _logger.info("Database upgraded to version 2 (${existingCards.length} cards updated)");
        }

        if (oldVersion < 3) {
          _logger.info('Applying migration to version 3...');
          await txn.execute("ALTER TABLE $_tableName ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT FALSE");
          await txn.execute("CREATE INDEX idx_deleted ON $_tableName (is_deleted)");
          _logger.info("Database upgraded to version 3");
        }

        // Ajout de l'index sur last_modified si nécessaire (toutes versions)
        try {
          await txn.execute("CREATE INDEX IF NOT EXISTS idx_last_modified ON $_tableName (last_modified)");
        } catch (e) {
          // Ignorer les erreurs si l'index existe déjà
          _logger.warning("Index creation warning (may already exist): $e");
        }
      });
    } catch (e, stackTrace) {
      _logger.error("Error during database migration: $e\n$stackTrace");
      rethrow; // Permet à SQFLite de gérer l'erreur
    }
  }

  /// Insère une nouvelle carte. Retourne l'ID ou -1 en cas d'échec.
  Future<int> saveCard(Flashcard card) async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final cards = List<Map<String, dynamic>>.from(storage.getItem('cards') ?? []);

        final map = card.toMap();
        map.remove('id');
        map['uuid'] ??= uuid.v4();
        map['id'] = cards.length + 1; // Simulating auto-increment
        map['last_modified'] ??= DateTime.now().millisecondsSinceEpoch;
        map['is_deleted'] ??= false;

        cards.add(map);
        await storage.setItem('cards', cards);

        _invalidateCache();
        _logger.debug('Card saved with ID: ${map['id']}, UUID: ${map['uuid']} (web)');
        return map['id'];
      } catch (e) {
        _logger.error('Error when saving card on web: $e');
        return -1;
      }
    } else {
      final dbClient = await db as Database;
      final map = card.toMap();
      map.remove('id');
      map['uuid'] ??= uuid.v4();
      map['last_modified'] ??= DateTime.now().millisecondsSinceEpoch;
      map['is_deleted'] ??= false;

      try {
        final res = await dbClient.insert(_tableName, map, conflictAlgorithm: ConflictAlgorithm.fail);
        _invalidateCache();
        _logger.debug('Card saved with ID: $res, UUID: ${map['uuid']}');
        return res;
      } on DatabaseException catch (e) {
        if (e.isUniqueConstraintError()) {
          _logger.warning('Failed to save card: UUID ${map['uuid']} already exists');
        } else {
          _logger.error('Database error when saving card: $e');
        }
        return -1;
      } catch (e, stackTrace) {
        _logger.error('Unexpected error when saving card: $e\n$stackTrace');
        return -1;
      }
    }
  }

  /// Insère ou met à jour une carte selon l'existence de l'UUID.
  /// Version optimisée avec moins de requêtes et meilleure gestion des erreurs
  Future<int> upsertCard(Flashcard card) async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final cards = List<Map<String, dynamic>>.from(storage.getItem('cards') ?? []);

        final map = card.toMap();
        map.remove('id');
        map['uuid'] ??= uuid.v4();
        map['last_modified'] ??= DateTime.now().millisecondsSinceEpoch;
        map['is_deleted'] ??= false;

        final uuidValue = map['uuid'];
        int index = cards.indexWhere((c) => c['uuid'] == uuidValue);

        if (index >= 0) {
          cards[index] = map;
          _logger.debug('Card updated during upsert: UUID $uuidValue (web)');
        } else {
          map['id'] = cards.length + 1; // Simulating auto-increment
          cards.add(map);
          _logger.debug('Card inserted during upsert: UUID $uuidValue (web)');
        }

        await storage.setItem('cards', cards);
        _invalidateCache();
        return 1;
      } catch (e) {
        _logger.error('Error during card upsert on web (UUID: ${card.uuid}): $e');
        return -1;
      }
    } else {
      final dbClient = await db as Database;
      final map = card.toMap();
      map.remove('id');
      map['uuid'] ??= uuid.v4();
      map['last_modified'] ??= DateTime.now().millisecondsSinceEpoch;
      map['is_deleted'] ??= false;

      final uuidValue = map['uuid'];

      try {
        // Utiliser une transaction pour garantir l'atomicité et les performances
        return await dbClient.transaction((txn) async {
          // Vérifier d'abord si la carte existe
          final existingCards = await txn.query(
            _tableName,
            columns: ['id'],
            where: 'uuid = ?',
            whereArgs: [uuidValue],
            limit: 1
          );

          int result;
          if (existingCards.isNotEmpty) {
            // Update existant
            result = await txn.update(
              _tableName,
              map,
              where: 'uuid = ?',
              whereArgs: [uuidValue],
            );
            _logger.debug('Card updated during upsert: UUID $uuidValue');
          } else {
            // Nouvelle insertion
            result = await txn.insert(_tableName, map);
            _logger.debug('Card inserted during upsert: UUID $uuidValue');
          }

          _invalidateCache();
          return result;
        });
      } catch (e) {
        _logger.error('Error during card upsert (UUID: $uuidValue): $e');
        return -1;
      }
    }
  }

  /// Récupère toutes les cartes (hors supprimées logiquement par défaut).
  /// Utilise le cache si activé.
  Future<List<Flashcard>> getAllCards({bool includeDeleted = false}) async {
    if (_useCache && _cache != null && !includeDeleted) {
      _logger.debug('Returning ${_cache!.length} cards from cache');
      return _cache!;
    }

    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final cards = List<Map<String, dynamic>>.from(storage.getItem('cards') ?? []);

        final filteredCards = includeDeleted
            ? cards
            : cards.where((card) => !(card['is_deleted'] ?? false)).toList();

        final result = filteredCards.map((m) => Flashcard.fromMap(m)).toList();

        if (_useCache && !includeDeleted) _cache = result;
        return result;
      } catch (e) {
        _logger.error('Error retrieving cards from web storage: $e');
        return [];
      }
    } else {
      final dbClient = await db as Database;
      final String? whereClause = includeDeleted ? null : 'is_deleted = ?';
      final List<dynamic>? whereArgs = includeDeleted ? null : [0];

      try {
        final Stopwatch stopwatch = Stopwatch()..start();

        final maps = await dbClient.query(
          _tableName,
          where: whereClause,
          whereArgs: whereArgs,
        );

        final cards = List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));

        stopwatch.stop();
        _logger.debug('Retrieved ${cards.length} cards in ${stopwatch.elapsedMilliseconds}ms');

        if (_useCache && !includeDeleted) _cache = cards;
        return cards;
      } catch (e, stackTrace) {
        _logger.error('Error retrieving cards: $e\n$stackTrace');
        return [];
      }
    }
  }

  /// Récupère une carte par UUID (hors supprimée logiquement).
  Future<Flashcard?> getCardByUuid(String uuidValue) async {
    if (kIsWeb) {
      try {
        final allCards = await getAllCards(includeDeleted: false);
        return allCards.firstWhere(
          (card) => card.uuid == uuidValue,
          orElse: () => Flashcard(front: '', back: '', uuid: '')
        );
      } catch (e) {
        _logger.error('Error retrieving card by UUID from web storage: $e');
        return null;
      }
    } else {
      final dbClient = await db as Database;
      try {
        final maps = await dbClient.query(
          _tableName,
          where: 'uuid = ? AND is_deleted = 0',
          whereArgs: [uuidValue],
          limit: 1,
        );

        if (maps.isNotEmpty) {
          return Flashcard.fromMap(maps.first);
        }

        _logger.debug('Card with UUID $uuidValue not found');
        return null;
      } catch (e) {
        _logger.error('Error retrieving card by UUID: $e');
        return null;
      }
    }
  }

  /// Effectue une suppression logique par ID.
  Future<int> deleteCard(int id) async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final cards = List<Map<String, dynamic>>.from(storage.getItem('cards') ?? []);

        int index = cards.indexWhere((c) => c['id'] == id);
        if (index >= 0) {
          cards[index]['is_deleted'] = true;
          cards[index]['last_modified'] = DateTime.now().millisecondsSinceEpoch;
          await storage.setItem('cards', cards);
          _invalidateCache();
          return 1;
        }

        return 0;
      } catch (e) {
        _logger.error('Error during logical delete by ID in web storage: $e');
        return -1;
      }
    } else {
      final dbClient = await db as Database;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      try {
        final res = await dbClient.update(
          _tableName,
          {
            'is_deleted': 1,
            'last_modified': timestamp
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        _invalidateCache();
        _logger.debug('Logical delete of card ID $id (affected: $res)');
        return res;
      } catch (e) {
        _logger.error('Error during logical delete by ID: $e');
        return -1;
      }
    }
  }

  /// Effectue une suppression logique par UUID.
  Future<int> deleteCardByUuid(String uuidValue) async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final cards = List<Map<String, dynamic>>.from(storage.getItem('cards') ?? []);

        int index = cards.indexWhere((c) => c['uuid'] == uuidValue);
        if (index >= 0) {
          cards[index]['is_deleted'] = true;
          cards[index]['last_modified'] = DateTime.now().millisecondsSinceEpoch;
          await storage.setItem('cards', cards);
          _invalidateCache();
          return 1;
        }

        return 0;
      } catch (e) {
        _logger.error('Error during logical delete by UUID in web storage: $e');
        return -1;
      }
    } else {
      final dbClient = await db as Database;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      try {
        final res = await dbClient.update(
          _tableName,
          {
            'is_deleted': 1,
            'last_modified': timestamp
          },
          where: 'uuid = ?',
          whereArgs: [uuidValue],
        );

        _invalidateCache();
        _logger.debug('Logical delete of card UUID $uuidValue (affected: $res)');
        return res;
      } catch (e) {
        _logger.error('Error during logical delete by UUID: $e');
        return -1;
      }
    }
  }

  /// Suppression physique (définitive) par ID.
  Future<int> deleteCardPermanently(int id) async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final cards = List<Map<String, dynamic>>.from(storage.getItem('cards') ?? []);

        int index = cards.indexWhere((c) => c['id'] == id);
        if (index >= 0) {
          cards.removeAt(index);
          await storage.setItem('cards', cards);
          _invalidateCache();
          return 1;
        }

        return 0;
      } catch (e) {
        _logger.error('Error during permanent delete by ID in web storage: $e');
        return -1;
      }
    } else {
      final dbClient = await db as Database;

      try {
        final res = await dbClient.delete(_tableName, where: 'id = ?', whereArgs: [id]);
        _invalidateCache();
        _logger.debug('Permanent delete of card ID $id (affected: $res)');
        return res;
      } catch (e) {
        _logger.error('Error during permanent delete by ID: $e');
        return -1;
      }
    }
  }

  /// Supprime définitivement toutes les cartes (danger : IRRÉVERSIBLE).
  Future<int> purgeAllCards() async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        await storage.setItem('cards', []);
        _invalidateCache();
        _logger.warning('PURGED ALL CARDS from web storage');
        return 1;
      } catch (e) {
        _logger.error('Error during purge all cards in web storage: $e');
        return -1;
      }
    } else {
      final dbClient = await db as Database;

      try {
        final res = await dbClient.delete(_tableName);
        _invalidateCache();
        _logger.warning('PURGED ALL CARDS from database (affected: $res)');
        return res;
      } catch (e) {
        _logger.error('Error during purge all cards: $e');
        return -1;
      }
    }
  }

  /// Renvoie toutes les cartes supprimées (soft delete).
  Future<List<Flashcard>> getDeletedCards() async {
    if (kIsWeb) {
      final allCards = await getAllCards(includeDeleted: true);
      return allCards.where((card) => card.isDeleted).toList();
    } else {
      final dbClient = await db as Database;

      try {
        final Stopwatch stopwatch = Stopwatch()..start();
        final maps = await dbClient.query(
          _tableName,
          where: 'is_deleted = 1',
        );

        final cards = List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
        stopwatch.stop();

        _logger.debug('Retrieved ${cards.length} deleted cards in ${stopwatch.elapsedMilliseconds}ms');
        return cards;
      } catch (e) {
        _logger.error('Error retrieving deleted cards: $e');
        return [];
      }
    }
  }

  /// Met à jour une carte (par UUID si possible, sinon par ID).
  Future<int> updateCard(Flashcard card) async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final cards = List<Map<String, dynamic>>.from(storage.getItem('cards') ?? []);

        int index = -1;
        if (card.uuid != null) {
          index = cards.indexWhere((c) => c['uuid'] == card.uuid);
        } else if (card.id != null) {
          index = cards.indexWhere((c) => c['id'] == card.id);
        }

        if (index >= 0) {
          final map = card.toMap();
          map['last_modified'] = DateTime.now().millisecondsSinceEpoch;
          cards[index] = map;
          await storage.setItem('cards', cards);
          _invalidateCache();
          return 1;
        }

        return 0;
      } catch (e) {
        _logger.error('Error updating card in web storage: $e');
        return -1;
      }
    } else {
      if (card.id == null && card.uuid == null) {
        _logger.error('Cannot update card: neither ID nor UUID provided');
        return -1;
      }

      final dbClient = await db as Database;
      final map = card.toMap();
      map['last_modified'] = DateTime.now().millisecondsSinceEpoch;
      map.remove('id');

      final String whereClause = card.uuid != null ? 'uuid = ?' : 'id = ?';
      final List<dynamic> whereArgs = card.uuid != null ? [card.uuid] : [card.id];

      try {
        final res = await dbClient.update(
          _tableName,
          map,
          where: whereClause,
          whereArgs: whereArgs,
          conflictAlgorithm: ConflictAlgorithm.fail,
        );

        _invalidateCache();
        _logger.debug('Card updated: ${card.uuid ?? card.id} (affected: $res)');
        return res;
      } catch (e) {
        _logger.error('Error updating card (UUID: ${card.uuid}, ID: ${card.id}): $e');
        return -1;
      }
    }
  }

  Future<List<Flashcard>> getUnknownCards() async {
    if (kIsWeb) {
      final allCards = await getAllCards(includeDeleted: false);
      return allCards.where((card) => !card.isKnown).toList();
    } else {
      final dbClient = await db as Database;
      final maps = await dbClient.query(_tableName, where: 'is_known = 0 AND is_deleted = 0');
      return maps.map((m) => Flashcard.fromMap(m)).toList();
    }
  }

  Future<List<Flashcard>> getCardsByCategory(String category) async {
    if (kIsWeb) {
      final allCards = await getAllCards(includeDeleted: false);
      return allCards.where((card) => card.category == category).toList();
    } else {
      final dbClient = await db as Database;
      final maps = await dbClient.query(_tableName,
        where: 'category = ? AND is_deleted = 0',
        whereArgs: [category]
      );
      return maps.map((m) => Flashcard.fromMap(m)).toList();
    }
  }

  Future<String?> getMetadata(String key) async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final metadata = Map<String, dynamic>.from(storage.getItem('metadata') ?? {});
        return metadata[key] as String?;
      } catch (e) {
        _logger.error('Error getting metadata from web storage: $e');
        return null;
      }
    } else {
      final dbClient = await db as Database;
      final maps = await dbClient.query('metadata', where: 'key = ?', whereArgs: [key]);
      if (maps.isNotEmpty) return maps.first['value'] as String?;
      return null;
    }
  }

  Future<void> setMetadata(String key, String value) async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final metadata = Map<String, dynamic>.from(storage.getItem('metadata') ?? {});
        metadata[key] = value;
        await storage.setItem('metadata', metadata);
      } catch (e) {
        _logger.error('Error setting metadata in web storage: $e');
      }
    } else {
      final dbClient = await db as Database;
      await dbClient.insert('metadata', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Récupère les cartes modifiées depuis la date spécifiée (timestamp)
  Future<List<Flashcard>> getCardsModifiedSince(int timestamp) async {
    if (kIsWeb) {
      try {
        final allCards = await getAllCards(includeDeleted: true);
        return allCards.where((card) => 
          card.lastModified != null && card.lastModified! > timestamp
        ).toList();
      } catch (e) {
        _logger.error('Error retrieving cards modified since $timestamp from web storage: $e');
        return [];
      }
    } else {
      final dbClient = await db as Database;
      try {
        final Stopwatch stopwatch = Stopwatch()..start();
        
        final maps = await dbClient.query(
          _tableName,
          where: 'last_modified > ?',
          whereArgs: [timestamp],
        );
        
        final cards = List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
        
        stopwatch.stop();
        _logger.debug('Retrieved ${cards.length} cards modified since $timestamp in ${stopwatch.elapsedMilliseconds}ms');
        
        return cards;
      } catch (e) {
        _logger.error('Error retrieving modified cards: $e');
        return [];
      }
    }
  }

  /// Récupère une carte par son ID
  Future<Flashcard?> getCardById(int id) async {
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final cards = List<Map<String, dynamic>>.from(storage.getItem('cards') ?? []);
        
        final cardData = cards.firstWhere(
          (card) => card['id'] == id,
          orElse: () => <String, dynamic>{},
        );
        
        if (cardData.isNotEmpty) {
          return Flashcard.fromMap(cardData);
        }
        
        return null;
      } catch (e) {
        _logger.error('Error retrieving card by ID from web storage: $e');
        return null;
      }
    } else {
      final dbClient = await db as Database;
      try {
        final maps = await dbClient.query(
          _tableName,
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        
        if (maps.isNotEmpty) {
          return Flashcard.fromMap(maps.first);
        }
        
        _logger.debug('Card with ID $id not found');
        return null;
      } catch (e) {
        _logger.error('Error retrieving card by ID: $e');
        return null;
      }
    }
  }
  
  /// Insère une carte dans la base de données (sans vérifier les conflits)
  Future<int> insertCard(Flashcard card) async {
    return saveCard(card);
  }
  
  /// Insère plusieurs cartes en bloc, optimisé pour de grandes quantités
  Future<ImportResult> insertMultipleCards(List<Flashcard> cards) async {
    int successCount = 0;
    int updateCount = 0;
    int errorCount = 0;
    List<String> errors = [];
    
    if (kIsWeb) {
      try {
        final storage = await db as LocalStorage;
        final existingCards = List<Map<String, dynamic>>.from(storage.getItem('cards') ?? []);
        
        int nextId = existingCards.isNotEmpty 
            ? (existingCards.map((c) => c['id'] as int).reduce((a, b) => a > b ? a : b) + 1) 
            : 1;
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        for (var card in cards) {
          try {
            final map = card.toMap();
            map.remove('id');
            map['uuid'] ??= uuid.v4();
            map['last_modified'] ??= timestamp;
            map['is_deleted'] ??= false;
            
            // Check if we have this card already
            int existingIndex = existingCards.indexWhere((c) => c['uuid'] == map['uuid']);
            
            if (existingIndex >= 0) {
              // Update
              existingCards[existingIndex] = map;
              updateCount++;
            } else {
              // Insert
              map['id'] = nextId++;
              existingCards.add(map);
              successCount++;
            }
          } catch (e) {
            _logger.error('Error while processing card: $e');
            errorCount++;
            errors.add('Erreur sur carte ${card.front}: $e');
          }
        }
        
        // Save all changes
        await storage.setItem('cards', existingCards);
        _invalidateCache();
        
        final message = 'Import terminé: $successCount ajoutées, $updateCount mises à jour, $errorCount erreurs';
        _logger.info(message);
        
        return ImportResult(
          message: message,
          successCount: successCount,
          updateCount: updateCount,
          errorCount: errorCount,
          errors: errors,
        );
      } catch (e) {
        _logger.error('Error during batch insert on web: $e');
        throw ImportSummaryException(
          'Erreur lors de l\'import: $e',
          successCount: successCount,
          errors: [e.toString()],
        );
      }
    } else {
      final dbClient = await db as Database;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      try {
        await dbClient.transaction((txn) async {
          for (var card in cards) {
            try {
              final map = card.toMap();
              map.remove('id');
              map['uuid'] ??= uuid.v4();
              map['last_modified'] ??= timestamp;
              map['is_deleted'] ??= false;
              
              final String? uuidValue = map['uuid'] as String?;
              
              if (uuidValue != null) {
                // Check if card exists
                final existing = await txn.query(
                  _tableName,
                  columns: ['id'],
                  where: 'uuid = ?',
                  whereArgs: [uuidValue],
                  limit: 1,
                );
                
                if (existing.isNotEmpty) {
                  // Update
                  await txn.update(
                    _tableName,
                    map,
                    where: 'uuid = ?',
                    whereArgs: [uuidValue],
                  );
                  updateCount++;
                } else {
                  // Insert
                  await txn.insert(_tableName, map);
                  successCount++;
                }
              } else {
                // No UUID, just insert
                await txn.insert(_tableName, map);
                successCount++;
              }
            } catch (e) {
              _logger.error('Error while processing card: $e');
              errorCount++;
              errors.add('Erreur sur carte ${card.front}: $e');
            }
          }
        });
        
        _invalidateCache();
        final message = 'Import terminé: $successCount ajoutées, $updateCount mises à jour, $errorCount erreurs';
        _logger.info(message);
        
        return ImportResult(
          message: message,
          successCount: successCount,
          updateCount: updateCount,
          errorCount: errorCount,
          errors: errors,
        );
      } catch (e) {
        _logger.error('Error during batch insert: $e');
        throw ImportSummaryException(
          'Erreur lors de l\'import: $e',
          successCount: successCount,
          errors: [e.toString()],
        );
      }
    }
  }

  /// Exporte les cartes au format CSV
  Future<String> exportToCsv() async {
    try {
      final List<Flashcard> cards = await getAllCards(includeDeleted: false);
      
      if (cards.isEmpty) {
        return "front,back,category,is_known\n";
      }
      
      List<List<dynamic>> csvData = [
        ['front', 'back', 'category', 'is_known']  // Headers
      ];
      
      for (var card in cards) {
        csvData.add([
          card.front,
          card.back,
          card.category ?? '',
          card.isKnown ? 1 : 0,
        ]);
      }
      final csvCodec = ListToCsvConverter();
      _logger.info('Exported ${cards.length} cards to CSV');

      return csvCodec.convert(csvData);
    } catch (e) {
      _logger.error('Error during CSV export: $e');
      throw e;
    }
  }
  
  /// Importe des cartes à partir d'une chaîne CSV
  Future<ImportResult> importFromCsv(String csvContent) async {
    try {
      const csvCodec = const CsvToListConverter();
      List<List<dynamic>> rows = csvCodec.convert(csvContent);
      
      if (rows.isEmpty) {
        return ImportResult(
          message: 'Fichier CSV vide',
          successCount: 0,
          updateCount: 0,
          errorCount: 0,
          errors: [],
        );
      }
      
      // Skip header row
      List<Flashcard> cards = [];
      List<String> errors = [];
      int errorCount = 0;
      
      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          if (row.length >= 2) {
            final card = Flashcard(
              front: row[0].toString(),
              back: row[1].toString(),
              category: row.length > 2 ? row[2].toString() : null,
              isKnown: row.length > 3 ? row[3] == 1 || row[3] == true : false,
            );
            cards.add(card);
          } else {
            errors.add('Ligne $i: nombre de colonnes insuffisant');
            errorCount++;
          }
        } catch (e) {
          errors.add('Erreur ligne $i: $e');
          errorCount++;
        }
      }
      
      if (cards.isEmpty) {
        return ImportResult(
          message: 'Aucune carte valide trouvée',
          successCount: 0,
          updateCount: 0,
          errorCount: errorCount,
          errors: errors,
        );
      }
      
      return await insertMultipleCards(cards);
    } catch (e) {
      _logger.error('Error during CSV import: $e');
      throw e;
    }
  }
}