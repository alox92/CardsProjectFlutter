import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui';

import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/core/theme/theme_manager.dart';
import 'package:projet/shared/widgets/neon_button.dart';

import 'audio_controls_widget.dart';
import 'category_selector_widget.dart';

class CardForm extends StatefulWidget {
  final Flashcard? card; // Null pour une nouvelle carte, valeur pour édition
  final Function(Flashcard card) onSave;
  final VoidCallback onCancel;
  final String title;
  final bool showIsKnownCheckbox;

  const CardForm({
    Key? key,
    this.card,
    required this.onSave,
    required this.onCancel,
    required this.title,
    this.showIsKnownCheckbox = false,
  }) : super(key: key);

  @override
  _CardFormState createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  String? _selectedCategory;
  List<String> _categories = [];
  bool _isKnown = false;
  
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    // Initialisation des valeurs si on édite une carte existante
    if (widget.card != null) {
      _frontController.text = widget.card!.front;
      _backController.text = widget.card!.back;
      _selectedCategory = widget.card!.category;
      _isKnown = widget.card!.isKnown;
      _audioPath = widget.card!.audioPath;
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    // Remplacez cette méthode par une logique appropriée pour charger les catégories
    setState(() {
      _categories = []; // Exemple : chargez les catégories depuis une source appropriée
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
      // Remplacez cette logique par une logique appropriée pour renommer la catégorie
      setState(() {
        _selectedCategory = newName;
      });
      await _loadCategories();
    }
  }

  Future<void> _deleteCategory(String category) async {
    // Remplacez cette méthode par une logique appropriée pour supprimer une catégorie
    setState(() {
      if (_selectedCategory == category) _selectedCategory = null;
    });
    await _loadCategories();
  }

  void _validateAndSave() {
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

    final card = Flashcard(
      id: widget.card?.id, // null pour une nouvelle carte, ID existant sinon
      front: _frontController.text,
      back: _backController.text,
      category: _selectedCategory,
      audioPath: _audioPath,
      isKnown: _isKnown,
    );
    
    widget.onSave(card);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth < 500 ? constraints.maxWidth * 0.95 : 420;
        return AnimatedContainer(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(themeManager.cardRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: themeManager.glassBlurSigma, sigmaY: themeManager.glassBlurSigma),
              child: Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(themeManager.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor,
                      blurRadius: 32,
                      offset: Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: themeManager.accentColor.withAlpha(31),
                    width: 1.5,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        controller: _frontController,
                        decoration: InputDecoration(labelText: 'Recto'),
                        textInputAction: TextInputAction.next,
                        style: TextStyle(fontFamily: 'Orbitron'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _backController,
                        decoration: InputDecoration(labelText: 'Verso'),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _validateAndSave(),
                        style: TextStyle(fontFamily: 'Orbitron'),
                      ),
                      SizedBox(height: 12),
                      CategorySelectorWidget(
                        selectedCategory: _selectedCategory,
                        categories: _categories,
                        onCategoryChanged: (value) => setState(() => _selectedCategory = value),
                        onAddCategory: () {
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
                                  onPressed: () => Navigator.of(context).pop(),
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
                        },
                        onRenameCategory: (cat) => _renameCategory(cat),
                        onDeleteCategory: (cat) => _deleteCategory(cat),
                        categoryController: _categoryController,
                      ),
                      if (widget.showIsKnownCheckbox) ...[
                        SizedBox(height: 12),
                        CheckboxListTile(
                          title: Text('Carte connue', style: TextStyle(fontFamily: 'Orbitron')),
                          value: _isKnown,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _isKnown = value);
                            }
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                      SizedBox(height: 12),
                      AudioControlsWidget(
                        initialAudioPath: _audioPath,
                        onAudioChanged: (path) => setState(() => _audioPath = path),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: 'Annuler et revenir',
                            child: NeonButton(
                              onTap: widget.onCancel,
                              child: Text('Annuler', style: TextStyle(color: Colors.white)),
                              color: Colors.redAccent,
                            ),
                          ),
                          SizedBox(width: 12),
                          Tooltip(
                            message: 'Enregistrer la carte',
                            child: NeonButton(
                              onTap: _validateAndSave,
                              child: Text('Enregistrer', style: TextStyle(color: Colors.white)),
                              color: themeManager.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}