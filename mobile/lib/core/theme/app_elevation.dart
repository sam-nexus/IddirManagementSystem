import 'package:flutter/material.dart';

/// Very subtle shadows only. No heavy drop shadows anywhere.
abstract final class AppElevation {
  static const none = <BoxShadow>[];

  static const paper = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F1B3A2F),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x141B3A2F),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}