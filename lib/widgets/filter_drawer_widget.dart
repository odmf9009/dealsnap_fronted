import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class FilterDrawerWidget extends StatelessWidget {
  final List<Category> categories;
  final List<String> preferredCategoryIds;
  final String? selectedCategory;
  final RangeValues discountRange;
  final RangeValues priceRange;
  final bool isLoggedIn;
  final ValueChanged<String?> onCategoryChanged;
  final void Function(double min, double max) onDiscountPreset;
  final ValueChanged<RangeValues> onDiscountRangeChanged;
  final ValueChanged<RangeValues> onPriceRangeChanged;
  final VoidCallback? onManageCategories;

  const FilterDrawerWidget({
    super.key,
    required this.categories,
    this.preferredCategoryIds = const [],
    required this.selectedCategory,
    required this.discountRange,
    required this.priceRange,
    this.isLoggedIn = false,
    required this.onCategoryChanged,
    required this.onDiscountPreset,
    required this.onDiscountRangeChanged,
    required this.onPriceRangeChanged,
    this.onManageCategories,
  });

  static const _kNavy = Color(0xFF1B3A6B);

  List<Category> _visibleCategories() {
    if (isLoggedIn && preferredCategoryIds.isNotEmpty) {
      final filtered = categories.where((c) {
        final key = c.id.isNotEmpty ? c.id : c.slug;
        return preferredCategoryIds.contains(c.id) ||
            preferredCategoryIds.contains(c.slug) ||
            preferredCategoryIds.contains(key);
      }).toList();
      return filtered.isNotEmpty ? filtered : categories;
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final visible = _visibleCategories();

    return Drawer(
      backgroundColor: AppColors.surface,
      width: 290,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: _kNavy, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kNavy),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Categoría ──────────────────────────────────────
                    if (categories.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context).myCategories,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800, color: _kNavy),
                          ),
                          if (isLoggedIn && onManageCategories != null)
                            GestureDetector(
                              onTap: onManageCategories,
                              child: const Icon(Icons.edit_rounded, size: 16, color: _kNavy),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CategoryDropdown(
                        categories: visible,
                        selectedCategory: selectedCategory,
                        locale: locale,
                        onChanged: onCategoryChanged,
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 20),
                    ],

                    // ── Descuento ──────────────────────────────────────
                    const Text('Descuento',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: _kNavy)),
                    const SizedBox(height: 10),
                    FilterDiscountPreset(
                      label: '0% – 30%',
                      active: discountRange.start == 0 && discountRange.end == 30,
                      onTap: () => onDiscountPreset(0, 30),
                    ),
                    const SizedBox(height: 8),
                    FilterDiscountPreset(
                      label: '30% – 60%',
                      active: discountRange.start == 30 && discountRange.end == 60,
                      onTap: () => onDiscountPreset(30, 60),
                    ),
                    const SizedBox(height: 8),
                    FilterDiscountPreset(
                      label: 'Más de 60%',
                      active: discountRange.start == 60 && discountRange.end == 100,
                      onTap: () => onDiscountPreset(60, 100),
                    ),
                    const SizedBox(height: 8),
                    FilterDiscountPreset(
                      label: locale == 'es' ? 'Todos' : 'All',
                      active: discountRange.start == 0 && discountRange.end == 100,
                      onTap: () => onDiscountPreset(0, 100),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${discountRange.start.toInt()}% – ${discountRange.end.toInt()}%',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _kNavy,
                        inactiveTrackColor: const Color(0xFFCDD8EA),
                        thumbColor: _kNavy,
                        overlayColor: const Color(0x1F1B3A6B),
                        rangeThumbShape:
                            const RoundRangeSliderThumbShape(enabledThumbRadius: 9),
                        trackHeight: 3,
                      ),
                      child: RangeSlider(
                        values: discountRange,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: onDiscountRangeChanged,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 20),

                    // ── Precio ─────────────────────────────────────────
                    const Text('Precio',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: _kNavy)),
                    const SizedBox(height: 4),
                    Text(
                      'US\$${priceRange.start.toInt()} – US\$${priceRange.end.toInt()}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _kNavy,
                        inactiveTrackColor: const Color(0xFFCDD8EA),
                        thumbColor: _kNavy,
                        overlayColor: const Color(0x1F1B3A6B),
                        rangeThumbShape:
                            const RoundRangeSliderThumbShape(enabledThumbRadius: 9),
                        trackHeight: 3,
                      ),
                      child: RangeSlider(
                        values: priceRange,
                        min: 0,
                        max: 1000,
                        divisions: 100,
                        onChanged: onPriceRangeChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategory;
  final String locale;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selectedCategory,
    required this.locale,
    required this.onChanged,
  });

  static const _kNavy = Color(0xFF1B3A6B);

  String? _resolvedValue() {
    if (selectedCategory == null) return null;
    for (final c in categories) {
      final key = c.id.isNotEmpty ? c.id : c.slug;
      if (key == selectedCategory) return key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final allLabel = locale == 'es' ? 'Todas las categorías' : 'All categories';
    final value = _resolvedValue();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value != null ? _kNavy : AppColors.divider, width: value != null ? 1.5 : 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String?>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kNavy, size: 20),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kNavy,
        ),
        selectedItemBuilder: (_) => [
          _buildItem(icon: Icons.apps_rounded, iconColor: _kNavy, label: allLabel),
          ...categories.map((c) => _buildItem(
                icon: c.icon,
                iconColor: c.iconColor,
                label: c.localizedName(locale),
              )),
        ],
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: _buildItem(icon: Icons.apps_rounded, iconColor: _kNavy, label: allLabel),
          ),
          ...categories.map((c) {
            final key = c.id.isNotEmpty ? c.id : c.slug;
            return DropdownMenuItem<String?>(
              value: key,
              child: _buildItem(icon: c.icon, iconColor: c.iconColor, label: c.localizedName(locale)),
            );
          }),
        ],
        onChanged: (v) => onChanged(v),
      ),
    );
  }

  Widget _buildItem({required IconData icon, required Color iconColor, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kNavy),
          ),
        ),
      ],
    );
  }
}

class FilterDiscountPreset extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const FilterDiscountPreset({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  static const _kNavy = Color(0xFF1B3A6B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _kNavy : const Color(0xFFE8EDF5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _kNavy,
          ),
        ),
      ),
    );
  }
}
