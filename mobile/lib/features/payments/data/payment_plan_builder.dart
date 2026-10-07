import 'package:odaa_mobile/features/months/data/models/month_row.dart';
import 'package:odaa_mobile/features/payments/data/models/payment_plan.dart';

/// Rules:
///
/// 1. Dues must be paid in chronological order. We never offer a later month
///    while an earlier one is unpaid or partial.
/// 2. A month's due is only payable inside its 27th → 2nd window.
/// 3. If no window is open, the plan still returns the oldest unpaid dues
///    (because the member might want to top up an older month), but
///    [PaymentPlan.windowOpen] is false so the UI can adapt.
abstract final class PaymentPlanBuilder {
  static PaymentPlan build({
    required List<MonthRow> allRows,
    required double penaltiesTotal,
    required String currency,
  }) {
    // Chronological order is guaranteed by the repository, but sort defensively.
    final sorted = [...allRows]..sort((a, b) => a.period.compareTo(b.period));

    final now = DateTime.now();
    final windowOpen = PaymentWindow.isAnyWindowOpen(now);

    // Oldest-first list of everything unpaid or partial.
    final unpaid = sorted.where((r) => r.isUnpaid).toList();

    // Rule 1: chronological lock. Walk from the oldest; the first one is
    // always eligible. Later ones are eligible only if every earlier one
    // is already fully paid (which can't happen here because they're unpaid).
    //
    // So the rule simplifies to: only the FIRST unpaid month is currently
    // payable, unless the window is open for the current month and all
    // previous months are paid.
    final payable = <MonthRow>[];
    if (unpaid.isNotEmpty) {
      payable.add(unpaid.first);

      // If the oldest unpaid is already inside its window, we're done —
      // nothing beyond it can be selected without breaking the rule.
      // If it's NOT in its window, the member can still pay it early
      // (to clear old debt), but again, not the ones after it.
      //
      // The one exception is the current month: if the member has paid
      // all prior months and the current month's window is open, they
      // can pay the current month too.
      final currentMonth = DateTime(now.year, now.month, 1);
      final oldestIsCurrentOrPast =
          !unpaid.first.period.isAfter(currentMonth);

      if (oldestIsCurrentOrPast &&
          PaymentWindow.isOpenFor(unpaid.first.period, now)) {
        // Oldest is the current month or earlier, and its window is open.
        // Nothing else to add (member still owes on this one).
      }
    }

    final duesTotal = payable.fold<double>(
      0,
      (sum, r) => sum + r.outstanding,
    );

    return PaymentPlan(
      payableRows: payable,
      duesTotal: duesTotal,
      penaltiesTotal: penaltiesTotal,
      total: duesTotal + penaltiesTotal,
      currency: currency,
      windowOpen: windowOpen,
    );
  }
}