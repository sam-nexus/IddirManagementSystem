import 'package:flutter/foundation.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

@immutable
class MonthRow {
  const MonthRow({
    required this.period,
    required this.monthNameEn,
    required this.monthNameOm,
    required this.state,
    required this.amountDue,
    required this.amountPaid,
    required this.currency,
    this.penaltyAmount = 0,
    this.paidAt,
  });

  final DateTime period;
  final String monthNameEn;
  final String monthNameOm;
  final ContributionState state;
  final double amountDue;
  final double amountPaid;
  final String currency;
  final double penaltyAmount;
  final DateTime? paidAt;

  double get outstanding => (amountDue - amountPaid).clamp(0, amountDue);
  double get outstandingWithPenalty => outstanding + penaltyAmount;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return period.year == now.year && period.month == now.month;
  }

  bool get isPastMonth {
    final now = DateTime.now();
    return period.isBefore(DateTime(now.year, now.month, 1));
  }

  bool get isFutureMonth {
    final now = DateTime.now();
    return period.isAfter(DateTime(now.year, now.month, 1));
  }

  bool get isFullyPaid =>
      state == ContributionState.paid || state == ContributionState.waived;

  bool get isUnpaid => state == ContributionState.unpaid;
}

enum DisplayState { paid, unpaid, suspended, comingSoon }

extension MonthRowDisplay on MonthRow {
  DisplayState resolveDisplayState({required bool hasOlderUnpaid}) {
    if (isFullyPaid) return DisplayState.paid;
    if (isFutureMonth) return DisplayState.comingSoon;
    if (isPastMonth) return DisplayState.unpaid;
    return hasOlderUnpaid ? DisplayState.suspended : DisplayState.unpaid;
  }
}

abstract final class PaymentWindow {
  static const openDay = 27;
  static const closeDay = 2;

  static bool isOpenFor(DateTime dueMonth, DateTime now) {
    final due = DateTime(dueMonth.year, dueMonth.month, 1);
    final open = DateTime(due.year, due.month, openDay);
    final close = DateTime(due.year, due.month + 1, closeDay, 23, 59, 59);
    return !now.isBefore(open) && !now.isAfter(close);
  }

  static bool isAnyWindowOpen(DateTime now) {
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    return isOpenFor(thisMonth, now) || isOpenFor(lastMonth, now);
  }

  static DateTime nextOpenPeriod(DateTime now) {
    if (isOpenFor(DateTime(now.year, now.month, 1), now)) {
      return DateTime(now.year, now.month, 1);
    }
    if (isOpenFor(DateTime(now.year, now.month - 1, 1), now)) {
      return DateTime(now.year, now.month - 1, 1);
    }
    return DateTime(now.year, now.month, 1);
  }
}