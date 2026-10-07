import 'package:flutter/foundation.dart';

enum PaymentMethod { chapa, cash, manual }

enum PaymentStatus { pending, success, failed }

@immutable
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.receiptNo,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.paidAt,
    required this.periodsCovered,
    this.note,
  });

  final String id;
  final String? receiptNo;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime paidAt;
  final List<String> periodsCovered; // e.g. ['2026-09-01', '2026-10-01']
  final String? note;

  bool get isSuccess => status == PaymentStatus.success;
}