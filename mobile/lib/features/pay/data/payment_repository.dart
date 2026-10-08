import 'package:odaa_mobile/core/api/api_client.dart';
import 'package:odaa_mobile/features/pay/data/models/payment_session.dart';

class PaymentRepository {
  PaymentRepository(this._api);

  final ApiClient _api;

  Future<PaymentSession> initChapa({
    required String memberId,
    required double amount,
    required List<String> periods,
  }) async {
    final raw = await _api.post<dynamic>(
      '/contributions/pay/init',
      body: {
        'months': periods.length,
        'include_penalties': true,
      },
    );
    final data = raw is Map ? raw : <String, dynamic>{};

    return PaymentSession(
      status: PaymentSessionStatus.awaitingUser,
      txRef: data['tx_ref'] as String?,
      checkoutUrl: data['checkout_url'] as String?,
      amount: double.tryParse('${data['amount']}') ?? 0,
      currency: (data['currency'] as String?) ?? 'ETB',
    );
  }

  Future<PaymentSession> verifyChapa({required String txRef}) async {
    final raw = await _api.post<dynamic>(
      '/contributions/pay/verify',
      body: {'tx_ref': txRef},
    );
    final data = raw is Map ? raw : <String, dynamic>{};

    final status = (data['status'] as String?) ?? 'pending';
    if (status == 'success') {
      return PaymentSession(
        status: PaymentSessionStatus.success,
        txRef: txRef,
        paymentId: data['payment_id'] as String?,
        receiptNo: data['receipt_no'] as String?,
      );
    } else if (status == 'failed') {
      return PaymentSession(
        status: PaymentSessionStatus.failed,
        txRef: txRef,
        errorMessage: 'Payment did not go through.',
      );
    } else {
      return PaymentSession(
        status: PaymentSessionStatus.awaitingUser,
        txRef: txRef,
      );
    }
  }
}
