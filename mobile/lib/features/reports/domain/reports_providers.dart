import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/reports/data/models/report.dart';
import 'package:odaa_mobile/features/reports/data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(apiClientProvider));
});

final reportsProvider = FutureProvider<List<Report>>((ref) async {
  return ref.watch(reportsRepositoryProvider).fetchAll();
});

final reportProvider =
    FutureProvider.family<Report?, String>((ref, id) async {
  return ref.watch(reportsRepositoryProvider).fetchOne(id);
});