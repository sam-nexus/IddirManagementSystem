import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/history/data/history_repository.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(apiClientProvider));
});

final historyProvider = FutureProvider<List<PaymentRecord>>((ref) async {
  return ref.watch(historyRepositoryProvider).fetchHistory(memberId: 'me');
});