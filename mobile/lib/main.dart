import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/l10n/om_fallback_delegates.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/router/app_router.dart';
import 'package:odaa_mobile/core/storage/prefs_store.dart';
import 'package:odaa_mobile/core/theme/app_theme.dart';
import 'package:odaa_mobile/l10n/app_localizations.dart';
import 'package:odaa_mobile/shared/widgets/welcome_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final prefs = await PrefsStore.open();
  runApp(
    ProviderScope(
      overrides: [prefsStoreProvider.overrideWithValue(prefs)],
      child: const OdaaApp(),
    ),
  );
}

class OdaaApp extends ConsumerWidget {
  const OdaaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lang = ref.watch(languageProvider);

    final api = ref.watch(apiClientProvider);
    api.onSessionExpired = () {
      router.goNamed('login');
    };

    // Welcome toast: fire once when the session transitions from
    // signed-out (or unknown) to signed-in. Do not fire on Home remount.
    ref.listen<SessionState>(sessionProvider, (previous, next) {
      final wasSignedOut = previous is! SessionSignedIn;
      final nowSignedIn = next is SessionSignedIn;

      if (wasSignedOut && nowSignedIn) {
        final firstName = next.firstName.isEmpty ? 'friend' : next.firstName;
        WelcomeBanner.show(
          context,
          title: 'Akkam, $firstName',
          subtitle: 'You are standing in the shade.',
          icon: Icons.eco_outlined,
        );
      }
    });

    return MaterialApp.router(
      title: 'Afoosha Odaa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: lang ?? const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('om')],
      localizationsDelegates: const [
        // Our own generated app strings (app_en.arb / app_om.arb)
        AppLocalizations.delegate,

        // Oromo fallbacks — route 'om' to English for the built-in strings
        OmMaterialLocalizationsDelegate(),
        OmWidgetsLocalizationsDelegate(),
        OmCupertinoLocalizationsDelegate(),

        // Normal delegates for every other locale (including 'en')
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
