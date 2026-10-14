import 'package:flutter/foundation.dart';

enum SupportType { death, illness, emergency, other }

enum SupportStatus {
  pending,
  underReview,
  approved,
  rejected,
  paid,
  cancelled,
}

@immutable
class SupportRequest {
  const SupportRequest({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.dependentName,
    this.amountRequested,
    this.amountApproved,
    this.decidedNote,
    this.payoutAmount,
    this.payoutMethod,
  });

  final String id;
  final SupportType type;
  final String description;
  final SupportStatus status;
  final DateTime createdAt;

  final String? dependentName;
  final double? amountRequested;
  final double? amountApproved;
  final String? decidedNote;
  final double? payoutAmount;
  final String? payoutMethod;

  bool get isOpen =>
      status == SupportStatus.pending || status == SupportStatus.underReview;

  bool get isResolved =>
      status == SupportStatus.approved ||
      status == SupportStatus.rejected ||
      status == SupportStatus.paid;
}