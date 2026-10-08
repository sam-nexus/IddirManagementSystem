import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/pay/data/models/payment_session.dart';
import 'package:odaa_mobile/features/pay/data/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(apiClientProvider));
});

class PaymentSessionNotifier extends StateNotifier<PaymentSession> {
  PaymentSessionNotifier(this._repo)
      : super(const PaymentSession(status: PaymentSessionStatus.idle));

  final PaymentRepository _repo;

  Future<void> init({
    required String memberId,
    required double amount,
    required List<String> periods,
  }) async {
    state = state.copyWith(status: PaymentSessionStatus.initializing);
    try {
      state = await _repo.initChapa(
        memberId: memberId,
        amount: amount,
        periods: periods,
      );
    } catch (e) {
      state = state.copyWith(
        status: PaymentSessionStatus.failed,
        errorMessage: 'Could not start payment.',
      );
    }
  }

  Future<void> verify(String txRef) async {
    state = state.copyWith(status: PaymentSessionStatus.verifying);
    try {
      state = await _repo.verifyChapa(txRef: txRef);
    } catch (e) {
      state = state.copyWith(
        status: PaymentSessionStatus.failed,
        errorMessage: 'Could not verify payment.',
      );
    }
  }

  void reset() {
    state = const PaymentSession(status: PaymentSessionStatus.idle);
  }
}

final paymentSessionProvider =
    StateNotifierProvider<PaymentSessionNotifier, PaymentSession>((ref) {
  return PaymentSessionNotifier(ref.watch(paymentRepositoryProvider));
});