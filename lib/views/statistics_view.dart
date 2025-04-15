import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../services/database_helper.dart';
import '../accessibility_manager.dart';

class StatisticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
    final accessibility = Provider.of<AccessibilityManager>(context);

    // Couleurs adaptées pour le mode daltonien
    final colorKnown = accessibility.daltonianModeEnabled ? Colors.blue : Colors.green;
    final colorUnknown = accessibility.daltonianModeEnabled ? Colors.orange : Colors.orange;

    return Scaffold(
      appBar: AppBar(title: Text('Statistiques')),
      body: FutureBuilder<List<Flashcard>>(
        future: dbHelper.getAllCards(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final cards = snapshot.data!;
          if (cards.isEmpty) {
            return Center(child: Text('Aucune statistique disponible.'));
          }
          final known = cards.where((c) => c.isKnown).length;
          final unknown = cards.length - known;
          final knownPercent = (known / cards.length * 100).toStringAsFixed(1);
          final unknownPercent = (unknown / cards.length * 100).toStringAsFixed(1);
          
          return Center(
            child: Container(
              width: 500,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Résumé des cartes',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context, 
                        'Cartes connues', 
                        known.toString(), 
                        '$knownPercent%',
                        colorKnown
                      ),
                      _buildStatCard(
                        context, 
                        'Cartes à apprendre', 
                        unknown.toString(), 
                        '$unknownPercent%',
                        colorUnknown
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Total: ${cards.length} cartes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, String title, String value, String percent, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 200, // Largeur fixe pour une présentation desktop cohérente
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18, // Police plus grande
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 42, // Police très grande pour les chiffres
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              percent,
              style: TextStyle(
                fontSize: 20, // Police plus grande
                color: color.withAlpha((255 * 0.7).round()), // Use withAlpha
              ),
            ),
          ],
        ),
      ),
    );
  }
}