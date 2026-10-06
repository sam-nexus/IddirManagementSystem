import 'package:flutter/material.dart';

/// Motion tokens. All animations in the app use these.
abstract final class AppMotion {
  static const fast   = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 220);
  static const slow   = Duration(milliseconds: 300);
  static const breath = Duration(milliseconds: 1400); // the PIN dot

  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutQuart;
  static const gentle = Curves.easeInOut;

  /// Respect the OS "reduce motion" setting.
  static Duration scale(BuildContext context, Duration base) {
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disable ? Duration.zero : base;
  }
}