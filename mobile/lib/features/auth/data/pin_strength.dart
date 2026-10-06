/// A PIN's strength score. Used to warn the member when they pick a
/// weak PIN, without shaming them.
enum PinStrength { weak, ok, strong }

abstract final class PinStrengthChecker {
  /// Rules (deliberately simple and explainable):
  ///   weak   — all same digit, or sequential (1234, 4321), or repeated (1212)
  ///   ok     — not weak, but 4 digits with low variation
  ///   strong — 4 digits with at least 3 distinct digits, not sequential
  static PinStrength check(String pin) {
    if (pin.length < 4) return PinStrength.weak;
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return PinStrength.weak;

    const sequential = {
      '0123', '1234', '2345', '3456', '4567', '5678', '6789',
      '9876', '8765', '7654', '6543', '5432', '4321', '3210',
    };
    if (sequential.contains(pin)) return PinStrength.weak;

    // Alternating pattern like 1212 / 2121
    if (pin.length >= 4 && pin[0] == pin[2] && pin[1] == pin[3]) {
      return PinStrength.weak;
    }

    final distinct = pin.split('').toSet().length;
    if (distinct <= 2) return PinStrength.ok;
    return PinStrength.strong;
  }

  /// A short, friendly message in a particular language.
  /// `lang` matches the ARB locale codes: 'en' or 'om'.
  static String? message(PinStrength s, String lang) {
    if (s != PinStrength.weak) return null;
    return lang == 'om'
        ? 'PIN kun salphaatti tilmaamama. Kan biraa filadhu.'
        : 'That PIN is easy to guess. Try a different one.';
  }
}