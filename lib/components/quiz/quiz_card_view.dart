import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/shared/widgets/neon_button.dart';

class QuizCardView extends StatelessWidget {
  final Flashcard card;
  final int currentIndex;
  final int totalCards;
  final int currentScore;
  final bool showAnswer;
  final double fontSize;
  final Color accentColor;
  final Color goodColor;
  final Color badColor;
  final VoidCallback onRevealAnswer;
  final VoidCallback onPlayAudio;
  final Function(bool) onAnswer;

  const QuizCardView({
    Key? key,
    required this.card,
    required this.currentIndex,
    required this.totalCards,
    required this.currentScore,
    required this.showAnswer,
    required this.fontSize,
    required this.accentColor,
    required this.goodColor,
    required this.badColor,
    required this.onRevealAnswer,
    required this.onPlayAudio,
    required this.onAnswer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.12 * 255).toInt()),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accentColor.withAlpha((0.18 * 255).toInt()), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha((0.18 * 255).toInt()),
                    blurRadius: 32,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  LinearProgressIndicator(
                    value: (currentIndex + 1) / totalCards,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Carte ${currentIndex + 1}/$totalCards',
                    style: TextStyle(
                      fontSize: fontSize - 2, 
                      color: Colors.grey[600], 
                      fontFamily: 'Orbitron'
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    card.front,
                    style: TextStyle(
                      fontSize: fontSize + 8, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'Orbitron'
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  
                  // Audio button if available
                  if (card.audioPath != null && card.audioPath!.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: NeonButton(
                        onTap: onPlayAudio,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Écouter (A)', 
                              style: TextStyle(fontSize: fontSize - 2, color: Colors.white)
                            ),
                          ],
                        ),
                        color: accentColor,
                      ),
                    ),
                  
                  Divider(height: 36),
                  
                  // Answer section
                  if (showAnswer)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha((0.10 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor, width: 1),
                      ),
                      child: Text(
                        card.back,
                        style: TextStyle(
                          fontSize: fontSize + 4, 
                          color: accentColor, 
                          fontFamily: 'Orbitron'
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    NeonButton(
                      onTap: onRevealAnswer,
                      child: Text(
                        'Voir la réponse (Espace)', 
                        style: TextStyle(fontSize: fontSize, color: Colors.white)
                      ),
                      color: accentColor,
                    ),
                  
                  SizedBox(height: 24),
                  
                  // Answer feedback buttons
                  if (showAnswer)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: NeonButton(
                            onTap: () => onAnswer(true),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Je savais (→ ou G)', 
                                  style: TextStyle(fontSize: fontSize - 1, color: Colors.white)
                                ),
                              ],
                            ),
                            color: goodColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: NeonButton(
                            onTap: () => onAnswer(false),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'À revoir (← ou B)', 
                                  style: TextStyle(fontSize: fontSize - 1, color: Colors.white)
                                ),
                              ],
                            ),
                            color: badColor,
                          ),
                        ),
                      ],
                    ),
                  
                  SizedBox(height: 16),
                  Text(
                    'Score actuel : $currentScore / $currentIndex',
                    style: TextStyle(
                      fontSize: fontSize - 2, 
                      color: Colors.grey[600], 
                      fontFamily: 'Orbitron'
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}