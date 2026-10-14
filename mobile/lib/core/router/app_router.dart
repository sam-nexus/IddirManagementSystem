import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/features/about/presentation/about_screen.dart';
import 'package:odaa_mobile/features/announcements/presentation/announcement_detail_screen.dart';
import 'package:odaa_mobile/features/announcements/presentation/announcements_screen.dart';
import 'package:odaa_mobile/features/auth/presentation/change_pin_screen.dart';
import 'package:odaa_mobile/features/auth/presentation/login_screen.dart';
import 'package:odaa_mobile/features/dependents/presentation/dependents_screen.dart';
import 'package:odaa_mobile/features/history/presentation/history_screen.dart';
import 'package:odaa_mobile/features/home/presentation/home_screen.dart';
import 'package:odaa_mobile/features/meetings/presentation/meeting_detail_screen.dart';
import 'package:odaa_mobile/features/meetings/presentation/meetings_screen.dart';
import 'package:odaa_mobile/features/months/presentation/months_screen.dart';
import 'package:odaa_mobile/features/pay/presentation/manual_payment_screen.dart';
import 'package:odaa_mobile/features/pay/presentation/pay_screen.dart';
import 'package:odaa_mobile/features/profile/presentation/profile_screen.dart';
import 'package:odaa_mobile/features/receipt/presentation/receipt_screen.dart';
import 'package:odaa_mobile/features/reports/presentation/report_detail_screen.dart';
import 'package:odaa_mobile/features/reports/presentation/reports_screen.dart';
import 'package:odaa_mobile/features/shell/presentation/app_shell.dart';
import 'package:odaa_mobile/features/shell/presentation/more_hub_screen.dart';
import 'package:odaa_mobile/features/shell/presentation/widgets/canopy_bar.dart';
import 'package:odaa_mobile/features/splash/presentation/language_screen.dart';
import 'package:odaa_mobile/features/splash/presentation/splash_screen.dart';
import 'package:odaa_mobile/features/support/presentation/submit_support_screen.dart';
import 'package:odaa_mobile/features/support/presentation/support_request_detail_screen.dart';
import 'package:odaa_mobile/features/support/presentation/support_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // ---------- Public ----------
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
            routes: [
              GoRoute(
                path: 'history',
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
          GoRoute(
            path: '/pay',
            name: 'pay',
            builder: (context, state) => PayScreen(
              period: state.uri.queryParameters['period'],
            ),
            routes: [
              GoRoute(
                path: 'manual',
                name: 'manualPayment',
                builder: (_, __) => const ManualPaymentScreen(),
              ),
            ],
          ),

          GoRoute(
            path: 'meetings',
            name: 'meetings',
            builder: (_, __) => const MeetingsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'meetingDetail',
                builder: (context, state) => MeetingDetailScreen(
                  id: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),

          // ---------- More hub and its children ----------
          GoRoute(
            path: '/more',
            name: 'more',
            builder: (_, __) => const MoreHubScreen(),
            routes: [
              GoRoute(
                path: 'about',
                name: 'about',
                builder: (_, __) => const AboutScreen(),
              ),
              GoRoute(
                path: 'profile',
                name: 'profile',
                builder: (_, __) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'announcements',
                name: 'announcements',
                builder: (_, __) => const AnnouncementsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'announcementDetail',
                    builder: (context, state) => AnnouncementDetailScreen(
                      id: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'reports',
                name: 'reports',
                builder: (_, __) => const ReportsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'reportDetail',
                    builder: (context, state) => ReportDetailScreen(
                      id: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'support',
                name: 'support',
                builder: (_, __) => const SupportScreen(),
                routes: [
                  GoRoute(
                    path: 'submit',
                    name: 'supportSubmit',
                    builder: (_, __) => const SubmitSupportScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'supportDetail',
                    builder: (context, state) => SupportRequestDetailScreen(
                      id: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'dependents',
                name: 'dependents',
                builder: (_, __) => const DependentsScreen(),
              ),
              // Meetings route will be added in Reply 16 once the screen exists.
            ],
          ),
        ],
      ),
    ],
  );
});

/// Determines which canopy section is highlighted for a given URL.
CanopySection _sectionFromLocation(String path) {
  if (path.startsWith('/months')) return CanopySection.months;
  if (path.startsWith('/pay')) return CanopySection.pay;
  if (path.startsWith('/more')) return CanopySection.more;
  return CanopySection.home;
}
