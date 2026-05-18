import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  static const _prefsKey = 'app_locale';

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);

    if (savedCode != null) {
      state = Locale(savedCode);
    } else {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (supportedLanguageCodes.contains(systemLocale.languageCode)) {
        state = Locale(systemLocale.languageCode);
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguageCodes.contains(locale.languageCode)) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  static const supportedLanguageCodes = ['en', 'es'];
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
