import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/features/history/data/history_repository.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return MockHistoryRepository();
});

final historyProvider = FutureProvider<List<PaymentRecord>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.fetchHistory(memberId: 'mock-member-id');
});