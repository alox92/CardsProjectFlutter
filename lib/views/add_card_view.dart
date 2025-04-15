import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ajouter pour les raccourcis
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../services/database_helper.dart';
import 'package:record/record.dart'; // Garder cet import
import 'package:path_provider/path_provider.dart';

// Ajout : Intent personnalisé pour les raccourcis clavier
class VoidCallbackIntent extends Intent {
  const VoidCallbackIntent(this.callback);
  final VoidCallback callback;
}

class AddCardView extends StatefulWidget {
  @override
  _AddCardViewState createState() => _AddCardViewState();
}

class _AddCardViewState extends State<AddCardView> {
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();
  String? _selectedCategory;
  final TextEditingController _categoryController = TextEditingController();
  List<String> _categories = [];
  String? _audioPath;
  bool _isRecording = false;
  final AudioRecorder _recorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    // Récupère toutes les catégories distinctes de la base
    final db = Provider.of<DatabaseHelper>(context, listen: false);
    final cards = await db.getAllCards();
    setState(() {
      _categories = cards.map((c) => c.category ?? '').where((c) => c.isNotEmpty).toSet().toList();
    });
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _isRecording = true;
      _audioPath = path;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _renameCategory(String oldCategory) async {
    final TextEditingController renameController = TextEditingController(text: oldCategory);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Renommer la catégorie'),
        content: TextField(
          controller: renameController,
          decoration: InputDecoration(hintText: 'Nouveau nom'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, renameController.text), child: Text('Renommer')),
        ],
      ),
    );
    if (newName != null && newName.trim().isNotEmpty && newName != oldCategory) {
      final db = Provider.of<DatabaseHelper>(context, listen: false);
      final cards = await db.getAllCards();
      for (final card in cards.where((c) => c.category == oldCategory)) {
        await db.updateCard(Flashcard(
          id: card.id,
          front: card.front,
          back: card.back,
          isKnown: card.isKnown,
          category: newName,
          audioPath: card.audioPath,
        ));
      }
      setState(() {
        _selectedCategory = newName;
      });
      await _loadCategories();
    }
  }

  Future<void> _deleteCategory(String category) async {
    final db = Provider.of<DatabaseHelper>(context, listen: false);
    final cards = await db.getAllCards();
    final cardsWithCategory = cards.where((c) => c.category == category).toList();
    if (cardsWithCategory.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Supprimer la catégorie'),
          content: Text('Supprimer la catégorie "$category" ? Les cartes associées ne seront plus catégorisées.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Supprimer')),
          ],
        ),
      );
      if (confirm == true) {
        for (final card in cardsWithCategory) {
          await db.updateCard(Flashcard(
            id: card.id,
            front: card.front,
            back: card.back,
            isKnown: card.isKnown,
            category: null,
            audioPath: card.audioPath,
          ));
        }
        setState(() {
          if (_selectedCategory == category) _selectedCategory = null;
        });
        await _loadCategories();
      }
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _frontController.dispose();
    _backController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Définir les raccourcis clavier
    final Map<ShortcutActivator, Intent> shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): VoidCallbackIntent(() => _saveCard(context)),
      LogicalKeySet(LogicalKeyboardKey.escape): VoidCallbackIntent(() => Navigator.pop(context)),
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
          child: Scaffold(
            appBar: AppBar(
              title: Text('Ajouter une carte'), // Traduit de 'Add Card'
            ),
            body: Center(
              child: Container(
                width: 400, // Largeur adaptée au desktop
                padding: const EdgeInsets.all(24.0),
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
                  children: <Widget>[
                    TextFormField(
                      controller: _frontController,
                      decoration: InputDecoration(labelText: 'Recto'), // Traduit de 'Front'
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _backController,
                      decoration: InputDecoration(labelText: 'Verso'), // Traduit de 'Back'
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _saveCard(context),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: [
                        DropdownMenuItem(value: null, child: Text('- Aucune catégorie -')),
                        ..._categories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(cat, overflow: TextOverflow.ellipsis)), // Pour éviter overflow
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, size: 18),
                                        tooltip: 'Renommer la catégorie',
                                        onPressed: () {
                                          // Fermer le dropdown avant d'ouvrir la dialog
                                          Navigator.of(context).pop();
                                          _renameCategory(cat);
                                        },
                                        splashRadius: 18,
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                        tooltip: 'Supprimer la catégorie',
                                        onPressed: () {
                                          // Fermer le dropdown avant d'ouvrir la dialog
                                          Navigator.of(context).pop();
                                          _deleteCategory(cat);
                                        },
                                        splashRadius: 18,
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                        DropdownMenuItem(
                          value: '__new__',
                          child: Text('Nouvelle catégorie...'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == '__new__') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Nouvelle catégorie'),
                              content: TextField(
                                controller: _categoryController,
                                decoration: InputDecoration(hintText: 'Nom de la catégorie'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final newCategoryName = _categoryController.text.trim();
                                    if (newCategoryName.isNotEmpty && !_categories.contains(newCategoryName)) {
                                      setState(() {
                                        _categories.add(newCategoryName);
                                        _selectedCategory = newCategoryName;
                                      });
                                    }
                                    _categoryController.clear();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Ajouter'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                      ),
                      isExpanded: true, // Permet à la Row de prendre toute la largeur
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? 'Arrêter' : 'Enregistrer audio'),
                          onPressed: _isRecording ? _stopRecording : _startRecording,
                        ),
                        if (_audioPath != null && !_isRecording)
                          Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text('Audio prêt'),
                          ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _AnimatedBounceButton(
                          onTap: () => Navigator.pop(context),
                          child: Text('Annuler'),
                          isTextButton: true,
                        ),
                        SizedBox(width: 12),
                        _AnimatedBounceButton(
                          onTap: () => _saveCard(context),
                          child: Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveCard(BuildContext context) async {
    if (_frontController.text.trim().isEmpty || _backController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Veuillez remplir les deux champs'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    Flashcard newCard = Flashcard(
      front: _frontController.text,
      back: _backController.text,
      category: _selectedCategory,
      audioPath: _audioPath,
    );
    await Provider.of<DatabaseHelper>(context, listen: false).saveCard(newCard);
    _frontController.clear();
    _backController.clear();
    Navigator.pop(context);
  }
}

// Widget pour effet rebond sur bouton (adapté pour TextButton ou ElevatedButton)
class _AnimatedBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isTextButton;
  const _AnimatedBounceButton({required this.child, required this.onTap, this.isTextButton = false});
  @override
  State<_AnimatedBounceButton> createState() => _AnimatedBounceButtonState();
}

class _AnimatedBounceButtonState extends State<_AnimatedBounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: widget.isTextButton
              ? TextButton(onPressed: widget.onTap, child: widget.child)
              : ElevatedButton(onPressed: widget.onTap, child: widget.child),
        ),
      ),
    );
  }
}