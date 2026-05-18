import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

enum SortOption {
  relevance(Icons.auto_awesome_rounded),
  priceLow(Icons.arrow_upward_rounded),
  priceHigh(Icons.arrow_downward_rounded),
  discountHigh(Icons.local_offer_rounded);

  const SortOption(this.icon);
  final IconData icon;
}

extension SortOptionL10n on SortOption {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case SortOption.relevance:    return l10n.sortRelevance;
      case SortOption.priceLow:    return l10n.sortPriceLow;
      case SortOption.priceHigh:   return l10n.sortPriceHigh;
      case SortOption.discountHigh: return l10n.sortDiscountHighest;
    }
  }
}

class SortBar extends StatelessWidget {
  final SortOption selected;
  final ValueChanged<SortOption> onChanged;

  const SortBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => _showSortSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 14, color: AppColors.brand),
            const SizedBox(width: 6),
            Text(
              selected.localizedLabel(l10n),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sortBy,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ...SortOption.values.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: opt == selected ? AppColors.brandLight : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(opt.icon, size: 18, color: opt == selected ? AppColors.brand : AppColors.textSecondary),
                  ),
                  title: Text(
                    opt.localizedLabel(l10n),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: opt == selected ? FontWeight.w600 : FontWeight.w400,
                      color: opt == selected ? AppColors.brand : AppColors.textPrimary,
                    ),
                  ),
                  trailing: opt == selected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.brand, size: 20)
                      : null,
                  onTap: () {
                    onChanged(opt);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
