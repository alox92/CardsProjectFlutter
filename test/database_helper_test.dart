import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:projet/services/database_helper.dart';
import 'package:projet/models/flashcard.dart';
import 'package:uuid/uuid.dart';

void main() {
  late DatabaseHelper dbHelper;
  var uuid = Uuid();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Utiliser un chemin de base de données en mémoire unique pour chaque test
    // pour éviter les interférences dues aux migrations persistantes.
    final dbPath = inMemoryDatabasePath;
    await deleteDatabase(dbPath); // Supprimer la base précédente si elle existe
    dbHelper = DatabaseHelper.internal(); // Utiliser le constructeur interne pour isoler
    await dbHelper.initDb(); // Initialiser la base pour ce test
  });

  tearDown(() async {
    // Pas besoin de supprimer explicitement si on utilise inMemoryDatabasePath
    // et qu'on le supprime dans setUp.
  });

  group('DatabaseHelper Tests', () {
    test('Should save a card and retrieve it with default values', () async {
      // Arrange
      final testCard = Flashcard(
        front: 'Test Front',
        back: 'Test Back',
        category: 'Test Category',
      );

      // Act
      final int id = await dbHelper.saveCard(testCard);
      final cards = await dbHelper.getAllCards();

      // Assert
      expect(id, greaterThan(0));
      expect(cards.length, 1);
      final savedCard = cards[0];
      expect(savedCard.front, 'Test Front');
      expect(savedCard.back, 'Test Back');
      expect(savedCard.category, 'Test Category');
      expect(savedCard.isKnown, false); // Default value
      expect(savedCard.isDeleted, false); // Default value
      expect(savedCard.uuid, isNotNull); // Should have UUID
      expect(savedCard.lastModified, isNotNull); // Should have timestamp
    });

    test('Should update a card using ID', () async {
      // Arrange
      final originalCard = Flashcard(
        front: 'Original Front',
        back: 'Original Back',
      );
      final id = await dbHelper.saveCard(originalCard);
      final originalSavedCard = (await dbHelper.getAllCards()).first; // Get the saved card with UUID etc.

      // Act
      final updatedCard = Flashcard(
        id: id, // Use local ID for update
        uuid: originalSavedCard.uuid, // Keep the original UUID
        front: 'Updated Front',
        back: 'Updated Back',
        isKnown: true,
        category: 'Updated Category',
      );
      final beforeUpdateTimestamp = originalSavedCard.lastModified;
      await Future.delayed(Duration(milliseconds: 10)); // Ensure timestamp changes
      final updateResult = await dbHelper.updateCard(updatedCard);
      final cards = await dbHelper.getAllCards();

      // Assert
      expect(updateResult, 1); // 1 row updated
      expect(cards.length, 1);
      final finalCard = cards[0];
      expect(finalCard.id, id);
      expect(finalCard.uuid, originalSavedCard.uuid); // UUID should not change
      expect(finalCard.front, 'Updated Front');
      expect(finalCard.back, 'Updated Back');
      expect(finalCard.isKnown, true);
      expect(finalCard.category, 'Updated Category');
      expect(finalCard.isDeleted, false);
      expect(finalCard.lastModified, isNotNull);
      expect(finalCard.lastModified, greaterThan(beforeUpdateTimestamp!)); // Timestamp should update
    });

     test('Should update a card using UUID', () async {
      // Arrange
      final cardUuid = uuid.v4();
      final originalCard = Flashcard(
        uuid: cardUuid,
        front: 'UUID Front',
        back: 'UUID Back',
      );
      await dbHelper.saveCard(originalCard);
      final originalSavedCard = (await dbHelper.getAllCards()).firstWhere((c) => c.uuid == cardUuid);

      // Act
      final updatedCard = Flashcard(
        // id: originalSavedCard.id, // ID is optional if UUID is present
        uuid: cardUuid, // Use UUID for update
        front: 'Updated UUID Front',
        back: 'Updated UUID Back',
        isKnown: true,
      );
       final beforeUpdateTimestamp = originalSavedCard.lastModified;
       await Future.delayed(Duration(milliseconds: 10));
       final updateResult = await dbHelper.updateCard(updatedCard);
       final cards = await dbHelper.getAllCards();

      // Assert
       expect(updateResult, 1);
       expect(cards.length, 1);
       final finalCard = cards[0];
       expect(finalCard.uuid, cardUuid);
       expect(finalCard.front, 'Updated UUID Front');
       expect(finalCard.isKnown, true);
       expect(finalCard.lastModified, greaterThan(beforeUpdateTimestamp!));
     });


    test('Should soft delete a card by ID', () async {
      // Arrange
      final testCard = Flashcard(front: 'To Delete', back: 'Will be soft deleted');
      final id = await dbHelper.saveCard(testCard);
      expect((await dbHelper.getAllCards()).length, 1); // Verify it exists

      // Act
      final deleteResult = await dbHelper.deleteCard(id); // Soft delete
      final activeCards = await dbHelper.getAllCards(); // Should be empty
      final allCardsIncludingDeleted = await dbHelper.getAllCards(includeDeleted: true); // Should contain 1

      // Assert
      expect(deleteResult, 1); // 1 row updated
      expect(activeCards.length, 0);
      expect(allCardsIncludingDeleted.length, 1);
      final deletedCard = allCardsIncludingDeleted[0];
      expect(deletedCard.id, id);
      expect(deletedCard.isDeleted, true); // Verify flag is set
      expect(deletedCard.lastModified, isNotNull); // Timestamp should be updated
    });

     test('Should soft delete a card by UUID', () async {
      // Arrange
       final cardUuid = uuid.v4();
       final testCard = Flashcard(uuid: cardUuid, front: 'Delete By UUID', back: '...');
       await dbHelper.saveCard(testCard);
       expect((await dbHelper.getAllCards()).length, 1);

      // Act
       final deleteResult = await dbHelper.deleteCardByUuid(cardUuid); // Soft delete by UUID
       final activeCards = await dbHelper.getAllCards();
       final allCardsIncludingDeleted = await dbHelper.getAllCards(includeDeleted: true);

      // Assert
       expect(deleteResult, 1);
       expect(activeCards.length, 0);
       expect(allCardsIncludingDeleted.length, 1);
       expect(allCardsIncludingDeleted[0].uuid, cardUuid);
       expect(allCardsIncludingDeleted[0].isDeleted, true);
     });

    test('Should prevent saving card with duplicate UUID', () async {
      // Arrange
      final cardUuid = uuid.v4();
      final card1 = Flashcard(uuid: cardUuid, front: 'Card 1', back: '...');
      final card2 = Flashcard(uuid: cardUuid, front: 'Card 2', back: '...');

      // Act
      final id1 = await dbHelper.saveCard(card1);
      final id2 = await dbHelper.saveCard(card2); // Should fail or return -1 due to UNIQUE constraint

      final cards = await dbHelper.getAllCards();

      // Assert
      expect(id1, greaterThan(0));
      expect(id2, -1); // Expecting error code
      expect(cards.length, 1); // Only the first card should be saved
      expect(cards[0].front, 'Card 1');
    });

    // TODO: Add tests for importFromCsv (mocking file content or providing string)
    // TODO: Add tests for exportToCsv
  });
}
