import 'package:flutter/material.dart';

class SyncStatGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const SyncStatGrid({required this.stats, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final Map<String, String> displayStats = {
      'Ajoutées': '${stats['added']}',
      'Mises à jour': '${stats['updated']}',
      'Supprimées localement': '${stats['deletedLocally']}',
      'Supprimées à distance': '${stats['deletedRemote']}',
      'Conflits (version locale gardée)': '${stats['conflictsLocalWins']}',
      'Ignorées (inchangées)': '${stats['skippedUnchanged']}',
      'Erreurs': '${stats['errors']}',
    };
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
      ),
      itemCount: displayStats.length,
      itemBuilder: (context, index) {
        final entry = displayStats.entries.elementAt(index);
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key),
              Text(
                entry.value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: entry.key.contains('Erreurs') && entry.value != '0'
                      ? Colors.red
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
