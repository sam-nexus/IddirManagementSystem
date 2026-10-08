import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/features/months/data/months_repository.dart';

final monthsRepositoryProvider = Provider<MonthsRepository>((ref) {
  return MonthsRepository(ref.watch(apiClientProvider));
});

/// Current year the app is showing months for.
final selectedYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

/// Which sub-tab of Months is active: 'this_year', 'past_years', or 'receipts'.
final monthsSegmentProvider = StateProvider<String>((ref) => 'this_year');

/// All years + rows, loaded once.
final allMonthsProvider = FutureProvider<
    ({List<int> years, Map<int, List<MonthRow>> byYear})>((ref) async {
  return ref.watch(monthsRepositoryProvider).fetchAll();
});

/// Rows for the currently selected year.
final yearMonthsProvider = FutureProvider<List<MonthRow>>((ref) async {
  final year = ref.watch(selectedYearProvider);
  final all = await ref.watch(allMonthsProvider.future);
  return all.byYear[year] ?? const <MonthRow>[];
});

/// Years the member actually has dues for, descending. Empty if none.
final availableYearsProvider = FutureProvider<List<int>>((ref) async {
  final all = await ref.watch(allMonthsProvider.future);
  return all.years;
});

final myDuesSummaryProvider = FutureProvider<MyDuesSummary>((ref) async {
  return ref.watch(monthsRepositoryProvider).fetchSummary();
});