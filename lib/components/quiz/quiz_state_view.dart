import 'package:flutter/material.dart';
import 'package:projet/shared/widgets/neon_button.dart';

class QuizStateView extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final double fontSize;
  final Color accentColor;
  final String? category;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const QuizStateView({
    Key? key,
    required this.isLoading,
    this.errorMessage,
    required this.fontSize,
    required this.accentColor,
    this.category,
    required this.onRetry,
    required this.onBack,
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

    // No cards view
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
}