import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

/// Summary returned by /contributions/my-dues.
class MyDuesSummary {
  const MyDuesSummary({
    required this.duesBalance,
    required this.penaltiesUnpaid,
    required this.totalOutstanding,
  });

  final double duesBalance;
  final double penaltiesUnpaid;
  final double totalOutstanding;
}

// Ethiopian month names keyed by Gregorian month number.
String _ethiopianMonthNameEn(int gregMonth) {
  const names = {
    9: 'Meskerem',
    10: 'Tikimt',
    11: 'Hidar',
    12: 'Tahsas',
    1: 'Tir',
    2: 'Yekatit',
    3: 'Megabit',
    4: 'Miazia',
    5: 'Ginbot',
    6: 'Sene',
    7: 'Hamle',
    8: 'Nehase',
  };
  return names[gregMonth] ?? '';
}

String _ethiopianMonthNameOm(int gregMonth) {
  const names = {
    9: 'Fulbaana',
    10: 'Onkoloolessa',
    11: 'Sadaasa',
    12: 'Muddee',
    1: 'Amajjii',
    2: 'Guraandhala',
    3: 'Bitooteessa',
    4: 'Elbaa',
    5: 'Caamsa',
    6: 'Waxabajjii',
    7: 'Adooleessa',
    8: 'Hagayya',
  };
  return names[gregMonth] ?? '';
}

class MonthsRepository {
  MonthsRepository(this._api);

  final ApiClient _api;

  /// Fetches all dues once and groups them by year.
  Future<({List<int> years, Map<int, List<MonthRow>> byYear})>
      fetchAll() async {
    final data = await _api.get<Map<String, dynamic>>('/contributions/my-dues');
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList()
        : <Map<String, dynamic>>[];

    final rowsByYear = <int, Map<int, Map<String, dynamic>>>{};
    for (final row in items) {
      final iso = row['period'] as String?;
      if (iso == null) continue;
      final dt = DateTime.parse(iso).toLocal();

      // Convert the Gregorian date to Ethiopian to get the correct year
      final ethDate = EthiopianDate.fromGregorian(dt);

      // Group by Ethiopian year (e.g., 2019) instead of Gregorian year (e.g., 2027)
      rowsByYear.putIfAbsent(ethDate.year, () => {})[dt.month] = row;
    }

    final now = DateTime.now();
    final byYear = <int, List<MonthRow>>{};

    for (final entry in rowsByYear.entries) {
      final year = entry.key;
      final months = entry.value;

      final yearRows = <MonthRow>[];
      for (var i = 0; i < 12; i++) {
        final month = i + 1;
        final backend = months[month];

        ContributionState state;
        double amountDue = 0;
        double amountPaid = 0;

        if (backend != null) {
          state = _toState(backend['status'] as String?);
          amountDue = double.tryParse('${backend['amount_due']}') ?? 0;
          amountPaid = double.tryParse('${backend['amount_paid']}') ?? 0;
        } else {
          final isFuture =
              (year > now.year) || (year == now.year && month > now.month);
          state =
              isFuture ? ContributionState.pending : ContributionState.waived;
          amountDue = 0;
        }

        yearRows.add(
          MonthRow(
            period: DateTime(year, month, 1),
            monthNameEn: _ethiopianMonthNameEn(month),
            monthNameOm: _ethiopianMonthNameOm(month),
            state: state,
            amountDue: amountDue,
            amountPaid: amountPaid,
            currency: 'ETB',
            penaltyAmount: 0,
            paidAt: null,
          ),
        );
      }
      byYear[year] = yearRows;
    }

    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    return (years: years, byYear: byYear);
  }

  Future<List<MonthRow>> fetchYear({required int year}) async {
    final all = await fetchAll();
    return all.byYear[year] ?? const <MonthRow>[];
  }

  Future<MyDuesSummary> fetchSummary() async {
    final data = await _api.get<Map<String, dynamic>>('/contributions/my-dues');
    final summary = data['summary'] as Map<String, dynamic>? ?? const {};
    final penalties = summary['penalties'] as Map<String, dynamic>? ?? const {};

    return MyDuesSummary(
      duesBalance: double.tryParse('${summary['dues_balance']}') ?? 0,
      penaltiesUnpaid: double.tryParse('${penalties['unpaid_total']}') ?? 0,
      totalOutstanding: double.tryParse('${summary['total_outstanding']}') ?? 0,
    );
  }

  ContributionState _toState(String? s) {
    switch (s) {
      case 'paid':
        return ContributionState.paid;
      case 'waived':
        return ContributionState.waived;
      case 'unpaid':
      case 'partial':
        return ContributionState.unpaid;
      default:
        return ContributionState.unpaid;
    }
  }
}
