import 'package:flutter/foundation.dart';

@immutable
class Report {
  const Report({
    required this.id,
    required this.titleEn,
    required this.titleOm,
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.publishedAt,
  });

  final String id;
  final String titleEn;
  final String titleOm;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Free-form summary JSON: income, expenses, balance, etc.
  final Map<String, dynamic> summary;

  final DateTime publishedAt;

  String title(bool isOm) => isOm ? titleOm : titleEn;

  // ---------- Convenience readers ----------
  double get income => _num(['income', 'total']);
  double get expenses => _num(['expenses', 'total']);
  double get payouts => _num(['payouts', 'total']);
  double get balance => _num(['balance']);

  double _num(List<String> path) {
    dynamic cur = summary;
    for (final k in path) {
      if (cur is Map && cur.containsKey(k)) {
        cur = cur[k];
      } else {
        return 0;
      }
    }
    return double.tryParse('$cur') ?? 0;
  }
}