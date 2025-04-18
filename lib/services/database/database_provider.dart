import 'package:projet/features/flashcards/models/flashcard.dart';
import 'models/import_result.dart';

/// Interface définissant les opérations requises pour un provider de base de données
abstract class DatabaseProvider {
  /// Initialise le provider de base de données
  Future<void> initialize();
  
  /// Insère une carte et retourne son ID
  Future<int> insertCard(Flashcard card);
  
  /// Récupère une carte par ID ou UUID
  Future<Flashcard?> getCard({int? id, String? uuid});
  
  /// Met à jour une carte existante
  Future<int> updateCard(Flashcard card);
  
  /// Marque une carte comme supprimée (suppression logique)
  Future<int> deleteCard(int id);
  
  /// Supprime définitivement une carte de la base de données
  Future<int> permanentlyDeleteCard(int id);
  
  /// Insère ou met à jour une carte (upsert)
  Future<int> upsertCard(Flashcard card);
  
  /// Récupère toutes les cartes avec filtrage optionnel
  Future<List<Flashcard>> getAllCards({
    Map<String, dynamic>? filters, 
    bool includeDeleted,
    int? limit,
    int? offset,
  });
  
  /// Récupère les cartes non connues
  Future<List<Flashcard>> getUnknownCards();
  
  /// Récupère les cartes par catégorie
  Future<List<Flashcard>> getCardsByCategory(String category);
  
  /// Récupère les cartes supprimées
  Future<List<Flashcard>> getDeletedCards();
  
  /// Récupère les cartes modifiées depuis un timestamp donné
  Future<List<Flashcard>> getCardsModifiedSince(int timestamp);
  
  /// Insère plusieurs cartes en une seule opération
  Future<ImportResult> insertMultipleCards(List<Flashcard> cards);
  
  /// Supprime définitivement toutes les cartes (DANGER)
  Future<int> purgeAllCards();
  
  /// Récupère une valeur de métadonnée par clé
  Future<String?> getMetadataValue(String key);
  
  /// Définit une valeur de métadonnée par clé
  Future<void> setMetadataValue(String key, String value);
  
  /// Efface toutes les métadonnées
  Future<void> clearAllMetadata();
  
  /// Ferme la connexion à la base de données
  Future<void> close();
  
  /// Exporte toutes les cartes au format CSV
  Future<String> exportToCsv();
  
  /// Importe des cartes depuis une chaîne CSV
  Future<int> importFromCsv(String csvContent);
}