import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:projet/shared/widgets/neon_button.dart';

class QuizResultView extends StatelessWidget {
  final int score;
  final int totalCards;
  final Color accentColor;
  final double fontSize;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const QuizResultView({
    Key? key,
    required this.score,
    required this.totalCards,
    required this.accentColor,
    required this.fontSize,
    required this.onRestart,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
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
                  Text(
                    'Quiz terminé !', 
                    style: TextStyle(
                      fontSize: fontSize + 8, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'Orbitron'
                    )
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Score : $score / $totalCards',
                    style: TextStyle(
                      fontSize: fontSize + 12, 
                      color: accentColor, 
                      fontFamily: 'Orbitron'
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '${(score / totalCards * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: fontSize + 16, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'Orbitron'
                    ),
                  ),
                  SizedBox(height: 32),
                  NeonButton(
                    onTap: onRestart,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Recommencer', 
                          style: TextStyle(fontSize: fontSize, color: Colors.white)
                        ),
                      ],
                    ),
                    color: accentColor,
                  ),
                  SizedBox(height: 12),
                  NeonButton(
                    onTap: onExit,
                    child: Text(
                      'Retour à l\'accueil', 
                      style: TextStyle(fontSize: fontSize, color: Colors.white)
                    ),
                    color: Colors.redAccent,
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