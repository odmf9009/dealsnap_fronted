import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/alert.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AlertFormScreen extends StatefulWidget {
  final AlertModel? alert;

  const AlertFormScreen({super.key, this.alert});

  @override
  State<AlertFormScreen> createState() => _AlertFormScreenState();
}

class _AlertFormScreenState extends State<AlertFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  String _type = 'product';
  final _asinCtrl    = TextEditingController();
  final _titleCtrl   = TextEditingController();
  final _brandCtrl   = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _priceCtrl   = TextEditingController();
  bool _notifyExpiry  = false;
  bool _emailChannel  = true;
  bool _active        = true;
  bool _saving        = false;

  @override
  void initState() {
    super.initState();
    final a = widget.alert;
    if (a != null) {
      _type           = a.type;
      _asinCtrl.text  = a.productAsin ?? '';
      _titleCtrl.text = a.productTitle ?? '';
      _brandCtrl.text = a.brandName ?? '';
      _discountCtrl.text = a.discountThreshold?.toInt().toString() ?? '';
      _priceCtrl.text    = a.priceTarget?.toStringAsFixed(2) ?? '';
      _notifyExpiry   = a.notifyExpiry;
      _emailChannel   = a.channels.contains('email');
      _active         = a.active;
    }
  }

  @override
  void dispose() {
    _asinCtrl.dispose(); _titleCtrl.dispose(); _brandCtrl.dispose();
    _discountCtrl.dispose(); _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final token = _auth.user?.token;
    if (token == null) return;

    setState(() => _saving = true);

    final body = <String, dynamic>{
      'type': _type,
      if (_type == 'product') ...{
        'productAsin': _asinCtrl.text.trim(),
        if (_titleCtrl.text.trim().isNotEmpty) 'productTitle': _titleCtrl.text.trim(),
      },
      if (_type == 'brand') 'brandName': _brandCtrl.text.trim(),
      if (_discountCtrl.text.trim().isNotEmpty)
        'discountThreshold': double.parse(_discountCtrl.text.trim()),
      if (_priceCtrl.text.trim().isNotEmpty)
        'priceTarget': double.parse(_priceCtrl.text.trim()),
      'notifyExpiry': _notifyExpiry,
      'channels': _emailChannel ? ['email'] : [],
      'active': _active,
    };

    AlertModel? result;
    if (widget.alert == null) {
      result = await AlertService.createAlert(token, body);
    } else {
      result = await AlertService.updateAlert(token, widget.alert!.id, body);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (result != null) {
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.alertCouldNotSave),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.alert != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          isEdit ? l10n.alertEdit : l10n.alertNew,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(l10n.save,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.brand, fontSize: 15)),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
          children: [
            _Label(l10n.alertType),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: l10n.alertTypeProduct,
                  icon: Icons.inventory_2_outlined,
                  selected: _type == 'product',
                  onTap: () => setState(() => _type = 'product'),
                ),
                const SizedBox(width: 10),
                _TypeChip(
                  label: l10n.alertTypeBrand,
                  icon: Icons.storefront_outlined,
                  selected: _type == 'brand',
                  onTap: () => setState(() => _type = 'brand'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_type == 'product') ...[
              _Label(l10n.alertProductAsin),
              const SizedBox(height: 8),
              TextFormField(
                controller: _asinCtrl,
                decoration: InputDecoration(
                  hintText: l10n.alertProductAsinHint,
                  prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: AppColors.textMuted),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.alertAsinRequired : null,
              ),
              const SizedBox(height: 14),
              _Label(l10n.alertProductNameOptional),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(hintText: 'e.g. Sony WH-1000XM5'),
              ),
            ] else ...[
              _Label(l10n.alertBrandNameLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _brandCtrl,
                decoration: InputDecoration(
                  hintText: l10n.alertBrandNameHint,
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.textMuted),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.alertBrandRequired : null,
              ),
            ],

            const SizedBox(height: 24),
            _Divider(label: l10n.alertTriggerConditions),
            const SizedBox(height: 14),

            _Label(l10n.alertMinDiscount),
            const SizedBox(height: 8),
            TextFormField(
              controller: _discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: InputDecoration(
                hintText: 'e.g. 30',
                prefixIcon: const Icon(Icons.percent_rounded, size: 18, color: AppColors.textMuted),
                suffixText: '%',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v.trim());
                if (n == null || n < 0 || n > 100) return l10n.alertDiscountRange;
                return null;
              },
            ),
            const SizedBox(height: 14),

            _Label(l10n.alertMaxPrice),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 99.99',
                prefixIcon: const Icon(Icons.attach_money_rounded, size: 18, color: AppColors.textMuted),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v.trim());
                if (n == null || n < 0) return l10n.alertPriceInvalid;
                return null;
              },
            ),
            const SizedBox(height: 14),

            SwitchListTile.adaptive(
              value: _notifyExpiry,
              onChanged: (v) => setState(() => _notifyExpiry = v),
              activeColor: AppColors.brand,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.alertNotifyBeforeExpiry,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.alertNotifyBeforeExpiryDesc,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ),

            const SizedBox(height: 24),
            _Divider(label: l10n.alertChannels),
            const SizedBox(height: 14),

            SwitchListTile.adaptive(
              value: _emailChannel,
              onChanged: (v) => setState(() => _emailChannel = v),
              activeColor: AppColors.brand,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.alertEmailChannel,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.alertEmailChannelDesc,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ),

            if (isEdit) ...[
              const SizedBox(height: 24),
              _Divider(label: l10n.alertStatusSection),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                activeColor: AppColors.brand,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.alertActiveLabel,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      );
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          const Expanded(child: Divider(height: 1, color: AppColors.divider)),
        ],
      );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.brand : AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
}
