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
    required this.ethiopianMonthIndex,
    this.penaltyAmount = 0,
    this.paidAt,
    this.isCurrentEthiopianMonth = false,
    this.isFutureEthiopianMonth = false,
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

  /// 1 = Meskerem, 2 = Tikimt, ... 12 = Nehase.
  /// Sourced directly from the backend `ethiopian_month_index` column.
  final int ethiopianMonthIndex;

  final bool isCurrentEthiopianMonth;
  final bool isFutureEthiopianMonth;

  double get outstanding => (amountDue - amountPaid).clamp(0, amountDue);
  double get outstandingWithPenalty => outstanding + penaltyAmount;

  bool get isCurrentMonth => isCurrentEthiopianMonth;

  bool get isFullyPaid =>
      state == ContributionState.paid || state == ContributionState.waived;

  bool get isUnpaid => state == ContributionState.unpaid;

  /// Used for display sorting. 0 = Meskerem, 11 = Nehase.
  int get sortIndex => ethiopianMonthIndex - 1;
}

enum DisplayState { paid, unpaid, suspended, comingSoon }

extension MonthRowDisplay on MonthRow {
  DisplayState resolveDisplayState({required bool hasOlderUnpaid}) {
    if (isFullyPaid) return DisplayState.paid;

    if (isFutureEthiopianMonth) {
      return DisplayState.comingSoon;
    }

    return hasOlderUnpaid ? DisplayState.suspended : DisplayState.unpaid;
  }
}