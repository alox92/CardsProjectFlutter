import 'package:flutter/material.dart';

/// Barre de recherche et filtres pour les flashcards
class SearchFilterBar extends StatelessWidget {
  final String searchQuery;
  final String filter;
  final String? selectedCategory;
  final List<String> categories;
  final Function(String) onSearchChanged;
  final Function(String) onFilterChanged;
  final Function(String?) onCategoryChanged;
  final Function(String) onDeleteCategory;
  
  const SearchFilterBar({
    Key? key,
    required this.searchQuery,
    required this.filter,
    required this.selectedCategory,
    required this.categories,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onCategoryChanged,
    required this.onDeleteCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une carte...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: EdgeInsets.all(8),
              ),
              onChanged: onSearchChanged,
              controller: TextEditingController(text: searchQuery),
            ),
          ),
          SizedBox(width: 16),
          ToggleButtons(
            isSelected: [
              filter == 'all',
              filter == 'known',
              filter == 'unknown',
            ],
            onPressed: (index) {
              if (index == 0) onFilterChanged('all');
              if (index == 1) onFilterChanged('known');
              if (index == 2) onFilterChanged('unknown');
            },
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Toutes'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Connues'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('À apprendre'),
              ),
            ],
          ),
          SizedBox(width: 16),
          _buildCategoryDropdown(context),
        ],
      ),
    );
  }
  
  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButton<String>(
      value: selectedCategory ?? '',
      hint: Text('Catégorie'),
      items: [
        DropdownMenuItem(value: '', child: Text('Toutes catégories')),
        ...categories.map((cat) => DropdownMenuItem(
              value: cat,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(cat, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Supprimer la catégorie (les cartes ne seront plus catégorisées)',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDeleteCategory(cat);
                    },
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            )),
      ],
      onChanged: onCategoryChanged,
    );
  }
}