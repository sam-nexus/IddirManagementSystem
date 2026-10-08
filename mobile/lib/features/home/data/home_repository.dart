import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/home/data/models/home_summary.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

class HomeRepository {
  HomeRepository(this._api);

  final ApiClient _api;

  Future<HomeSummary> fetchSummary({required String memberId}) async {
    // Two calls in parallel: my-dues and the newest announcement.
    final results = await Future.wait([
      _api.get<Map<String, dynamic>>('/contributions/my-dues'),
      _api.get<Map<String, dynamic>>('/announcements', query: {'limit': 1}),
    ]);

    final dues = results[0];
    final announcementsResponse = results[1];
    final announcements =
        (announcementsResponse['items'] as List<dynamic>?) ?? const <dynamic>[];

    final items = (dues['items'] as List).cast<Map<String, dynamic>>();
    final summary = dues['summary'] as Map<String, dynamic>;

    // Convert to 12 slots for the current year.
    final now = DateTime.now();
    final byMonth = <int, ContributionState>{};
    for (final row in items) {
      final period = DateTime.parse(row['period'] as String);
      if (period.year != now.year) continue;
      byMonth[period.month] = _toState(row['status'] as String);
    }

    final months = List.generate(12, (i) {
      final m = i + 1;
      if (byMonth.containsKey(m)) return byMonth[m]!;
      // Future months with no row show pending; past months with no row show unpaid.
      final isFuture = m > now.month;
      return isFuture ? ContributionState.pending : ContributionState.unpaid;
    });

    final penalties = summary['penalties'] as Map<String, dynamic>? ?? {};
    final duesBalance = double.tryParse('${summary['dues_balance']}') ?? 0;
    final penaltiesBalance =
        double.tryParse('${penalties['unpaid_total']}') ?? 0;
    final monthsPaid = months.where((m) => m == ContributionState.paid).length;

    NoticeTeaser? notice;
    if (announcements.isNotEmpty) {
      final a = announcements.first as Map<String, dynamic>;
      notice = NoticeTeaser(
        id: a['id'] as String,
        titleEn: (a['title_en'] as String?) ?? '',
        titleOm: (a['title_om'] as String?) ?? '',
        publishedAt: DateTime.parse(a['published_at'] as String),
        isUrgent: (a['is_urgent'] as bool?) ?? false,
      );
    }

    return HomeSummary(
      firstName: 'Member', // will come from /auth/me in a later reply
      months: months,
      currentMonthIndex: now.month - 1,
      duesBalance: duesBalance,
      penaltiesBalance: penaltiesBalance,
      currency: 'ETB',
      monthsPaid: monthsPaid,
      monthsTotal: 12,
      latestNotice: notice,
      nextMeeting: null, // wire in a later reply
    );
  }

  ContributionState _toState(String backendStatus) {
    switch (backendStatus) {
      case 'paid':
        return ContributionState.paid;
      case 'waived':
        return ContributionState.waived;
      case 'unpaid':
      case 'partial':
        return ContributionState.unpaid;
      default:
        return ContributionState.pending;
    }
  }
}
