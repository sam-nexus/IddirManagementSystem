import 'package:flutter/material.dart';

/// Afoosha Odaa type scale. Fraunces for headings and numbers, Figtree for body.
abstract final class AppTypography {
  static const _serif = 'Fraunces';
  static const _sans = 'Figtree';

  // ---------- Display (Fraunces) ----------
  static const display = TextStyle(
    fontFamily: _serif,
    fontSize: 40,
    height: 1.1,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );
  static const titleL = TextStyle(
    fontFamily: _serif,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const titleM = TextStyle(
    fontFamily: _serif,
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );
  static const titleS = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  // ---------- Body (Figtree) ----------
  static const body = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );
  static const bodyS = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  static const label = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static const caption = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  // ---------- Numeric (Fraunces) ----------
  static const moneyLarge = TextStyle(
    fontFamily: _serif,
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const moneyMedium = TextStyle(
    fontFamily: _serif,
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Receipt numbers, phone numbers — monospaced feel via tabular figures.
  static const mono = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}