import 'package:flutter/foundation.dart';
import 'package:odaa_mobile/features/months/data/models/month_row.dart';

@immutable
class PaymentPlan {
  const PaymentPlan({
    required this.payableRows,
    required this.duesTotal,
    required this.penaltiesTotal,
    required this.total,
    required this.currency,
    required this.windowOpen,
  });

  /// Months eligible to be paid right now, in chronological order (oldest first).
  final List<MonthRow> payableRows;

  final double duesTotal;
  final double penaltiesTotal;
  final double total;
  final String currency;

  /// Whether the 27th → 2nd window is currently open.
  final bool windowOpen;

  bool get hasAnythingToPay => total > 0;
  int get payableMonthCount => payableRows.length;
}