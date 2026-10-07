import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/features/home/data/home_repository.dart';
import 'package:odaa_mobile/features/home/data/models/home_summary.dart';

/// Swap this override when the real API is ready.
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return MockHomeRepository();
});

/// The Home summary. Use `.when(...)` in the screen for loading/error/data.
final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  // Hard-coded for now; will read from the session provider in Reply 9.
  return repo.fetchSummary(memberId: 'mock-member-id');
});