import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/category_prefs_notifier.dart';
import '../theme/app_theme.dart';

class CategoryPreferencesScreen extends StatefulWidget {
  const CategoryPreferencesScreen({super.key});

  @override
  State<CategoryPreferencesScreen> createState() => _CategoryPreferencesScreenState();
}

class _CategoryPreferencesScreenState extends State<CategoryPreferencesScreen> {
  final _auth = AuthService();
  List<Category> _categories = [];
  Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = _auth.user?.token;
    if (token == null) return;
    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getCategoryPreferences(token),
      ]);
      if (!mounted) return;
      final cats = results[0] as List<Category>;
      final prefs = results[1] as List<String>;
      setState(() {
        _categories = cats;
        _selected = prefs.toSet();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final token = _auth.user?.token;
    if (token == null) return;
    setState(() => _saving = true);
    final ok = await ApiService.saveCategoryPreferences(token, _selected.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    final l10n = AppLocalizations.of(context);
    if (ok) {
      final saved = _selected.toList();
      CategoryPrefsNotifier.instance.update(saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.categoryPreferencesSaved),
        backgroundColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context, saved);
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    const kNavy = Color(0xFF1B3A6B);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          l10n.categoryPreferencesTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.categoryPreferencesSubtitle,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _categories.map((cat) {
                        final catKey = cat.id.isNotEmpty ? cat.id : cat.slug;
                        final isOn = _selected.contains(catKey);
                        return GestureDetector(
                          onTap: () => _toggle(catKey),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isOn ? kNavy : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isOn ? kNavy : AppColors.divider,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 16,
                                  color: isOn ? Colors.white : cat.iconColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat.localizedName(locale),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isOn ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.divider),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(l10n.cancel, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: kNavy,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(l10n.save, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
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
