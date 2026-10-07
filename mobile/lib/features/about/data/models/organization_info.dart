import 'package:flutter/foundation.dart';

@immutable
class OrganizationInfo {
  const OrganizationInfo({
    required this.missionEn,
    required this.missionOm,
    required this.visionEn,
    required this.visionOm,
    required this.bylawsEn,
    required this.bylawsOm,
    required this.committee,
  });

  final String missionEn;
  final String missionOm;
  final String visionEn;
  final String visionOm;
  final String bylawsEn;
  final String bylawsOm;
  final List<CommitteeMember> committee;
}

@immutable
class CommitteeMember {
  const CommitteeMember({
    required this.name,
    required this.role,
    required this.phone,
  });

  final String name;
  final String role; // 'chairperson' | 'secretary' | 'treasurer' | 'auditor'
  final String phone;
}