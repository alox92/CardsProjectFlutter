import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/services/database/database.dart';
import 'package:projet/core/accessibility/accessibility_manager.dart';
import 'package:projet/core/theme/theme_manager.dart';
import 'package:projet/shared/widgets/stat_card.dart';

class StatisticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
    final accessibility = Provider.of<AccessibilityManager>(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final accentColor = themeManager.accentColor;
    final fontSize = themeManager.fontSize;

    // Couleurs adaptées pour le mode daltonien
    final colorKnown = accessibility.daltonianModeEnabled ? Colors.blue : Colors.green;
    final colorUnknown = accessibility.daltonianModeEnabled ? Colors.orange : Colors.orange;

    return Stack(
      children: [
        const _AnimatedGradientBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('Statistiques', style: TextStyle(fontFamily: 'Orbitron')),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: FutureBuilder<List<Flashcard>>(
            future: dbHelper.getAllCards(),
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
                          color: Colors.white.withAlpha((30 * 255).toInt()),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: accentColor.withAlpha((45 * 255).toInt()), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withAlpha((45 * 255).toInt()),
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
              
              // Calculs des statistiques
              final int known = cards.where((c) => c.isKnown).length;
              final int unknown = cards.length - known;
              final String knownPercent = (known / cards.length * 100).toStringAsFixed(1);
              final String unknownPercent = (unknown / cards.length * 100).toStringAsFixed(1);
              
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: 500,
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((30 * 255).toInt()),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: accentColor.withAlpha((45 * 255).toInt()), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withAlpha((45 * 255).toInt()),
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
                              StatCard(
                                title: 'Cartes connues',
                                value: known.toString(),
                                subtitle: '$knownPercent%',
                                color: colorKnown,
                                fontSize: fontSize,
                                icon: Icons.check_circle,
                              ),
                              StatCard(
                                title: 'Cartes à apprendre',
                                value: unknown.toString(),
                                subtitle: '$unknownPercent%',
                                color: colorUnknown,
                                fontSize: fontSize,
                                icon: Icons.school,
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

// Fond animé dégradé dynamique (réutilisable)
class _AnimatedGradientBackground extends StatefulWidget {
  const _AnimatedGradientBackground();
  
  @override
  State<_AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<_AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 8))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(Colors.blue, Colors.purple, _controller.value)!,
                Color.lerp(Colors.cyan, Colors.pinkAccent, _controller.value)!,
                Color.lerp(Colors.indigo, Colors.tealAccent, 1 - _controller.value)!,
              ],
            ),
          ),
        );
      },
    );
  }
}