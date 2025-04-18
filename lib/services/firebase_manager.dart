import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import '../config/firebase_config.dart';
import 'dart:async';
import 'package:collection/collection.dart';

class FirebaseManager {
  static final FirebaseManager _instance = FirebaseManager._internal();
  factory FirebaseManager() => _instance;

  FirebaseManager._internal();

  // Initialize Firebase with appropriate options for the current platform
  Future<void> initializeFirebase() async {
    try {
      final options = await FirebaseConfig.getPlatformOptions();

      if (options != null) {
        await Firebase.initializeApp(options: options);
        print('Firebase initialized successfully.');
      } else {
        print('No Firebase configuration found for this platform.');
      }
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  // Reference to the Firestore collection
  CollectionReference<Map<String, dynamic>> get _flashcardsCollection =>
      FirebaseFirestore.instance.collection('flashcards');

  // Save a card to Firestore using its UUID as document ID
  Future<void> saveCardByUuid(Flashcard card) async {
    if (card.uuid == null) {
      throw ArgumentError('Cannot save card to Firebase without a UUID');
    }

    // Ensure timestamps are properly set
    final Map<String, dynamic> data = card.toMap()
      ..remove('id') // Remove local ID
      ..['server_timestamp'] = FieldValue.serverTimestamp(); // Add server timestamp
    
    // Use set with merge to create or update
    await _flashcardsCollection.doc(card.uuid).set(data, SetOptions(merge: true));
  }

  // Delete a card from Firestore by UUID (implement soft delete)
  Future<void> deleteCardByUuid(String uuid) async {
    // Two approaches:
    // 1. Physical deletion (remove from Firestore)
    // await _flashcardsCollection.doc(uuid).delete();
    
    // 2. Soft deletion (mark as deleted but keep the document)
    await _flashcardsCollection.doc(uuid).set({
      'is_deleted': true,
      'last_modified': DateTime.now().millisecondsSinceEpoch,
      'server_timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Fetch all cards, optionally filtering by timestamp
  Future<List<Flashcard>> fetchCards({DateTime? since}) async {
    try {
      Query<Map<String, dynamic>> query = _flashcardsCollection;
      
      // If since is provided, only fetch cards modified after that timestamp
      if (since != null) {
        query = query.where('last_modified', isGreaterThan: since.millisecondsSinceEpoch);
      }

      final QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();
      final List<Flashcard> cards = [];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          // Ensure UUID is set to the document ID
          data['uuid'] = doc.id;
          cards.add(Flashcard.fromMap(data));
        } catch (e) {
          print('Error converting Firestore document ${doc.id} to Flashcard: $e');
        }
      }
      
      return cards;
    } catch (e) {
      print('Error fetching cards from Firestore: $e');
      // Return empty list instead of throwing to allow partial sync
      return [];
    }
  }
  
  // Optimized method to fetch only UUID and lastModified for efficient comparison
  Future<Map<String, int>> fetchCardsMetadata({DateTime? since}) async {
    try {
      Query<Map<String, dynamic>> query = _flashcardsCollection;
      if (since != null) {
        query = query.where('last_modified', isGreaterThan: since.millisecondsSinceEpoch);
      }
      final QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();
      final Map<String, int> metadata = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final lastModified = data['last_modified'];
        if (lastModified is int) {
          metadata[doc.id] = lastModified;
        }
      }
      return metadata;
    } catch (e) {
      print('Error fetching card metadata from Firestore: $e');
      return {};
    }
  }

  // Get total number of cards in Firestore
  Future<int> getTotalCardCount() async {
    try {
      final AggregateQuerySnapshot snapshot =
          await _flashcardsCollection.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting card count from Firestore: $e');
      return -1; // Indicate error
    }
  }
  
  // Batch save multiple cards at once (more efficient)
  Future<void> batchSaveCards(List<Flashcard> cards) async {
    if (cards.isEmpty) return;
    
    // Split into chunks of 500 (Firestore batch limit)
    final int chunkSize = 500;
    final List<List<Flashcard>> batches = cards.slices(chunkSize).toList();
    
    for (final batch in batches) {
      final WriteBatch writeBatch = FirebaseFirestore.instance.batch();
      
      for (final card in batch) {
        if (card.uuid == null) continue;
        
        final doc = _flashcardsCollection.doc(card.uuid);
        final data = card.toMap()
          ..remove('id')
          ..['server_timestamp'] = FieldValue.serverTimestamp();
        
        writeBatch.set(doc, data, SetOptions(merge: true));
      }
      
      await writeBatch.commit();
    }
  }
  
  // Batch delete multiple cards at once (more efficient)
  Future<void> batchDeleteCards(List<String> uuids) async {
    if (uuids.isEmpty) return;
    
    // Split into chunks of 500 (Firestore batch limit)
    final int chunkSize = 500;
    for (int i = 0; i < uuids.length; i += chunkSize) {
      final WriteBatch writeBatch = FirebaseFirestore.instance.batch();
      final end = (i + chunkSize < uuids.length) ? i + chunkSize : uuids.length;
      
      for (int j = i; j < end; j++) {
        final doc = _flashcardsCollection.doc(uuids[j]);
        
        // Soft delete
        writeBatch.set(doc, {
          'is_deleted': true,
          'last_modified': DateTime.now().millisecondsSinceEpoch,
          'server_timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // For hard delete, use:
        // writeBatch.delete(doc);
      }
      
      await writeBatch.commit();
    }
  }

  Future<bool> isConnected() async {
    try {
      await FirebaseFirestore.instance.collection('test').limit(1).get();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Flashcard>> getCardsModifiedSince(int since) async {
    return await fetchCards(since: DateTime.fromMillisecondsSinceEpoch(since));
  }

  Future<void> pushCards(List<Flashcard> cards) async {
    await batchSaveCards(cards);
  }
}