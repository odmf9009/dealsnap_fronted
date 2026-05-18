import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

int _cols(double w) {
  if (w < 480) return 2;
  if (w < 768) return 3;
  if (w < 1100) return 4;
  if (w < 1500) return 5;
  return 6;
}

class SearchScreen extends StatefulWidget {
  final ValueNotifier<String> queryNotifier;

  const SearchScreen({super.key, required this.queryNotifier});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  List<Product> _results = [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.queryNotifier.addListener(_onQueryChanged);
    if (widget.queryNotifier.value.isNotEmpty) {
      _scheduleSearch(widget.queryNotifier.value);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.queryNotifier.removeListener(_onQueryChanged);
    super.dispose();
  }

  void _onQueryChanged() {
    final query = widget.queryNotifier.value;
    if (query.trim().isEmpty) {
      _debounce?.cancel();
      setState(() { _results = []; _hasSearched = false; _loading = false; });
      return;
    }
    _scheduleSearch(query);
  }

  void _scheduleSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() { _loading = true; _error = null; _hasSearched = true; });
    try {
      final res = await ApiService.searchProducts(query);
      if (!mounted) return;
      setState(() { _results = res; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    final cols = _cols(width);
    final query = widget.queryNotifier.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasSearched)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _loading
                ? Row(children: [
                    const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand)),
                    const SizedBox(width: 8),
                    Text(l10n.searching, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ])
                : Text(
                    _error != null
                        ? l10n.searchError
                        : _results.length == 1
                            ? l10n.searchResult(query)
                            : l10n.searchResults(_results.length, query),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
          ),

        Expanded(
          child: _loading
              ? _buildShimmer(cols)
              : _error != null
                  ? _buildError(l10n, query)
                  : !_hasSearched
                      ? _buildHint(l10n)
                      : _results.isEmpty
                          ? _buildEmpty(l10n, query)
                          : _buildGrid(cols),
        ),
      ],
    );
  }

  Widget _buildGrid(int cols) => MasonryGridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: _results.length,
        itemBuilder: (_, i) => ProductCard(product: _results[i]),
      );

  Widget _buildShimmer(int cols) => MasonryGridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: cols * 3,
        itemBuilder: (_, i) => Shimmer.fromColors(
          baseColor: AppColors.surfaceVariant,
          highlightColor: Colors.white,
          child: Container(
            height: 240 + (i.isEven ? 40.0 : 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );

  Widget _buildHint(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppColors.brandLight, shape: BoxShape.circle),
              child: const Icon(Icons.search_rounded, size: 40, color: AppColors.brand),
            ),
            const SizedBox(height: 16),
            Text(l10n.searchForProducts,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(l10n.typeKeywordToFind,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _buildEmpty(AppLocalizations l10n, String query) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(l10n.noResultsFor(query),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(l10n.tryDifferentKeyword,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _buildError(AppLocalizations l10n, String query) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(l10n.searchFailed, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _search(query),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
}
