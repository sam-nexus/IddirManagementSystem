import 'package:flutter/foundation.dart';

@immutable
class Dependent {
  const Dependent({
    required this.id,
    required this.fullName,
    required this.relationship,
    required this.isActive,
    this.dateOfBirth,
  });

  final String id;
  final String fullName;
  final String relationship;
  final bool isActive;
  final DateTime? dateOfBirth;

  bool get isChild => relationship == 'child';
  bool get isSpouse => relationship == 'spouse';
  bool get isParent => relationship == 'parent';
}