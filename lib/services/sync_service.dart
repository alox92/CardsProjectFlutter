import 'dart:async';
import 'dart:math' as math;
import 'dart:collection';
import 'dart:convert';
import '../services/database_helper.dart';
import '../services/firebase_manager.dart';
import '../utils/logger.dart';
import '../models/flashcard.dart';

/// Service responsible for bidirectional synchronization between local SQLite database
/// and remote Firebase Firestore. Implements reliable sync mechanisms with conflict
/// resolution, resume capability, and network error handling.
class SyncService {
  final DatabaseHelper _db;
  final FirebaseManager _firebase;
  final Logger _logger = Logger();

  // Nouvelle instance de la file d'attente de synchronisation
  final _SyncQueue _syncQueue = _SyncQueue();

  // Limitation du nombre d'opérations concurrentes
  final _Semaphore _concurrencyLimiter = _Semaphore(3);

  // Stream controller pour les événements de synchronisation
  final _syncEventController = StreamController<SyncEvent>.broadcast();

  // Paramètres de configuration
  int _batchSize = 50;
  Duration _throttleDelay = Duration.zero;
  bool _adaptiveBatchSizing = true;

  // Méta-données de synchronisation en cache
  Map<String, int> _lastSyncTimestamps = {};

  // Flag pour annuler une synchronisation en cours
  bool _cancelSync = false;

  SyncService(this._db, this._firebase) {
    // Tentative de récupération des timestamps de dernière synchronisation
    _loadSyncTimestamps();
  }

  Stream<SyncEvent> get syncEvents => _syncEventController.stream;

  /// Configure le service de synchronisation
  void configure({
    int? batchSize,
    Duration? throttleDelay,
    bool? adaptiveBatchSizing,
  }) {
    if (batchSize != null) _batchSize = batchSize;
    if (throttleDelay != null) _throttleDelay = throttleDelay;
    if (adaptiveBatchSizing != null) _adaptiveBatchSizing = adaptiveBatchSizing;

    _logger.debug('SyncService configured: batchSize=$_batchSize, '
        'throttleDelay=${_throttleDelay.inMilliseconds}ms, '
        'adaptiveBatchSizing=$_adaptiveBatchSizing');
  }

  /// Synchronise les cartes avec le serveur Firebase
  /// Utilise la nouvelle file d'attente pour optimiser les opérations
  Future<SyncResult> synchronize() async {
    _cancelSync = false;
    final startTime = DateTime.now();

    // Notification de début de synchronisation
    _syncEventController.add(SyncEvent(SyncEventType.started, 'Synchronization started'));

    try {
      // Vérifier la connexion Firebase
      if (!await _firebase.isConnected()) {
        throw SyncServiceException('Firebase is not connected');
      }

      // Récupérer les cartes locales modifiées depuis la dernière synchronisation
      final lastSyncTime = _getLastSyncTimestamp('cards') ?? 0;
      final localCards = await _db.getCardsModifiedSince(lastSyncTime);

      // Récupérer les cartes distantes modifiées depuis la dernière synchronisation
      final remoteCards = await _firebase.getCardsModifiedSince(lastSyncTime);

      int syncedCount = 0;
      int conflictCount = 0;

      // Adapter la taille des lots en fonction du volume de données
      final effectiveBatchSize = _adaptiveBatchSizing
          ? _calculateAdaptiveBatchSize(localCards.length + remoteCards.length)
          : _batchSize;

      _logger.info('Starting sync with ${localCards.length} local changes and '
          '${remoteCards.length} remote changes, batch size: $effectiveBatchSize');

      // Synchroniser les changements locaux vers le serveur
      if (localCards.isNotEmpty) {
        int processed = 0;
        final batches = _createBatches(localCards, effectiveBatchSize);

        for (final batch in batches) {
          if (_cancelSync) break;

          // Ajouter à la file de priorité élevée
          final operation = _SyncOperation(
            execute: () async {
              await _concurrencyLimiter.acquire();
              try {
                await _pushLocalChanges(batch.cast<Flashcard>());
              } finally {
                _concurrencyLimiter.release();
              }
            },
            priority: _SyncPriority.high,
          );

          _syncQueue.enqueue(operation);
          await operation.completer.future;

          processed += batch.length;
          syncedCount += batch.length;

          // Notification de progression
          _notifyProgress(processed, localCards.length, 'Uploading changes');

          // Throttling pour éviter une surcharge des serveurs
          if (_throttleDelay > Duration.zero) {
            await Future.delayed(_throttleDelay);
          }
        }
      }

      // Synchroniser les changements distants vers le local
      if (remoteCards.isNotEmpty) {
        int processed = 0;
        final batches = _createBatches(remoteCards, effectiveBatchSize);

        for (final batch in batches) {
          if (_cancelSync) break;

          final operation = _SyncOperation(
            execute: () async {
              await _concurrencyLimiter.acquire();
              try {
                final conflicts = await _pullRemoteChanges(batch.cast<Flashcard>());
                conflictCount += conflicts;
              } finally {
                _concurrencyLimiter.release();
              }
            },
            priority: _SyncPriority.normal,
          );

          _syncQueue.enqueue(operation);
          await operation.completer.future;

          processed += batch.length;
          syncedCount += batch.length;

          // Notification de progression
          _notifyProgress(processed, remoteCards.length, 'Downloading changes');

          // Throttling pour éviter une surcharge
          if (_throttleDelay > Duration.zero) {
            await Future.delayed(_throttleDelay);
          }
        }
      }

      // Attendre que toutes les opérations soient terminées
      await _syncQueue.waitForCompletion();

      if (_cancelSync) {
        _syncEventController.add(SyncEvent(
          SyncEventType.cancelled,
          'Synchronization was cancelled',
          {'processed': syncedCount, 'conflicts': conflictCount},
        ));

        return SyncResult(
          success: false,
          message: 'Synchronization cancelled by user',
          syncedItems: syncedCount,
          conflictsResolved: conflictCount,
        );
      }

      // Mettre à jour le timestamp de dernière synchronisation
      _setLastSyncTimestamp('cards', DateTime.now().millisecondsSinceEpoch);

      final duration = DateTime.now().difference(startTime).inMilliseconds;

      _syncEventController.add(SyncEvent(
        SyncEventType.completed,
        'Synchronization completed successfully',
        {
          'synced': syncedCount,
          'conflicts': conflictCount,
          'duration': duration,
        },
      ));

      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        syncedItems: syncedCount,
        conflictsResolved: conflictCount,
        syncDuration: duration,
      );
    } catch (e, stackTrace) {
      _logger.error('Sync error: $e\n$stackTrace');

      _syncEventController.add(SyncEvent(
        SyncEventType.error,
        'Synchronization failed: ${e.toString()}',
      ));

      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
        syncedItems: 0,
        conflictsResolved: 0,
      );
    }
  }

  /// Annule la synchronisation en cours
  void cancelSync() {
    _cancelSync = true;
    _logger.debug('Sync cancellation requested');
  }

  /// Calcule une taille de lot adaptative en fonction du nombre d'éléments
  int _calculateAdaptiveBatchSize(int itemCount) {
    if (itemCount < 100) return 20;
    if (itemCount < 500) return 50;
    if (itemCount < 2000) return 100;
    return 200; // Pour les très grandes collections
  }

  /// Crée des lots pour le traitement par lots
  List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    final result = <List<T>>[];
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      result.add(items.sublist(i, end));
    }
    return result;
  }

  /// Envoie les changements locaux vers Firebase
  Future<void> _pushLocalChanges(List<Flashcard> cards) async {
    try {
      // Optimisation: envoi en masse plutôt qu'individuel
      await _firebase.pushCards(cards);
      _logger.debug('Successfully pushed ${cards.length} cards to Firebase');
    } catch (e) {
      _logger.error('Error pushing cards to Firebase: $e');
      throw SyncServiceException('Failed to push cards to Firebase', e);
    }
  }

  /// Récupère les changements distants et gère les conflits
  Future<int> _pullRemoteChanges(List<Flashcard> remoteCards) async {
    int conflicts = 0;

    try {
      for (final remoteCard in remoteCards) {
        // Récupérer la version locale si elle existe
        final localCard = remoteCard.id != null ? await _db.getCardById(remoteCard.id!) : null;

        if (localCard == null) {
          // Pas de conflit, juste insérer la carte distante
          await _db.insertCard(remoteCard);
        } else if ((remoteCard.modifiedAt ?? 0) > (localCard.modifiedAt ?? 0)) {
          // La version distante est plus récente
          await _db.updateCard(remoteCard);
        } else if ((remoteCard.modifiedAt ?? 0) < (localCard.modifiedAt ?? 0)) {
          // La version locale est plus récente (conflit résolu en faveur du local)
          // On garde la version locale et on synchronisera lors du prochain cycle
          conflicts++;
        } else {
          // Même timestamp de modification mais potentiellement différent
          // On compare les contenus et on conserve celui qui est différent de la dernière synchronisation
          if (remoteCard.toString() != localCard.toString()) {
            await _db.updateCard(remoteCard); // On privilégie la version distante
            conflicts++;
          }
        }
      }

      _logger.debug('Successfully pulled ${remoteCards.length} cards from Firebase (conflicts: $conflicts)');
      return conflicts;
    } catch (e) {
      _logger.error('Error pulling cards from Firebase: $e');
      throw SyncServiceException('Failed to pull cards from Firebase', e);
    }
  }

  /// Envoie une notification de progression
  void _notifyProgress(int processed, int total, String operation) {
    final percentComplete = (processed / total * 100).round();
    _syncEventController.add(SyncEvent(
      SyncEventType.progress,
      '$operation: $percentComplete% ($processed/$total)',
      {'processed': processed, 'total': total, 'percent': percentComplete},
    ));
  }

  /// Récupère le timestamp de dernière synchronisation
  int? _getLastSyncTimestamp(String key) {
    return _lastSyncTimestamps[key];
  }

  /// Définit le timestamp de dernière synchronisation
  void _setLastSyncTimestamp(String key, int timestamp) {
    _lastSyncTimestamps[key] = timestamp;
    _saveSyncTimestamps();
  }

  /// Charge les timestamps de dernière synchronisation depuis le stockage persistant
  Future<void> _loadSyncTimestamps() async {
    try {
      final timestamps = await _db.getMetadata('sync_timestamps');
      if (timestamps != null) {
        _lastSyncTimestamps = Map<String, int>.from(
          jsonDecode(timestamps) as Map,
        );
        _logger.debug('Loaded sync timestamps: $_lastSyncTimestamps');
      }
    } catch (e) {
      _logger.error('Failed to load sync timestamps: $e');
      // Continuer avec une map vide
      _lastSyncTimestamps = {};
    }
  }

  /// Enregistre les timestamps de dernière synchronisation dans le stockage persistant
  Future<void> _saveSyncTimestamps() async {
    try {
      await _db.setMetadata('sync_timestamps', jsonEncode(_lastSyncTimestamps));
      _logger.debug('Saved sync timestamps');
    } catch (e) {
      _logger.error('Failed to save sync timestamps: $e');
    }
  }

  /// Retourne les statistiques sur la file d'attente de synchronisation
  Map<String, dynamic> getSyncStats() {
    return {
      ..._syncQueue.getStats(),
      'lastSyncTimestamps': _lastSyncTimestamps,
      'adaptiveBatchSizing': _adaptiveBatchSizing,
      'batchSize': _batchSize,
      'throttleDelay': _throttleDelay.inMilliseconds,
    };
  }

  /// Retourne le statut de synchronisation pour l'UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    final lastUpload = _getLastSyncTimestamp('cards');
    final lastDownload = _getLastSyncTimestamp('cards');
    return {
      'lastUploadDate': lastUpload != null ? DateTime.fromMillisecondsSinceEpoch(lastUpload).toString() : 'Jamais',
      'lastDownloadDate': lastDownload != null ? DateTime.fromMillisecondsSinceEpoch(lastDownload).toString() : 'Jamais',
      'maxBatchSize': _batchSize,
      'syncInProgress': false, // À adapter si besoin
    };
  }

  /// Réinitialise l'état de synchronisation (timestamps, file d'attente, etc.)
  Future<void> resetSyncState() async {
    _lastSyncTimestamps.clear();
    await _saveSyncTimestamps();
    _logger.info('Sync state reset');
  }

  /// Modifie dynamiquement la taille des lots de synchronisation
  void setBatchSize(int size) {
    _batchSize = size;
    _logger.info('Batch size set to $size');
  }

  /// Nettoie les ressources
  void dispose() {
    _syncEventController.close();
  }
}

/// Exception thrown when sync service encounters errors
class SyncServiceException implements Exception {
  final String message;
  final dynamic cause;

  SyncServiceException(this.message, [this.cause]);

  @override
  String toString() => 'SyncServiceException: $message${cause != null ? ', cause: $cause' : ''}';
}

/// Represents an individual sync operation
class _SyncOperation {
  final Future<void> Function() execute;
  final _SyncPriority priority;
  final Completer<void> completer = Completer<void>();

  _SyncOperation({required this.execute, required this.priority});
}

/// Priority levels for sync operations
enum _SyncPriority { high, normal, low }

/// Queue for managing sync operations
class _SyncQueue {
  final Queue<_SyncOperation> _highPriorityQueue = Queue<_SyncOperation>();
  final Queue<_SyncOperation> _normalPriorityQueue = Queue<_SyncOperation>();
  final Queue<_SyncOperation> _lowPriorityQueue = Queue<_SyncOperation>();

  void enqueue(_SyncOperation operation) {
    switch (operation.priority) {
      case _SyncPriority.high:
        _highPriorityQueue.add(operation);
        break;
      case _SyncPriority.normal:
        _normalPriorityQueue.add(operation);
        break;
      case _SyncPriority.low:
        _lowPriorityQueue.add(operation);
        break;
    }
  }

  Future<void> waitForCompletion() async {
    while (_highPriorityQueue.isNotEmpty ||
        _normalPriorityQueue.isNotEmpty ||
        _lowPriorityQueue.isNotEmpty) {
      final operation = _highPriorityQueue.isNotEmpty
          ? _highPriorityQueue.removeFirst()
          : _normalPriorityQueue.isNotEmpty
              ? _normalPriorityQueue.removeFirst()
              : _lowPriorityQueue.removeFirst();

      try {
        await operation.execute();
        operation.completer.complete();
      } catch (e) {
        operation.completer.completeError(e);
      }
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'highPriorityQueueSize': _highPriorityQueue.length,
      'normalPriorityQueueSize': _normalPriorityQueue.length,
      'lowPriorityQueueSize': _lowPriorityQueue.length,
    };
  }
}

/// A semaphore implementation for limiting concurrent operations
class _Semaphore {
  int _currentCount;
  final int _maxCount;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this._maxCount) : _currentCount = _maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return Future.value();
    }

    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final completer = _waiters.removeAt(0);
      completer.complete();
    } else {
      _currentCount = math.min(_currentCount + 1, _maxCount);
    }
  }
}

/// Type of sync events emitted during synchronization
enum SyncEventType {
  started,
  progress,
  completed,
  cancelled,
  error,
  uploadStarted,
  uploadProgress,
  downloadStarted,
  downloadProgress,
  completedWithErrors,
  failed,
}

/// Event emitted during synchronization
class SyncEvent {
  final SyncEventType type;
  final String message;
  final Map<String, dynamic>? details;
  double? get progress => details != null && details!.containsKey('percent') ? (details!['percent'] as num?)?.toDouble() : null;
  SyncEvent(this.type, this.message, [this.details]);
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedItems;
  final int conflictsResolved;
  final int? syncDuration;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedItems,
    required this.conflictsResolved,
    this.syncDuration,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'syncedItems': syncedItems,
    'conflictsResolved': conflictsResolved,
    'syncDuration': syncDuration,
  };
}
