import 'package:flutter/material.dart';

class Category {
  final String id;
  final String slug;
  final String nameEs;
  final String nameEn;
  final String iconKey;
  final String color;
  final int order;

  const Category({
    required this.id,
    required this.slug,
    required this.nameEs,
    required this.nameEn,
    required this.iconKey,
    required this.color,
    this.order = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        slug: json['slug'] as String? ?? 'miscellaneous',
        nameEs: json['nameEs'] as String? ?? json['nameEn'] as String? ?? '',
        nameEn: json['nameEn'] as String? ?? json['nameEs'] as String? ?? '',
        iconKey: json['iconKey'] as String? ?? 'category',
        color: json['color'] as String? ?? '#607D8B',
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  String localizedName(String languageCode) =>
      languageCode == 'es' ? nameEs : nameEn;

  IconData get icon => _iconMap[iconKey] ?? Icons.category_rounded;

  Color get iconColor {
    try {
      final hex = color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF607D8B);
    }
  }

  static const Map<String, IconData> _iconMap = {
    'local_dining': Icons.local_dining_rounded,
    'edit': Icons.edit_rounded,
    'pets': Icons.pets_rounded,
    'directions_car': Icons.directions_car_rounded,
    'child_care': Icons.child_care_rounded,
    'face': Icons.face_rounded,
    'smartphone': Icons.smartphone_rounded,
    'kitchen': Icons.kitchen_rounded,
    'headset': Icons.headset_rounded,
    'computer': Icons.computer_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'local_laundry_service': Icons.local_laundry_service_rounded,
    'music_note': Icons.music_note_rounded,
    'diamond': Icons.diamond_rounded,
    'smart_toy': Icons.smart_toy_rounded,
    'home_repair_service': Icons.home_repair_service_rounded,
    'category': Icons.category_rounded,
    'grass': Icons.grass_rounded,
    'watch': Icons.watch_rounded,
    'checkroom': Icons.checkroom_rounded,
    'favorite': Icons.favorite_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'luggage': Icons.luggage_rounded,
    'menu_book': Icons.menu_book_rounded,
    'movie': Icons.movie_rounded,
    'album': Icons.album_rounded,
    'devices': Icons.devices_rounded,
    'code': Icons.code_rounded,
    'tablet_android': Icons.tablet_android_rounded,
    'light_mode': Icons.light_mode_rounded,
    'science': Icons.science_rounded,
    'camera_alt': Icons.camera_alt_rounded,
    'chair': Icons.chair_rounded,
  };
}
