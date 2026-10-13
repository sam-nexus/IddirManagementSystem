import 'package:flutter/foundation.dart';

@immutable
class Announcement {
  const Announcement({
    required this.id,
    required this.titleEn,
    required this.titleOm,
    required this.bodyEn,
    required this.bodyOm,
    required this.publishedAt,
    required this.isUrgent,
    required this.sendSms,
  });

  final String id;
  final String titleEn;
  final String titleOm;
  final String bodyEn;
  final String bodyOm;
  final DateTime publishedAt;
  final bool isUrgent;
  final bool sendSms;

  String title(bool isOm) => isOm ? titleOm : titleEn;
  String body(bool isOm) => isOm ? bodyOm : bodyEn;
}