import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';

class HistoryRepository {
  HistoryRepository(this._api);

  final ApiClient _api;

  Future<List<PaymentRecord>> fetchHistory({required String memberId}) async {
    final raw = await _api.get<dynamic>('/contributions/payments');
    final items = extractList(raw);
    return items.map(_toRecord).toList();
  }

  /// Finds the successful payment record that covered a specific period.
  Future<PaymentRecord?> fetchPaymentForPeriod(String periodIso) async {
    // 1. Fetch all payments
    final raw = await _api.get<dynamic>('/contributions/payments');
    final items = extractList(raw);
    final payments = items.map(_toRecord).toList();

    // 2. Find the successful payment that includes this month
    // (In a real app, you'd do this on the backend, but for now we filter locally)
    for (final p in payments) {
      if (p.status == PaymentStatus.success && p.periodsCovered.contains(periodIso)) {
        return p;
      }
    }
    return null;
  }

PaymentRecord _toRecord(Map<String, dynamic> json) {
  final periodsRaw = json['periods_covered'];
  final periods = periodsRaw is List
      ? periodsRaw.map((e) => e.toString()).toList()
      : <String>[];

  return PaymentRecord(
    id: json['id'] as String,
    receiptNo: json['receipt_no'] as String?,
    amount: double.tryParse('${json['amount']}') ?? 0,
    currency: (json['currency'] as String?) ?? 'ETB',
    method: _toMethod(json['method'] as String?),
    status: _toStatus(json['status'] as String?),
    paidAt: _parseDate(json['paid_at'] ?? json['created_at']),
    periodsCovered: periods,
    note: json['note'] as String?,
  );
}

  PaymentMethod _toMethod(String? s) {
    switch (s) {
      case 'cash': return PaymentMethod.cash;
      case 'manual': return PaymentMethod.manual;
      default: return PaymentMethod.chapa;
    }
  }

  PaymentStatus _toStatus(String? s) {
    switch (s) {
      case 'success': return PaymentStatus.success;
      case 'failed': return PaymentStatus.failed;
      default: return PaymentStatus.pending;
    }
  }

  DateTime _parseDate(Object? raw) {
    if (raw is String) return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
    return DateTime.now();
  }
}