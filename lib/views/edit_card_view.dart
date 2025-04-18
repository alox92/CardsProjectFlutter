import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/services/database/database.dart';
import 'package:projet/features/flashcards/widgets/card_form.dart';
import 'package:projet/shared/widgets/animated_gradient_background.dart';

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
  // Variable temporaire pour stocker la carte en cours d'édition
  Flashcard? _currentCard;
  
  @override
  void initState() {
    super.initState();
    _currentCard = widget.card;
  }
  
  @override
  Widget build(BuildContext context) {
    // Définir les raccourcis clavier
    final Map<ShortcutActivator, Intent> shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): 
          VoidCallbackIntent(() => _saveCurrentCard()),
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

  void _updateCard(Flashcard updatedCard) {
    _currentCard = updatedCard;
    _saveCurrentCard();
  }
  
  void _saveCurrentCard() async {
    if (_currentCard != null) {
      await Provider.of<DatabaseHelper>(context, listen: false).updateCard(_currentCard!);
      Navigator.pop(context);
    }
  }
}
