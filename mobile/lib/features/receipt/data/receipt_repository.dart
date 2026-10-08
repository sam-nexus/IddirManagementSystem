import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';

class ReceiptRepository {
  ReceiptRepository(this._api);

  final ApiClient _api;

  Future<PaymentRecord?> fetchReceipt({required String paymentId}) async {
    final raw = await _api.get<dynamic>('/contributions/payments/$paymentId');
    if (raw is! Map) return null;

    final payment = raw['payment'] as Map<String, dynamic>?;
    if (payment == null) return null;

    final allocations = extractList(raw['allocations']);

    final periods = allocations
        .map((a) => (a['period'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return PaymentRecord(
      id: payment['id'] as String,
      receiptNo: payment['receipt_no'] as String?,
      amount: double.tryParse('${payment['amount']}') ?? 0,
      currency: (payment['currency'] as String?) ?? 'ETB',
      method: _toMethod(payment['method'] as String?),
      status: _toStatus(payment['status'] as String?),
      paidAt: _parseDate(payment['paid_at'] ?? payment['created_at']),
      periodsCovered: periods,
      note: payment['note'] as String?,
    );
  }

  PaymentMethod _toMethod(String? s) {
    switch (s) {
      case 'cash':
        return PaymentMethod.cash;
      case 'manual':
        return PaymentMethod.manual;
      case 'chapa':
      default:
        return PaymentMethod.chapa;
    }
  }

  PaymentStatus _toStatus(String? s) {
    switch (s) {
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  DateTime _parseDate(Object? raw) {
    if (raw is String) {
      return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }
}
