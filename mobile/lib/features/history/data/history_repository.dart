import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';

class HistoryRepository {
  HistoryRepository(this._api);

  final ApiClient _api;

  Future<List<PaymentRecord>> fetchHistory({required String memberId}) async {
    final raw = await _api.get<dynamic>('/contributions/payments');
    final items = extractList(raw);

    return items.map((json) => _toRecord(json)).toList();
  }

  PaymentRecord _toRecord(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      receiptNo: json['receipt_no'] as String?,
      amount: double.tryParse('${json['amount']}') ?? 0,
      currency: (json['currency'] as String?) ?? 'ETB',
      method: _toMethod(json['method'] as String?),
      status: _toStatus(json['status'] as String?),
      paidAt: _parseDate(json['paid_at'] ?? json['created_at']),
      periodsCovered: const [], // not returned by the list endpoint
      note: json['note'] as String?,
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
      case 'pending':
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
