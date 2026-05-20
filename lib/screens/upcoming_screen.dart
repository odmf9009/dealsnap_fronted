import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'category_preferences_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/category_prefs_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/sort_bar.dart';
import '../widgets/filter_drawer_widget.dart';

int _columnCount(double width) {
  if (width < 480) return 2;
  if (width < 768) return 3;
  if (width < 1100) return 4;
  if (width < 1500) return 5;
  return 6;
}

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  final _auth = AuthService();
  List<Product> _products = [];
  List<Category> _categories = [];
  List<String> _preferredCategoryIds = [];

  String? _selectedCategory;
  RangeValues _discountRange = const RangeValues(0, 100);
  RangeValues _priceRange = const RangeValues(0, 1000);
  SortOption _sort = SortOption.discountHigh;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;

  final _scrollController = ScrollController();
  final _drawerKey = GlobalKey<ScaffoldState>();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _preferredCategoryIds = CategoryPrefsNotifier.instance.ids;
    CategoryPrefsNotifier.instance.addListener(_onPrefsChanged);
    _loadFilters();
    _load(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    CategoryPrefsNotifier.instance.removeListener(_onPrefsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPrefsChanged() {
    if (!mounted) return;
    setState(() => _preferredCategoryIds = CategoryPrefsNotifier.instance.ids);
    if (_selectedCategory == null) _load(reset: true);
  }

  void _onScroll() {
    final showFab = _scrollController.offset > 300;
    if (showFab != _showBackToTop) setState(() => _showBackToTop = showFab);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400 &&
        !_loadingMore && _hasMore) {
      _load();
    }
  }

  Future<void> _loadFilters() async {
    try {
      final token = _auth.user?.token;
      final futures = <Future>[
        ApiService.getCategories(),
        if (token != null) ApiService.getCategoryPreferences(token),
      ];
      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<Category>;
        if (token != null && results.length > 1) {
          _preferredCategoryIds = results[1] as List<String>;
        }
      });
    } catch (_) {}
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _page = 1; _hasMore = true; });
    } else {
      setState(() { _loadingMore = true; });
    }
    final usePrefs = _selectedCategory == null && _preferredCategoryIds.isNotEmpty;
    try {
      final res = await ApiService.getUpcoming(
        page: reset ? 1 : _page,
        category: _selectedCategory,
        categoryIds: usePrefs ? _preferredCategoryIds : null,
        discount: _discountRange.start > 0 ? _discountRange.start.toInt() : null,
      );
      if (!mounted) return;
      setState(() {
        _total = res.total;
        _products = reset ? res.products : [..._products, ...res.products];
        _page = (reset ? 1 : _page) + 1;
        _hasMore = _products.length < _total;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; _loadingMore = false; });
    }
  }

  List<Product> get _sorted {
    var list = _products.where((p) {
      final inPrice = p.currentPrice >= _priceRange.start && p.currentPrice <= _priceRange.end;
      final inDiscount = p.discountPercentage >= _discountRange.start &&
          p.discountPercentage <= _discountRange.end;
      return inPrice && inDiscount;
    }).toList();
    switch (_sort) {
      case SortOption.priceLow:
        list.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
      case SortOption.priceHigh:
        list.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
      case SortOption.discountHigh:
        list.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
      case SortOption.relevance:
        break;
    }
    return list;
  }

  void _applyCategory(String? cat) {
    setState(() => _selectedCategory = cat);
    _load(reset: true);
    _drawerKey.currentState?.closeEndDrawer();
  }

  void _applyDiscountPreset(double min, double max) {
    setState(() => _discountRange = RangeValues(min, max));
    _load(reset: true);
    _drawerKey.currentState?.closeEndDrawer();
  }

  void _openCategoryPreferences() {
    _drawerKey.currentState?.closeEndDrawer();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryPreferencesScreen()))
          .then((updatedIds) {
        if (updatedIds is List<String>) {
          setState(() => _preferredCategoryIds = updatedIds);
          if (_selectedCategory == null) _load(reset: true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    final cols = _columnCount(width);
    final sorted = _sorted;

    return Scaffold(
      key: _drawerKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        offset: _showBackToTop ? Offset.zero : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _showBackToTop ? 1 : 0,
          child: FloatingActionButton.small(
            onPressed: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
            backgroundColor: AppColors.brand,
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
          ),
        ),
      ),
      endDrawer: FilterDrawerWidget(
        categories: _categories,
        preferredCategoryIds: _preferredCategoryIds,
        selectedCategory: _selectedCategory,
        discountRange: _discountRange,
        priceRange: _priceRange,
        isLoggedIn: _auth.isLoggedIn,
        onCategoryChanged: _applyCategory,
        onDiscountPreset: _applyDiscountPreset,
        onDiscountRangeChanged: (v) => setState(() => _discountRange = v),
        onPriceRangeChanged: (v) => setState(() => _priceRange = v),
        onManageCategories: _openCategoryPreferences,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      l10n.dealsCount(_total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    SortBar(selected: _sort, onChanged: (s) => setState(() => _sort = s)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _drawerKey.currentState?.openEndDrawer(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.tune_rounded, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              'Filtros',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: (_selectedCategory != null ||
                                        _discountRange != const RangeValues(0, 100) ||
                                        _priceRange != const RangeValues(0, 1000))
                                    ? AppColors.brand
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_loading)
              _ShimmerGrid(cols: cols)
            else if (_error != null)
              SliverFillRemaining(
                child: _ErrorView(onRetry: () => _load(reset: true), l10n: l10n),
              )
            else if (_products.isEmpty)
              SliverFillRemaining(child: _EmptyView(l10n: l10n))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: sorted.length,
                  itemBuilder: (_, i) => ProductCard(
                    product: sorted[i],
                    isUpcoming: true,
                    isLocked: i > 0,
                  ),
                ),
              ),

            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.brand, strokeWidth: 2)),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  final int cols;
  const _ShimmerGrid({required this.cols});

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childCount: cols * 3,
          itemBuilder: (_, i) => Shimmer.fromColors(
            baseColor: AppColors.surfaceVariant,
            highlightColor: Colors.white,
            child: Container(
              height: 240 + (i % 2 == 0 ? 40.0 : 0),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final AppLocalizations l10n;
  const _ErrorView({required this.onRetry, required this.l10n});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.dangerLight, shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, size: 36, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              Text(l10n.failedToLoadUpcoming, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Text(l10n.checkConnectionRetry, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: Text(l10n.retry)),
            ],
          ),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyView({required this.l10n});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(l10n.noUpcomingDeals, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Text(l10n.tryDifferentFilter, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}
