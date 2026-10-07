import 'package:flutter/foundation.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

/// Everything the Home screen needs, in one object.
/// Immutable so Riverpod can compare cheaply.
@immutable
class HomeSummary {
  const HomeSummary({
    required this.firstName,
    required this.months,
    required this.currentMonthIndex,
    required this.duesBalance,
    required this.penaltiesBalance,
    required this.currency,
    required this.monthsPaid,
    required this.monthsTotal,
    this.latestNotice,
    this.nextMeeting,
  });

  final String firstName;

  /// Exactly 12 entries, calendar order.
  final List<ContributionState> months;
  final int currentMonthIndex;

  final double duesBalance;
  final double penaltiesBalance;
  final String currency;      // 'ETB'
  final int monthsPaid;
  final int monthsTotal;

  final NoticeTeaser? latestNotice;
  final MeetingTeaser? nextMeeting;

  double get totalOwed => duesBalance + penaltiesBalance;

  bool get isInGoodStanding => totalOwed <= 0;
}

@immutable
class NoticeTeaser {
  const NoticeTeaser({
    required this.id,
    required this.titleEn,
    required this.titleOm,
    required this.publishedAt,
    this.isUrgent = false,
  });

  final String id;
  final String titleEn;
  final String titleOm;
  final DateTime publishedAt;
  final bool isUrgent;
}

@immutable
class MeetingTeaser {
  const MeetingTeaser({
    required this.id,
    required this.titleEn,
    required this.titleOm,
    required this.scheduledAt,
    required this.location,
  });

  final String id;
  final String titleEn;
  final String titleOm;
  final DateTime scheduledAt;
  final String location;
}