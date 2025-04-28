import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:get_it/get_it.dart';

import '../../../services/database_helper.dart';
import '../../../utils/logger.dart';
import '../models/flashcard.dart';

/// ViewModel pour la fonctionnalité de quiz
class QuizViewModel with ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  final Logger _logger;
  
  // État
  final List<String> _selectedTags = [];
  String? _selectedDeck;
  final List<String> _customLabels = ['Important', 'À revoir', 'À approfondir'];
  String? _selectedLabel;
  String _searchQuery = '';
  bool _useRegex = false;
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';
  bool _hovered = false;
  
  // Données
  List<Flashcard> _cards = [];
  List<Flashcard> _filteredCards = [];
  List<String> _decks = [];
  List<String> _tags = [];
  
  // Cache des expressions régulières pour optimisation
  RegExp? _compiledRegex;
  String? _lastRegexPattern;
  
  // Getters
  List<String> get selectedTags => _selectedTags;
  String? get selectedDeck => _selectedDeck;
  List<String> get customLabels => _customLabels;
  String? get selectedLabel => _selectedLabel;
  String get searchQuery => _searchQuery;
  bool get useRegex => _useRegex;
  bool get isLoading => _isLoading;
  bool get isError => _isError;
  String get errorMessage => _errorMessage;
  bool get hovered => _hovered;
  List<Flashcard> get filteredCards => _filteredCards;
  List<Flashcard> get cards => _cards;
  List<String> get decks => _decks;
  List<String> get tags => _tags;
  
  QuizViewModel({
    required DatabaseHelper databaseHelper,
    required Logger logger,
  }) : _databaseHelper = databaseHelper,
       _logger = logger {
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    try {
      _setLoading(true);
      _logger.info('Chargement des données initiales du quiz', tag: 'QuizViewModel');
      
      final loadedDecks = await _databaseHelper.getDecks();
      final loadedTags = await _databaseHelper.getTags();
      
      _decks = loadedDecks;
      _tags = loadedTags;
      
      _setLoading(false);
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors du chargement des données initiales',
        tag: 'QuizViewModel',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Erreur lors du chargement des données: ${e.toString()}');
    }
  }
  
  Future<void> loadCards() async {
    try {
      _setLoading(true);
      _logger.info('Chargement des cartes pour le quiz', tag: 'QuizViewModel');
      
      final allCards = await _databaseHelper.getAllCards();
      _cards = allCards;
      _applyFilters();
      
      _logger.debug('${allCards.length} cartes chargées', tag: 'QuizViewModel');
      _setLoading(false);
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors du chargement des cartes',
        tag: 'QuizViewModel',
        error: e,
        stackTrace: stackTrace,
      );
      _setError('Erreur lors du chargement des cartes: ${e.toString()}');
    }
  }
  
  void setHovered(bool value) {
    if (_hovered != value) {
      _hovered = value;
      notifyListeners();
    }
  }
  
  void setSelectedDeck(String? value) {
    if (_selectedDeck != value) {
      _selectedDeck = value;
      if (_cards.isNotEmpty) {
        _applyFilters();
      }
      notifyListeners();
    }
  }
  
  void setSelectedLabel(String? value) {
    if (_selectedLabel != value) {
      _selectedLabel = value;
      if (_cards.isNotEmpty) {
        _applyFilters();
      }
      notifyListeners();
    }
  }
  
  void toggleTag(String tag, bool selected) {
    if (selected && !_selectedTags.contains(tag)) {
      _selectedTags.add(tag);
    } else if (!selected && _selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      return;
    }
    
    if (_cards.isNotEmpty) {
      _applyFilters();
    }
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _lastRegexPattern = null;
      _compiledRegex = null;
      
      if (_cards.isNotEmpty) {
        _applyFilters();
      }
      notifyListeners();
    }
  }
  
  void toggleUseRegex(bool value) {
    if (_useRegex != value) {
      _useRegex = value;
      _lastRegexPattern = null;
      _compiledRegex = null;
      
      if (_cards.isNotEmpty && _searchQuery.isNotEmpty) {
        _applyFilters();
      }
      notifyListeners();
    }
  }
  
  Future<void> exportAnki(BuildContext context) async {
    try {
      _logger.info('Démarrage de l\'export Anki', tag: 'QuizViewModel');
      final file = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter pour Anki',
        fileName: 'anki_export.txt',
      );
      
      if (file != null) {
        final buffer = StringBuffer();
        for (final card in _cards) {
          buffer.writeln('${card.front ?? ''}\t${card.back ?? ''}\t${card.deck ?? ''}\t${card.tags?.join(', ') ?? ''}');
        }
        
        await File(file).writeAsString(buffer.toString());
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export Anki terminé.')),
          );
        }
        
        _logger.info('Export Anki terminé: $file', tag: 'QuizViewModel');
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Erreur lors de l\'export Anki',
        tag: 'QuizViewModel',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _applyFilters() {
    _filteredCards = _cards.where((card) {
      // Filtre par deck
      final matchesDeck = _selectedDeck == null || card.deck == _selectedDeck;
      if (!matchesDeck) return false;
      
      // Filtre par tags
      final matchesTags = _selectedTags.isEmpty || 
                          _selectedTags.every((tag) => card.tags?.contains(tag) ?? false);
      if (!matchesTags) return false;
      
      // Filtre par label
      final matchesLabel = _selectedLabel == null || 
                           (card.labels?.contains(_selectedLabel) ?? false);
      if (!matchesLabel) return false;
      
      // Filtre par recherche/regex
      if (_searchQuery.isEmpty) return true;
      
      if (_useRegex) {
        try {
          // Mise en cache des expressions régulières pour performance
          if (_lastRegexPattern != _searchQuery) {
            _compiledRegex = RegExp(_searchQuery, caseSensitive: false);
            _lastRegexPattern = _searchQuery;
          }
          
          return _compiledRegex!.hasMatch(card.front ?? '') ||
                 _compiledRegex!.hasMatch(card.back ?? '');
        } catch (e) {
          _logger.warning(
            'Expression régulière invalide: $_searchQuery',
            tag: 'QuizViewModel',
            error: e,
          );
          return false;
        }
      } else {
        final query = _searchQuery.toLowerCase();
        // Utilisation correcte sans opérateurs null-aware inutiles
        final front = card.question.toLowerCase();
        final back = card.answer.toLowerCase();
        return front.contains(query) || back.contains(query);
      }
    }).toList();
    
    notifyListeners();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _isError = false;
      _errorMessage = '';
    }
    notifyListeners();
  }
  
  void _setError(String message) {
    _isLoading = false;
    _isError = true;
    _errorMessage = message;
    notifyListeners();
  }
  
  void clearFilters() {
    _selectedDeck = null;
    _selectedLabel = null;
    _selectedTags.clear();
    _searchQuery = '';
    _useRegex = false;
    
    if (_cards.isNotEmpty) {
      _applyFilters();
    }
    
    notifyListeners();
  }
}

class QuizView extends StatefulWidget {
  const QuizView({super.key});

  @override
  _QuizViewState createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  String? _selectedDeck;
  String? _selectedLabel;
  late QuizViewModel _quizService;
  
  // Méthodes publiques
  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    try {
      _quizService = QuizViewModel(
        databaseHelper: GetIt.instance<DatabaseHelper>(),
        logger: GetIt.instance<Logger>(),
      );
      await _quizService.loadCards();
    } catch (e, stackTrace) {
      // Gérer les erreurs ici
      Logger().error(
        'Erreur lors de l\'initialisation du quiz',
        tag: 'QuizView',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizViewModel(
        databaseHelper: GetIt.instance<DatabaseHelper>(),
        logger: GetIt.instance<Logger>(),
      ),
      child: QuizViewContent(
        selectedDeck: _selectedDeck,
        selectedLabel: _selectedLabel,
        onDeckChanged: (value) {
          setState(() {
            _selectedDeck = value;
          });
        },
        onLabelChanged: (value) {
          setState(() {
            _selectedLabel = value;
          });
        },
      ),
    );
  }
}

class QuizViewContent extends StatelessWidget {
  final String? selectedDeck;
  final String? selectedLabel;
  final ValueChanged<String?> onDeckChanged;
  final ValueChanged<String?> onLabelChanged;
  
  const QuizViewContent({
    super.key,
    required this.selectedDeck,
    required this.selectedLabel,
    required this.onDeckChanged,
    required this.onLabelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<QuizViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: 'Exporter Anki',
            onPressed: () => viewModel.exportAnki(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterHeader(context),
            _buildSearchBar(context),
            _buildQuizButton(context),
            _buildCardsList(context),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Progrès', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Question',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterHeader(BuildContext context) {
    final viewModel = Provider.of<QuizViewModel>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Sélecteur de decks
          Expanded(
            child: DropdownButton<String?>(
              value: selectedDeck,
              hint: const Text('Sélectionner un deck'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('- Tous -')),
                ...viewModel.decks.map((deck) => DropdownMenuItem<String?>(
                  value: deck,
                  child: Text(deck),
                )),
              ],
              onChanged: onDeckChanged,
            ),
          ),
          const SizedBox(width: 16),
          // Sélection multi-tags
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                ...viewModel.tags.map((tag) => FilterChip(
                  label: Text(tag),
                  selected: viewModel.selectedTags.contains(tag),
                  onSelected: (selected) => viewModel.toggleTag(tag, selected),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final viewModel = Provider.of<QuizViewModel>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: viewModel.setSearchQuery,
              decoration: InputDecoration(
                labelText: viewModel.useRegex ? 'Recherche (regex)' : 'Recherche',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(viewModel.useRegex ? Icons.check_box : Icons.check_box_outline_blank),
                      tooltip: 'Activer la recherche regex',
                      onPressed: () => viewModel.toggleUseRegex(!viewModel.useRegex),
                    ),
                    const Icon(Icons.search),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String?>(
            value: selectedLabel,
            hint: const Text('Label'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('- Tous -')),
              ...viewModel.customLabels.map((label) => DropdownMenuItem<String?>(
                value: label,
                child: Text(label),
              )),
            ],
            onChanged: (value) {
              viewModel.setSelectedLabel(value ?? '');
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuizButton(BuildContext context) {
    final viewModel = Provider.of<QuizViewModel>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: MouseRegion(
        onEnter: (_) => viewModel.setHovered(true),
        onExit: (_) => viewModel.setHovered(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: viewModel.hovered
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          child: ElevatedButton(
            onPressed: viewModel.isLoading ? null : viewModel.loadCards,
            child: viewModel.isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Démarrer le quiz'),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardsList(BuildContext context) {
    final viewModel = Provider.of<QuizViewModel>(context);
    
    if (viewModel.isLoading) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des cartes...'),
            ],
          ),
        ),
      );
    }
    
    if (viewModel.isError) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                viewModel.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: viewModel.loadCards,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (viewModel.cards.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('Aucune carte disponible. Appuyez sur "Démarrer le quiz" pour charger les cartes.'),
        ),
      );
    }
    
    if (viewModel.filteredCards.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.filter_alt, size: 60),
              const SizedBox(height: 16),
              const Text('Aucune carte ne correspond aux filtres sélectionnés.'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: viewModel.clearFilters,
                child: const Text('Effacer les filtres'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: ListView.builder(
          key: ValueKey('${viewModel.filteredCards.length}_${viewModel.selectedDeck ?? ''}_${viewModel.selectedTags.join(',')}'),
          itemCount: viewModel.filteredCards.length,
          itemBuilder: (context, index) {
            final card = viewModel.filteredCards[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(card.front ?? ''),
                subtitle: Text(card.back ?? ''),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    if (card.deck != null)
                      Chip(
                        label: Text(
                          card.deck!,
                          style: const TextStyle(fontSize: 10),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                onTap: () {
                  showDialog<void>(

                    context: context,
                    builder: (BuildContext dialogContext) => AlertDialog(
                      title: Text(card.front ?? ''),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.back ?? ''),
                            const SizedBox(height: 16),
                            if (card.tags != null && card.tags!.isNotEmpty) ...[
                              const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: card.tags!.map((tag) => Chip(
                                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                )).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}