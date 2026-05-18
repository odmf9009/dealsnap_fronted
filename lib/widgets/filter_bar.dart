import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  static const _emojiMap = {
    'electron': '💻', 'tech': '💻', 'computer': '🖥', 'laptop': '💻',
    'phone': '📱', 'tablet': '📱', 'tv': '📺', 'camera': '📷',
    'audio': '🎧', 'headphone': '🎧', 'speaker': '🔊',
    'fashion': '👗', 'cloth': '👕', 'apparel': '👔',
    'shoes': '👟', 'sneaker': '👟',
    'accessories': '👜', 'bag': '👜', 'jewelry': '💎', 'watch': '⌚',
    'home & kitchen': '🍳', 'kitchen': '🍳', 'cooking': '🍳',
    'home': '🏠', 'furniture': '🛋', 'bedding': '🛏', 'bath': '🛁',
    'beauty': '💄', 'makeup': '💄', 'skincare': '🧴',
    'personal care': '🧴', 'hair': '💇',
    'health': '🌿', 'vitamin': '💊', 'supplement': '💊',
    'sports': '⚽', 'fitness': '🏋', 'outdoor': '🏕', 'camping': '⛺',
    'tools': '🔧', 'hardware': '🔩',
    'automotive': '🚗', 'car': '🚗',
    'pet': '🐶', 'dog': '🐶', 'cat': '🐱',
    'office': '🖊', 'stationery': '✏️',
    'food': '🍜', 'grocery': '🛒', 'snack': '🍿',
    'baby': '🍼', 'kids': '🧸', 'toy': '🧸',
    'game': '🎮', 'gaming': '🎮',
    'garden': '🪴', 'plant': '🌱',
    'book': '📚', 'music': '🎵',
    'art': '🎨', 'craft': '✂️',
    'travel': '✈️', 'luggage': '🧳',
    'vacuum': '🧹', 'cleaning': '🧹',
  };

  static String _emoji(String cat) {
    final k = cat.toLowerCase();
    for (final e in _emojiMap.entries) {
      if (k.contains(e.key)) return e.value;
    }
    return '🏷';
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CategorySheet(
        categories: categories,
        selected: selected,
        onChanged: (v) {
          Navigator.pop(context);
          onChanged(v);
        },
        emojiFor: _emoji,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasSelection ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasSelection ? AppColors.brand : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined,
                size: 15,
                color: hasSelection ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              hasSelection ? selected! : 'Categorías',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasSelection ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: hasSelection ? Colors.white : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final String Function(String) emojiFor;

  const _CategorySheet({
    required this.categories,
    required this.selected,
    required this.onChanged,
    required this.emojiFor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Categorías',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 17)),
                const Spacer(),
                if (selected != null)
                  TextButton(
                    onPressed: () => onChanged(null),
                    child: Text('Limpiar',
                        style: GoogleFonts.inter(
                            color: AppColors.brand, fontSize: 13)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: 'Todas',
                    emoji: '🏪',
                    selected: selected == null,
                    onTap: () => onChanged(null),
                  ),
                  ...categories.map((cat) => _Chip(
                        label: cat,
                        emoji: emojiFor(cat),
                        selected: cat == selected,
                        onTap: () => onChanged(cat),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}
