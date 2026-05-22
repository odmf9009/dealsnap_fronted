import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/product.dart';
import '../screens/auth/login_screen.dart';
import '../screens/group_products_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isUpcoming;
  final bool isLocked;

  const ProductCard({super.key, required this.product, this.isUpcoming = false, this.isLocked = false});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.favorite;
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final auth = AuthService();
    if (!auth.isLoggedIn) {
      _showLoginDialog(context);
      return;
    }
    final prev = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);
    try {
      final token = auth.user!.token;
      if (prev) {
        await ApiService.removeFavorite(token, widget.product.id);
      } else {
        await ApiService.addFavorite(token, widget.product.id);
      }
    } catch (_) {
      if (mounted) setState(() => _isFavorite = prev);
    }
  }

  void _showLoginDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 22),
            const SizedBox(width: 8),
            Text(l10n.loginRequiredTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(l10n.loginRequiredFavoriteBody, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: Text(l10n.signIn, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
            child: Text(l10n.goToRegister),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) =>
      price == price.truncateToDouble()
          ? '\$${price.toStringAsFixed(0)}'
          : '\$${price.toStringAsFixed(2)}';

  (double, double?) _resolvePrices() {
    final discount = widget.product.discountPercentage;
    if (widget.product.originalPrice > widget.product.currentPrice) {
      return (widget.product.currentPrice, widget.product.originalPrice);
    }
    if (discount > 0 && widget.product.currentPrice > 0) {
      final discounted = widget.product.currentPrice * (1 - discount / 100);
      return (discounted, widget.product.currentPrice);
    }
    return (widget.product.currentPrice, null);
  }

  String _timeLabel(AppLocalizations l10n, String? dateStr, {bool isStart = false}) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return isStart ? l10n.liveNow : l10n.expired;
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    if (days > 0) return isStart ? l10n.launchesInDaysHours(days, hours) : l10n.expiresInDays(days);
    if (hours > 0) return isStart ? l10n.launchesInHours(hours) : l10n.expiresInHours(hours);
    return isStart ? l10n.launchingSoon : l10n.expiringSoon;
  }

  Color _expiryColor(String? dateStr) {
    if (dateStr == null) return AppColors.textMuted;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return AppColors.textMuted;
    final days = date.difference(DateTime.now()).inDays;
    if (days <= 2) return AppColors.danger;
    if (days <= 7) return AppColors.accent;
    return AppColors.brand;
  }

  Future<void> _onTap(BuildContext context) async {
    final key = widget.product.groupKey ?? widget.product.promoCode;
    if (widget.product.isGroup && key != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupProductsScreen(promoCode: key)),
      );
      return;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _HowToUseDialog(product: widget.product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final discount = widget.product.discountPercentage;
    final hasCode = widget.product.hasPromoCode && widget.product.promoCode != null;

    final (displayPrice, strikePrice) = _resolvePrices();
    final hasSavings = strikePrice != null && strikePrice > displayPrice;
    final savings = hasSavings ? strikePrice - displayPrice : 0.0;

    Widget? timeBadge;
    if (widget.isUpcoming && widget.product.promo?.startsAt != null) {
      timeBadge = _TimeBadge(
        icon: Icons.rocket_launch_rounded,
        label: _timeLabel(l10n, widget.product.promo!.startsAt, isStart: true),
        color: AppColors.badgeExclusive,
        bgColor: AppColors.badgeExclusiveLight,
      );
    } else if (!widget.isUpcoming && widget.product.promo?.expiresAt != null) {
      final c = _expiryColor(widget.product.promo!.expiresAt);
      timeBadge = _TimeBadge(
        icon: Icons.timer_outlined,
        label: _timeLabel(l10n, widget.product.promo!.expiresAt),
        color: c,
        bgColor: c.withValues(alpha: 0.12),
      );
    }

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Image area ──────────────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ColoredBox(
                    color: const Color(0xFFF8F8F8),
                    child: widget.product.image != null
                        ? CachedNetworkImage(
                            imageUrl: widget.product.image!,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const _ImagePlaceholder(),
                            errorWidget: (_, __, ___) =>
                                const _ImagePlaceholder(broken: true),
                          )
                        : const _ImagePlaceholder(),
                  ),
                ),
              ),
              if (discount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$discount% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 14,
                      color: _isFavorite ? AppColors.danger : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              if (widget.product.isGroup)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3A6B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_rounded, size: 10, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.product.groupCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── Info area ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  widget.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),

                // Store
                if (widget.product.storeName.isNotEmpty)
                  Text(
                    widget.product.storeName,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                const SizedBox(height: 6),

                // Price row: discounted (bold) + original (strikethrough)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatPrice(displayPrice),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (strikePrice != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _formatPrice(strikePrice),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Savings row
                if (hasSavings) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.youSave(_formatPrice(savings), discount),
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                // Promo code with coupon/scratch effect
                if (hasCode) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        l10n.codeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(child: _CodeChip(code: widget.product.promoCode!)),
                    ],
                  ),
                ],

                // Time badge
                if (timeBadge != null) ...[
                  const SizedBox(height: 6),
                  timeBadge,
                ],

                // Action button
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () { _onTap(context); },
                    icon: Icon(
                      widget.product.isGroup ? Icons.layers_rounded : Icons.local_offer_rounded,
                      size: 13,
                    ),
                    label: Text(
                      widget.product.isGroup
                          ? l10n.viewProducts(widget.product.groupCount)
                          : l10n.revealCode,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.product.isGroup
                          ? const Color(0xFF1B3A6B)
                          : const Color(0xFFFFA41C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!widget.isLocked) return card;

    return Stack(
      children: [
        card,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_rounded, size: 13),
              label: Text(
                AppLocalizations.of(context).premiumAccess,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                disabledBackgroundColor: const Color(0xFF7C3AED),
                disabledForegroundColor: Colors.white,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Code chip with coupon/scratch visual ───────────────────────────────────────

// ── How to use centered dialog ─────────────────────────────────────────────────

class _HowToUseDialog extends StatefulWidget {
  final Product product;
  const _HowToUseDialog({required this.product});

  @override
  State<_HowToUseDialog> createState() => _HowToUseDialogState();
}

class _HowToUseDialogState extends State<_HowToUseDialog> {
  bool _loadingUrl = true;
  String? _amazonUrl;

  @override
  void initState() {
    super.initState();
    _fetchUrl();
  }

  String? _extractAsin(String url) {
    final match = RegExp(r'/dp/([A-Z0-9]{10})').firstMatch(url);
    return match?.group(1);
  }

  Future<void> _fetchUrl() async {
    final asin = _extractAsin(widget.product.url);
    if (asin != null) {
      final url = await ApiService.getAmazonItemUrl(asin);
      if (mounted) setState(() { _amazonUrl = url ?? widget.product.url; _loadingUrl = false; });
    } else {
      if (mounted) setState(() { _amazonUrl = widget.product.url; _loadingUrl = false; });
    }
  }

  Future<void> _launch(BuildContext context) async {
    Navigator.pop(context);
    final code = widget.product.promoCode;
    if (widget.product.hasPromoCode && code != null) {
      await Clipboard.setData(ClipboardData(text: code));
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.codeCopied(code),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.brand,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    final urlToOpen = _amazonUrl ?? widget.product.url;
    if (urlToOpen.isNotEmpty) {
      final uri = Uri.parse(urlToOpen);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.howToUseCode,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Promo tag icon with decorative dots
              Center(
                child: SizedBox(
                  width: 110,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative dots
                      Positioned(top: 4, left: 8, child: _Dot(color: const Color(0xFF3B82F6), size: 6)),
                      Positioned(top: 12, right: 6, child: _Dot(color: const Color(0xFFF59E0B), size: 5)),
                      Positioned(bottom: 8, left: 12, child: _Dot(color: const Color(0xFFEF4444), size: 5)),
                      Positioned(bottom: 4, right: 14, child: _Dot(color: const Color(0xFF8B5CF6), size: 6)),
                      // Circle background
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF7ED),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(Icons.local_offer_rounded, size: 38, color: Color(0xFFFFA41C)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Steps
              _HowToUseStep(number: 1, text: l10n.howToUseStep1),
              const SizedBox(height: 10),
              _HowToUseStep(number: 2, text: l10n.howToUseStep2),
              const SizedBox(height: 10),
              _HowToUseStep(number: 3, text: l10n.howToUseStep3),
              const SizedBox(height: 10),
              _HowToUseStep(number: 4, text: l10n.howToUseStep4),
              const SizedBox(height: 10),
              _HowToUseStep(number: 5, text: l10n.howToUseStep5),
              const SizedBox(height: 16),

              // Limited uses warning box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF22C55E), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.codesLimitedUsesTitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.codesLimitedUsesDesc,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // How to use outline button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: Text(l10n.howToUseCode),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    disabledForegroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Get discount button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loadingUrl ? null : () => _launch(context),
                  icon: _loadingUrl
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.local_offer_rounded, size: 16),
                  label: Text(_loadingUrl ? l10n.loading : l10n.getDiscountOnAmazon),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA41C),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFFFD080),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowToUseStep extends StatelessWidget {
  final int number;
  final String text;
  const _HowToUseStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Code chip with coupon/scratch visual ───────────────────────────────────────

class _CodeChip extends StatelessWidget {
  final String code;
  const _CodeChip({required this.code});

  String get _masked {
    if (code.length <= 2) return code;
    return '${'●' * (code.length - 2)}${code.substring(code.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    const chipColor = Color(0xFF1A1A2E);
    const foldSize = 14.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dark chip body (top-right corner is square — will be covered by fold)
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, foldSize + 4, 4),
          decoration: const BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            _masked,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Folded corner — top-right
        Positioned(
          top: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(foldSize, foldSize),
            painter: _PeelCornerPainter(baseColor: chipColor),
          ),
        ),
      ],
    );
  }
}

// Draws a "peeled corner" triangle at the top-right of the code chip.
class _PeelCornerPainter extends CustomPainter {
  final Color baseColor;
  const _PeelCornerPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    // The "underside" of the fold — lighter shade, triangular
    final foldPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      foldPath,
      Paint()..color = const Color(0xFF3A3A5E),
    );

    // Diagonal crease line (shadow edge)
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, size.height),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PeelCornerPainter old) => old.baseColor != baseColor;
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  final bool broken;
  const _ImagePlaceholder({this.broken = false});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Icon(
            broken ? Icons.broken_image_outlined : Icons.image_outlined,
            color: AppColors.textMuted,
            size: 32,
          ),
        ),
      );
}

class _TimeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _TimeBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
