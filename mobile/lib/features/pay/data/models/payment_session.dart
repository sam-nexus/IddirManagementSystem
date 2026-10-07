import 'package:flutter/foundation.dart';

enum PaymentSessionStatus { idle, initializing, awaitingUser, verifying, success, failed }

@immutable
class PaymentSession {
  const PaymentSession({
    required this.status,
    this.txRef,
    this.checkoutUrl,
    this.paymentId,
    this.receiptNo,
    this.errorMessage,
    this.amount,
    this.currency = 'ETB',
  });

  final PaymentSessionStatus status;
  final String? txRef;
  final String? checkoutUrl;
  final String? paymentId;
  final String? receiptNo;
  final String? errorMessage;
  final double? amount;
  final String currency;

  PaymentSession copyWith({
    PaymentSessionStatus? status,
    String? txRef,
    String? checkoutUrl,
    String? paymentId,
    String? receiptNo,
    String? errorMessage,
    double? amount,
    String? currency,
  }) {
    return PaymentSession(
      status: status ?? this.status,
      txRef: txRef ?? this.txRef,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      paymentId: paymentId ?? this.paymentId,
      receiptNo: receiptNo ?? this.receiptNo,
      errorMessage: errorMessage ?? this.errorMessage,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }
}