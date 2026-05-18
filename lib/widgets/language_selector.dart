import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/locale/locale_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    return ListTile(
      title: Text(l10n.settingsLanguage),
      trailing: DropdownButton<Locale>(
        value: currentLocale,
        underline: const SizedBox(),
        dropdownColor: AppColors.surfaceVariant,
        style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600, fontSize: 15),
        iconEnabledColor: AppColors.brand,
        items: const [
          DropdownMenuItem(
            value: Locale('en'),
            child: Text('English'),
          ),
          DropdownMenuItem(
            value: Locale('es'),
            child: Text('Español'),
          ),
        ],
        onChanged: (locale) {
          if (locale != null) {
            ref.read(localeProvider.notifier).setLocale(locale);
          }
        },
      ),
    );
  }
}
