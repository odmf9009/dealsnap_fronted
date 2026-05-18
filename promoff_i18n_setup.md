# PromOff - Multilingual Setup Instructions for Claude Agent

## Goal

Set up complete internationalization (i18n) in the PromOff Flutter project supporting English (en) and Spanish (es) at launch, with a scalable architecture for adding more languages in the future.

If the project already has any localization implementation done differently (e.g., easy_localization, hardcoded strings, custom locale handling), **migrate it to this approach** by removing the old implementation and replacing it with what's described below.

---

## Step 1: Update `pubspec.yaml`

Make sure these dependencies and config are present. Add or modify if missing:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  flutter_riverpod: ^2.5.1
  shared_preferences: ^2.2.3

flutter:
  generate: true
```

Then run:

```bash
flutter pub get
```

If `easy_localization`, `flutter_translate`, `slang`, or any other localization package is in `pubspec.yaml`, **remove it**.

---

## Step 2: Create `l10n.yaml` in the project root

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
output-dir: lib/l10n/generated
nullable-getter: false
```

---

## Step 3: Create `lib/l10n/app_en.arb` (English template)

```json
{
  "@@locale": "en",

  "appName": "PromOff",
  "@appName": { "description": "Application name" },

  "homeTitle": "Today's best deals",
  "@homeTitle": { "description": "Title shown on the home screen" },

  "searchPlaceholder": "Search products...",
  "categories": "Categories",
  "discount": "Discount",
  "store": "Store",
  "discountType": "Discount Type",

  "sortBy": "Sort by",
  "sortHighestDiscount": "Highest discount",
  "sortHighestPrice": "Highest price",
  "sortExpiringSoon": "Expiring soon",

  "mostPopular": "Most Popular",
  "bestSellers": "Best Sellers",
  "dealsOfTheBrand": "Deals of the Brand",
  "amazonPromoCodes": "Amazon Promo Codes",
  "viewAll": "View all",
  "shopNow": "Shop now",

  "navHome": "Home",
  "navPromoCodes": "Promo Codes",
  "navComingSoon": "Coming Soon",
  "navComingEnd": "Ending Soon",

  "topPick": "Top Pick",
  "popular": "Popular",
  "promoCode": "PROMO CODE",
  "getCode": "Get Code",
  "off": "OFF",

  "loginTitle": "Welcome to PromOff",
  "loginSubtitle": "Save more on your favorite Amazon products",
  "email": "Email",
  "password": "Password",
  "signIn": "Sign in",
  "signUp": "Sign up",
  "continueWithGoogle": "Continue with Google",
  "forgotPassword": "Forgot password?",
  "dontHaveAccount": "Don't have an account?",
  "alreadyHaveAccount": "Already have an account?",

  "profileTitle": "Profile",
  "profileEditPhoto": "Edit photo",
  "profileName": "Name",
  "profilePhone": "Phone",
  "profileSave": "Save changes",
  "profileMyAlerts": "My alerts",
  "profileLogout": "Log out",

  "alertConfigTitle": "Set alert",
  "alertNotifyPriceDrop": "Notify me when price drops to:",
  "alertNotifyDiscountReaches": "Notify me when discount reaches:",
  "alertNotifyPromoLive": "Notify me when this upcoming promo goes live",
  "alertNotifyPromoExpiring": "Notify me when this promo is about to expire",
  "alertSave": "Save alert",
  "alertDelete": "Delete alert",
  "alertSavedAt": "Alert set for {date}",
  "@alertSavedAt": {
    "placeholders": {
      "date": { "type": "DateTime", "format": "yMMMd" }
    }
  },

  "settingsTitle": "Settings",
  "settingsLanguage": "Language",
  "settingsNotifications": "Notifications",
  "settingsTheme": "Theme",
  "settingsTermsConditions": "Terms and Conditions",
  "settingsPrivacyPolicy": "Privacy Policy",
  "settingsAbout": "About",
  "settingsVersion": "Version {version}",
  "@settingsVersion": {
    "placeholders": { "version": { "type": "String" } }
  },

  "notificationsTitle": "Notifications",
  "notificationsEmpty": "You have no notifications yet",

  "hello": "Hello, {name}!",
  "@hello": {
    "placeholders": { "name": { "type": "String" } }
  },

  "itemsCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemsCount": {
    "placeholders": { "count": { "type": "int" } }
  },

  "errorGeneric": "Something went wrong. Please try again.",
  "errorNoInternet": "No internet connection",
  "retry": "Retry",
  "cancel": "Cancel",
  "confirm": "Confirm",
  "delete": "Delete",
  "edit": "Edit",
  "save": "Save",
  "close": "Close"
}
```

---

## Step 4: Create `lib/l10n/app_es.arb` (Spanish translations)

```json
{
  "@@locale": "es",

  "appName": "PromOff",
  "homeTitle": "Las mejores ofertas de hoy",
  "searchPlaceholder": "Buscar productos...",
  "categories": "Categorías",
  "discount": "Descuento",
  "store": "Tienda",
  "discountType": "Tipo de descuento",

  "sortBy": "Ordenar por",
  "sortHighestDiscount": "Mayor descuento",
  "sortHighestPrice": "Mayor precio",
  "sortExpiringSoon": "Caducan pronto",

  "mostPopular": "Más populares",
  "bestSellers": "Más vendidos",
  "dealsOfTheBrand": "Ofertas de la marca",
  "amazonPromoCodes": "Códigos promocionales de Amazon",
  "viewAll": "Ver todo",
  "shopNow": "Comprar ahora",

  "navHome": "Inicio",
  "navPromoCodes": "Códigos promo",
  "navComingSoon": "Próximamente",
  "navComingEnd": "Caducan pronto",

  "topPick": "Mejor elección",
  "popular": "Popular",
  "promoCode": "CÓDIGO PROMO",
  "getCode": "Obtener código",
  "off": "DESC.",

  "loginTitle": "Bienvenido a PromOff",
  "loginSubtitle": "Ahorra más en tus productos favoritos de Amazon",
  "email": "Correo electrónico",
  "password": "Contraseña",
  "signIn": "Iniciar sesión",
  "signUp": "Registrarse",
  "continueWithGoogle": "Continuar con Google",
  "forgotPassword": "¿Olvidaste tu contraseña?",
  "dontHaveAccount": "¿No tienes cuenta?",
  "alreadyHaveAccount": "¿Ya tienes cuenta?",

  "profileTitle": "Perfil",
  "profileEditPhoto": "Editar foto",
  "profileName": "Nombre",
  "profilePhone": "Teléfono",
  "profileSave": "Guardar cambios",
  "profileMyAlerts": "Mis alertas",
  "profileLogout": "Cerrar sesión",

  "alertConfigTitle": "Configurar alerta",
  "alertNotifyPriceDrop": "Avísame cuando el precio baje a:",
  "alertNotifyDiscountReaches": "Avísame cuando el descuento alcance:",
  "alertNotifyPromoLive": "Avísame cuando esta promoción esté disponible",
  "alertNotifyPromoExpiring": "Avísame cuando esta promoción esté a punto de caducar",
  "alertSave": "Guardar alerta",
  "alertDelete": "Eliminar alerta",
  "alertSavedAt": "Alerta programada para {date}",

  "settingsTitle": "Ajustes",
  "settingsLanguage": "Idioma",
  "settingsNotifications": "Notificaciones",
  "settingsTheme": "Tema",
  "settingsTermsConditions": "Términos y condiciones",
  "settingsPrivacyPolicy": "Política de privacidad",
  "settingsAbout": "Acerca de",
  "settingsVersion": "Versión {version}",

  "notificationsTitle": "Notificaciones",
  "notificationsEmpty": "Aún no tienes notificaciones",

  "hello": "¡Hola, {name}!",
  "itemsCount": "{count, plural, =0{Sin artículos} =1{1 artículo} other{{count} artículos}}",

  "errorGeneric": "Algo salió mal. Por favor, inténtalo de nuevo.",
  "errorNoInternet": "Sin conexión a internet",
  "retry": "Reintentar",
  "cancel": "Cancelar",
  "confirm": "Confirmar",
  "delete": "Eliminar",
  "edit": "Editar",
  "save": "Guardar",
  "close": "Cerrar"
}
```

---

## Step 5: Generate localization classes

After creating the ARB files, run:

```bash
flutter gen-l10n
```

This creates the auto-generated `AppLocalizations` class at `lib/l10n/generated/app_localizations.dart`.

Add `lib/l10n/generated/` to `.gitignore` if you want to keep it out of version control (recommended for cleaner diffs).

---

## Step 6: Create `lib/core/locale/locale_provider.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier that holds the current app locale and persists it to SharedPreferences.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  static const _prefsKey = 'app_locale';

  /// Loads the saved locale from SharedPreferences (or system locale on first run).
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);

    if (savedCode != null) {
      state = Locale(savedCode);
    } else {
      // Fallback to system locale if supported, otherwise English
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (supportedLanguageCodes.contains(systemLocale.languageCode)) {
        state = Locale(systemLocale.languageCode);
      }
    }
  }

  /// Updates the app locale and persists the choice.
  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguageCodes.contains(locale.languageCode)) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// Convenience getter for languages this app supports.
  static const supportedLanguageCodes = ['en', 'es'];
}

/// Global provider exposing the current locale to the widget tree.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
```

---

## Step 7: Integrate into `MaterialApp` (in `lib/app/app.dart` or wherever your `MaterialApp` lives)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:promoff/core/locale/locale_provider.dart';
import 'package:promoff/l10n/generated/app_localizations.dart';

class PromOffApp extends ConsumerWidget {
  const PromOffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'PromOff',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // theme: ...
      // home: ...
    );
  }
}
```

If using `MaterialApp.router` with GoRouter, the integration is the same — just keep `locale`, `localizationsDelegates`, and `supportedLocales` properties.

---

## Step 8: Make sure `main.dart` wraps the app in `ProviderScope`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:promoff/app/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PromOffApp(),
    ),
  );
}
```

---

## Step 9: Use translations in any widget

```dart
import 'package:flutter/material.dart';
import 'package:promoff/l10n/generated/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Column(
        children: [
          Text(l10n.searchPlaceholder),
          Text(l10n.hello('Orlando')),
          Text(l10n.itemsCount(5)),
          Text(l10n.bestSellers),
        ],
      ),
    );
  }
}
```

**Rule:** never hardcode strings. If you find hardcoded strings in existing code, move them to the ARB files and replace them with `l10n.keyName`.

---

## Step 10: Build a language selector for the Settings screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:promoff/core/locale/locale_provider.dart';
import 'package:promoff/l10n/generated/app_localizations.dart';

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
```

---

## Step 11: (Optional) Format dates and currencies with `intl`

```dart
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

String formatPrice(BuildContext context, double price) {
  final localeCode = Localizations.localeOf(context).toString();
  // Use EUR for Spanish locale, USD otherwise (adjust as needed)
  final symbol = localeCode.startsWith('es') ? '€' : '\$';
  return NumberFormat.currency(locale: localeCode, symbol: symbol).format(price);
}

String formatDate(BuildContext context, DateTime date) {
  final localeCode = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(localeCode).format(date);
}
```

---

## Adding more languages later

To add, e.g., French in the future:

1. Create `lib/l10n/app_fr.arb` with all the same keys translated to French
2. Add `'fr'` to `LocaleNotifier.supportedLanguageCodes`
3. Add a new `DropdownMenuItem(value: Locale('fr'), child: Text('Français'))` in the language selector
4. Run `flutter gen-l10n`

That's it — no other code changes needed.

---

## Migration notes

If the project already has localization done differently (e.g., easy_localization, hardcoded strings, custom JSON files):

1. **Remove old packages** from `pubspec.yaml` (e.g., `easy_localization`, `flutter_translate`).
2. **Delete old translation files** (e.g., `assets/translations/*.json`, custom locale services).
3. **Find all `tr()`, `'string'.tr`, or hardcoded strings** in the codebase, move them into the new ARB files, and replace usage with `AppLocalizations.of(context).keyName`.
4. **Remove old `EasyLocalization` widgets** from the widget tree and replace with the `MaterialApp` configuration described in Step 7.
5. **Remove old locale provider/state** and replace with the Riverpod-based `LocaleNotifier` from Step 6.
6. Run `flutter pub get && flutter gen-l10n` to regenerate.
7. Verify no missing translations by testing both languages end-to-end.

---

## Final checklist

- [ ] `pubspec.yaml` updated with `flutter_localizations`, `intl`, `flutter_riverpod`, `shared_preferences`
- [ ] `flutter: generate: true` enabled
- [ ] `l10n.yaml` created at root
- [ ] `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb` created
- [ ] `flutter gen-l10n` run successfully
- [ ] `lib/core/locale/locale_provider.dart` created
- [ ] `MaterialApp` wired up with `locale`, `localizationsDelegates`, `supportedLocales`
- [ ] `main.dart` wraps app in `ProviderScope`
- [ ] Language selector working in Settings screen
- [ ] All existing hardcoded strings migrated to ARB
- [ ] Old localization implementation removed (if any)
- [ ] App tested in both English and Spanish

---

## Final structure

```
promoff/
├── pubspec.yaml
├── l10n.yaml
└── lib/
    ├── main.dart
    ├── app/
    │   └── app.dart
    ├── core/
    │   └── locale/
    │       └── locale_provider.dart
    └── l10n/
        ├── app_en.arb
        ├── app_es.arb
        └── generated/
            └── app_localizations.dart   (auto-generated)
```
