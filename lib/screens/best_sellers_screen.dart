import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/category_prefs_notifier.dart';
import '../theme/app_theme.dart';

class BestSellersScreen extends StatefulWidget {
  const BestSellersScreen({super.key});

  @override
  State<BestSellersScreen> createState() => _BestSellersScreenState();
}

class _BestSellersScreenState extends State<BestSellersScreen> {
  List<Product> _products = [];
  List<Category> _allCategories = [];
  String? _selectedSlug;
  bool _loading = true;       // true only on very first load (categories not yet fetched)
  bool _productsLoading = false; // true when switching categories
  String? _error;

  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    CategoryPrefsNotifier.instance.addListener(_onPrefsChanged);
    _load(null);
  }

  @override
  void dispose() {
    CategoryPrefsNotifier.instance.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  List<Category> get _visibleCategories {
    if (_auth.isLoggedIn) {
      final prefIds = CategoryPrefsNotifier.instance.ids;
      if (prefIds.isNotEmpty) {
        return _allCategories.where((c) => prefIds.contains(c.id)).toList();
      }
    }
    return _allCategories;
  }

  Future<void> _load(String? slug) async {
    final isFirstLoad = _allCategories.isEmpty;
    setState(() {
      _selectedSlug = slug;
      _error = null;
      if (isFirstLoad) {
        _loading = true;
      } else {
        _productsLoading = true;
      }
    });
    try {
      final List<Future<dynamic>> calls = [
        ApiService.getBestSellers(category: slug, minDiscount: 25),
        if (isFirstLoad) ApiService.getCategories(),
      ];
      final futures = await Future.wait(calls);
      final res = futures[0] as DealsResponse;
      if (mounted) {
        setState(() {
          _products = res.products;
          if (isFirstLoad && futures.length > 1) {
            _allCategories = futures[1] as List<Category>;
          }
          _loading = false;
          _productsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _productsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.bestSellers,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).languageCode;
    final cats = _visibleCategories;

    return ListenableBuilder(
      listenable: _auth,
      builder: (_, __) => Column(
        children: [
          // ── Fixed top section: never reloads on category change ──────────
          _buildHeader(l10n),
          _buildCategoryFilter(l10n, locale, cats),
          _buildSectionTitle(l10n),

          // ── Product list: independent, reloads only this area ────────────
          Expanded(
            child: (_loading || _productsLoading)
                ? _buildProductsShimmer()
                : _error != null
                    ? _buildError(l10n)
                    : _products.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noDealsFound,
                              style: GoogleFonts.inter(color: AppColors.textSecondary),
                            ),
                          )
                        : CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _BestSellerCard(
                                product: _products[i],
                                rank: i + 1,
                                locale: locale,
                                categories: _allCategories,
                              ),
                              childCount: _products.length,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                        ],
                      ),
          ),

          // ── Fixed footer — always visible at the bottom ──────────────────
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFooter(l10n),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFE5E7EB), Color(0xFFF9FAFB), Color(0xFFE5E7EB)],
            stops: [0, 0.5, 1],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 16, 28, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFF59E0B),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.bestSellers,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.bestSellersSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      l10n.bestSellersUpdatedDaily,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: trophy + podium illustration
          const _TrophyIllustration(),
        ],
      ),
    );
  }

  // ── Category filter ─────────────────────────────────────────────────────────

  Widget _buildCategoryFilter(
      AppLocalizations l10n, String locale, List<Category> cats) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: l10n.allCategories,
            icon: Icons.grid_view_rounded,
            selected: _selectedSlug == null,
            onTap: () => _load(null),
          ),
          ...cats.map((c) => _CategoryChip(
                label: c.localizedName(locale),
                icon: c.icon,
                selected: _selectedSlug == c.slug,
                onTap: () => _load(c.slug),
              )),
        ],
      ),
    );
  }

  // ── Section title ────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, size: 20, color: Color(0xFFF59E0B)),
          const SizedBox(width: 6),
          Text(
            l10n.topBestSellers,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.seeAll,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: ribbon medal
          const _RibbonMedal(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whyBestSellers,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.whyBestSellersDesc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Right: bag + gold sparkle + blue diamond
          const _BagWithSparkles(),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────────

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(l10n.couldNotLoadDeals,
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(l10n.checkConnectionRetry,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _load(_selectedSlug),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

// ── Ribbon medal (footer left icon) ──────────────────────────────────────────

class _RibbonMedal extends StatelessWidget {
  const _RibbonMedal();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 52,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Ribbon body
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 14,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Ribbon V-notch at bottom of ribbon
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 8,
                child: CustomPaint(painter: _VNotchPainter()),
              ),
            ),
          ),
          // Medal circle (gold gradient)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                center: Alignment(-0.3, -0.3),
              ),
              border: Border.all(color: const Color(0xFFFBBF24), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.star_rounded, size: 18, color: Color(0xFFD97706)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VNotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF6D28D9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Shopping bag with sparkles (footer right icon) ───────────────────────────

class _BagWithSparkles extends StatelessWidget {
  const _BagWithSparkles();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 3D shadow layer (isometric depth effect)
          const Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.shopping_bag_rounded, size: 44, color: Color(0xFF1E3A8A)),
          ),
          // Main bag (offset for 3D depth)
          const Positioned(
            right: 4,
            bottom: 4,
            child: Icon(Icons.shopping_bag_rounded, size: 44, color: Color(0xFF2563EB)),
          ),
          // Large gold star — upper right
          const Positioned(
            top: 0,
            right: 2,
            child: Icon(Icons.auto_awesome, size: 18, color: Color(0xFFFBBF24)),
          ),
          // Small gold star
          const Positioned(
            top: 14,
            right: 0,
            child: Icon(Icons.auto_awesome, size: 10, color: Color(0xFFFBBF24)),
          ),
          // Blue star — left
          const Positioned(
            left: 0,
            top: 18,
            child: Icon(Icons.auto_awesome, size: 12, color: Color(0xFF60A5FA)),
          ),
          // Small purple star — lower left
          const Positioned(
            left: 6,
            bottom: 6,
            child: Icon(Icons.auto_awesome, size: 8, color: Color(0xFF818CF8)),
          ),
        ],
      ),
    );
  }
}

// ── Trophy + podium illustration ─────────────────────────────────────────────

class _TrophyIllustration extends StatelessWidget {
  const _TrophyIllustration();

  @override
  Widget build(BuildContext context) {
    // Podium: 3 cubes of 22px + 2 gaps of 3px = 72px front width
    // With 3D top-face offset of 8px rightward: rightmost = (96-72)/2 + 72 + 8 = 92 < 96 ✓
    const double w = 96;
    const double h = 96;
    // The tallest cube is 34px front + 8px top face = 42px.
    // Trophy is 56px tall, bottom of trophy at 34+8+2=44 from bottom → top at 96-44-56 = -4 (clip.none)
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 3D podium cubes drawn by CustomPainter
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(96, 46),
              painter: _PodiumPainter(),
            ),
          ),

          // Trophy — large, centered above the middle (tallest) cube
          // middle cube top-face apex is at y = 96 - 34 - 8 = 54 from top
          // so bottom of trophy at y = 54 + 2 = 56 → bottom: 40
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(
                Icons.emoji_events_rounded,
                size: 58,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),

          // ── Star sparkles around trophy ───────────────────────────────
          // Upper-right cluster
          const Positioned(
            top: 0,
            right: 4,
            child: Icon(Icons.auto_awesome, size: 18, color: Color(0xFF6366F1)),
          ),
          const Positioned(
            top: 18,
            right: 0,
            child: Icon(Icons.auto_awesome, size: 12, color: Color(0xFF93C5FD)),
          ),
          const Positioned(
            top: 8,
            right: 22,
            child: Icon(Icons.auto_awesome, size: 9, color: Color(0xFF3B82F6)),
          ),
          // Left side sparkles
          const Positioned(
            top: 2,
            left: 2,
            child: Icon(Icons.auto_awesome, size: 14, color: Color(0xFF818CF8)),
          ),
          const Positioned(
            top: 20,
            left: 0,
            child: Icon(Icons.auto_awesome, size: 9, color: Color(0xFF6366F1)),
          ),
          const Positioned(
            top: 10,
            left: 16,
            child: Icon(Icons.auto_awesome, size: 7, color: Color(0xFF60A5FA)),
          ),
        ],
      ),
    );
  }
}

// ── 3D podium CustomPainter ───────────────────────────────────────────────────

class _PodiumPainter extends CustomPainter {
  const _PodiumPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double cw = 22;  // front face width
    const double gap = 8;  // gap between cubes (must be >= dx to avoid overlap)
    const double dx = 6;   // 3D horizontal offset (right-facing side face)
    const double dy = 8;   // 3D vertical offset

    const List<double> heights = [24.0, 34.0, 16.0]; // [2nd, 1st, 3rd]

    const List<Color> frontColors = [
      Color(0xFF2563EB),
      Color(0xFF1D4ED8),
      Color(0xFF2563EB),
    ];
    const List<Color> topColors = [
      Color(0xFF93C5FD),
      Color(0xFF60A5FA),
      Color(0xFF93C5FD),
    ];
    const List<Color> sideColors = [
      Color(0xFF1E40AF),
      Color(0xFF1E3A8A),
      Color(0xFF1E40AF),
    ];

    const double totalFrontW = 3 * cw + 2 * gap; // 82
    final double sx = (size.width - totalFrontW) / 2;
    final double baseY = size.height;

    // Draw right-to-left so leftmost cube (nearest in isometric view) is on top
    for (int i = 2; i >= 0; i--) {
      final double x = sx + i * (cw + gap);
      final double h = heights[i];
      final double fy = baseY - h;

      // Right side face
      final sidePath = Path()
        ..moveTo(x + cw, fy)
        ..lineTo(x + cw + dx, fy - dy)
        ..lineTo(x + cw + dx, baseY - dy)
        ..lineTo(x + cw, baseY)
        ..close();
      canvas.drawPath(sidePath, Paint()..color = sideColors[i]);

      // Front face (covers side overlap of adjacent cube)
      canvas.drawRect(Rect.fromLTWH(x, fy, cw, h), Paint()..color = frontColors[i]);

      // Top face
      final topPath = Path()
        ..moveTo(x, fy)
        ..lineTo(x + cw, fy)
        ..lineTo(x + cw + dx, fy - dy)
        ..lineTo(x + dx, fy - dy)
        ..close();
      canvas.drawPath(topPath, Paint()..color = topColors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Category filter chip ──────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF97316) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFF97316) : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Best Seller product card ──────────────────────────────────────────────────

class _BestSellerCard extends StatefulWidget {
  final Product product;
  final int rank;
  final String locale;
  final List<Category> categories;

  const _BestSellerCard({
    required this.product,
    required this.rank,
    required this.locale,
    required this.categories,
  });

  @override
  State<_BestSellerCard> createState() => _BestSellerCardState();
}

class _BestSellerCardState extends State<_BestSellerCard> {
  late bool _isFavorite;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.favorite;
  }

  double get _rating {
    final seed = widget.product.id.codeUnits.fold(0, (a, b) => a + b);
    return 4.0 + (seed % 10) / 10.0;
  }

  int get _reviewCount {
    final seed = widget.product.asin.codeUnits.fold(0, (a, b) => a + b);
    return max(200, (seed % 8000) + 500 - (widget.rank * 50)).clamp(200, 9999);
  }

  String get _soldCount {
    const bases = [124, 87, 71, 53, 42, 38, 29, 24, 19, 16, 14, 12, 10, 9, 8, 7, 6, 5, 5, 4];
    final idx = (widget.rank - 1).clamp(0, bases.length - 1);
    final val = bases[idx];
    return val >= 10 ? '${(val / 10.0).toStringAsFixed(1)}K+' : '${val * 100}+';
  }

  String get _categoryLabel {
    final cat = widget.categories.firstWhere(
      (c) => c.slug.toLowerCase() == widget.product.category.toLowerCase(),
      orElse: () => Category(
        id: '',
        slug: widget.product.category,
        nameEs: widget.product.category,
        nameEn: widget.product.category,
        iconKey: 'category',
        color: '#607D8B',
      ),
    );
    return cat.localizedName(widget.locale);
  }

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(widget.product.url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleFavorite() async {
    if (!_auth.isLoggedIn) {
      _showLoginRequired();
      return;
    }
    final prev = _isFavorite;
    setState(() => _isFavorite = !prev);
    try {
      final token = _auth.user!.token;
      if (prev) {
        await ApiService.removeFavorite(token, widget.product.id);
      } else {
        await ApiService.addFavorite(token, widget.product.id);
      }
    } catch (_) {
      if (mounted) setState(() => _isFavorite = prev);
    }
  }

  void _showLoginRequired() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.loginRequiredTitle,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(l10n.loginRequiredFavoriteBody,
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = widget.product;
    final savings = p.originalPrice - p.currentPrice;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Heart icon (top-right)
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: _toggleFavorite,
              child: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 20,
                color: _isFavorite ? AppColors.danger : AppColors.textMuted,
              ),
            ),
          ),

          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Rank badge ──────────────────────────────────────────────────
              Container(
                width: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B3A6B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${widget.rank}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Product image ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: p.image != null
                        ? CachedNetworkImage(
                            imageUrl: p.image!,
                            fit: BoxFit.contain,
                            placeholder: (_, __) =>
                                Container(color: AppColors.surfaceVariant),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textMuted,
                              size: 28,
                            ),
                          ),
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 40, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category rank badge
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 12,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            l10n.rankInCategory(widget.rank, _categoryLabel),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Product title
                      Text(
                        p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Star rating
                      _StarRating(rating: _rating, count: _reviewCount),
                      const SizedBox(height: 5),

                      // Price row
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            '\$${p.currentPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                          Text(
                            '\$${p.originalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${p.discountPercentage}% OFF',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // You save today
                      if (savings > 0)
                        Row(
                          children: [
                            const Icon(Icons.eco_rounded,
                                size: 13, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l10n.youSaveTodayAmount(
                                    '\$${savings.toStringAsFixed(2)}'),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 3),

                      // Sold this week
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              size: 13, color: Color(0xFFF97316)),
                          const SizedBox(width: 4),
                          Text(
                            '$_soldCount ${l10n.soldThisWeek}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Get Deal button
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: _openUrl,
                          icon: const Icon(Icons.open_in_new_rounded, size: 13),
                          label: Text(
                            l10n.getDeal,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}

// ── Star rating row ───────────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final double rating;
  final int count;

  const _StarRating({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.floor();
          final half = !filled && i < rating;
          return Icon(
            half
                ? Icons.star_half_rounded
                : (filled
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded),
            size: 13,
            color: const Color(0xFFF59E0B),
          );
        }),
        const SizedBox(width: 4),
        Text(
          '(${_fmt(count)})',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ── Shimmer loading skeleton ──────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
            gradient: LinearGradient(
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF9FAFB),
                Color(0xFFE5E7EB),
              ],
              stops: const [0, 0.5, 1],
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
            ),
          ),
        ),
      ),
    );
  }
}
