import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:projet/features/flashcards/models/flashcard.dart';
import 'package:projet/services/database_helper.dart'; // Correction de l'import
import 'package:projet/core/accessibility/accessibility_manager.dart';
import 'package:projet/core/theme/theme_manager.dart';
import '../utils/logger.dart';
import '../shared/widgets/animated_gradient_background.dart';
import '../features/quiz/widgets/quiz_card_view.dart';
import '../features/quiz/widgets/quiz_result_view.dart';
import '../features/quiz/widgets/quiz_state_view.dart';
import '../features/quiz/helpers/quiz_audio_helper.dart';
import '../features/quiz/helpers/quiz_loader_helper.dart';
import '../features/quiz/helpers/quiz_shortcuts_helper.dart';

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
    QuizLoaderHelper.loadCards(context, widget.category, setState, _logger, _setCardsState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_quizFocusNode);
    });
  }

  void _setCardsState(List<Flashcard> cards) {
    setState(() {
      _cards = cards;
      _current = 0;
      _score = 0;
      _showAnswer = false;
      _finished = false;
      _isLoading = false;
      _timeSpentPerCard.clear();
      _startTimerForCurrentCard();
    });
    if (_cards.isNotEmpty) {
      QuizAudioHelper.preloadAudioIfAvailable(_cards[0], _audioPlayer, _logger);
    }
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
          QuizAudioHelper.preloadAudioIfAvailable(_cards[_current], _audioPlayer, _logger);
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
      await db.updateCard(card.copyWith(isKnown: isKnown));
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
    await QuizAudioHelper.playAudio(_cards, _current, _audioPlayer, context, _logger, _quizFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final fontSize = themeManager.fontSize;
    final accentColor = themeManager.accentColor;
    final accessibility = Provider.of<AccessibilityManager>(context);

    Color goodColor = accessibility.daltonianModeEnabled ? Colors.blue : Colors.green;
    Color badColor = accessibility.daltonianModeEnabled ? Colors.orange : Colors.red;

    final Map<ShortcutActivator, Intent> shortcuts = QuizShortcutsHelper.getShortcuts(
      _revealAnswer, _playAudio, () => _answer(true), () => _answer(false), () => Navigator.pop(context)
    );

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          QuizVoidCallbackIntent: CallbackAction<QuizVoidCallbackIntent>(
            onInvoke: (QuizVoidCallbackIntent intent) => intent.callback(),
          ),
        },
        child: Focus(
          focusNode: _quizFocusNode,
          autofocus: true,
          child: Stack(
            children: [
              const AnimatedGradientBackground(),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(widget.category != null
                      ? 'Quiz - ${widget.category}'
                      : 'Quiz', style: TextStyle(fontFamily: 'Orbitron')),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      tooltip: 'Recommencer',
                      onPressed: () => QuizLoaderHelper.loadCards(context, widget.category, setState, _logger, _setCardsState),
                    ),
                  ],
                ),
                body: _buildBody(fontSize, accentColor, goodColor, badColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double fontSize, Color accentColor, Color goodColor, Color badColor) {
    // Show loading or error state
    if (_isLoading || _errorMessage != null || _cards.isEmpty) {
      return QuizStateView(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        finished: _finished,
        cards: _cards,
        current: _current,
        score: _score,
        showAnswer: _showAnswer,
        fontSize: fontSize,
        accentColor: accentColor,
        category: widget.category,
        onRetry: () => QuizLoaderHelper.loadCards(context, widget.category, setState, _logger, _setCardsState),
        onBack: () => Navigator.pop(context),
        onRestart: () => QuizLoaderHelper.loadCards(context, widget.category, setState, _logger, _setCardsState),
        onExit: () => Navigator.pop(context),
        onRevealAnswer: _revealAnswer,
        onPlayAudio: _playAudio,
        onAnswer: _answer,
      );
    }

    // Show quiz results
    if (_finished) {
      return QuizResultView(
        score: _score,
        total: _cards.length,
        accentColor: accentColor,
        fontSize: fontSize,
        onRestart: () => QuizLoaderHelper.loadCards(context, widget.category, setState, _logger, _setCardsState),
        onExit: () => Navigator.pop(context),
      );
    }

    // Show current card
    final card = _cards[_current];
    return QuizCardView(
      card: card,
      showAnswer: _showAnswer,
      progress: (_current + 1) / _cards.length,
      score: _score,
      total: _cards.length,
      fontSize: fontSize,
      accentColor: accentColor,
      onRevealAnswer: _revealAnswer,
      onPlayAudio: _playAudio,
      onAnswer: _answer,
    );
  }
}

class QuizVoidCallbackIntent extends Intent {
  final VoidCallback callback;
  const QuizVoidCallbackIntent(this.callback);
}
