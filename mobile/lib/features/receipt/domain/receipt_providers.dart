import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';
import 'package:odaa_mobile/features/receipt/data/receipt_repository.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return MockReceiptRepository();
});

final receiptProvider = FutureProvider.family<PaymentRecord?, String>((ref, id) async {
  final repo = ref.watch(receiptRepositoryProvider);
  return repo.fetchReceipt(paymentId: id);
});