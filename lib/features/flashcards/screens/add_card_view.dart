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

class AddCardView extends StatefulWidget {
  @override
  _AddCardViewState createState() => _AddCardViewState();
}

class _AddCardViewState extends State<AddCardView> {
  @override
  Widget build(BuildContext context) {
    // Définir les raccourcis clavier pour la vue
    final Map<ShortcutActivator, Intent> shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): 
          VoidCallbackIntent(() => _saveCard),
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
                  title: Text('Ajouter une carte', 
                    style: Theme.of(context).textTheme.headlineMedium),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                body: Center(
                  child: CardForm(
                    title: 'Ajouter une carte',
                    onSave: _saveCard,
                    onCancel: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveCard(Flashcard card) async {
    // TODO: Remplacez par une instance réelle ou une solution appropriée
    print('Card saved: ${card.front}');
    Navigator.pop(context);
  }
}