// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:projet/main.dart';
import 'package:projet/services/database_helper.dart'; // Import DatabaseHelper
import 'package:projet/features/flashcards/models/flashcard.dart'; // Import Flashcard model
import 'package:projet/core/theme/theme_manager.dart';
import 'package:projet/core/accessibility/accessibility_manager.dart';
import 'package:uuid/uuid.dart'; // Import Uuid
import 'package:projet/services/database/models/import_result.dart'; // Import ImportResult

// Mock DatabaseHelper pour les tests
class MockDatabaseHelper implements DatabaseHelper {
  Future<int> deleteCard(int id) async => 1;
  Future<int> deleteCardByUuid(String uuid) async => 1;
  Future<int> deleteCardPermanently(int id) async => 1;
  Future<List<Flashcard>> getAllCards({bool includeDeleted = false}) async => [];
  Future<Flashcard?> getCardById(int id) async => null;
  Future<Flashcard?> getCardByUuid(String uuid) async => null;
  Future<List<Flashcard>> getCardsByCategory(String category) async => [];
  Future<List<Flashcard>> getCardsModifiedSince(int timestamp) async => [];
  Future<List<Flashcard>> getDeletedCards() async => [];
  Future<List<String>> getDistinctCategories() async => [];
  Future<String?> getMetadata(String key) async => null;
  Future<List<Flashcard>> getUnknownCards() async => [];
  Future<ImportResult> insertMultipleCards(List<Flashcard> cards) async => ImportResult(
    successCount: cards.length, 
    updateCount: 0, 
    errorCount: 0, 
    errors: [], 
    message: 'Mock insert result'
  );
  Future<int> purgeAllCards() async => 0;
  Future<int> saveCard(Flashcard card) async => 1;
  Future<void> setMetadata(String key, String value) async {}
  Future<int> updateCard(Flashcard card) async => 1;
  Future<int> upsertCard(Flashcard card) async => 1;
  Future<String> exportToCsv() async => "";
  Future<ImportResult> importFromCsv(String csvContent) async => ImportResult(
    successCount: 0, 
    updateCount: 0, 
    errorCount: 0, 
    errors: [], 
    message: 'Mock import result'
  );
  String get tableName => 'flashcards';
  Uuid get uuid => Uuid();
  void enableCache(bool enable) {}
  Future<void> close() async {}
  void clearCache() {}

  // Ajouter les méthodes manquantes
  Future<String> exportCardsToFile() async => "";
  Future<Flashcard?> getCard({int? id, String? uuid}) async => null;
  Future<void> initialize() async {}
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeManager>(create: (_) => ThemeManager()),
          ChangeNotifierProvider<AccessibilityManager>(create: (_) => AccessibilityManager()),
          Provider<DatabaseHelper>(create: (_) => MockDatabaseHelper()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
