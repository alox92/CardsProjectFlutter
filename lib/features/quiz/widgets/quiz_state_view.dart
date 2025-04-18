import 'package:flutter/material.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/features/quiz/widgets/quiz_card_view.dart';
import 'package:projet/features/quiz/widgets/quiz_result_view.dart';
import 'package:projet/shared/widgets/neon_button.dart';

class QuizStateView extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final bool finished;
  final List<Flashcard> cards;
  final int current;
  final int score;
  final bool showAnswer;
  final double fontSize;
  final Color accentColor;
  final String? category;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final VoidCallback onRevealAnswer;
  final VoidCallback onPlayAudio;
  final Function(bool) onAnswer;

  const QuizStateView({
    Key? key,
    required this.isLoading,
    this.errorMessage,
    required this.finished,
    required this.cards,
    required this.current,
    required this.score,
    required this.showAnswer,
    required this.fontSize,
    required this.accentColor,
    this.category,
    required this.onRetry,
    required this.onBack,
    required this.onRestart,
    required this.onExit,
    required this.onRevealAnswer,
    required this.onPlayAudio,
    required this.onAnswer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: accentColor),
            SizedBox(height: 16),
            Text(
              'Chargement des cartes...', 
              style: TextStyle(fontSize: fontSize, fontFamily: 'Orbitron')
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Erreur', 
              style: TextStyle(
                fontSize: fontSize + 4, 
                fontWeight: FontWeight.bold, 
                fontFamily: 'Orbitron'
              )
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!, 
              style: TextStyle(fontSize: fontSize, fontFamily: 'Orbitron')
            ),
            SizedBox(height: 24),
            NeonButton(
              onTap: onRetry,
              child: Text(
                'Réessayer', 
                style: TextStyle(fontSize: fontSize, color: Colors.white)
              ),
              color: accentColor,
            ),
          ],
        ),
      );
    }

    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(
              'Aucune carte à réviser${category != null ? ' dans $category' : ''}.',
              style: TextStyle(fontSize: fontSize + 2, fontFamily: 'Orbitron')
            ),
            SizedBox(height: 24),
            NeonButton(
              onTap: onBack,
              child: Text(
                'Retour', 
                style: TextStyle(fontSize: fontSize, color: Colors.white)
              ),
              color: accentColor,
            ),
          ],
        ),
      );
    }

    if (finished) {
      return QuizResultView(
        score: score,
        total: cards.length,
        fontSize: fontSize,
        accentColor: accentColor,
        onRestart: onRestart,
        onExit: onExit,
      );
    }

    return QuizCardView(
      card: cards[current],
      showAnswer: showAnswer,
      progress: (current + 1) / cards.length,
      score: score,
      total: cards.length, 
      fontSize: fontSize,
      accentColor: accentColor,
      onRevealAnswer: onRevealAnswer,
      onPlayAudio: onPlayAudio,
      onAnswer: onAnswer,
    );
  }
}