import 'package:odaa_mobile/features/history/data/models/payment_record.dart';

abstract interface class ReceiptRepository {
  Future<PaymentRecord?> fetchReceipt({required String paymentId});
}

class MockReceiptRepository implements ReceiptRepository {
  @override
  Future<PaymentRecord?> fetchReceipt({required String paymentId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Match the mock history records.
    final now = DateTime.now();
    switch (paymentId) {
      case 'p-1':
        return PaymentRecord(
          id: 'p-1',
          receiptNo: 'RCT-2026-004812',
          amount: 220.00,
          currency: 'ETB',
          method: PaymentMethod.chapa,
          status: PaymentStatus.success,
          paidAt: now.subtract(const Duration(days: 8)),
          periodsCovered: const ['2026-09-01', '2026-10-01'],
        );
      case 'p-2':
        return PaymentRecord(
          id: 'p-2',
          receiptNo: 'RCT-2026-003301',
          amount: 100.00,
          currency: 'ETB',
          method: PaymentMethod.cash,
          status: PaymentStatus.success,
          paidAt: now.subtract(const Duration(days: 45)),
          periodsCovered: const ['2026-08-01'],
          note: 'Paid at committee meeting',
        );
      case 'p-3':
        return PaymentRecord(
          id: 'p-3',
          receiptNo: 'RCT-2026-002105',
          amount: 300.00,
          currency: 'ETB',
          method: PaymentMethod.chapa,
          status: PaymentStatus.success,
          paidAt: now.subtract(const Duration(days: 82)),
          periodsCovered: const ['2026-06-01', '2026-07-01', '2026-08-01'],
        );
      default:
        return null;
    }
  }
}