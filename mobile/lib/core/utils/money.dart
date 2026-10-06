import 'package:intl/intl.dart';

/// Formats a numeric amount as ETB with thousands separators and two decimals.
/// Result examples: "ETB 0.00", "ETB 1,200.00", "ETB 45.50".
abstract final class Money {
  static final _fmt = NumberFormat('#,##0.00', 'en_US');

  static String etb(num amount) => 'ETB ${_fmt.format(amount)}';

  /// Short form used where space is tight: "1,200" (drops cents if whole).
  static String etbShort(num amount) {
    if (amount == amount.roundToDouble()) {
      return 'ETB ${NumberFormat('#,##0', 'en_US').format(amount)}';
    }
    return etb(amount);
  }
}