import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tv_focusable.dart';

class CategoryList extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onSelectCategory;
  final Function(String) getChannelCount;

  const CategoryList({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.getChannelCount,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.grid_view_rounded;
      case 'Favorites':
        return Icons.star_rounded;
      case 'Recently Watched':
        return Icons.history_rounded;
      case 'News':
        return Icons.newspaper_rounded;
      case 'Sports':
        return Icons.sports_soccer_rounded;
      case 'Movies':
        return Icons.movie_rounded;
      case 'Entertainment':
        return Icons.tv_rounded;
      case 'Kids':
        return Icons.child_care_rounded;
      case 'Music':
        return Icons.music_note_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category == selectedCategory;
        final count = getChannelCount(category);

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: TvFocusable(
            onPressed: () => onSelectCategory(category),
            normalBackgroundColor: isSelected
                ? AppTheme.primaryAccent.withValues(alpha: 0.12)
                : Colors.transparent,
            focusedBackgroundColor: colors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 20,
                  color: isSelected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.14)
                        : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? colors.primary : colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
