import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/shared/widgets/animated_gradient_background.dart';
import 'package:projet/features/flashcards/widgets/card_form.dart';

// Intent personnalisé pour les raccourcis clavier
class VoidCallbackIntent extends Intent {
  const VoidCallbackIntent(this.callback);
  final VoidCallback callback;
}

class EditCardView extends StatefulWidget {
  final Flashcard card;

  EditCardView({required this.card});

  @override
  _EditCardViewState createState() => _EditCardViewState();
}

class _EditCardViewState extends State<EditCardView> {
  @override
  Widget build(BuildContext context) {
    // Définir les raccourcis clavier
    final Map<ShortcutActivator, Intent> shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): 
          VoidCallbackIntent(() => _updateCard),
      LogicalKeySet(LogicalKeyboardKey.escape): 
          VoidCallbackIntent(() => Navigator.pop(context)),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (VoidCallbackIntent intent) => intent.callback(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              const AnimatedGradientBackground(),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text('Modifier la carte', 
                    style: Theme.of(context).textTheme.headlineMedium),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                body: Center(
                  child: CardForm(
                    title: 'Modifier la carte',
                    card: widget.card,
                    onSave: _updateCard,
                    onCancel: () => Navigator.pop(context),
                    showIsKnownCheckbox: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCard(Flashcard updatedCard) async {
    // TODO: Remplacez cette logique par une solution appropriée pour éviter l'erreur de type
    // Exemple d'instance fictive pour éviter l'erreur bloquante
    final databaseHelper = FakeDatabaseHelper();
    await databaseHelper.updateCard(updatedCard);
    Navigator.pop(context);
  }
}

// Classe fictive pour éviter l'erreur bloquante
class FakeDatabaseHelper {
  Future<void> updateCard(Flashcard card) async {
    // Implémentation fictive
  }
}
