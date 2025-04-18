import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:window_manager/window_manager.dart';
import 'package:projet/core/theme/theme_manager.dart';

/// Dialogue permettant de personnaliser l'interface utilisateur
class CustomizationDialog extends StatefulWidget {
  final ThemeManager themeManager;
  final bool isFullScreen;
  final Function(bool) onFullScreenChanged;

  const CustomizationDialog({
    Key? key,
    required this.themeManager,
    required this.isFullScreen,
    required this.onFullScreenChanged,
  }) : super(key: key);

  /// Affiche le dialogue de personnalisation
  static Future<void> show({
    required BuildContext context,
    required ThemeManager themeManager,
    required bool isFullScreen,
    required Function(bool) onFullScreenChanged,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CustomizationDialog(
        themeManager: themeManager,
        isFullScreen: isFullScreen,
        onFullScreenChanged: onFullScreenChanged,
      ),
    );
  }

  @override
  State<CustomizationDialog> createState() => _CustomizationDialogState();
}

class _CustomizationDialogState extends State<CustomizationDialog> {
  late double fontSize;
  late Color accentColor;
  late bool isFullScreen;

  @override
  void initState() {
    super.initState();
    fontSize = widget.themeManager.fontSize;
    accentColor = widget.themeManager.accentColor;
    isFullScreen = widget.isFullScreen;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Personnaliser l\'interface'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Taille de police : ${fontSize.toStringAsFixed(0)}'),
            Slider(
              min: 12,
              max: 32,
              divisions: 10,
              value: fontSize,
              onChanged: (v) => setState(() => fontSize = v),
              onChangeEnd: (v) => widget.themeManager.setFontSize(v),
            ),
            SizedBox(height: 16),
            Text('Couleur d\'accent'),
            BlockPicker(
              pickerColor: accentColor,
              onColorChanged: (color) {
                setState(() => accentColor = color);
                widget.themeManager.setAccentColor(color);
              },
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Mode plein écran'),
              value: isFullScreen,
              onChanged: (value) async {
                await windowManager.setFullScreen(value);
                setState(() {
                  isFullScreen = value;
                });
                widget.onFullScreenChanged(value);
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