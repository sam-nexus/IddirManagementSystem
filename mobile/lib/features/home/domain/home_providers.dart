import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/home/data/home_repository.dart';
import 'package:odaa_mobile/features/home/data/models/home_summary.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(apiClientProvider));
});

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchSummary(memberId: 'me');
});