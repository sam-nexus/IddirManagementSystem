import 'package:odaa_mobile/core/utils/payment_window.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/features/payments/data/models/payment_plan.dart';

abstract final class PaymentPlanBuilder {
  static PaymentPlan build({
    required List<MonthRow> allRows,
    required double penaltiesTotal,
    required String currency,
  }) {
    // Sort by Ethiopian month index to ensure chronological order
    final sorted = [...allRows]..sort((a, b) {
      final yearA = a.period.month >= 9 ? a.period.year - 7 : a.period.year - 8;
      final yearB = b.period.month >= 9 ? b.period.year - 7 : b.period.year - 8;
      final yearCmp = yearA.compareTo(yearB);
      if (yearCmp != 0) return yearCmp;
      return a.ethiopianMonthIndex.compareTo(b.ethiopianMonthIndex);
    });

    final now = DateTime.now();
    //final windowOpen = PaymentWindow.isAnyWindowOpen(now);

    // Find ALL unpaid months (not just the oldest)
    final unpaid = sorted.where((r) => r.isUnpaid).toList();

    // For the window check, we use the OLDEST unpaid month. 
    // (If the oldest month's window isn't open, they can't start paying yet).
    bool canPayNow = false;
    if (unpaid.isNotEmpty) {
      final oldest = unpaid.first;
      final ethYear = oldest.period.month >= 9 ? oldest.period.year - 7 : oldest.period.year - 8;
      canPayNow = PaymentWindow.isOpenFor(
        ethMonth: oldest.ethiopianMonthIndex,
        ethYear: ethYear,
        now: now,
      );
    }

    final duesTotal = unpaid.fold<double>(
      0,
      (sum, r) => sum + r.outstanding,
    );

    return PaymentPlan(
      payableRows: unpaid, // Return ALL unpaid months
      duesTotal: duesTotal,
      penaltiesTotal: penaltiesTotal,
      total: duesTotal + penaltiesTotal,
      currency: currency,
      windowOpen: canPayNow, // The button enables based on the oldest month's window
    );
  }
}