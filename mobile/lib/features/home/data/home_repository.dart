import 'package:odaa_mobile/features/home/data/models/home_summary.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

abstract interface class HomeRepository {
  Future<HomeSummary> fetchSummary({required String memberId});
}

class MockHomeRepository implements HomeRepository {
  @override
  Future<HomeSummary> fetchSummary({required String memberId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return HomeSummary(
      firstName: 'Abebe',
      months: const [
        ContributionState.paid,     // Jan
        ContributionState.paid,     // Feb
        ContributionState.paid,     // Mar
        ContributionState.paid,     // Apr
        ContributionState.paid,     // May
        ContributionState.unpaid,   // Jun
        ContributionState.paid,     // Jul
        ContributionState.waived,   // Aug
        ContributionState.paid,     // Sep
        ContributionState.paid,     // Oct
        ContributionState.unpaid,   // Nov
        ContributionState.pending,  // Dec
      ],
      currentMonthIndex: 10,
      duesBalance: 200.00,
      penaltiesBalance: 20.00,
      currency: 'ETB',
      monthsPaid: 7,
      monthsTotal: 12,
      latestNotice: NoticeTeaser(
        id: 'notice-1',
        titleEn: 'Annual general meeting on 15 December',
        titleOm: 'Walga\'ii waliigalaa baraa Muddee 15',
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
        isUrgent: false,
      ),
      nextMeeting: MeetingTeaser(
        id: 'meeting-1',
        titleEn: 'Committee meeting',
        titleOm: 'Walga\'ii koree',
        scheduledAt: DateTime.now().add(const Duration(days: 12)),
        location: 'Community hall',
      ),
    );
  }
}