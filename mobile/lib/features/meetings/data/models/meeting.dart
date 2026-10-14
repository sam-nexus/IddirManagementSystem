import 'package:flutter/foundation.dart';

@immutable
class Meeting {
  const Meeting({
    required this.id,
    required this.titleEn,
    required this.titleOm,
    required this.scheduledAt,
    required this.location,
    this.agendaEn,
    this.agendaOm,
    this.minutesEn,
    this.minutesOm,
    this.isPublished = false,
    this.hasMinutes = false,
  });

  final String id;
  final String titleEn;
  final String titleOm;
  final DateTime scheduledAt;
  final String? location;
  final String? agendaEn;
  final String? agendaOm;
  final String? minutesEn;
  final String? minutesOm;
  final bool isPublished;
  final bool hasMinutes;

  String title(bool isOm) => isOm ? titleOm : titleEn;
  String? agenda(bool isOm) => isOm ? agendaOm : agendaEn;
  String? minutes(bool isOm) => isOm ? minutesOm : minutesEn;

  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());
  bool get isPast => !isUpcoming;
}