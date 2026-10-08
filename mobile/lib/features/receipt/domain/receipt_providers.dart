import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';
import 'package:odaa_mobile/features/receipt/data/receipt_repository.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository(ref.watch(apiClientProvider));
});

final receiptProvider =
    FutureProvider.family<PaymentRecord?, String>((ref, id) async {
  return ref.watch(receiptRepositoryProvider).fetchReceipt(paymentId: id);
});