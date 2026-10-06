/// 4-based spacing scale. Never use raw pixels in screens — use these tokens.
abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 12.0;
  static const lg  = 16.0;
  static const xl  = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Minimum tap target size (Android/iOS accessibility guidance).
  static const minTapTarget = 48.0;

  /// Standard screen edge padding.
  static const screenEdge = 20.0;
}