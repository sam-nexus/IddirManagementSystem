import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/l10n/om_fallback_delegates.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/providers/theme_provider.dart';
import 'package:odaa_mobile/core/push/push_service.dart';
import 'package:odaa_mobile/core/router/app_router.dart';
import 'package:odaa_mobile/core/storage/prefs_store.dart';
import 'package:odaa_mobile/core/theme/app_theme.dart';
import 'package:odaa_mobile/firebase_options.dart';
import 'package:odaa_mobile/l10n/app_localizations.dart';
import 'package:odaa_mobile/shared/widgets/welcome_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

// Firebase must be initialized before any Firebase service is used.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background handler (used when the app is closed).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: '.env');
  final prefs = await PrefsStore.open();

  // Sync the calendar library with the stored preference.
  AppDate.calendar = prefs.readCalendarSystem() == 'ethiopian'
      ? CalendarSystem.ethiopian
      : CalendarSystem.gregorian;


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

        // Initialize push on first app start.
    ref.listen<SessionState>(sessionProvider, (prev, next) {
      if (prev is! SessionSignedIn && next is SessionSignedIn) {
        ref.read(pushServiceProvider).initialize();
      }
    });

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
      themeMode: ref.watch(themeModeProvider),
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
