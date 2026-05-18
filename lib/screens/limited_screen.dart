import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'upcoming_screen.dart';
import 'ending_soon_screen.dart';

class LimitedScreen extends StatelessWidget {
  const LimitedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero header ──────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.limitedDealsTitle,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.limitedDealsSubtitle,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _StopwatchIllustration(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Choose a category ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.limitedChooseCategory,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _CategoryCard(
                        icon: Icons.calendar_month_rounded,
                        iconColor: const Color(0xFF22C55E),
                        bgColor: const Color(0xFFF0FDF4),
                        label: l10n.navUpcoming,
                        desc: l10n.limitedUpcomingDesc,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UpcomingScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CategoryCard(
                        icon: Icons.timer_rounded,
                        iconColor: const Color(0xFFEF4444),
                        bgColor: const Color(0xFFFFF1F2),
                        label: l10n.navComingEnd,
                        desc: l10n.limitedEndingSoonDesc,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EndingSoonScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Feature highlights ───────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _FeatureItem(
                        icon: Icons.sell_rounded,
                        iconColor: const Color(0xFF22C55E),
                        title: l10n.limitedFeatureTimeTitle,
                        desc: l10n.limitedFeatureTimeDesc,
                      ),
                    ),
                    Expanded(
                      child: _FeatureItem(
                        icon: Icons.military_tech_rounded,
                        iconColor: const Color(0xFF0EA5E9),
                        title: l10n.limitedFeatureSavingsTitle,
                        desc: l10n.limitedFeatureSavingsDesc,
                      ),
                    ),
                    Expanded(
                      child: _FeatureItem(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFF97316),
                        title: l10n.limitedFeatureMissTitle,
                        desc: l10n.limitedFeatureMissDesc,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Deal alerts banner ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        size: 28,
                        color: Color(0xFF1B3A6B),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.limitedAlertTitle,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              l10n.limitedAlertDesc,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3A6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(l10n.limitedAlertButton),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stopwatch illustration ─────────────────────────────────────────────────────

class _StopwatchIllustration extends StatelessWidget {
  const _StopwatchIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orange squiggles top-left
          Positioned(
            top: 6,
            left: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 16, height: 2.5, decoration: BoxDecoration(color: const Color(0xFFFFA41C), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 3),
                Container(width: 11, height: 2.5, decoration: BoxDecoration(color: const Color(0xFFFFA41C), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          // Green % circle (left)
          Positioned(
            left: 2,
            top: 28,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
              child: const Center(
                child: Text('%', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          // Red dot bottom-left
          Positioned(
            bottom: 10,
            left: 20,
            child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
          ),
          // Blue blob top-right
          Positioned(
            top: 4,
            right: 4,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 18,
                height: 14,
                decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          // Green diamond (right)
          Positioned(
            right: 14,
            top: 36,
            child: Transform.rotate(
              angle: 0.785,
              child: Container(width: 10, height: 10, color: const Color(0xFF22C55E)),
            ),
          ),
          // Orange % rounded square (bottom-right)
          Positioned(
            bottom: 6,
            right: 4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(6)),
              child: const Center(
                child: Text('%', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          // Stopwatch crown button (top center of circle)
          Positioned(
            top: 8,
            child: Container(
              width: 18,
              height: 9,
              decoration: BoxDecoration(color: const Color(0xFF3D4A5C), borderRadius: BorderRadius.circular(4)),
            ),
          ),
          // Stopwatch body
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3D4A5C), width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.bolt_rounded, size: 36, color: Color(0xFFFFA500)),
          ),
        ],
      ),
    );
  }
}

// ── Category card ──────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String desc;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Circular icon background
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: iconColor, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feature item ───────────────────────────────────────────────────────────────

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
