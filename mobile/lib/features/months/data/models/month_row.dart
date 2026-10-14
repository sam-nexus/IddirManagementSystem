import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
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

/// The 27th → 2nd payment window, computed on the Ethiopian calendar.
///
/// The backend stores `period` as a Gregorian date (2026-09-01). We convert
/// that to its Ethiopian equivalent (Meskerem 1, 2019) and check whether
/// "now" falls between day 27 of that Ethiopian month and day 2 of the next.
abstract final class PaymentWindow {
  /// Ethiopian day the window opens (27th of the due's Ethiopian month).
  static const openDay = 27;

  /// Ethiopian day the window closes (2nd of the next Ethiopian month).
  static const closeDay = 2;

  /// True if `now` is inside the window for the due whose period is `dueMonth`.
  static bool isOpenFor(DateTime dueMonth, DateTime now) {
    final dueEth = EthiopianDate.fromGregorian(
      DateTime(dueMonth.year, dueMonth.month, 1),
    );
    final nowEth = EthiopianDate.fromGregorian(now);

    // Same Ethiopian month as the due: window is open on days 27–30.
    if (nowEth.year == dueEth.year && nowEth.month == dueEth.month) {
      return nowEth.day >= openDay;
    }

    // Next Ethiopian month: window is open on days 1–2.
    final nextMonth = dueEth.month == 13 ? 1 : dueEth.month + 1;
    final nextYear = dueEth.month == 13 ? dueEth.year + 1 : dueEth.year;
    if (nowEth.year == nextYear && nowEth.month == nextMonth) {
      return nowEth.day <= closeDay;
    }

    return false;
  }

  /// True if today is within the window for *some* month.
  static bool isAnyWindowOpen(DateTime now) {
    final nowEth = EthiopianDate.fromGregorian(now);

    // Current Ethiopian month's window is open on days 27–30.
    if (nowEth.day >= openDay) {
      final currentDue = _ethiopianMonthToGregorian(nowEth.year, nowEth.month);
      if (isOpenFor(currentDue, now)) return true;
    }

    // Previous Ethiopian month's window is open on days 1–2.
    if (nowEth.day <= closeDay) {
      final prevMonth = nowEth.month == 1 ? 13 : nowEth.month - 1;
      final prevYear = nowEth.month == 1 ? nowEth.year - 1 : nowEth.year;
      final prevDue = _ethiopianMonthToGregorian(prevYear, prevMonth);
      if (isOpenFor(prevDue, now)) return true;
    }

    return false;
  }

  /// The Gregorian period of the next payable cycle, given today.
  static DateTime nextOpenPeriod(DateTime now) {
    final nowEth = EthiopianDate.fromGregorian(now);

    if (nowEth.day >= openDay) {
      return _ethiopianMonthToGregorian(nowEth.year, nowEth.month);
    }

    if (nowEth.day <= closeDay) {
      final prevMonth = nowEth.month == 1 ? 13 : nowEth.month - 1;
      final prevYear = nowEth.month == 1 ? nowEth.year - 1 : nowEth.year;
      return _ethiopianMonthToGregorian(prevYear, prevMonth);
    }

    return _ethiopianMonthToGregorian(nowEth.year, nowEth.month);
  }

  /// Returns the Gregorian first-of-month for an Ethiopian (year, month).
  static DateTime _ethiopianMonthToGregorian(int ethYear, int ethMonth) {
    return EthiopianDate.toGregorian(ethYear, ethMonth, 1);
  }
}