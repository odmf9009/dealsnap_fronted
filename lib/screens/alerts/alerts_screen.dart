import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/alert.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'alert_form_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _auth = AuthService();
  List<AlertModel> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = _auth.user?.token;
    if (token == null) return;
    final list = await AlertService.getAlerts(token);
    if (mounted) setState(() { _alerts = list; _loading = false; });
  }

  Future<void> _openForm({AlertModel? alert}) async {
    final result = await Navigator.push<AlertModel>(
      context,
      MaterialPageRoute(builder: (_) => AlertFormScreen(alert: alert)),
    );
    if (result != null) {
      setState(() {
        if (alert == null) {
          _alerts.insert(0, result);
        } else {
          final i = _alerts.indexWhere((a) => a.id == result.id);
          if (i != -1) _alerts[i] = result;
        }
      });
    }
  }

  Future<void> _toggleActive(AlertModel alert) async {
    final token = _auth.user?.token;
    if (token == null) return;
    final updated = await AlertService.updateAlert(
        token, alert.id, {'active': !alert.active});
    if (updated != null && mounted) {
      setState(() {
        final i = _alerts.indexWhere((a) => a.id == updated.id);
        if (i != -1) _alerts[i] = updated;
      });
    }
  }

  Future<void> _delete(AlertModel alert) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(dl.alertDeleteTitle,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text(dl.alertDeleteConfirm(alert.displayName),
              style: GoogleFonts.inter(fontSize: 14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(dl.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dl.delete, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    final token = _auth.user?.token;
    if (token == null) return;
    final ok = await AlertService.deleteAlert(token, alert.id);
    if (ok && mounted) {
      setState(() => _alerts.removeWhere((a) => a.id == alert.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.alertsTitle,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.brand,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(l10n.alertNewButton,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : _alerts.isEmpty
              ? _EmptyView(onAdd: () => _openForm())
              : RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _AlertTile(
                      alert: _alerts[i],
                      onEdit: () => _openForm(alert: _alerts[i]),
                      onToggle: () => _toggleActive(_alerts[i]),
                      onDelete: () => _delete(_alerts[i]),
                    ),
                  ),
                ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AlertTile({
    required this.alert,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isProduct = alert.type == 'product';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isProduct ? AppColors.brandLight : AppColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isProduct ? Icons.inventory_2_outlined : Icons.storefront_outlined,
                size: 18,
                color: isProduct ? AppColors.brand : AppColors.accent,
              ),
            ),
            title: Text(
              alert.displayName,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: alert.active ? AppColors.textPrimary : AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(alert.conditionText,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit')   onEdit();
                if (v == 'toggle') onToggle();
                if (v == 'delete') onDelete();
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit',
                    child: _popItem(Icons.edit_outlined, l10n.edit)),
                PopupMenuItem(
                  value: 'toggle',
                  child: _popItem(
                    alert.active
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    alert.active ? l10n.alertPause : l10n.alertResume,
                  ),
                ),
                PopupMenuItem(value: 'delete',
                    child: _popItem(Icons.delete_outline_rounded, l10n.delete,
                        color: AppColors.danger)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _Tag(
                  label: isProduct ? l10n.alertTypeProduct : l10n.alertTypeBrand,
                  color: isProduct ? AppColors.brandLight : AppColors.accentLight,
                  textColor: isProduct ? AppColors.brand : AppColors.accent,
                ),
                const SizedBox(width: 6),
                if (alert.channels.contains('email'))
                  const _Tag(
                    label: 'Email',
                    color: Color(0xFFEDE9FE),
                    textColor: Color(0xFF8B5CF6),
                  ),
                const Spacer(),
                _StatusBadge(active: alert.active),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _popItem(IconData icon, String label, {Color? color}) => Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color ?? AppColors.textPrimary)),
        ],
      );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Tag({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
      );
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.brand : AppColors.textMuted,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          active ? l10n.alertActive : l10n.alertPaused,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.brand : AppColors.textMuted),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.brandLight, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_outlined,
                  size: 36, color: AppColors.brand),
            ),
            const SizedBox(height: 16),
            Text(l10n.alertNoAlerts,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              l10n.alertNoAlertsDesc,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.alertCreateButton),
            ),
          ],
        ),
      ),
    );
  }
}
