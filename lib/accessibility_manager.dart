import 'package:flutter/material.dart';

class AccessibilityManager with ChangeNotifier {
  bool _voiceOverEnabled = false;
  bool _talkBackEnabled = false;
  bool _daltonianModeEnabled = false;

  bool get voiceOverEnabled => _voiceOverEnabled;
  bool get talkBackEnabled => _talkBackEnabled;
  bool get daltonianModeEnabled => _daltonianModeEnabled;

  void enableVoiceOver() {
    _voiceOverEnabled = true;
    notifyListeners();
  }

  void disableVoiceOver() {
    _voiceOverEnabled = false;
    notifyListeners();
  }

  void enableTalkBack() {
    _talkBackEnabled = true;
    notifyListeners();
  }

  void disableTalkBack() {
    _talkBackEnabled = false;
    notifyListeners();
  }

  void enableDaltonianMode() {
    _daltonianModeEnabled = true;
    notifyListeners();
  }

  void disableDaltonianMode() {
    _daltonianModeEnabled = false;
    notifyListeners();
  }
}