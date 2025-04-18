import 'package:flutter/material.dart';
import '../../../utils/logger.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:provider/provider.dart';

typedef CardsStateSetter = void Function(List<Flashcard> cards);

class QuizLoaderHelper {
  static Future<void> loadCards(
    BuildContext context,
    String? category,
    void Function(void Function()) setState,
    Logger logger,
    CardsStateSetter setCardsState,
  ) async {
    setState(() {
      // isLoading, errorMessage, etc. à gérer dans le State
    });
    try {
      final List<Flashcard> cardsToLearn;
      if (category != null) {
        cardsToLearn = await Provider.of(context, listen: false).getCardsByCategory(category);
      } else {
        cardsToLearn = await Provider.of(context, listen: false).getUnknownCards();
      }
      cardsToLearn.shuffle();
      setCardsState(cardsToLearn);
      logger.info('Quiz démarré avec [${cardsToLearn.length} cartes${category != null ? ' dans la catégorie $category' : ''}');
    } catch (e) {
      logger.error('Erreur lors du chargement des cartes pour le quiz: $e');
      setState(() {
        // isLoading, errorMessage, etc. à gérer dans le State
      });
    }
  }
}
