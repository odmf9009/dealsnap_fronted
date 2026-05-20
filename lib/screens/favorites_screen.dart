import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'auth/login_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _auth = AuthService();
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    _load();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _load();
  }

  Future<void> _load() async {
    final token = _auth.user?.token;
    if (token == null) {
      setState(() { _loading = false; _products = []; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final products = await ApiService.getFavorites(token);
      if (!mounted) return;
      setState(() { _products = products; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          l10n.favoritesTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _load,
        child: _loading
            ? _buildShimmer()
            : _auth.user == null
                ? _buildNotLoggedIn(l10n)
                : _error != null
                    ? _buildError(l10n)
                    : _products.isEmpty
                        ? _buildEmpty(l10n)
                        : _buildGrid(),
      ),
      ),
    );
  }

  Widget _buildNotLoggedIn(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              l10n.loginRequiredTitle,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loginToViewFavorites,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(l10n.signIn),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: _products.length,
            itemBuilder: (_, i) => ProductCard(product: _products[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: 6,
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

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border_rounded, size: 52, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            l10n.noFavorites,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.noFavoritesHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(l10n.errorGeneric, style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
