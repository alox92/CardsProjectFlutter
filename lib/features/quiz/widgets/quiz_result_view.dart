import 'package:flutter/material.dart';

class QuizResultView extends StatelessWidget {
  final int score;
  final int total;
  final double fontSize;
  final Color accentColor;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const QuizResultView({
    Key? key,
    required this.score,
    required this.total,
    required this.fontSize,
    required this.accentColor,
    required this.onRestart,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double percentage = (score / total) * 100;
    final String resultLabel = _getResultLabel(percentage);
    final Color resultColor = _getResultColor(percentage);
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.15 * 255).toInt()),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withAlpha((0.3 * 255).toInt()),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha((0.2 * 255).toInt()),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon
            Icon(
              _getResultIcon(percentage),
              size: 72,
              color: resultColor,
            ),
            
            SizedBox(height: 24),
            
            // Quiz finished title
            Text(
              'Quiz terminé !',
              style: TextStyle(
                fontSize: fontSize + 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16),
            
            // Score
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: resultColor.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '$score/$total',
                    style: TextStyle(
                      fontSize: fontSize + 24,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: fontSize + 8,
                      fontFamily: 'Orbitron',
                      color: resultColor,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Result evaluation
            Text(
              resultLabel,
              style: TextStyle(
                fontSize: fontSize + 4,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                color: resultColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onExit,
                    icon: Icon(Icons.exit_to_app),
                    label: Text(
                      'Quitter',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                
                SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRestart,
                    icon: Icon(Icons.replay),
                    label: Text(
                      'Rejouer',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  String _getResultLabel(double percentage) {
    if (percentage >= 90) {
      return 'Excellent !';
    } else if (percentage >= 70) {
      return 'Très bien !';
    } else if (percentage >= 50) {
      return 'Bon travail !';
    } else if (percentage >= 30) {
      return 'Continue tes efforts !';
    } else {
      return 'N\'abandonne pas !';
    }
  }

  Color _getResultColor(double percentage) {
    if (percentage >= 90) {
      return Colors.purpleAccent;
    } else if (percentage >= 70) {
      return Colors.greenAccent;
    } else if (percentage >= 50) {
      return Colors.blueAccent;
    } else if (percentage >= 30) {
      return Colors.orangeAccent;
    } else {
      return Colors.redAccent;
    }
  }

  IconData _getResultIcon(double percentage) {
    if (percentage >= 90) {
      return Icons.emoji_events;
    } else if (percentage >= 70) {
      return Icons.star;
    } else if (percentage >= 50) {
      return Icons.thumb_up;
    } else if (percentage >= 30) {
      return Icons.trending_up;
    } else {
      return Icons.school;
    }
  }
}