import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:io';
import '../models/flashcard.dart';
import '../services/database_helper.dart';
import '../accessibility_manager.dart';
import '../theme_manager.dart';
import '../utils/logger.dart';

class QuizView extends StatefulWidget {
  final String? category;

  const QuizView({Key? key, this.category}) : super(key: key);

  @override
  _QuizViewState createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> with WidgetsBindingObserver {
  List<Flashcard> _cards = [];
  int _current = 0;
  int _score = 0;
  bool _showAnswer = false;
  bool _finished = false;
  bool _isLoading = true;
  String? _errorMessage;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _quizFocusNode = FocusNode();
  final Map<int, int> _timeSpentPerCard = {};
  int? _cardStartTime;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCards();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_quizFocusNode);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioPlayer.pause();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _quizFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = Provider.of<DatabaseHelper>(context, listen: false);
      final List<Flashcard> cardsToLearn;

      if (widget.category != null) {
        cardsToLearn = await db.getCardsByCategory(widget.category!);
      } else {
        cardsToLearn = await db.getUnknownCards();
      }

      cardsToLearn.shuffle();

      setState(() {
        _cards = cardsToLearn;
        _current = 0;
        _score = 0;
        _showAnswer = false;
        _finished = false;
        _isLoading = false;
        _timeSpentPerCard.clear();
        _startTimerForCurrentCard();
      });

      _logger.info('Quiz démarré avec ${cardsToLearn.length} cartes${widget.category != null ? ' dans la catégorie ${widget.category}' : ''}');

      if (_cards.isNotEmpty) {
        _preloadAudioIfAvailable(_cards[0]);
      }
    } catch (e) {
      _logger.error('Erreur lors du chargement des cartes pour le quiz: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des cartes: $e';
      });
    }
  }

  Future<void> _preloadAudioIfAvailable(Flashcard card) async {
    if (card.audioPath != null && card.audioPath!.isNotEmpty) {
      try {
        final file = File(card.audioPath!);
        if (await file.exists()) {
          await _audioPlayer.setFilePath(card.audioPath!);
        } else {
          _logger.warning('Fichier audio non trouvé: ${card.audioPath}');
        }
      } catch (e) {
        _logger.error('Erreur lors du préchargement audio: $e');
      }
    }
  }

  void _startTimerForCurrentCard() {
    _cardStartTime = DateTime.now().millisecondsSinceEpoch;
  }

  void _recordTimeForCurrentCard() {
    if (_cardStartTime != null && _cards.isNotEmpty && _current < _cards.length) {
      final cardId = _cards[_current].id;
      if (cardId != null) {
        final endTime = DateTime.now().millisecondsSinceEpoch;
        final duration = endTime - _cardStartTime!;
        _timeSpentPerCard[cardId] = (_timeSpentPerCard[cardId] ?? 0) + duration;
      }
    }
  }

  void _answer(bool correct) {
    _recordTimeForCurrentCard();
    final currentCard = _cards[_current];

    setState(() {
      if (correct) {
        _score++;
        _updateCardStatus(currentCard, true);
      }

      if (_current < _cards.length - 1) {
        _current++;
        _showAnswer = false;
        _startTimerForCurrentCard();
        if (_current < _cards.length - 1) {
          _preloadAudioIfAvailable(_cards[_current]);
        }
      } else {
        _finished = true;
        _saveQuizStats();
      }
    });

    FocusScope.of(context).requestFocus(_quizFocusNode);
  }

  Future<void> _updateCardStatus(Flashcard card, bool isKnown) async {
    try {
      final db = Provider.of<DatabaseHelper>(context, listen: false);
      final updatedCard = card.copyWith(isKnown: isKnown);
      await db.updateCard(updatedCard);
    } catch (e) {
      _logger.error('Erreur lors de la mise à jour du statut de la carte: $e');
    }
  }

  Future<void> _saveQuizStats() async {
    try {
      _logger.info('Quiz terminé: $_score/${_cards.length} bonnes réponses, ${_timeSpentPerCard.length} cartes étudiées');
    } catch (e) {
      _logger.error('Erreur lors de l\'enregistrement des statistiques du quiz: $e');
    }
  }

  void _revealAnswer() {
    setState(() {
      _showAnswer = true;
    });
    FocusScope.of(context).requestFocus(_quizFocusNode);
  }

  Future<void> _playAudio() async {
    if (_cards.isEmpty || _current >= _cards.length) return;

    final card = _cards[_current];
    if (card.audioPath == null || card.audioPath!.isEmpty) {
      return;
    }

    try {
      final file = File(card.audioPath!);
      if (await file.exists()) {
        await _audioPlayer.setFilePath(card.audioPath!);
        await _audioPlayer.play();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fichier audio introuvable')),
        );
        _logger.warning('Fichier audio non trouvé: ${card.audioPath}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la lecture audio')),
      );
      _logger.error('Erreur lors de la lecture audio: $e');
    }

    FocusScope.of(context).requestFocus(_quizFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final fontSize = themeManager.fontSize;
    final accentColor = themeManager.accentColor;
    final accessibility = Provider.of<AccessibilityManager>(context);

    Color goodColor = accessibility.daltonianModeEnabled ? Colors.blue : Colors.green;
    Color badColor = accessibility.daltonianModeEnabled ? Colors.orange : Colors.red;

    final Map<ShortcutActivator, Intent> shortcuts = {
      const SingleActivator(LogicalKeyboardKey.space): VoidCallbackIntent(_revealAnswer),
      const SingleActivator(LogicalKeyboardKey.keyA): VoidCallbackIntent(_playAudio),
      const SingleActivator(LogicalKeyboardKey.arrowRight): VoidCallbackIntent(() => _answer(true)),
      const SingleActivator(LogicalKeyboardKey.keyG): VoidCallbackIntent(() => _answer(true)),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): VoidCallbackIntent(() => _answer(false)),
      const SingleActivator(LogicalKeyboardKey.keyB): VoidCallbackIntent(() => _answer(false)),
      const SingleActivator(LogicalKeyboardKey.escape): VoidCallbackIntent(() => Navigator.pop(context)),
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
          focusNode: _quizFocusNode,
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.category != null
                  ? 'Quiz - ${widget.category}'
                  : 'Quiz'),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: 'Recommencer',
                  onPressed: () => _loadCards(),
                ),
              ],
            ),
            body: _buildBody(fontSize, accentColor, goodColor, badColor),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double fontSize, Color accentColor, Color goodColor, Color badColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: accentColor),
            SizedBox(height: 16),
            Text('Chargement des cartes...', style: TextStyle(fontSize: fontSize)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Erreur', style: TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(fontSize: fontSize)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadCards(),
              child: Text('Réessayer', style: TextStyle(fontSize: fontSize)),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            ),
          ],
        ),
      );
    }

    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text('Aucune carte à réviser${widget.category != null ? ' dans ${widget.category}' : ''}.',
                style: TextStyle(fontSize: fontSize + 2)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Retour', style: TextStyle(fontSize: fontSize)),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            ),
          ],
        ),
      );
    }

    if (_finished) {
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Quiz terminé !', style: TextStyle(fontSize: fontSize + 8, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text(
                    'Score : $_score / ${_cards.length}',
                    style: TextStyle(fontSize: fontSize + 12, color: accentColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '${(_score / _cards.length * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: fontSize + 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Recommencer', style: TextStyle(fontSize: fontSize)),
                    style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                    onPressed: _loadCards,
                  ),
                  SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Retour à l\'accueil', style: TextStyle(fontSize: fontSize)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final card = _cards[_current];
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: (_current + 1) / _cards.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
                SizedBox(height: 12),
                Text(
                  'Carte ${_current + 1}/${_cards.length}',
                  style: TextStyle(fontSize: fontSize - 2, color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                Text(
                  card.front,
                  style: TextStyle(fontSize: fontSize + 8, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                if (card.audioPath != null && card.audioPath!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.volume_up),
                      label: Text('Écouter (A)', style: TextStyle(fontSize: fontSize - 2)),
                      onPressed: _playAudio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                Divider(height: 36),
                if (_showAnswer)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(26), // Remplacement de withOpacity(0.1) par withAlpha(26) (environ 10% d'opacité)
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor, width: 1),
                    ),
                    child: Text(
                      card.back,
                      style: TextStyle(fontSize: fontSize + 4, color: accentColor),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _revealAnswer,
                    child: Text('Voir la réponse (Espace)', style: TextStyle(fontSize: fontSize)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                SizedBox(height: 24),
                if (_showAnswer)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.check, color: Colors.white),
                          label: Text('Je savais (→ ou G)', style: TextStyle(fontSize: fontSize - 1)),
                          style: ElevatedButton.styleFrom(backgroundColor: goodColor),
                          onPressed: () => _answer(true),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.close, color: Colors.white),
                          label: Text('À revoir (← ou B)', style: TextStyle(fontSize: fontSize - 1)),
                          style: ElevatedButton.styleFrom(backgroundColor: badColor),
                          onPressed: () => _answer(false),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 16),
                Text(
                  'Score actuel : $_score / $_current',
                  style: TextStyle(fontSize: fontSize - 2, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VoidCallbackIntent extends Intent {
  final VoidCallback callback;
  const VoidCallbackIntent(this.callback);
}
