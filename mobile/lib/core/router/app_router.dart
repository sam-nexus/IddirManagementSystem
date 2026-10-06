import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/features/auth/presentation/change_pin_screen.dart';
import 'package:odaa_mobile/features/auth/presentation/login_screen.dart';
import 'package:odaa_mobile/features/splash/presentation/language_screen.dart';
import 'package:odaa_mobile/features/splash/presentation/splash_screen.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language',
        name: 'language',
        builder: (context, state) => const LanguageScreen(),
      ),
      // ---------- Placeholders for screens built in later replies ----------
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/change-pin',
        name: 'changePin',
        builder: (context, state) => const ChangePinScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const _PlaceholderScreen(name: 'Home'),
      ),
      GoRoute(
        path: '/months',
        name: 'months',
        builder: (context, state) => const _PlaceholderScreen(name: 'Months'),
      ),
      GoRoute(
        path: '/pay',
        name: 'pay',
        builder: (context, state) => const _PlaceholderScreen(name: 'Pay'),
      ),
      GoRoute(
        path: '/more',
        name: 'more',
        builder: (context, state) => const _PlaceholderScreen(name: 'More'),
      ),
    ],
    redirect: (context, state) {
      // Reserved for future redirect logic (auth guard).
      return null;
    },
  );
});

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: EmptyView(
        title: '$name — coming soon',
        body: 'This screen will be built in a later step.',
      ),
    );
  }
}
