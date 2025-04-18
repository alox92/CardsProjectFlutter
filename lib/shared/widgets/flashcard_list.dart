import 'package:flutter/material.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import '../../services/database_helper.dart';
import 'package:projet/core/theme/theme_manager.dart';
import '../../views/edit_card_view.dart';

/// Composant pour afficher une liste de flashcards avec des fonctionnalités de gestion
class FlashcardList extends StatelessWidget {
  final List<Flashcard> cards;
  final DatabaseHelper databaseHelper;
  final Function() onCardModified;
  final Function(String?) onPlayAudio;
  final ThemeManager themeManager;
  final bool showDeleteConfirmation;
  final Function(String)? onError;

  const FlashcardList({
    Key? key,
    required this.cards,
    required this.databaseHelper,
    required this.onCardModified,
    required this.onPlayAudio,
    required this.themeManager,
    this.onError,
    this.showDeleteConfirmation = true,
  }) : super(key: key);

  // Animation de transition fade
  Future<T?> _pushFade<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _confirmDeleteCard(BuildContext context, Flashcard card) async {
    final cardId = card.id;
    if (cardId != null) {
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Voulez-vous vraiment supprimer cette carte ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Supprimer'),
            ),
          ],
        ),
      );
      
      if (confirmDelete == true) {
        try {
          await databaseHelper.deleteCard(cardId);
          onCardModified();
        } catch (e, stackTrace) {
          final errorMessage = 'Error deleting card: $e';
          print('$errorMessage\n$stackTrace');
          
          if (onError != null) {
            onError!(errorMessage);
          }
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Erreur : carte sans identifiant'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (cards.isEmpty) {
      return Center(
        child: Text(
          'Aucune carte ne correspond aux critères.',
          style: theme.textTheme.bodyLarge
        )
      );
    }
    
    return ListView.builder(
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Card(
            elevation: 8,
            color: theme.cardColor.withAlpha(242),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(themeManager.cardRadius),
            ),
            child: ListTile(
              title: Text(
                card.front, 
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
              ),
              subtitle: Text(
                card.back, 
                style: theme.textTheme.bodyLarge
              ),
              leading: card.audioPath != null ? IconButton(
                icon: Icon(Icons.volume_up, color: themeManager.accentColor),
                tooltip: 'Écouter',
                onPressed: () => onPlayAudio(card.audioPath),
              ) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.edit, color: themeManager.accentColor),
                    tooltip: 'Modifier',
                    onPressed: () async {
                      await _pushFade(context, EditCardView(card: card));
                      onCardModified();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Supprimer',
                    onPressed: () => _confirmDeleteCard(context, card),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
