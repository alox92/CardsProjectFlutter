import 'package:flutter/material.dart';

/// Boîte de dialogue pour la sélection des colonnes CSV
Future<Map<String, int>?> showColumnSelectionDialog(
  BuildContext context, {
  required List<String> headers,
}) async {
  int frontColIndex = -1;
  int backColIndex = -1;
  int categoryColIndex = -1;

  // Tenter de détecter automatiquement les colonnes
  for (int i = 0; i < headers.length; i++) {
    final header = headers[i].toLowerCase();
    if (frontColIndex == -1 &&
        (header.contains('front') || header.contains('question') || header.contains('recto'))) {
      frontColIndex = i;
    }
    if (backColIndex == -1 &&
        (header.contains('back') || header.contains('answer') || header.contains('verso'))) {
      backColIndex = i;
    }
    if (categoryColIndex == -1 &&
        (header.contains('category') || header.contains('catégorie') ||
         header.contains('tag') || header.contains('tags'))) {
      categoryColIndex = i;
    }
  }

  if (frontColIndex == -1 && headers.length > 0) frontColIndex = 0;
  if (backColIndex == -1 && headers.length > 1) backColIndex = 1;
  if (categoryColIndex == -1 && headers.length > 2) categoryColIndex = 2;

  final result = await showDialog<Map<String, int>>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Sélection des colonnes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Veuillez sélectionner les colonnes à importer:'),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Colonne recto (question)'),
                  value: frontColIndex >= 0 ? frontColIndex : null,
                  items: List.generate(
                    headers.length,
                    (i) => DropdownMenuItem(value: i, child: Text('${i+1}: ${headers[i]}')),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => frontColIndex = value);
                    }
                  },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Colonne verso (réponse)'),
                  value: backColIndex >= 0 ? backColIndex : null,
                  items: List.generate(
                    headers.length,
                    (i) => DropdownMenuItem(value: i, child: Text('${i+1}: ${headers[i]}')),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => backColIndex = value);
                    }
                  },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Colonne catégorie (optionnel)'),
                  value: categoryColIndex >= 0 ? categoryColIndex : null,
                  items: [
                    DropdownMenuItem(value: -1, child: Text('Aucune')),
                    ...List.generate(
                      headers.length,
                      (i) => DropdownMenuItem(value: i, child: Text('${i+1}: ${headers[i]}')),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => categoryColIndex = value ?? -1);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (frontColIndex >= 0 && backColIndex >= 0) {
                    Navigator.pop(context, {
                      'front': frontColIndex,
                      'back': backColIndex,
                      'category': categoryColIndex >= 0 ? categoryColIndex : null,
                    });
                  }
                },
                child: Text('Importer'),
              ),
            ],
          );
        },
      );
    },
  );
  return result;
}
