import 'package:flutter/material.dart';

class PodcastCategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const PodcastCategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          ChoiceChip(
            label: const Text('Toutes'),
            selected: selectedCategory == null,
            onSelected: (_) {
              onSelected(null);
            },
          ),

          const SizedBox(width: 8),

          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: selectedCategory == category,
                onSelected: (_) {
                  onSelected(category);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

