import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/core/theme/theme_manager.dart';
import '../../../shared/widgets/animated_gradient_background.dart';

class StatisticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final accentColor = themeManager.accentColor;
    final fontSize = themeManager.fontSize;

    // Définir colorKnown et colorUnknown avant leur utilisation
    final colorKnown = Colors.green;
    final colorUnknown = Colors.red;

    return Stack(
      children: [
        const AnimatedGradientBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('Statistiques', style: TextStyle(fontFamily: 'Orbitron')),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: FutureBuilder<List<Flashcard>>(
            future: Future.value([]), // Remplace dbHelper.getAllCards()
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: accentColor));
              }
              final cards = snapshot.data!;
              if (cards.isEmpty) {
                return Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: accentColor.withAlpha(45), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withAlpha(45),
                              blurRadius: 32,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bar_chart, color: accentColor, size: 48),
                            SizedBox(height: 16),
                            Text('Aucune statistique disponible.', style: TextStyle(fontSize: fontSize + 2, fontFamily: 'Orbitron')),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              final known = cards.where((c) => c.isKnown).length;
              final unknown = cards.length - known;
              final knownPercent = (known / cards.length * 100).toStringAsFixed(1);
              final unknownPercent = (unknown / cards.length * 100).toStringAsFixed(1);
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: 500,
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: accentColor.withAlpha(45), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withAlpha(45),
                            blurRadius: 32,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Résumé des cartes',
                            style: TextStyle(fontFamily: 'Orbitron', fontSize: fontSize + 8, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Cartes connues',
                                    style: TextStyle(fontSize: fontSize, color: colorKnown),
                                  ),
                                  Text(
                                    known.toString(),
                                    style: TextStyle(fontSize: fontSize, color: colorKnown),
                                  ),
                                  Text(
                                    '$knownPercent%',
                                    style: TextStyle(fontSize: fontSize, color: colorKnown),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'Cartes à apprendre',
                                    style: TextStyle(fontSize: fontSize, color: colorUnknown),
                                  ),
                                  Text(
                                    unknown.toString(),
                                    style: TextStyle(fontSize: fontSize, color: colorUnknown),
                                  ),
                                  Text(
                                    '$unknownPercent%',
                                    style: TextStyle(fontSize: fontSize, color: colorUnknown),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 32),
                          Text(
                            'Total: ${cards.length} cartes',
                            style: TextStyle(fontFamily: 'Orbitron', fontSize: fontSize + 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}