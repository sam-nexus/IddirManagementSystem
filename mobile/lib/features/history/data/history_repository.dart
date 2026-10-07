import 'package:odaa_mobile/features/history/data/models/payment_record.dart';

abstract interface class HistoryRepository {
  Future<List<PaymentRecord>> fetchHistory({required String memberId});
}

class MockHistoryRepository implements HistoryRepository {
  @override
  Future<List<PaymentRecord>> fetchHistory({required String memberId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    return [
      PaymentRecord(
        id: 'p-1',
        receiptNo: 'RCT-2026-004812',
        amount: 220.00,
        currency: 'ETB',
        method: PaymentMethod.chapa,
        status: PaymentStatus.success,
        paidAt: now.subtract(const Duration(days: 8)),
        periodsCovered: const ['2026-09-01', '2026-10-01'],
      ),
      PaymentRecord(
        id: 'p-2',
        receiptNo: 'RCT-2026-003301',
        amount: 100.00,
        currency: 'ETB',
        method: PaymentMethod.cash,
        status: PaymentStatus.success,
        paidAt: now.subtract(const Duration(days: 45)),
        periodsCovered: const ['2026-08-01'],
        note: 'Paid at committee meeting',
      ),
      PaymentRecord(
        id: 'p-3',
        receiptNo: 'RCT-2026-002105',
        amount: 300.00,
        currency: 'ETB',
        method: PaymentMethod.chapa,
        status: PaymentStatus.success,
        paidAt: now.subtract(const Duration(days: 82)),
        periodsCovered: const ['2026-06-01', '2026-07-01', '2026-08-01'],
      ),
      PaymentRecord(
        id: 'p-4',
        receiptNo: null,
        amount: 100.00,
        currency: 'ETB',
        method: PaymentMethod.manual,
        status: PaymentStatus.pending,
        paidAt: now.subtract(const Duration(hours: 3)),
        periodsCovered: const ['2026-05-01'],
        note: 'Bank transfer — awaiting review',
      ),
    ];
  }
}