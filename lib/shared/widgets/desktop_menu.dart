import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, exit; // Ajout de exit ici
import 'package:provider/provider.dart';
import 'package:projet/core/theme/theme_manager.dart';
import '../../views/statistics_view.dart'; // Chemin corrigé

class DesktopMenu extends StatelessWidget {
  final VoidCallback refreshCards;
  final VoidCallback addNewCard;
  final VoidCallback toggleFullScreen; // Ajout pour plein écran
  final VoidCallback printCards; // Ajout pour impression

  const DesktopMenu({
    Key? key,
    required this.refreshCards,
    required this.addNewCard,
    required this.toggleFullScreen, // Requis
    required this.printCards, // Requis
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Vérifier si on est sur desktop (pas Web)
    bool isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

    // Si ce n'est pas desktop, ne pas afficher le menu
    if (!isDesktop) return SizedBox.shrink();

    return Container(
      height: 30,
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Row(
        children: [
          _buildMenuDropdown(
            context,
            'Fichier',
            [
              PopupMenuItem(
                child: _menuItem(Icons.add, 'Nouvelle carte (Ctrl+N)'),
                onTap: addNewCard,
              ),
              PopupMenuItem(
                child: _menuItem(Icons.refresh, 'Actualiser (Ctrl+R)'),
                onTap: refreshCards,
              ),
              PopupMenuItem(
                child: _menuItem(Icons.import_export, 'Importer / Exporter'),
                onTap: () {
                  // Remplacé par une alerte temporaire puisque ImportExportView n'existe pas
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fonctionnalité d\'import/export non implémentée. Utilisez les boutons dans la barre d\'outils.'))
                  );
                },
              ),
              PopupMenuItem(
                child: _menuItem(Icons.print, 'Imprimer les cartes'),
                onTap: printCards,
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                child: _menuItem(Icons.exit_to_app, 'Quitter (Ctrl+Q)'),
                onTap: () => exit(0),
              ),
            ],
          ),
          _buildMenuDropdown(
            context,
            'Affichage',
            [
              PopupMenuItem(
                child: _menuItem(
                  Provider.of<ThemeManager>(context).isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  'Changer de thème',
                ),
                onTap: () {
                  Provider.of<ThemeManager>(context, listen: false).toggleTheme();
                },
              ),
              PopupMenuItem(
                child: _menuItem(Icons.bar_chart, 'Statistiques'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StatisticsView()),
                  );
                },
              ),
              PopupMenuItem(
                child: _menuItem(Icons.fullscreen, 'Plein écran'),
                onTap: toggleFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuDropdown(BuildContext context, String title, List<PopupMenuEntry> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: PopupMenuButton(
        tooltip: title,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
        itemBuilder: (context) => items,
      ),
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18),
        SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
