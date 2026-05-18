import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/locale/locale_provider.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await AuthService().init();
  runApp(
    const ProviderScope(
      child: PromOffApp(),
    ),
  );
}

class PromOffApp extends ConsumerWidget {
  const PromOffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'PromOff',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ShellScreen(),
    );
  }
}
