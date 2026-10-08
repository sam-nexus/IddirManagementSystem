import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/features/months/domain/months_providers.dart';
import 'package:odaa_mobile/features/payments/data/models/payment_plan.dart';
import 'package:odaa_mobile/features/payments/data/payment_plan_builder.dart';

/// Real penalties come from the backend's my-dues summary.
/// We expose it here by reading the same repository.
final penaltiesTotalProvider = FutureProvider<double>((ref) async {
  final summary = await ref.watch(myDuesSummaryProvider.future);
  return summary.penaltiesUnpaid;
});

final paymentPlanProvider = FutureProvider<PaymentPlan>((ref) async {
  final rows = await ref.watch(yearMonthsProvider.future);
  final penalties = await ref.watch(penaltiesTotalProvider.future);

  return PaymentPlanBuilder.build(
    allRows: rows,
    penaltiesTotal: penalties,
    currency: 'ETB',
  );
});