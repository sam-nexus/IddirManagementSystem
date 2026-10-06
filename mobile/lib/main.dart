import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/router/app_router.dart';
import 'package:odaa_mobile/core/storage/prefs_store.dart';
import 'package:odaa_mobile/core/theme/app_theme.dart';
import 'package:odaa_mobile/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await PrefsStore.open();
  runApp(ProviderScope(
    overrides: [prefsStoreProvider.overrideWithValue(prefs)],
    child: const OdaaApp(),
  ),);
}

class OdaaApp extends ConsumerWidget {
  const OdaaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lang = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'Afoosha Odaa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: lang,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}