
/// Small helpers that make accessibility consistent.
abstract final class A11y {
  /// Announce a value to screen readers without a visible label.
  static String money(String value) => value.replaceAll('ETB', 'ETB ');

  /// A semantic label for a month in a specific state.
  static String monthLabel({
    required String monthName,
    required String state,
    required String amount,
  }) => '$monthName, $state, $amount';
}