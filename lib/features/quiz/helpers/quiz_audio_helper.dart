import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../utils/logger.dart';
import '../../flashcards/models/flashcard.dart';

class QuizAudioHelper {
  static Future<void> preloadAudioIfAvailable(Flashcard card, AudioPlayer audioPlayer, Logger logger) async {
    if (card.audioPath == null || card.audioPath!.isEmpty) return;
    try {
      final file = File(card.audioPath!);
      if (await file.exists()) {
        await audioPlayer.setFilePath(card.audioPath!);
        logger.debug('Audio préchargé avec succès: [${card.audioPath}');
      } else {
        logger.warning('Préchargement impossible, fichier audio non trouvé: ${card.audioPath}');
      }
    } catch (e) {
      logger.error('Erreur lors du préchargement audio: $e');
    }
  }

  static Future<void> playAudio(List<Flashcard> cards, int current, AudioPlayer audioPlayer, BuildContext context, Logger logger, FocusNode focusNode) async {
    if (cards.isEmpty || current >= cards.length) return;
    final card = cards[current];
    if (card.audioPath == null || card.audioPath!.isEmpty) {
      return;
    }
    try {
      final file = File(card.audioPath!);
      if (await file.exists()) {
        await audioPlayer.stop();
        try {
          await audioPlayer.setFilePath(card.audioPath!).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw TimeoutException('Chargement audio trop long');
            },
          );
          await audioPlayer.play();
        } on Exception catch (audioError) {
          logger.error('Erreur spécifique à la lecture audio: $audioError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Problème de lecture audio: format non supporté ou fichier corrompu')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fichier audio introuvable')),
        );
        logger.warning('Fichier audio non trouvé: ${card.audioPath}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la lecture audio')),
      );
      logger.error('Erreur lors de la lecture audio: $e');
    }
    FocusScope.of(context).requestFocus(focusNode);
  }
}
