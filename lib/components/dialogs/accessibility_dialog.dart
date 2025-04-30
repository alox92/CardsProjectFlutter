import 'package:flutter/material.dart';
import 'package:projet/core/accessibility/accessibility_manager.dart';
import 'package:provider/provider.dart';

class AccessibilityDialog extends StatelessWidget {
  const AccessibilityDialog({Key? key}) : super(key: key);

  static Future<void> show({required BuildContext context}) {
    return showDialog(
      context: context,
      builder: (context) => AccessibilityDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityManager = Provider.of<AccessibilityManager>(context);

    return AlertDialog(
      title: Text('Accessibilité'),
      content: StatefulBuilder(
        builder:
            (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text('Mode daltonien'),
                  value: accessibilityManager.daltonianModeEnabled,
                  onChanged: (enabled) {
                    if (enabled) {
                      accessibilityManager.enableDaltonianMode();
                    } else {
                      accessibilityManager.disableDaltonianMode();
                    }
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
