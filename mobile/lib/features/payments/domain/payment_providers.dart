import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/features/months/domain/months_providers.dart';
import 'package:odaa_mobile/features/payments/data/models/payment_plan.dart';
import 'package:odaa_mobile/features/payments/data/payment_plan_builder.dart';

/// Penalties total — hard-coded for now; the real API will supply it.
final penaltiesTotalProvider = Provider<double>((ref) => 20.0);

/// The plan the Pay screen will use.
final paymentPlanProvider = FutureProvider<PaymentPlan>((ref) async {
  final rows = await ref.watch(yearMonthsProvider.future);
  final penalties = ref.watch(penaltiesTotalProvider);

  return PaymentPlanBuilder.build(
    allRows: rows,
    penaltiesTotal: penalties,
    currency: 'ETB',
  );
});