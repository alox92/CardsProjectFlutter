import 'package:flutter/material.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';

class QuizCardView extends StatelessWidget {
  final Flashcard card;
  final bool showAnswer;
  final double progress;
  final int score;
  final int total;
  final double fontSize;
  final Color accentColor;
  final VoidCallback onRevealAnswer;
  final VoidCallback onPlayAudio;
  final Function(bool) onAnswer;

  const QuizCardView({
    Key? key,
    required this.card,
    required this.showAnswer,
    required this.progress,
    required this.score,
    required this.total,
    required this.fontSize,
    required this.accentColor,
    required this.onRevealAnswer,
    required this.onPlayAudio,
    required this.onAnswer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasAudio = card.audioPath != null && card.audioPath!.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress and stats
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$score/$total correct',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withAlpha((0.2 * 255).toInt()),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            
            SizedBox(height: 24),
            
            // Card content
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Container(
                    key: ValueKey<String>(showAnswer ? 'answer' : 'question'),
                    padding: const EdgeInsets.all(24.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: showAnswer 
                          ? accentColor.withAlpha((0.15 * 255).toInt())
                          : Colors.white.withAlpha((0.15 * 255).toInt()),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: showAnswer 
                            ? accentColor.withAlpha((0.5 * 255).toInt())
                            : Colors.white.withAlpha((0.3 * 255).toInt()),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: showAnswer
                              ? accentColor.withAlpha((0.2 * 255).toInt())
                              : Colors.black.withAlpha((0.1 * 255).toInt()),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Side indicator and title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: showAnswer
                                      ? accentColor.withAlpha((0.2 * 255).toInt())
                                      : Colors.white.withAlpha((0.2 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  showAnswer ? 'Réponse' : 'Question',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                    color: showAnswer
                                        ? accentColor
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              if (hasAudio)
                                IconButton(
                                  icon: Icon(Icons.volume_up),
                                  onPressed: onPlayAudio,
                                  tooltip: 'Écouter l\'audio',
                                  color: accentColor,
                                ),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Card content
                          Text(
                            showAnswer ? card.back : card.front,
                            style: TextStyle(
                              fontSize: fontSize + 8,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Category chip if available
                          if (card.category != null && card.category!.isNotEmpty)
                            Chip(
                              label: Text(
                                card.category!,
                                style: TextStyle(
                                  fontSize: fontSize - 2,
                                  color: accentColor,
                                ),
                              ),
                              backgroundColor: accentColor.withAlpha((0.1 * 255).toInt()),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Action buttons
            if (!showAnswer)
              ElevatedButton(
                onPressed: onRevealAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 16.0,
                  ),
                ),
                child: Text(
                  'Voir la réponse',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onAnswer(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text(
                        'Je ne savais pas',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: 'Orbitron',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onAnswer(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text(
                        'Je savais',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: 'Orbitron',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}