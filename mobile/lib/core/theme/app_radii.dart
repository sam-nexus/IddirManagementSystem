import 'package:flutter/widgets.dart';

abstract final class AppRadii {
  static const xs  = BorderRadius.all(Radius.circular(4));
  static const sm  = BorderRadius.all(Radius.circular(8));
  static const md  = BorderRadius.all(Radius.circular(12));
  static const lg  = BorderRadius.all(Radius.circular(16));
  static const xl  = BorderRadius.all(Radius.circular(24));

  /// Leaf shape — asymmetric, matches the Odaa leaf painter.
  static const leaf = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(24),
    bottomRight: Radius.circular(24),
  );

  /// Receipt slip corners — top square (torn), bottom rounded.
  static const receiptTop = BorderRadius.vertical(top: Radius.zero);
  static const receiptBottom = BorderRadius.vertical(bottom: Radius.circular(12));
}