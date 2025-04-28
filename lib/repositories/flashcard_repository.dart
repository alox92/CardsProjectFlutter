import 'package:flutter/foundation.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/services/database_helper.dart';

/// Repository pour gérer les opérations CRUD sur les flashcards
class FlashcardRepository {
  final DatabaseHelper _dbHelper;
  
  /// Constructeur qui prend un DatabaseHelper en paramètre
  FlashcardRepository(this._dbHelper);
  
  /// Instance singleton du repository
  static late FlashcardRepository instance;
  
  /// Configure l'instance singleton du repository
  static void configureInstance(DatabaseHelper dbHelper) {
    instance = FlashcardRepository(dbHelper);
  }
  
  /// Récupère toutes les cartes de la base de données
  Future<List<Flashcard>> getAllCards() async {
    final cards = await _dbHelper.getFlashcards();
    return cards.map((map) => Flashcard.fromMap(map)).toList();
  }
  
  /// Récupère les cartes filtrées par catégorie
  Future<List<Flashcard>> getCardsByCategory(String? category) async {
    final cards = await _dbHelper.getFlashcardsByCategory(category);
    return cards.map((map) => Flashcard.fromMap(map)).toList();
  }
  
  /// Récupère les cartes filtrées par étiquette (tag)
  Future<List<Flashcard>> getCardsByTag(String tag) async {
    final cards = await _dbHelper.getFlashcardsByTag(tag);
    return cards.map((map) => Flashcard.fromMap(map)).toList();
  }
  
  /// Récupère une carte par son ID
  Future<Flashcard?> getCardById(String id) async {
    final cardMap = await _dbHelper.getFlashcardById(id);
    if (cardMap != null) {
      return Flashcard.fromMap(cardMap);
    }
    return null;
  }
  
  /// Ajoute une nouvelle carte
  Future<String> addCard(Flashcard card) async {
    final id = await _dbHelper.insertFlashcard(card.toMap());
    return id;
  }
  
  /// Met à jour une carte existante
  Future<int> updateCard(Flashcard card) async {
    return await _dbHelper.updateFlashcard(card.toMap());
  }
  
  /// Supprime une carte par son ID
  Future<int> deleteCard(String id) async {
    return await _dbHelper.deleteFlashcard(id);
  }
  
  /// Supprime toutes les cartes
  Future<int> deleteAllCards() async {
    return await _dbHelper.deleteAllFlashcards();
  }

  /// Structure pour le résultat de l'importation
  class ImportResult {
    final int successCount;
    final int updateCount;
    final int errorCount;
    
    ImportResult({
      required this.successCount,
      required this.updateCount,
      required this.errorCount,
    });
  }
  
  /// Importe une liste de cartes
  Future<ImportResult> importCards(List<Flashcard> cards) async {
    int successCount = 0;
    int updateCount = 0;
    int errorCount = 0;
    
    for (final card in cards) {
      try {
        final existingCard = await getCardById(card.id);
        if (existingCard != null) {
          final result = await updateCard(card);
          if (result > 0) updateCount++;
          else errorCount++;
        } else {
          final id = await addCard(card);
          if (id.isNotEmpty) successCount++;
          else errorCount++;
        }
      } catch (e) {
        errorCount++;
      }
    }
    
    return ImportResult(
      successCount: successCount,
      updateCount: updateCount,
      errorCount: errorCount,
    );
  }
}