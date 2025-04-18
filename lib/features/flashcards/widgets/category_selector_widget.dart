import 'package:flutter/material.dart';

class CategorySelectorWidget extends StatelessWidget {
  final String? selectedCategory;
  final List<String> categories;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onAddCategory;
  final ValueChanged<String> onRenameCategory;
  final ValueChanged<String> onDeleteCategory;
  final TextEditingController categoryController;

  const CategorySelectorWidget({
    Key? key,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.onAddCategory,
    required this.onRenameCategory,
    required this.onDeleteCategory,
    required this.categoryController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      items: [
        DropdownMenuItem(value: null, child: Text('- Aucune catégorie -')),
        ...categories.map((cat) => DropdownMenuItem(
              value: cat,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(cat, overflow: TextOverflow.ellipsis)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 18),
                        tooltip: 'Renommer la catégorie',
                        onPressed: () => onRenameCategory(cat),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 18, color: Colors.redAccent),
                        tooltip: 'Supprimer la catégorie',
                        onPressed: () => onDeleteCategory(cat),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            )),
        DropdownMenuItem(
          value: '__new__',
          child: Text('Nouvelle catégorie...'),
        ),
      ],
      onChanged: (value) {
        if (value == '__new__') {
          onAddCategory();
        } else {
          onCategoryChanged(value);
        }
      },
      decoration: InputDecoration(
        labelText: 'Catégorie',
      ),
      isExpanded: true,
      style: TextStyle(fontFamily: 'Orbitron'),
    );
  }
}
