import 'package:odaa_mobile/features/pay/data/models/payment_session.dart';

abstract interface class PaymentRepository {
  /// Init a Chapa payment. Returns the session with a checkout URL.
  Future<PaymentSession> initChapa({
    required String memberId,
    required double amount,
    required List<String> periods,
  });

  /// Verify a Chapa payment by tx_ref. Returns the updated session.
  Future<PaymentSession> verifyChapa({required String txRef});
}

/// Mock — simulates the real backend.
class MockPaymentRepository implements PaymentRepository {
  @override
  Future<PaymentSession> initChapa({
    required String memberId,
    required double amount,
    required List<String> periods,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final txRef = 'odaa-${DateTime.now().millisecondsSinceEpoch}';

    return PaymentSession(
      status: PaymentSessionStatus.awaitingUser,
      txRef: txRef,
      // A real Chapa URL would be returned here.
      checkoutUrl: 'https://checkout.chapa.co/checkout/demo?tx_ref=$txRef',
      amount: amount,
    );
  }

  @override
  Future<PaymentSession> verifyChapa({required String txRef}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Mock: 80% success.
    final success = DateTime.now().millisecond % 5 != 0;

    if (success) {
      return PaymentSession(
        status: PaymentSessionStatus.success,
        txRef: txRef,
        paymentId: 'mock-payment-${txRef.hashCode}',
        receiptNo: 'RCT-2026-${txRef.hashCode.toString().padLeft(6, '0').substring(0, 6)}',
      );
    } else {
      return PaymentSession(
        status: PaymentSessionStatus.failed,
        txRef: txRef,
        errorMessage: 'Payment did not go through.',
      );
    }
  }
}