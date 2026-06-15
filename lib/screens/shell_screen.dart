import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/locale/locale_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'deals_screen.dart';
import 'limited_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'alerts/alerts_screen.dart';
import 'auth/login_screen.dart';
import 'profile/profile_screen.dart';
import 'category_preferences_screen.dart';
import 'best_sellers_screen.dart';
import '../services/category_prefs_notifier.dart';

const _kTabHome = 0;
const _kTabDeals = 1;
const _kTabLimited = 2;
const _kTabFavorites = 3;
const _kTabProfile = 4;

// Sidebar is persistent when running on web with width >= this threshold
const _kWebSidebarBreakpoint = 1024.0;


class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  bool _isSearching = false;
  int _currentIndex = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _queryNotifier = ValueNotifier<String>('');
  final _auth = AuthService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const DealsScreen(),
      const LimitedScreen(),
      const FavoritesScreen(),
    ];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    Future.delayed(const Duration(milliseconds: 80), () => _searchFocus.requestFocus());
  }

  void _closeSearch() {
    _searchCtrl.clear();
    _queryNotifier.value = '';
    _searchFocus.unfocus();
    setState(() => _isSearching = false);
  }

  void _onSearchChanged(String value) {
    _queryNotifier.value = value;
    setState(() {});
  }

  Widget _currentScreen() => _screens[_currentIndex];

  void _navigate(int index) {
    if (index == _kTabProfile) {
      if (_auth.user != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return;
    }
    if (index < _screens.length) {
      setState(() => _currentIndex = index);
    }
    _scaffoldKey.currentState?.closeDrawer();
  }

  bool get _useWebSidebar =>
      kIsWeb && MediaQuery.sizeOf(context).width >= _kWebSidebarBreakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;
    final l10n = AppLocalizations.of(context);

    if (_useWebSidebar) {
      return _buildWebLayout(l10n);
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      appBar: _isSearching ? _buildSearchBar(l10n) : _buildMainBar(isWide, l10n),
      drawer: _buildDrawer(l10n),
      body: _isSearching
          ? SearchScreen(queryNotifier: _queryNotifier)
          : _currentScreen(),
      bottomNavigationBar: isWide || _isSearching
          ? null
          : _buildBottomNav(l10n),
    );
  }

  Widget _buildWebLayout(AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _WebHeader(
            auth: _auth,
            isSearching: _isSearching,
            searchCtrl: _searchCtrl,
            searchFocus: _searchFocus,
            queryNotifier: _queryNotifier,
            onOpenSearch: _openSearch,
            onCloseSearch: _closeSearch,
            onSearchChanged: _onSearchChanged,
            onLogin: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            onProfile: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WebSidebar(
                  currentIndex: _currentIndex,
                  auth: _auth,
                  onNavigate: _navigate,
                  onBestSellers: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BestSellersScreen()),
                  ),
                  onAlerts: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlertsScreen()),
                  ),
                  onCategories: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryPreferencesScreen()),
                  ).then((ids) {
                    if (ids is List<String>) CategoryPrefsNotifier.instance.update(ids);
                  }),
                ),
                const VerticalDivider(width: 1, color: AppColors.divider),
                Expanded(
                  child: _isSearching
                      ? SearchScreen(queryNotifier: _queryNotifier)
                      : _currentScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: l10n.navHome,
                selected: _currentIndex == _kTabHome,
                onTap: () => _navigate(_kTabHome),
              ),
              _BottomNavItem(
                icon: Icons.sell_outlined,
                activeIcon: Icons.sell_rounded,
                label: l10n.navDeals,
                selected: _currentIndex == _kTabDeals,
                onTap: () => _navigate(_kTabDeals),
              ),
              _BottomNavItem(
                icon: Icons.timer_outlined,
                activeIcon: Icons.timer_rounded,
                label: l10n.navLimited,
                selected: _currentIndex == _kTabLimited,
                onTap: () => _navigate(_kTabLimited),
              ),
              _BottomNavItem(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: l10n.navFavorites,
                selected: _currentIndex == _kTabFavorites,
                onTap: () => _navigate(_kTabFavorites),
              ),
              _ProfileNavItem(
                auth: _auth,
                label: l10n.navProfile,
                onTap: () => _navigate(_kTabProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(AppLocalizations l10n) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: _Logo(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(height: 1, color: AppColors.divider),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _DrawerNavItem(
                      icon: Icons.visibility_off_rounded,
                      color: const Color(0xFF7C3AED),
                      label: l10n.drawerHiddenDeals,
                      selected: false,
                      onTap: () => _navigate(_kTabHome),
                    ),
                    _DrawerNavItem(
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFF59E0B),
                      label: l10n.bestSellers,
                      selected: false,
                      onTap: () {
                        _scaffoldKey.currentState?.closeDrawer();
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BestSellersScreen()),
                          );
                        });
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFFEF4444),
                      label: l10n.drawerTrendingNow,
                      selected: false,
                      onTap: () => _navigate(_kTabDeals),
                    ),
                    _DrawerNavItem(
                      icon: Icons.timer_rounded,
                      color: const Color(0xFF22C55E),
                      label: l10n.drawerLimitedDeals,
                      selected: _currentIndex == _kTabLimited,
                      onTap: () => _navigate(_kTabLimited),
                    ),
                    _DrawerNavItem(
                      icon: Icons.discount_rounded,
                      color: const Color(0xFF3B82F6),
                      label: l10n.drawerPromoCodes,
                      selected: false,
                      onTap: () => _navigate(_kTabHome),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),

                    ListenableBuilder(
                      listenable: _auth,
                      builder: (_, __) {
                        if (_auth.user == null) return const SizedBox.shrink();
                        return _DrawerNavItem(
                          icon: Icons.grid_view_rounded,
                          color: const Color(0xFF1B3A6B),
                          label: l10n.myCategories,
                          selected: false,
                          onTap: () {
                            _scaffoldKey.currentState?.closeDrawer();
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CategoryPreferencesScreen(),
                                ),
                              ).then((updatedIds) {
                                if (updatedIds is List<String>) {
                                  CategoryPrefsNotifier.instance.update(updatedIds);
                                }
                              });
                            });
                          },
                        );
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.workspace_premium_rounded,
                      color: const Color(0xFF8B5CF6),
                      label: l10n.drawerPremiumDeals,
                      selected: false,
                      onTap: () => _navigate(_kTabHome),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),

                    _DrawerNavItem(
                      icon: Icons.notifications_rounded,
                      color: const Color(0xFFF97316),
                      label: l10n.drawerDealAlerts,
                      selected: false,
                      onTap: () => _navigate(_kTabHome),
                    ),
                    _DrawerNavItem(
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF06B6D4),
                      label: l10n.drawerDailyPicks,
                      selected: false,
                      onTap: () => _navigate(_kTabHome),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),

                    _DrawerNavItem(
                      icon: Icons.headset_mic_rounded,
                      color: const Color(0xFF0EA5E9),
                      label: l10n.drawerSupport,
                      selected: false,
                      onTap: () => _navigate(_kTabHome),
                    ),
                    _DrawerNavItem(
                      icon: Icons.star_rounded,
                      color: const Color(0xFFEC4899),
                      label: l10n.drawerRateApp,
                      selected: false,
                      onTap: () => _navigate(_kTabHome),
                    ),
                    _DrawerNavItem(
                      icon: Icons.person_add_rounded,
                      color: const Color(0xFF10B981),
                      label: l10n.drawerInviteFriends,
                      selected: false,
                      onTap: () => _navigate(_kTabHome),
                    ),
                    _DrawerNavItem(
                      icon: Icons.settings_rounded,
                      color: const Color(0xFF6B7280),
                      label: l10n.drawerSettings,
                      selected: false,
                      onTap: () => _navigate(_kTabHome),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Show user tile only when logged in
            ListenableBuilder(
              listenable: _auth,
              builder: (_, __) {
                final user = _auth.user;
                if (user == null) return const SizedBox.shrink();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                    _DrawerUserTile(user: user, auth: _auth),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMainBar(bool isWide, AppLocalizations l10n) {
    return AppBar(
      titleSpacing: 4,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: isWide
          ? Row(children: [
              _Logo(),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 2 / 3,
                    child: _InlineSearchField(onTap: _openSearch),
                  ),
                ),
              ),
            ])
          : Row(children: [
              _Logo(),
              const Spacer(),
              Expanded(
                flex: 4,
                child: _InlineSearchField(onTap: _openSearch),
              ),
            ]),
      actions: [
        const _LanguageButton(),
        const SizedBox(width: 4),
      ],
    );
  }

  PreferredSizeWidget _buildSearchBar(AppLocalizations l10n) {
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
        onPressed: _closeSearch,
      ),
      title: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: l10n.searchDealsPlaceholder,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    _queryNotifier.value = '';
                    _searchFocus.requestFocus();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _searchFocus.unfocus(),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.divider),
      ),
    );
  }
}

// ── Language button (compact toggle) ─────────────────────────────────────────

class _LanguageButton extends ConsumerWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return TextButton(
      onPressed: () {
        final next = locale.languageCode == 'en' ? const Locale('es') : const Locale('en');
        ref.read(localeProvider.notifier).setLocale(next);
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language_rounded, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 3),
          Text(
            locale.languageCode.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: 32,
      fit: BoxFit.contain,
    );
  }
}

class _InlineSearchField extends StatelessWidget {
  final VoidCallback onTap;
  const _InlineSearchField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Flexible(
              child: Text(
                l10n.searchDealsPlaceholder,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerUserTile extends StatelessWidget {
  final AuthUser user;
  final AuthService auth;
  const _DrawerUserTile({required this.user, required this.auth});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.brandLight,
            backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
            child: user.avatar == null
                ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 14))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(user.email,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
            onPressed: () => auth.signOut(),
            tooltip: l10n.signOut,
          ),
        ],
      ),
    );
  }
}

// ── Profile nav item (supports CircleAvatar when logged in) ──────────────────

class _ProfileNavItem extends StatelessWidget {
  final AuthService auth;
  final String label;
  final VoidCallback onTap;

  const _ProfileNavItem({
    required this.auth,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListenableBuilder(
              listenable: auth,
              builder: (_, __) {
                final user = auth.user;
                if (user != null) {
                  return CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.brandLight,
                    backgroundImage:
                        user.avatar != null ? NetworkImage(user.avatar!) : null,
                    child: user.avatar == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          )
                        : null,
                  );
                }
                return const Icon(
                  Icons.person_outline_rounded,
                  size: 24,
                  color: AppColors.textMuted,
                );
              },
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: selected ? color.withValues(alpha: 0.08) : null,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? color : AppColors.textPrimary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.textMuted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WEB LAYOUT WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _WebHeader extends ConsumerWidget {
  final AuthService auth;
  final bool isSearching;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final ValueNotifier<String> queryNotifier;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onLogin;
  final VoidCallback onProfile;

  const _WebHeader({
    required this.auth,
    required this.isSearching,
    required this.searchCtrl,
    required this.searchFocus,
    required this.queryNotifier,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onSearchChanged,
    required this.onLogin,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Logo
          Image.asset('assets/images/logo.png', height: 34, fit: BoxFit.contain),
          const SizedBox(width: 24),

          // Search bar (expanded)
          Expanded(
            child: isSearching
                ? _WebSearchField(
                    controller: searchCtrl,
                    focusNode: searchFocus,
                    placeholder: l10n.searchDealsPlaceholder,
                    onChanged: onSearchChanged,
                    onClose: onCloseSearch,
                  )
                : GestureDetector(
                    onTap: onOpenSearch,
                    child: Container(
                      height: 38,
                      constraints: const BoxConstraints(maxWidth: 560),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            l10n.searchDealsPlaceholder,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          const SizedBox(width: 16),

          // Language toggle
          TextButton(
            onPressed: () {
              final next = locale.languageCode == 'en'
                  ? const Locale('es')
                  : const Locale('en');
              ref.read(localeProvider.notifier).setLocale(next);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  locale.languageCode.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Auth button
          ListenableBuilder(
            listenable: auth,
            builder: (_, __) {
              final user = auth.user;
              if (user != null) {
                return InkWell(
                  onTap: onProfile,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.brandLight,
                          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                          child: user.avatar == null
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.name.split(' ').first,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              }
              return FilledButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.person_rounded, size: 15),
                label: Text(l10n.signIn),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WebSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _WebSearchField({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brand, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _WebSidebar extends StatelessWidget {
  final int currentIndex;
  final AuthService auth;
  final ValueChanged<int> onNavigate;
  final VoidCallback onBestSellers;
  final VoidCallback onAlerts;
  final VoidCallback onCategories;

  const _WebSidebar({
    required this.currentIndex,
    required this.auth,
    required this.onNavigate,
    required this.onBestSellers,
    required this.onAlerts,
    required this.onCategories,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: 240,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Main navigation ──────────────────────────────
                    _SidebarItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: l10n.navHome,
                      selected: currentIndex == _kTabHome,
                      color: AppColors.brand,
                      onTap: () => onNavigate(_kTabHome),
                    ),
                    _SidebarItem(
                      icon: Icons.sell_outlined,
                      activeIcon: Icons.sell_rounded,
                      label: l10n.navDeals,
                      selected: currentIndex == _kTabDeals,
                      color: const Color(0xFFEF4444),
                      onTap: () => onNavigate(_kTabDeals),
                    ),
                    _SidebarItem(
                      icon: Icons.rocket_launch_outlined,
                      activeIcon: Icons.rocket_launch_rounded,
                      label: l10n.navLimited,
                      selected: currentIndex == _kTabLimited,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => onNavigate(_kTabLimited),
                    ),
                    _SidebarItem(
                      icon: Icons.favorite_border_rounded,
                      activeIcon: Icons.favorite_rounded,
                      label: l10n.navFavorites,
                      selected: currentIndex == _kTabFavorites,
                      color: const Color(0xFFEC4899),
                      onTap: () => onNavigate(_kTabFavorites),
                    ),

                    _SidebarDivider(label: l10n.bestSellers),

                    // ── Discover ─────────────────────────────────────
                    _SidebarItem(
                      icon: Icons.emoji_events_outlined,
                      activeIcon: Icons.emoji_events_rounded,
                      label: l10n.bestSellers,
                      selected: false,
                      color: const Color(0xFFF59E0B),
                      onTap: onBestSellers,
                    ),
                    _SidebarItem(
                      icon: Icons.notifications_outlined,
                      activeIcon: Icons.notifications_rounded,
                      label: l10n.drawerDealAlerts,
                      selected: false,
                      color: const Color(0xFFF97316),
                      onTap: onAlerts,
                    ),

                    _SidebarDivider(label: l10n.myCategories),

                    // ── Account ──────────────────────────────────────
                    ListenableBuilder(
                      listenable: auth,
                      builder: (_, __) {
                        if (auth.user == null) return const SizedBox.shrink();
                        return _SidebarItem(
                          icon: Icons.grid_view_outlined,
                          activeIcon: Icons.grid_view_rounded,
                          label: l10n.myCategories,
                          selected: false,
                          color: const Color(0xFF1B3A6B),
                          onTap: onCategories,
                        );
                      },
                    ),
                    _SidebarItem(
                      icon: Icons.workspace_premium_outlined,
                      activeIcon: Icons.workspace_premium_rounded,
                      label: l10n.drawerPremiumDeals,
                      selected: false,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => onNavigate(_kTabHome),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer: user tile or login CTA ───────────────────────
            const Divider(height: 1, color: AppColors.divider),
            ListenableBuilder(
              listenable: auth,
              builder: (_, __) {
                final user = auth.user;
                if (user == null) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onNavigate(_kTabProfile),
                        icon: const Icon(Icons.person_rounded, size: 15),
                        label: Text(l10n.signIn),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brand,
                          side: const BorderSide(color: AppColors.brand),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.brandLight,
                        backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                        child: user.avatar == null
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.brand,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.email,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.danger),
                        onPressed: () => auth.signOut(),
                        tooltip: l10n.signOut,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 18,
                  color: selected ? color : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  final String label;
  const _SidebarDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
