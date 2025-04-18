import 'package:flutter/material.dart';
import 'package:projet/core/accessibility/accessibility_manager.dart';

/// Dialogue permettant de configurer les options d'accessibilité
class AccessibilityDialog extends StatelessWidget {
  final AccessibilityManager accessibilityManager;

  const AccessibilityDialog({
    Key? key,
    required this.accessibilityManager,
  }) : super(key: key);

  /// Affiche le dialogue d'accessibilité
  static Future<void> show({
    required BuildContext context,
    required AccessibilityManager accessibilityManager,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AccessibilityDialog(
        accessibilityManager: accessibilityManager,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Accessibilité'),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Mode daltonien'),
              value: accessibilityManager.daltonianModeEnabled,
              onChanged: (v) {
                if (v) {
                  accessibilityManager.enableDaltonianMode();
                } else {
                  accessibilityManager.disableDaltonianMode();
                }
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('VoiceOver (macOS)'),
              value: accessibilityManager.voiceOverEnabled,
              onChanged: (v) {
                if (v) {
                  accessibilityManager.enableVoiceOver();
                } else {
                  accessibilityManager.disableVoiceOver();
                }
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('TalkBack (Windows/Android)'),
              value: accessibilityManager.talkBackEnabled,
              onChanged: (v) {
                if (v) {
                  accessibilityManager.enableTalkBack();
                } else {
                  accessibilityManager.disableTalkBack();
                }
                setState(() {});
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Fermer'),
        ),
      ],
    );
  }
}