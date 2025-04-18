import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:window_manager/window_manager.dart';

import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/services/database_helper.dart'; // Correction de l'import
import 'package:projet/core/theme/theme_manager.dart';
import 'package:projet/core/accessibility/accessibility_manager.dart';

import '../shared/widgets/desktop_menu.dart';
import '../shared/widgets/animated_gradient_background.dart';
import '../shared/widgets/neon_button.dart';
import '../shared/widgets/flashcard_list.dart';
import '../shared/widgets/search_filter_bar.dart';
import '../shared/widgets/accessibility_dialog.dart';
import '../shared/widgets/customization_dialog.dart';
import 'add_card_view.dart';
import 'statistics_view.dart';
import 'quiz_view.dart';

// Intent personnalisé pour les raccourcis clavier
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
  String? _selectedCategory;
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isFullScreen = false;

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
    _audioPlayer.dispose();
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
    final csv = await db.exportCardsToFile(); // Correction du nom de la méthode
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
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final accessibility = Provider.of<AccessibilityManager>(context, listen: false);
    
    final Map<ShortcutActivator, Intent> shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): VoidCallbackIntent(_navigateToAddCard),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ): VoidCallbackIntent(() => exit(0)),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): VoidCallbackIntent(_loadCards),
    };

    final categories = _cards
        .map((c) => c.category ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    List<Flashcard> filteredCards = _cards.where((card) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = card.front.toLowerCase().contains(query) ||
          card.back.toLowerCase().contains(query);
      final matchesFilter = _filter == 'all'
          || (_filter == 'known' && card.isKnown)
          || (_filter == 'unknown' && !card.isKnown);
      final matchesCategory = _selectedCategory == null || 
                              _selectedCategory == '' || 
                              card.category == _selectedCategory;
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
          child: Stack(
            children: [
              // Fond animé
              const AnimatedGradientBackground(),
              
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text('Flashcards', style: theme.textTheme.headlineMedium),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
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
                      onPressed: () => CustomizationDialog.show(
                        context: context,
                        themeManager: themeManager,
                        isFullScreen: _isFullScreen,
                        onFullScreenChanged: (value) => setState(() => _isFullScreen = value),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.accessibility),
                      tooltip: 'Accessibilité',
                      onPressed: () => AccessibilityDialog.show(
                        context: context,
                        accessibilityManager: accessibility,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      tooltip: 'Quitter',
                      onPressed: () => exit(0),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    // Menu du bureau
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
                    
                    // Barre de recherche et filtres
                    SearchFilterBar(
                      searchQuery: _searchQuery,
                      filter: _filter,
                      selectedCategory: _selectedCategory,
                      categories: categories,
                      onSearchChanged: (value) => setState(() => _searchQuery = value),
                      onFilterChanged: (value) => setState(() => _filter = value),
                      onCategoryChanged: (value) => setState(() => _selectedCategory = value == '' ? null : value),
                      onDeleteCategory: _deleteCategory,
                    ),
                    
                    // Liste de cartes
                    Expanded(
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(themeManager.cardRadius),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: themeManager.glassBlurSigma,
                              sigmaY: themeManager.glassBlurSigma
                            ),
                            child: Container(
                              width: 600,
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
                              child: FlashcardList(
                                cards: filteredCards,
                                databaseHelper: _databaseHelper,
                                onCardModified: _loadCards,
                                onPlayAudio: _playCardAudio,
                                themeManager: themeManager,
                              ),
                            ),
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
                      NeonButton(
                        onTap: _navigateToAddCard,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Ajouter une carte (Ctrl+N)', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        color: themeManager.accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}