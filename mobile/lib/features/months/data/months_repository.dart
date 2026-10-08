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

class MonthsRepository {
  MonthsRepository(this._api);

  final ApiClient _api;

  // ------------- Public API -------------

  /// Fetches everything once and returns:
  ///   - `years`: distinct years the member has dues for, descending
  ///   - `byYear`: Map<year, List<MonthRow>> with 12 rows per year
  Future<({List<int> years, Map<int, List<MonthRow>> byYear})> fetchAll() async {
    final data = await _api.get<Map<String, dynamic>>('/contributions/my-dues');
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList()
        : <Map<String, dynamic>>[];

    // Group backend rows by year.
    final rowsByYear = <int, Map<int, Map<String, dynamic>>>{};
    for (final row in items) {
      final iso = row['period'] as String?;
      if (iso == null) continue;
      final dt = DateTime.parse(iso).toLocal();
      rowsByYear.putIfAbsent(dt.year, () => {})[dt.month] = row;
    }

    const namesEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const namesOm = [
      'Amajjii', 'Guraandhala', 'Bitooteessa', 'Elbaa', 'Caamsa', 'Waxabajjii',
      'Adooleessa', 'Hagayya', 'Fuulbana', 'Onkololeessa', 'Sadaasa', 'Muddee',
    ];

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
          state = isFuture
              ? ContributionState.pending
              : ContributionState.waived;
          amountDue = 0;
        }

        yearRows.add(MonthRow(
          period: DateTime(year, month, 1),
          monthNameEn: namesEn[i],
          monthNameOm: namesOm[i],
          state: state,
          amountDue: amountDue,
          amountPaid: amountPaid,
          currency: 'ETB',
          penaltyAmount: 0,
          paidAt: null,
        ),);
      }
      byYear[year] = yearRows;
    }

    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    return (years: years, byYear: byYear);
  }

  /// Fetches a single year's rows. Used by older callers.
  Future<List<MonthRow>> fetchYear({required int year}) async {
    final all = await fetchAll();
    return all.byYear[year] ?? const <MonthRow>[];
  }

  /// The my-dues summary. Used for penalties and total-outstanding.
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