import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

int _cols(double w) {
  if (w < 480) return 2;
  if (w < 768) return 3;
  return 4;
}

class GroupProductsScreen extends StatefulWidget {
  final String promoCode;

  const GroupProductsScreen({super.key, required this.promoCode});

  @override
  State<GroupProductsScreen> createState() => _GroupProductsScreenState();
}

class _GroupProductsScreenState extends State<GroupProductsScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final products = await ApiService.getProductsByCode(widget.promoCode);
      if (!mounted) return;
      setState(() { _products = products; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = _cols(width);

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.groupProductsTitle,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            if (!_loading)
              Text(
                '${_products.length} ${l10n.groupProductsTitle.toLowerCase()}',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _load,
        child: _loading
            ? _buildShimmer(cols)
            : _error != null
                ? _buildError()
                : _products.isEmpty
                    ? _buildEmpty()
                    : _buildGrid(cols),
      ),
    );
  }

  Widget _buildGrid(int cols) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: _products.length,
            itemBuilder: (_, i) => ProductCard(product: _products[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer(int cols) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
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
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(l10n.couldNotLoadDeals),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(l10n.noDealsFound),
        ],
      ),
    );
  }
}
