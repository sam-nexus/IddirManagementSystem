import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

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

String _ethiopianMonthNameEn(int ethMonthIndex) {
  const names = [
    'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yekatit',
    'Megabit', 'Miazia', 'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagume'
  ,];
  return (ethMonthIndex >= 1 && ethMonthIndex <= 13) ? names[ethMonthIndex - 1] : '';
}

String _ethiopianMonthNameOm(int ethMonthIndex) {
  const names = [
    'Fulbaana', 'Onkoloolessa', 'Sadaasa', 'Muddee', 'Amajjii', 'Guraandhala',
    'Bitooteessa', 'Elbaa', 'Caamsa', 'Waxabajjii', 'Adooleessa', 'Hagayya', 'Qammee'
  ,];
  return (ethMonthIndex >= 1 && ethMonthIndex <= 13) ? names[ethMonthIndex - 1] : '';
}

class MonthsRepository {
  MonthsRepository(this._api);

  final ApiClient _api;

  Future<({List<int> years, Map<int, List<MonthRow>> byYear})> fetchAll() async {
    final data = await _api.get<Map<String, dynamic>>('/contributions/my-dues');
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : <Map<String, dynamic>>[];

    // Map: Ethiopian Year -> List<MonthRow>
    final rowsByEthYear = <int, List<MonthRow>>{};

    for (final row in items) {
      // Read the pre-computed Ethiopian index directly from the backend
      final ethMonthIdx = int.tryParse('${row['ethiopian_month_index']}') ?? 0;
      if (ethMonthIdx < 1 || ethMonthIdx > 13) continue;

      // Determine the Ethiopian year from the Gregorian period
      final iso = row['period'] as String?;
      if (iso == null) continue;
      final dt = DateTime.parse(iso);
      
      // Sep-Dec belong to year-7; Jan-Aug belong to year-8
      final ethYear = dt.month >= 9 ? dt.year - 7 : dt.year - 8;

      final state = _toState(row['status'] as String?);
      final amountDue = double.tryParse('${row['amount_due']}') ?? 0;
      final amountPaid = double.tryParse('${row['amount_paid']}') ?? 0;

      // Figure out if this is the "current" or "future" month
      final now = DateTime.now();
      final currentEthYear = now.month >= 9 ? now.year - 7 : now.year - 8;
      final currentEthMonth = now.month >= 9 ? now.month - 8 : now.month + 4;

      final isCurrent = (ethYear == currentEthYear && ethMonthIdx == currentEthMonth);
      final isFuture = (ethYear > currentEthYear) ||
                       (ethYear == currentEthYear && ethMonthIdx > currentEthMonth);

      // Map Ethiopian month back to Gregorian for the DateTime period
      final gregMonth = ethMonthIdx <= 4 ? ethMonthIdx + 8 : ethMonthIdx - 4;
      final gregYear = ethYear + (gregMonth >= 9 ? 7 : 8);

      rowsByEthYear.putIfAbsent(ethYear, () => []).add(MonthRow(
        period: DateTime(gregYear, gregMonth, 1),
        monthNameEn: _ethiopianMonthNameEn(ethMonthIdx),
        monthNameOm: _ethiopianMonthNameOm(ethMonthIdx),
        state: state,
        amountDue: amountDue,
        amountPaid: amountPaid,
        currency: 'ETB',
        ethiopianMonthIndex: ethMonthIdx,
        penaltyAmount: 0,
        paidAt: null,
        isCurrentEthiopianMonth: isCurrent,
        isFutureEthiopianMonth: isFuture,
      ),);
    }

    // If the member has no dues yet, create placeholders for the current year
    if (rowsByEthYear.isEmpty) {
      final now = DateTime.now();
      final currentEthYear = now.month >= 9 ? now.year - 7 : now.year - 8;
      final currentEthMonth = now.month >= 9 ? now.month - 8 : now.month + 4;

      final yearRows = <MonthRow>[];
      for (var ethMonth = 1; ethMonth <= 12; ethMonth++) {
        final gregMonth = ethMonth <= 4 ? ethMonth + 8 : ethMonth - 4;
        final gregYear = currentEthYear + (gregMonth >= 9 ? 7 : 8);
        final isCurrent = (ethMonth == currentEthMonth);
        final isFuture = (ethMonth > currentEthMonth);

        yearRows.add(MonthRow(
          period: DateTime(gregYear, gregMonth, 1),
          monthNameEn: _ethiopianMonthNameEn(ethMonth),
          monthNameOm: _ethiopianMonthNameOm(ethMonth),
          state: isFuture ? ContributionState.pending : ContributionState.waived,
          amountDue: 0,
          amountPaid: 0,
          currency: 'ETB',
          ethiopianMonthIndex: ethMonth,
          isCurrentEthiopianMonth: isCurrent,
          isFutureEthiopianMonth: isFuture,
        ),);
      }
      rowsByEthYear[currentEthYear] = yearRows;
    }

    // Ensure all 12 months of a year are present (fill missing)
    for (final ethYear in rowsByEthYear.keys.toList()) {
      final existing = rowsByEthYear[ethYear]!;
      final existingIndices = existing.map((r) => r.ethiopianMonthIndex).toSet();

      final now = DateTime.now();
      final currentEthYear = now.month >= 9 ? now.year - 7 : now.year - 8;
      final currentEthMonth = now.month >= 9 ? now.month - 8 : now.month + 4;

      for (var ethMonth = 1; ethMonth <= 12; ethMonth++) {
        if (existingIndices.contains(ethMonth)) continue;

        final gregMonth = ethMonth <= 4 ? ethMonth + 8 : ethMonth - 4;
        final gregYear = ethYear + (gregMonth >= 9 ? 7 : 8);
        final isCurrent = (ethYear == currentEthYear && ethMonth == currentEthMonth);
        final isFuture = (ethYear > currentEthYear) ||
                         (ethYear == currentEthYear && ethMonth > currentEthMonth);

        existing.add(MonthRow(
          period: DateTime(gregYear, gregMonth, 1),
          monthNameEn: _ethiopianMonthNameEn(ethMonth),
          monthNameOm: _ethiopianMonthNameOm(ethMonth),
          state: isFuture ? ContributionState.pending : ContributionState.waived,
          amountDue: 0,
          amountPaid: 0,
          currency: 'ETB',
          ethiopianMonthIndex: ethMonth,
          isCurrentEthiopianMonth: isCurrent,
          isFutureEthiopianMonth: isFuture,
        ),);
      }
      existing.sort((a, b) => a.ethiopianMonthIndex.compareTo(b.ethiopianMonthIndex));
    }

    final years = rowsByEthYear.keys.toList()..sort((a, b) => b.compareTo(a));
    return (years: years, byYear: rowsByEthYear);
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
      case 'paid': return ContributionState.paid;
      case 'waived': return ContributionState.waived;
      case 'unpaid':
      case 'partial': return ContributionState.unpaid;
      default: return ContributionState.unpaid;
    }
  }
}