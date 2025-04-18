import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../../views/quiz_view.dart' show QuizVoidCallbackIntent;

class QuizShortcutsHelper {
  static Map<ShortcutActivator, Intent> getShortcuts(
    VoidCallback revealAnswer,
    Future<void> Function() playAudio,
    VoidCallback answerGood,
    VoidCallback answerBad,
    VoidCallback exitQuiz,
  ) {
    return {
      const SingleActivator(LogicalKeyboardKey.space): QuizVoidCallbackIntent(revealAnswer),
      const SingleActivator(LogicalKeyboardKey.keyA): QuizVoidCallbackIntent(() => playAudio()),
      const SingleActivator(LogicalKeyboardKey.arrowRight): QuizVoidCallbackIntent(answerGood),
      const SingleActivator(LogicalKeyboardKey.keyG): QuizVoidCallbackIntent(answerGood),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): QuizVoidCallbackIntent(answerBad),
      const SingleActivator(LogicalKeyboardKey.keyB): QuizVoidCallbackIntent(answerBad),
      const SingleActivator(LogicalKeyboardKey.escape): QuizVoidCallbackIntent(exitQuiz),
    };
  }
}
