import 'package:flutter/material.dart';
import 'package:smartbudget/components/forms/emoji_category_tile.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<(String emoji, String label)> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories
          .map(
            (item) => EmojiCategoryTile(
              emoji: item.$1,
              label: item.$2,
              selected: selected == item.$2,
              onTap: () => onSelected(item.$2),
            ),
          )
          .toList(),
    );
  }
}
