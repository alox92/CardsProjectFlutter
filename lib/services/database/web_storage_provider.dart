import 'package:localstorage/localstorage.dart';
import 'package:uuid/uuid.dart';
import 'package:csv/csv.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';

import '../../utils/logger.dart';
import 'database_provider.dart';
import 'models/import_result.dart';

/// Implémentation du DatabaseProvider pour le stockage web en utilisant LocalStorage
class WebStorageProvider implements DatabaseProvider {
  final Logger _logger;
  final Uuid _uuid = Uuid();
  
  LocalStorage? _storage;
  
  WebStorageProvider({required Logger logger}) : _logger = logger;

  /// Initialise et renvoie l'instance de stockage
  Future<LocalStorage> get storage async {
    if (_storage != null) return _storage!;
    _storage = await _initWebStorage();
    return _storage!;
  }

  @override
  Future<void> initialize() async {
    await storage;
    _logger.info('Web Storage Provider initialized');
  }

  /// Initialise le stockage web
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
      _logger.error('Error initializing web storage: $e');
      rethrow;
    }
  }

  /// Prépare les données de carte pour le stockage
  Map<String, dynamic> _prepareCardMap(Flashcard card) {
    final map = card.toMap();
    map.remove('id');
    map['uuid'] ??= _uuid.v4();
    map['last_modified'] ??= DateTime.now().millisecondsSinceEpoch;
    map['is_deleted'] ??= false;
    return map;
  }

  // IMPLÉMENTATION DE L'INTERFACE DATABASE PROVIDER

  @override
  Future<int> insertCard(Flashcard card) async {
    try {
      final ls = await storage;
      final cards = List<Map<String, dynamic>>.from(ls.getItem('cards') ?? []);

      final map = _prepareCardMap(card);
      
      // Simuler un auto-increment pour id
      int newId = 1;
      if (cards.isNotEmpty) {
        newId = (cards.map((c) => c['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
      }
      map['id'] = newId;
      
      cards.add(map);
      await ls.setItem('cards', cards);

      _logger.debug('Card saved with ID: ${map['id']}, UUID: ${map['uuid']} (web)');
      return newId;
    } catch (e) {
      _logger.error('Error when saving card on web: $e');
      return -1;
    }
  }

  @override
  Future<Flashcard?> getCard({int? id, String? uuid}) async {
    try {
      final ls = await storage;
      final cards = List<Map<String, dynamic>>.from(ls.getItem('cards') ?? []);
      
      final Map<String, dynamic> cardData;
      
      if (id != null) {
        cardData = cards.firstWhere(
          (card) => card['id'] == id,
          orElse: () => <String, dynamic>{},
        );
      } else if (uuid != null) {
        cardData = cards.firstWhere(
          (card) => card['uuid'] == uuid && !(card['is_deleted'] ?? false),
          orElse: () => <String, dynamic>{},
        );
      } else {
        _logger.error('Either id or uuid must be provided to getCard');
        return null;
      }
      
      if (cardData.isNotEmpty) {
        return Flashcard.fromMap(cardData);
      }
      
      return null;
    } catch (e) {
      _logger.error('Error retrieving card from web storage: $e');
      return null;
    }
  }

  @override
  Future<int> updateCard(Flashcard card) async {
    try {
      final ls = await storage;
      final cards = List<Map<String, dynamic>>.from(ls.getItem('cards') ?? []);
      
      int index = -1;
      if (card.id != null) {
        index = cards.indexWhere((c) => c['id'] == card.id);
      } else if (card.uuid != null) {
        index = cards.indexWhere((c) => c['uuid'] == card.uuid);
      }
      
      if (index != -1) {
        final cardMap = card.toMap();
        // Conserver l'ID existant et mettre à jour la date de dernière modification
        cardMap['id'] = cards[index]['id'];
        cardMap['last_modified'] = DateTime.now().millisecondsSinceEpoch;
        
        cards[index] = cardMap;
        await ls.setItem('cards', cards);
        _logger.debug('Card updated: ${card.id ?? card.uuid}');
        return 1; // Retourne 1 pour un succès comme attendu par les tests
      } else {
        _logger.warning('Card not found for update: ${card.id ?? card.uuid} (web)');
        return 0;
      }
    } catch (e) {
      _logger.error('Error updating card on web: $e');
      return 0;
    }
  }

  @override
  Future<int> deleteCard(int id) async {
    try {
      final ls = await storage;
      final cards = List<Map<String, dynamic>>.from(ls.getItem('cards') ?? []);

      int index = cards.indexWhere((c) => c['id'] == id);
      if (index >= 0) {
        cards[index]['is_deleted'] = true;
        cards[index]['last_modified'] = DateTime.now().millisecondsSinceEpoch;
        await ls.setItem('cards', cards);
        return 1;
      }

      return 0;
    } catch (e) {
      _logger.error('Error during logical delete by ID in web storage: $e');
      return 0;
    }
  }

  @override
  Future<int> permanentlyDeleteCard(int id) async {
    try {
      final ls = await storage;
      final cards = List<Map<String, dynamic>>.from(ls.getItem('cards') ?? []);

      int index = cards.indexWhere((c) => c['id'] == id);
      if (index >= 0) {
        cards.removeAt(index);
        await ls.setItem('cards', cards);
        return 1;
      }

      return 0;
    } catch (e) {
      _logger.error('Error during permanent delete by ID in web storage: $e');
      return 0;
    }
  }

  @override
  Future<List<Flashcard>> getAllCards({
    Map<String, dynamic>? filters,
    bool includeDeleted = false,
    int? offset,
    int? limit,
  }) async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      
      final ls = await storage;
      final cards = List<Map<String, dynamic>>.from(ls.getItem('cards') ?? []);

      final filteredCards = includeDeleted
          ? cards
          : cards.where((card) => !(card['is_deleted'] ?? false)).toList();

      final result = filteredCards.map((m) => Flashcard.fromMap(m)).toList();
      
      stopwatch.stop();
      _logger.debug('Retrieved ${result.length} cards from web storage in ${stopwatch.elapsedMilliseconds}ms');
      
      return result;
    } catch (e) {
      _logger.error('Error retrieving cards from web storage: $e');
      return [];
    }
  }

  @override
  Future<List<Flashcard>> getUnknownCards() async {
    try {
      final allCards = await getAllCards(includeDeleted: false);
      return allCards.where((card) => !card.isKnown).toList();
    } catch (e) {
      _logger.error('Error retrieving unknown cards from web storage: $e');
      return [];
    }
  }

  @override
  Future<List<Flashcard>> getCardsByCategory(String category) async {
    try {
      final allCards = await getAllCards(includeDeleted: false);
      return allCards.where((card) => card.category == category).toList();
    } catch (e) {
      _logger.error('Error retrieving cards by category from web storage: $e');
      return [];
    }
  }

  @override
  Future<List<Flashcard>> getCardsModifiedSince(int timestamp) async {
    try {
      final allCards = await getAllCards(includeDeleted: true);
      return allCards.where((card) => 
        card.lastModified != null && card.lastModified! > timestamp
      ).toList();
    } catch (e) {
      _logger.error('Error retrieving cards modified since $timestamp from web storage: $e');
      return [];
    }
  }

  @override
  Future<List<Flashcard>> getDeletedCards() async => [];

  @override
  Future<int> purgeAllCards() async => 0;

  @override
  Future<int> upsertCard(Flashcard card) async => 0;

  @override
  Future<String?> getMetadataValue(String key) async {
    try {
      final ls = await storage;
      final metadata = Map<String, dynamic>.from(ls.getItem('metadata') ?? {});
      return metadata[key] as String?;
    } catch (e) {
      _logger.error('Error getting metadata from web storage: $e');
      return null;
    }
  }

  @override
  Future<void> setMetadataValue(String key, String value) async {
    try {
      final ls = await storage;
      final metadata = Map<String, dynamic>.from(ls.getItem('metadata') ?? {});
      metadata[key] = value;
      await ls.setItem('metadata', metadata);
    } catch (e) {
      _logger.error('Error setting metadata in web storage: $e');
    }
  }

  @override
  Future<void> clearAllMetadata() async {
    try {
      final ls = await storage;
      await ls.setItem('metadata', {});
      _logger.info('Cleared all metadata from web storage');
    } catch (e) {
      _logger.error('Error clearing metadata in web storage: $e');
    }
  }

  @override
  Future<void> close() async {
    _logger.info('Closing web storage provider');
    _storage = null;
  }

  @override
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
      _logger.info('Exported ${cards.length} cards to CSV from web storage');

      return csvCodec.convert(csvData);
    } catch (e) {
      _logger.error('Error during CSV export from web storage: $e');
      throw e;
    }
  }

  @override
  Future<int> importFromCsv(String csvContent) async {
    try {
      const csvCodec = CsvToListConverter();
      List<List<dynamic>> rows = csvCodec.convert(csvContent);
      
      if (rows.isEmpty) {
        return 0;
      }
      
      // Skip header row
      List<Flashcard> cards = [];
      
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
          }
        } catch (e) {
          _logger.error('Error processing row $i: $e');
        }
      }
      
      if (cards.isEmpty) {
        return 0;
      }
      
      final result = await insertMultipleCards(cards);
      return result.successCount;
    } catch (e) {
      _logger.error('Error during CSV import to web storage: $e');
      return 0;
    }
  }
  
  @override
  Future<ImportResult> insertMultipleCards(List<Flashcard> cards) async {
    int successCount = 0;
    int updateCount = 0;
    int errorCount = 0;
    List<String> errors = [];
    
    try {
      final ls = await storage;
      final existingCards = List<Map<String, dynamic>>.from(ls.getItem('cards') ?? []);
      
      int nextId = existingCards.isNotEmpty 
          ? (existingCards.map((c) => c['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b) + 1) 
          : 1;
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      for (var card in cards) {
        try {
          final map = card.toMap();
          map.remove('id');
          map['uuid'] ??= _uuid.v4();
          map['last_modified'] ??= timestamp;
          map['is_deleted'] ??= false;
          
          // Check if we have this card already
          int existingIndex = existingCards.indexWhere((c) => c['uuid'] == map['uuid']);
          
          if (existingIndex >= 0) {
            // Update
            map['id'] = existingCards[existingIndex]['id'];
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
      await ls.setItem('cards', existingCards);
      
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
  }
}