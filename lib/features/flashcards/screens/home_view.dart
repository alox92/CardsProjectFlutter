import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:just_audio/just_audio.dart';
import 'package:window_manager/window_manager.dart';

import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/core/theme/theme_manager.dart';
import 'package:projet/core/accessibility/accessibility_manager.dart';
import '../../../shared/widgets/desktop_menu.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/neon_button.dart';
import '../../../shared/widgets/search_filter_bar.dart';
import '../../../shared/widgets/accessibility_dialog.dart';
import '../../../shared/widgets/customization_dialog.dart';
import 'add_card_view.dart';

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
    // Placeholder for loading cards logic
    if (mounted) {
      setState(() {
        _cards = []; // Replace with actual card loading logic
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
          // Replace with actual update logic
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
              const AnimatedGradientBackground(),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text('Flashcards'),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () => CustomizationDialog.show(
                        context: context,
                        themeManager: themeManager,
                        isFullScreen: _isFullScreen,
                        onFullScreenChanged: (value) => setState(() => _isFullScreen = value),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.accessibility),
                      onPressed: () => AccessibilityDialog.show(
                        context: context,
                        accessibilityManager: Provider.of<AccessibilityManager>(context),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.exit_to_app),
                      onPressed: () => exit(0),
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
                                  color: themeManager.accentColor.withAlpha((0.12 * 255).toInt()),
                                  width: 1.5,
                                ),
                              ),
                              child: ListView.builder(
                                itemCount: filteredCards.length,
                                itemBuilder: (context, index) {
                                  final card = filteredCards[index];
                                  return ListTile(
                                    title: Text(card.front),
                                    subtitle: Text(card.back),
                                    onTap: () => _playCardAudio(card.audioPath),
                                  );
                                },
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