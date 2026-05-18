import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_selector.dart';
import '../alerts/alerts_screen.dart';
import '../category_preferences_screen.dart';

// ─── Available options ────────────────────────────────────────────────────────

const _kCategories = [
  'Electronics', 'Fashion', 'Home & Kitchen', 'Sports & Outdoors',
  'Beauty & Personal Care', 'Books', 'Toys & Games', 'Automotive',
  'Health & Wellness', 'Pet Supplies', 'Music', 'Video Games',
];

const _kStores = [
  'Amazon', 'Best Buy', 'Target', 'Walmart', 'Costco', 'Apple',
  'Samsung', 'Nike', 'Adidas', 'IKEA', 'Home Depot', 'Sephora',
];

const _kDealPriorities = [
  'Highest Discount', 'Expiring Soon', 'Newest', 'Most Popular', 'Best Rated',
];

const _kGenders = {
  'secret': 'Keep secret',
  'male':   'Male',
  'female': 'Female',
  'other':  'Other',
};

// ─── Screen ──────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = _auth.user?.token;
    if (token == null) return;
    final p = await UserService.getProfile(token);
    if (mounted) setState(() { _profile = p; _loading = false; });
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.brand,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<String?> _editDialog(String title, String initial, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: const InputDecoration(isDense: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _editBirthday() async {
    final now = DateTime.now();
    DateTime initial = now.subtract(const Duration(days: 365 * 25));
    if (_profile?.birthday != null) {
      initial = DateTime.tryParse(_profile!.birthday!) ?? initial;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brand),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    _save({'birthday': picked.toIso8601String()},
        (p) => setState(() => _profile = p));
  }

  Future<void> _editGender() async {
    final l10n = AppLocalizations.of(context);
    String selected = _profile?.gender ?? 'secret';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.gender, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: _kGenders.entries.map((e) => RadioListTile<String>(
              value: e.key,
              groupValue: selected,
              title: Text(e.value),
              activeColor: AppColors.brand,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setS(() => selected = v!),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result == null) return;
    _save({'gender': result}, (p) => setState(() => _profile = p));
  }

  Future<void> _editMultiSelect(
      String title, List<String> options, List<String> current,
      Future<bool> Function(List<String>) onSave) async {
    final l10n = AppLocalizations.of(context);
    final selected = Set<String>.from(current);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (ctx, setS) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final on = selected.contains(opt);
                return FilterChip(
                  label: Text(opt, style: TextStyle(fontSize: 12, color: on ? Colors.white : AppColors.textPrimary)),
                  selected: on,
                  backgroundColor: AppColors.surfaceVariant,
                  selectedColor: AppColors.brand,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  onSelected: (_) => setS(() => on ? selected.remove(opt) : selected.add(opt)),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected.toList()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result == null) return;
    final ok = await onSave(result);
    if (ok && mounted) {
      _showSnack(l10n.preferencesUpdated);
      _loadProfile();
    }
  }

  Future<void> _save(Map<String, dynamic> fields, void Function(UserProfile) onSuccess) async {
    final l10n = AppLocalizations.of(context);
    final token = _auth.user?.token;
    if (token == null) return;
    final updated = await UserService.updateProfile(token, fields);
    if (updated != null) {
      onSuccess(updated);
      if (fields.containsKey('name')) _auth.updateName(fields['name']);
      _showSnack(l10n.savedMessage);
    } else {
      _showSnack(l10n.couldNotSaveChanges, error: true);
    }
  }

  Future<void> _editAddress() async {
    final l10n = AppLocalizations.of(context);
    final addr = _profile?.address ?? const ShippingAddress();
    final ctrls = {
      'fullName': TextEditingController(text: addr.fullName),
      'email':    TextEditingController(text: addr.email),
      'phone':    TextEditingController(text: addr.phone),
      'address1': TextEditingController(text: addr.address1),
      'address2': TextEditingController(text: addr.address2),
      'city':     TextEditingController(text: addr.city),
      'state':    TextEditingController(text: addr.state),
      'zipCode':  TextEditingController(text: addr.zipCode),
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bsCtx) {
        final bsL10n = AppLocalizations.of(bsCtx);
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(bsL10n.addAddress,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bsCtx)),
                  ],
                ),
                const SizedBox(height: 16),
                _addrField(ctrls['fullName']!, bsL10n.profileName),
                _addrField(ctrls['email']!, bsL10n.email, type: TextInputType.emailAddress),
                _addrField(ctrls['phone']!, bsL10n.profilePhone, type: TextInputType.phone),
                _addrField(ctrls['address1']!, bsL10n.address1),
                _addrField(ctrls['address2']!, bsL10n.address2Optional),
                _addrField(ctrls['city']!, bsL10n.city),
                Row(children: [
                  Expanded(child: _addrField(ctrls['state']!, bsL10n.state)),
                  const SizedBox(width: 12),
                  Expanded(child: _addrField(ctrls['zipCode']!, bsL10n.zipCode, type: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(bsCtx), child: Text(bsL10n.cancel)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final token = _auth.user?.token;
                        if (token == null) return;
                        final newAddr = ShippingAddress(
                          fullName: ctrls['fullName']!.text.trim(),
                          email:    ctrls['email']!.text.trim(),
                          phone:    ctrls['phone']!.text.trim(),
                          address1: ctrls['address1']!.text.trim(),
                          address2: ctrls['address2']!.text.trim(),
                          city:     ctrls['city']!.text.trim(),
                          state:    ctrls['state']!.text.trim(),
                          zipCode:  ctrls['zipCode']!.text.trim(),
                        );
                        final nav = Navigator.of(bsCtx);
                        final saved = await UserService.updateAddress(token, newAddr);
                        nav.pop();
                        if (saved != null) {
                          setState(() => _profile = UserProfile(
                            id: _profile!.id, name: _profile!.name,
                            lastName: _profile!.lastName,
                            email: _profile!.email, phone: _profile!.phone,
                            avatar: _profile!.avatar,
                            birthday: _profile!.birthday, gender: _profile!.gender,
                            address: saved, preferences: _profile!.preferences,
                            authProvider: _profile!.authProvider,
                          ));
                          _showSnack(l10n.addressSaved);
                        } else {
                          _showSnack(l10n.couldNotSaveAddress, error: true);
                        }
                      },
                      child: Text(bsL10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _addrField(TextEditingController ctrl, String label, {
    TextInputType type = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    final isLocal = _profile?.authProvider == 'local';
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) {
        final dlgL10n = AppLocalizations.of(dlgCtx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(dlgL10n.changePassword, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLocal) ...[
                TextField(controller: currentCtrl, obscureText: true,
                    decoration: InputDecoration(labelText: dlgL10n.currentPassword, isDense: true)),
                const SizedBox(height: 12),
              ],
              TextField(controller: newCtrl, obscureText: true,
                  decoration: InputDecoration(labelText: dlgL10n.newPassword, isDense: true)),
              const SizedBox(height: 12),
              TextField(controller: confirmCtrl, obscureText: true,
                  decoration: InputDecoration(labelText: dlgL10n.confirmNewPassword, isDense: true)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: Text(dlgL10n.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(dlgCtx, true),
              child: Text(dlgL10n.update),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    if (newCtrl.text != confirmCtrl.text) {
      _showSnack(l10n.passwordsDoNotMatch, error: true); return;
    }
    final token = _auth.user?.token;
    if (token == null) return;
    final err = await UserService.changePassword(
        token, isLocal ? currentCtrl.text : null, newCtrl.text);
    if (err == null) { _showSnack(l10n.passwordUpdated); }
    else             { _showSnack(err, error: true); }
  }

  Future<void> _logout() async {
    final nav = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(dl.profileLogoutButton,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text(dl.profileLogoutConfirm),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(dl.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dl.profileLogoutButton,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      _auth.signOut();
      nav.popUntil((r) => r.isFirst);
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) {
        final dlgL10n = AppLocalizations.of(dlgCtx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(dlgL10n.deleteAccount,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.danger)),
          content: Text(dlgL10n.deleteAccountConfirmation),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: Text(dlgL10n.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(dlgCtx, true),
              child: Text(dlgL10n.delete, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    final token = _auth.user?.token;
    if (token == null) return;
    final ok = await UserService.deleteAccount(token);
    if (ok) {
      _auth.signOut();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      _showSnack(l10n.couldNotDeleteAccount, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.profileSettings,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : _profile == null
              ? _errorView(l10n)
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 680 : double.infinity),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      children: [
                        _AvatarHeader(profile: _profile!),
                        const SizedBox(height: 24),

                        // ── Language ───────────────────────────────────────────
                        _SectionCard(
                          title: l10n.settingsLanguage,
                          children: [const LanguageSelector()],
                        ),
                        const SizedBox(height: 20),

                        // ── Account ───────────────────────────────────────────
                        _SectionCard(
                          title: l10n.account,
                          children: [
                            _FieldRow(
                              label: l10n.profileName,
                              value: _profile!.name,
                              onTap: () async {
                                final v = await _editDialog(l10n.profileName, _profile!.name);
                                if (v != null && v.isNotEmpty) _save({'name': v}, (p) => setState(() => _profile = p));
                              },
                            ),
                            _FieldRow(
                              label: l10n.profileLastName,
                              value: _profile!.lastName ?? l10n.notSet,
                              onTap: () async {
                                final v = await _editDialog(l10n.profileLastName, _profile!.lastName ?? '');
                                if (v != null) _save({'lastName': v}, (p) => setState(() => _profile = p));
                              },
                            ),
                            _FieldRow(
                              label: l10n.email,
                              value: _profile!.email,
                              onTap: () async {
                                final v = await _editDialog(l10n.email, _profile!.email,
                                    keyboardType: TextInputType.emailAddress);
                                if (v != null && v.isNotEmpty) _save({'email': v}, (p) => setState(() => _profile = p));
                              },
                            ),
                            _FieldRow(
                              label: l10n.profilePhone,
                              value: _profile!.phone ?? l10n.notSet,
                              onTap: () async {
                                final v = await _editDialog(l10n.profilePhone, _profile!.phone ?? '',
                                    keyboardType: TextInputType.phone);
                                if (v != null) _save({'phone': v}, (p) => setState(() => _profile = p));
                              },
                            ),
                            _FieldRow(
                              label: l10n.password,
                              value: '••••••••',
                              actionLabel: l10n.update,
                              onTap: _changePassword,
                            ),
                            _FieldRow(
                              label: l10n.birthday,
                              value: _profile!.birthday != null
                                  ? _formatDate(_profile!.birthday!)
                                  : l10n.notSet,
                              onTap: _editBirthday,
                            ),
                            _FieldRow(
                              label: l10n.gender,
                              value: _kGenders[_profile!.gender] ?? 'Keep secret',
                              onTap: _editGender,
                            ),
                            _FieldRow(
                              label: l10n.shippingAddress,
                              value: _profile!.address.isEmpty
                                  ? l10n.notSet
                                  : _profile!.address.address1,
                              actionLabel: l10n.update,
                              onTap: _editAddress,
                              last: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Alerts ────────────────────────────────────────────
                        _SectionCard(
                          title: l10n.alertSectionTitle,
                          children: [
                            _FieldRow(
                              label: l10n.profileMyAlerts,
                              value: l10n.alertGetNotified,
                              actionLabel: l10n.alertManage,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AlertsScreen()),
                              ),
                              last: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Shopping preferences ──────────────────────────────
                        _SectionCard(
                          title: l10n.shoppingPreferences,
                          children: [
                            _FieldRow(
                              label: l10n.categoryPreferences,
                              value: l10n.categoryPreferencesTitle,
                              actionLabel: l10n.update,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CategoryPreferencesScreen()),
                              ),
                            ),
                            _FieldRow(
                              label: l10n.storePreferences,
                              value: _profile!.preferences.stores.isEmpty
                                  ? l10n.notSet
                                  : _profile!.preferences.stores.join(', '),
                              actionLabel: l10n.update,
                              onTap: () => _editMultiSelect(
                                l10n.storePreferences,
                                _kStores,
                                _profile!.preferences.stores,
                                (list) async {
                                  final token = _auth.user?.token;
                                  if (token == null) return false;
                                  return UserService.updatePreferences(token, {'stores': list});
                                },
                              ),
                            ),
                            _FieldRow(
                              label: l10n.dealPriorities,
                              value: _profile!.preferences.dealPriorities.isEmpty
                                  ? l10n.notSet
                                  : _profile!.preferences.dealPriorities.join(', '),
                              actionLabel: l10n.update,
                              last: true,
                              onTap: () => _editMultiSelect(
                                l10n.dealPriorities,
                                _kDealPriorities,
                                _profile!.preferences.dealPriorities,
                                (list) async {
                                  final token = _auth.user?.token;
                                  if (token == null) return false;
                                  return UserService.updatePreferences(token, {'dealPriorities': list});
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Email preferences ─────────────────────────────────
                        _SectionCard(
                          title: l10n.emailPreference,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.emailPreferenceTitle,
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: AppColors.textPrimary)),
                                        const SizedBox(height: 3),
                                        Text(
                                          l10n.emailPreferenceDesc,
                                          style: GoogleFonts.inter(
                                              fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Switch.adaptive(
                                    value: _profile!.preferences.emailNotifications,
                                    activeColor: AppColors.brand,
                                    onChanged: (val) async {
                                      final token = _auth.user?.token;
                                      if (token == null) return;
                                      final ok = await UserService.updatePreferences(
                                          token, {'emailNotifications': val});
                                      if (ok) _loadProfile();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Log out ───────────────────────────────────────────
                        _SectionCard(
                          title: l10n.profileLogoutButton,
                          titleColor: AppColors.danger,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                                  label: Text(l10n.profileLogoutButton,
                                      style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(color: AppColors.danger),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Delete account ────────────────────────────────────
                        _SectionCard(
                          title: l10n.deleteAccount,
                          titleColor: AppColors.danger,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.deleteAccountDescription,
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.deleteAccountWarning,
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: _deleteAccount,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: const BorderSide(color: AppColors.danger),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(l10n.deleteAccountButton),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _errorView(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(l10n.couldNotLoadProfile,
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadProfile, child: Text(l10n.retry)),
          ],
        ),
      );

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _AvatarHeader extends StatelessWidget {
  final UserProfile profile;
  const _AvatarHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.brandLight,
          backgroundImage: profile.avatar != null ? NetworkImage(profile.avatar!) : null,
          child: profile.avatar == null
              ? Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 28))
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(profile.email,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
    this.titleColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: titleColor)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback onTap;
  final bool last;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.actionLabel,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveLabel = actionLabel ?? l10n.edit;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(effectiveLabel,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.brand)),
              ],
            ),
          ),
        ),
        if (!last)
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
      ],
    );
  }
}
