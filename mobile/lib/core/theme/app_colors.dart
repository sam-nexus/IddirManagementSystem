import 'package:flutter/material.dart';

/// Raw colour palette for Afoosha Odaa.
///
/// Screens MUST NOT reference these directly. Use the semantic tokens exposed
/// through [AppTokens] (a [ThemeExtension]) instead, so light and dark themes
/// stay in sync.
abstract final class AppColors {
  // ---------- Forest (green) ----------
  static const forest900 = Color(0xFF1B3A2F);
  static const forest700 = Color(0xFF2E5A44);
  static const forest500 = Color(0xFF4A7B5C);
  static const forest300 = Color(0xFF7BB08C);
  static const forest100 = Color(0xFFDDE9DF);

  // ---------- Clay (terracotta) ----------
  static const clay700 = Color(0xFF8B4A2B);
  static const clay500 = Color(0xFFB36A3F);
  static const clay300 = Color(0xFFD68A5C);
  static const clay100 = Color(0xFFF4E3D4);

  // ---------- Ochre ----------
  static const ochre500 = Color(0xFFC9922E);
  static const ochre300 = Color(0xFFE0B45C);
  static const ochre100 = Color(0xFFF8EED2);

  // ---------- Cream / paper ----------
  static const cream50  = Color(0xFFFAF6EE);
  static const cream100 = Color(0xFFF2EBDD);
  static const cream200 = Color(0xFFE8DFCB);

  // ---------- Charcoal (text) ----------
  static const charcoal900 = Color(0xFF211E1A);
  static const charcoal700 = Color(0xFF4A443B);
  static const charcoal500 = Color(0xFF6E675E);
  static const charcoal300 = Color(0xFFA89F8E);

  // ---------- Rust (error) ----------
  static const rust600 = Color(0xFFA3341F);
  static const rust300 = Color(0xFFE07868);

  // ---------- Dark theme backgrounds ----------
  static const night900 = Color(0xFF14110D);
  static const night800 = Color(0xFF1E1A14);
  static const night700 = Color(0xFF2A2419);

  // ---------- Utility ----------
  static const transparent = Color(0x00000000);
}