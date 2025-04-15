import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:just_audio/just_audio.dart'; // Ajout de l'import
import 'package:window_manager/window_manager.dart'; // Ajout pour plein écran
import '../models/flashcard.dart';
import '../services/database_helper.dart';
import '../theme_manager.dart';
import '../accessibility_manager.dart';
import 'add_card_view.dart';
import 'edit_card_view.dart';
import 'statistics_view.dart';
import '../components/desktop_menu.dart';
import 'quiz_view.dart'; // Ajout

// Ajout : Intent personnalisé pour les raccourcis clavier
class VoidCallbackIntent extends Intent {
  const VoidCallbackIntent(this.callback);
  final VoidCallback callback;
}

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late DatabaseHelper _databaseHelper;
  List<Flashcard> _cards = [];
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'known', 'unknown'
  String? _selectedCategory; // Ajout pour filtrage par catégorie
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Ajout du lecteur audio
  bool _isFullScreen = false; // Ajout pour l'état plein écran

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _databaseHelper = Provider.of<DatabaseHelper>(context, listen: false);
      _loadCards();
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Libérer les ressources
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    List<Flashcard> cards = await _databaseHelper.getAllCards();
    if (mounted) {
      setState(() {
        _cards = cards;
      });
    }
  }

  // Animation de transition fade
  Future<T?> _pushFade<T>(Widget page) {
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

  void _navigateToAddCard() async {
    await _pushFade(AddCardView());
    await _loadCards();
  }

  Future<void> _exportCards() async {
    final db = Provider.of<DatabaseHelper>(context, listen: false);
    final csv = await db.exportToCsv();
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Exporter les cartes (CSV)',
      fileName: 'flashcards.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) {
      final file = File(result);
      await file.writeAsString(csv);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exportation réussie.')));
    }
  }

  Future<void> _importCards() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Importer des cartes (CSV)',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final db = Provider.of<DatabaseHelper>(context, listen: false);
      await db.importFromCsv(content);
      await _loadCards();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Importation réussie.')));
    }
  }

  void _showCustomizationDialog() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    double fontSize = themeManager.fontSize;
    Color accentColor = themeManager.accentColor;
    Color pickerColor = accentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Personnaliser l\'interface'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Taille de police : ${fontSize.toStringAsFixed(0)}'),
                  Slider(
                    min: 12,
                    max: 32,
                    divisions: 10,
                    value: fontSize,
                    onChanged: (v) => setStateDialog(() => fontSize = v),
                    onChangeEnd: (v) => themeManager.setFontSize(v),
                  ),
                  SizedBox(height: 16),
                  Text('Couleur d\'accent'),
                  BlockPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) {
                      setStateDialog(() => pickerColor = color);
                      themeManager.setAccentColor(color);
                    },
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Mode plein écran'),
                    value: _isFullScreen,
                    onChanged: (value) async {
                      await windowManager.setFullScreen(value);
                      setStateDialog(() {
                        _isFullScreen = value;
                      });
                      setState(() {
                        _isFullScreen = value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityDialog() {
    final accessibility = Provider.of<AccessibilityManager>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accessibilité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Mode daltonien'),
              value: accessibility.daltonianModeEnabled,
              onChanged: (v) {
                if (v) {
                  accessibility.enableDaltonianMode();
                } else {
                  accessibility.disableDaltonianMode();
                }
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('VoiceOver (macOS)'),
              value: accessibility.voiceOverEnabled,
              onChanged: (v) {
                if (v) {
                  accessibility.enableVoiceOver();
                } else {
                  accessibility.disableVoiceOver();
                }
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('TalkBack (Windows/Android)'),
              value: accessibility.talkBackEnabled,
              onChanged: (v) {
                if (v) {
                  accessibility.enableTalkBack();
                } else {
                  accessibility.disableTalkBack();
                }
                setState(() {});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String category) async {
    final cardsWithCategory = _cards.where((c) => c.category == category).toList();
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
          await _databaseHelper.updateCard(
            Flashcard(
              id: card.id,
              front: card.front,
              back: card.back,
              isKnown: card.isKnown,
              category: null,
              audioPath: card.audioPath,
            ),
          );
        }
        await _loadCards();
        setState(() {
          if (_selectedCategory == category) _selectedCategory = null;
        });
      }
    }
  }

  Future<void> _playCardAudio(String? audioPath) async {
    if (audioPath != null && audioPath.isNotEmpty) {
      try {
        await _audioPlayer.setFilePath(audioPath);
        await _audioPlayer.play();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de lecture audio: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<ShortcutActivator, Intent> shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): VoidCallbackIntent(_navigateToAddCard),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ): VoidCallbackIntent(() => exit(0)),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): VoidCallbackIntent(_loadCards),
    };

    final categories = _cards.map((c) => c.category ?? '').where((c) => c.isNotEmpty).toSet().toList();

    List<Flashcard> filteredCards = _cards.where((card) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = card.front.toLowerCase().contains(query) ||
          card.back.toLowerCase().contains(query);
      final matchesFilter = _filter == 'all'
          || (_filter == 'known' && card.isKnown)
          || (_filter == 'unknown' && !card.isKnown);
      final matchesCategory = _selectedCategory == null || _selectedCategory == '' || card.category == _selectedCategory;
      return matchesSearch && matchesFilter && matchesCategory;
    }).toList();

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (VoidCallbackIntent intent) => intent.callback(),
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Flashcards'),
              actions: [
                IconButton(
                  icon: Provider.of<ThemeManager>(context).isDarkMode 
                    ? Icon(Icons.light_mode) 
                    : Icon(Icons.dark_mode),
                  tooltip: 'Changer de thème',
                  onPressed: () {
                    Provider.of<ThemeManager>(context, listen: false).toggleTheme();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.bar_chart),
                  tooltip: 'Statistiques',
                  onPressed: () {
                    _pushFade(StatisticsView());
                  },
                ),
                IconButton(
                  icon: Icon(Icons.quiz),
                  tooltip: 'Mode Quiz',
                  onPressed: () {
                    _pushFade(QuizView());
                  },
                ),
                IconButton(
                  icon: Icon(Icons.file_upload),
                  tooltip: 'Exporter (CSV)',
                  onPressed: _exportCards,
                ),
                IconButton(
                  icon: Icon(Icons.file_download),
                  tooltip: 'Importer (CSV)',
                  onPressed: _importCards,
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  tooltip: 'Personnaliser',
                  onPressed: _showCustomizationDialog,
                ),
                IconButton(
                  icon: Icon(Icons.accessibility),
                  tooltip: 'Accessibilité',
                  onPressed: _showAccessibilityDialog,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  tooltip: 'Quitter',
                  onPressed: () {
                    exit(0);
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                DesktopMenu(
                  refreshCards: _loadCards,
                  addNewCard: _navigateToAddCard,
                  toggleFullScreen: () async {
                    bool isCurrentlyFullScreen = await windowManager.isFullScreen();
                    await windowManager.setFullScreen(!isCurrentlyFullScreen);
                    setState(() {
                      _isFullScreen = !isCurrentlyFullScreen;
                    });
                  },
                  printCards: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Fonctionnalité d\'impression non implémentée.'))
                     );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher une carte...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                            contentPadding: EdgeInsets.all(8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      ToggleButtons(
                        isSelected: [
                          _filter == 'all',
                          _filter == 'known',
                          _filter == 'unknown',
                        ],
                        onPressed: (index) {
                          setState(() {
                            if (index == 0) _filter = 'all';
                            if (index == 1) _filter = 'known';
                            if (index == 2) _filter = 'unknown';
                          });
                        },
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Toutes'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Connues'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('À apprendre'),
                          ),
                        ],
                      ),
                      SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedCategory ?? '',
                        hint: Text('Catégorie'),
                        items: [
                          DropdownMenuItem(value: '', child: Text('Toutes catégories')),
                          ...categories.map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(cat, overflow: TextOverflow.ellipsis),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                      tooltip: 'Supprimer la catégorie (les cartes ne seront plus catégorisées)',
                                      onPressed: () async {
                                         Navigator.of(context).pop();
                                         await _deleteCategory(cat);
                                      },
                                      splashRadius: 18,
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value == '' ? null : value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 600,
                      child: filteredCards.isEmpty
                          ? Center(child: Text('Aucune carte ne correspond aux critères.'))
                          : ListView.builder(
                              itemCount: filteredCards.length,
                              itemBuilder: (context, index) {
                                final card = filteredCards[index];
                                return ListTile(
                                  title: Text(card.front),
                                  subtitle: Text(card.back),
                                  leading: card.audioPath != null ? IconButton(
                                    icon: Icon(Icons.volume_up),
                                    tooltip: 'Écouter',
                                    onPressed: () => _playCardAudio(card.audioPath),
                                  ) : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        tooltip: 'Modifier',
                                        onPressed: () async {
                                          await _pushFade(EditCardView(card: card));
                                          await _loadCards();
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        tooltip: 'Supprimer',
                                        onPressed: () async {
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
                                              await _databaseHelper.deleteCard(cardId);
                                              await _loadCards();
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
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _AnimatedBounceButton(
                    onTap: _navigateToAddCard,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('Ajouter une carte (Ctrl+N)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget pour effet rebond sur bouton
class _AnimatedBounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _AnimatedBounceButton({required this.child, required this.onTap});
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
          child: ElevatedButton(
            onPressed: widget.onTap,
            child: widget.child,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}