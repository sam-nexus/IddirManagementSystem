import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/features/about/presentation/about_screen.dart';
import 'package:odaa_mobile/features/auth/presentation/change_pin_screen.dart';
import 'package:odaa_mobile/features/auth/presentation/login_screen.dart';
import 'package:odaa_mobile/features/history/presentation/history_screen.dart';
import 'package:odaa_mobile/features/home/presentation/home_screen.dart';
import 'package:odaa_mobile/features/months/presentation/months_screen.dart';
import 'package:odaa_mobile/features/pay/presentation/pay_screen.dart';
import 'package:odaa_mobile/features/profile/presentation/profile_screen.dart';
import 'package:odaa_mobile/features/receipt/presentation/receipt_screen.dart';
import 'package:odaa_mobile/features/shell/presentation/app_shell.dart';
import 'package:odaa_mobile/features/shell/presentation/widgets/canopy_bar.dart';
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
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language',
        name: 'language',
        builder: (_, __) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/change-pin',
        name: 'changePin',
        builder: (_, __) => const ChangePinScreen(),
      ),

      // ---------- Shell with the canopy ----------
      ShellRoute(
        builder: (context, state, child) {
          final section = _sectionFromLocation(state.uri.path);
          return AppShell(section: section, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/months',
            name: 'months',
            builder: (_, __) => const MonthsScreen(),
          ),
          GoRoute(
            path: '/pay',
            name: 'pay',
            builder: (context, state) => PayScreen(
              period: state.uri.queryParameters['period'],
            ),
          ),
          GoRoute(
            path: '/more',
            name: 'more',
            builder: (_, __) => const AboutScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/months/history',
            name: 'history',
            builder: (_, __) => const HistoryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'receipt',
                builder: (context, state) => ReceiptScreen(
                  paymentId: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

CanopySection _sectionFromLocation(String path) {
  if (path.startsWith('/months')) return CanopySection.months;
  if (path.startsWith('/pay')) return CanopySection.pay;
  if (path.startsWith('/more')) return CanopySection.more;
  return CanopySection.home;
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: '$name — coming soon',
      body: 'This screen will be built in a later step.',
    );
  }
}
