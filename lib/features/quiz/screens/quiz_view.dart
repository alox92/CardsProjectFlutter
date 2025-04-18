import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:io';

import 'package:projet/features/flashcards/models/flashcard.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../shared/utils/logger.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import 'package:projet/features/quiz/widgets/quiz_state_view.dart';

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
      final List<Flashcard> cardsToLearn;

      if (widget.category != null) {
        // TODO: Remplacer par une solution temporaire ou mock
        cardsToLearn = []; // Mock temporaire
      } else {
        // TODO: Remplacer par une solution temporaire ou mock
        cardsToLearn = []; // Mock temporaire
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
    if (card.audioPath == null || card.audioPath!.isEmpty) return;
    
    try {
      final file = File(card.audioPath!);
      if (await file.exists()) {
        await _audioPlayer.setFilePath(card.audioPath!);
        _logger.debug('Audio préchargé avec succès: ${card.audioPath}');
      } else {
        _logger.warning('Préchargement impossible, fichier audio non trouvé: ${card.audioPath}');
      }
    } catch (e) {
      _logger.error('Erreur lors du préchargement audio: $e');
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
      // TODO: Remplacer par une solution temporaire ou mock
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
        await _audioPlayer.stop();
        
        try {
          await _audioPlayer.setFilePath(card.audioPath!).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw TimeoutException('Chargement audio trop long');
            },
          );
          await _audioPlayer.play();
        } on Exception catch (audioError) {
          _logger.error('Erreur spécifique à la lecture audio: $audioError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Problème de lecture audio: format non supporté ou fichier corrompu')),
          );
        }
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
    return Stack(
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
                onPressed: () => _loadCards(),
              ),
            ],
          ),
          body: QuizStateView(
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            finished: _finished,
            cards: _cards,
            current: _current,
            score: _score,
            showAnswer: _showAnswer,
            fontSize: fontSize,
            accentColor: accentColor,
            onRetry: _loadCards,
            onBack: () => Navigator.pop(context),
            onRestart: _loadCards,
            onExit: () => Navigator.pop(context),
            onRevealAnswer: _revealAnswer,
            onPlayAudio: _playAudio,
            onAnswer: _answer,
          ),
        ),
      ],
    );
  }
}

class VoidCallbackIntent extends Intent {
  final VoidCallback callback;
  const VoidCallbackIntent(this.callback);
}
