import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/features/months/data/months_repository.dart';

final monthsRepositoryProvider = Provider<MonthsRepository>((ref) {
  return MockMonthsRepository();
});

/// Current year, overridable via UI.
final selectedYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

/// The 12 months of the selected year.
final yearMonthsProvider = FutureProvider<List<MonthRow>>((ref) async {
  final year = ref.watch(selectedYearProvider);
  final repo = ref.watch(monthsRepositoryProvider);
  return repo.fetchYear(year: year, memberId: 'mock-member-id');
});