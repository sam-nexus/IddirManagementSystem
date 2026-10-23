import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';

/// The 27th → 2nd payment window, computed on the Ethiopian calendar.
/// 
/// Usage:
/// - For a specific due month, pass both `ethiopianMonthIndex` (1-13) and
///   `ethiopianYear` from the MonthRow.
abstract final class PaymentWindow {
  static const openDay = 27;
  static const closeDay = 2;

  /// Returns true if `now` is inside the payment window for a due that
  /// corresponds to Ethiopian month `ethMonth` (1-13) in Ethiopian year `ethYear`.
  static bool isOpenFor({
    required int ethMonth,
    required int ethYear,
    required DateTime now,
  }) {
    final nowEth = EthiopianDate.fromGregorian(now);

    // Same Ethiopian month as the due: window is open on days 27–30
    if (nowEth.year == ethYear && nowEth.month == ethMonth) {
      return nowEth.day >= openDay;
    }

    // Next Ethiopian month: window is open on days 1–2
    final nextEthMonth = ethMonth == 13 ? 1 : ethMonth + 1;
    final nextEthYear = ethMonth == 13 ? ethYear + 1 : ethYear;

    if (nowEth.year == nextEthYear && nowEth.month == nextEthMonth) {
      return nowEth.day <= closeDay;
    }

    return false;
  }

  /// True if today is within the window for *some* month.
  static bool isAnyWindowOpen(DateTime now) {
    final nowEth = EthiopianDate.fromGregorian(now);

    // Current Ethiopian month
    if (isOpenFor(ethMonth: nowEth.month, ethYear: nowEth.year, now: now)) {
      return true;
    }

    // Previous Ethiopian month
    final prevMonth = nowEth.month == 1 ? 13 : nowEth.month - 1;
    final prevYear = nowEth.month == 1 ? nowEth.year - 1 : nowEth.year;
    if (isOpenFor(ethMonth: prevMonth, ethYear: prevYear, now: now)) {
      return true;
    }

    return false;
  }

  /// The Gregorian date that represents the start of the next open window.
  static DateTime nextOpenPeriod(DateTime now) {
    final nowEth = EthiopianDate.fromGregorian(now);

    // If today is inside the current Ethiopian month's window, use this month
    if (isOpenFor(ethMonth: nowEth.month, ethYear: nowEth.year, now: now)) {
      return _ethiopianMonthToGregorian(nowEth.year, nowEth.month);
    }

    // If today is inside the previous Ethiopian month's window, use it
    final prevMonth = nowEth.month == 1 ? 13 : nowEth.month - 1;
    final prevYear = nowEth.month == 1 ? nowEth.year - 1 : nowEth.year;
    if (isOpenFor(ethMonth: prevMonth, ethYear: prevYear, now: now)) {
      return _ethiopianMonthToGregorian(prevYear, prevMonth);
    }

    // Not currently in any window. Return this Ethiopian month's start
    return _ethiopianMonthToGregorian(nowEth.year, nowEth.month);
  }

  static DateTime _ethiopianMonthToGregorian(int ethYear, int ethMonth) {
    return EthiopianDate.toGregorian(ethYear, ethMonth, 1);
  }
}