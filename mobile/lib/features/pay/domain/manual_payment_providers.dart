import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/features/pay/data/manual_payment_repository.dart';

final manualPaymentRepositoryProvider =
    Provider<ManualPaymentRepository>((ref) {
  return ManualPaymentRepository(ref.watch(apiClientProvider));
});