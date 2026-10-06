import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_colors.dart';

/// Semantic tokens that vary by theme. Screens read these via
/// `context.tokens` — never the raw palette.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color divider;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnPrimary;

  final Color primary;
  final Color primaryAction;
  final Color accent;

  final Color statePaid;
  final Color statePaidBg;
  final Color statePartial;
  final Color statePartialBg;
  final Color stateUnpaid;
  final Color stateUnpaidBg;
  final Color stateWaived;
  final Color stateWaivedBg;
  final Color statePending;
  final Color statePendingBg;

  final Color success;
  final Color error;

  /// Very subtle paper texture overlay colour for the background.
  final Color paperNoise;

  const AppTokens({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnPrimary,
    required this.primary,
    required this.primaryAction,
    required this.accent,
    required this.statePaid,
    required this.statePaidBg,
    required this.statePartial,
    required this.statePartialBg,
    required this.stateUnpaid,
    required this.stateUnpaidBg,
    required this.stateWaived,
    required this.stateWaivedBg,
    required this.statePending,
    required this.statePendingBg,
    required this.success,
    required this.error,
    required this.paperNoise,
  });

  @override
  AppTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnPrimary,
    Color? primary,
    Color? primaryAction,
    Color? accent,
    Color? statePaid,
    Color? statePaidBg,
    Color? statePartial,
    Color? statePartialBg,
    Color? stateUnpaid,
    Color? stateUnpaidBg,
    Color? stateWaived,
    Color? stateWaivedBg,
    Color? statePending,
    Color? statePendingBg,
    Color? success,
    Color? error,
    Color? paperNoise,
  }) {
    return AppTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      primary: primary ?? this.primary,
      primaryAction: primaryAction ?? this.primaryAction,
      accent: accent ?? this.accent,
      statePaid: statePaid ?? this.statePaid,
      statePaidBg: statePaidBg ?? this.statePaidBg,
      statePartial: statePartial ?? this.statePartial,
      statePartialBg: statePartialBg ?? this.statePartialBg,
      stateUnpaid: stateUnpaid ?? this.stateUnpaid,
      stateUnpaidBg: stateUnpaidBg ?? this.stateUnpaidBg,
      stateWaived: stateWaived ?? this.stateWaived,
      stateWaivedBg: stateWaivedBg ?? this.stateWaivedBg,
      statePending: statePending ?? this.statePending,
      statePendingBg: statePendingBg ?? this.statePendingBg,
      success: success ?? this.success,
      error: error ?? this.error,
      paperNoise: paperNoise ?? this.paperNoise,
    );
  }

  @override
  AppTokens lerp(covariant ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      divider: l(divider, other.divider),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textOnPrimary: l(textOnPrimary, other.textOnPrimary),
      primary: l(primary, other.primary),
      primaryAction: l(primaryAction, other.primaryAction),
      accent: l(accent, other.accent),
      statePaid: l(statePaid, other.statePaid),
      statePaidBg: l(statePaidBg, other.statePaidBg),
      statePartial: l(statePartial, other.statePartial),
      statePartialBg: l(statePartialBg, other.statePartialBg),
      stateUnpaid: l(stateUnpaid, other.stateUnpaid),
      stateUnpaidBg: l(stateUnpaidBg, other.stateUnpaidBg),
      stateWaived: l(stateWaived, other.stateWaived),
      stateWaivedBg: l(stateWaivedBg, other.stateWaivedBg),
      statePending: l(statePending, other.statePending),
      statePendingBg: l(statePendingBg, other.statePendingBg),
      success: l(success, other.success),
      error: l(error, other.error),
      paperNoise: l(paperNoise, other.paperNoise),
    );
  }

  static const light = AppTokens(
    background: AppColors.cream50,
    surface: AppColors.cream100,
    surfaceAlt: AppColors.cream200,
    divider: AppColors.cream200,
    textPrimary: AppColors.charcoal900,
    textSecondary: AppColors.charcoal700,
    textMuted: AppColors.charcoal500,
    textOnPrimary: AppColors.cream50,
    primary: AppColors.forest700,
    primaryAction: AppColors.clay500,
    accent: AppColors.ochre500,
    statePaid: AppColors.forest500,
    statePaidBg: AppColors.forest100,
    statePartial: AppColors.ochre500,
    statePartialBg: AppColors.ochre100,
    stateUnpaid: AppColors.rust600,
    stateUnpaidBg: Color(0xFFF3DDD8),
    stateWaived: AppColors.charcoal500,
    stateWaivedBg: AppColors.cream200,
    statePending: AppColors.ochre500,
    statePendingBg: AppColors.ochre100,
    success: AppColors.forest500,
    error: AppColors.rust600,
    paperNoise: Color(0x08000000),
  );

  static const dark = AppTokens(
    background: AppColors.night900,
    surface: AppColors.night800,
    surfaceAlt: AppColors.night700,
    divider: AppColors.night700,
    textPrimary: AppColors.cream100,
    textSecondary: AppColors.cream200,
    textMuted: AppColors.charcoal300,
    textOnPrimary: AppColors.night900,
    primary: AppColors.forest300,
    primaryAction: AppColors.clay300,
    accent: AppColors.ochre300,
    statePaid: AppColors.forest300,
    statePaidBg: Color(0x2A4A7B5C),
    statePartial: AppColors.ochre300,
    statePartialBg: Color(0x2AC9922E),
    stateUnpaid: AppColors.rust300,
    stateUnpaidBg: Color(0x2AA3341F),
    stateWaived: AppColors.charcoal300,
    stateWaivedBg: AppColors.night700,
    statePending: AppColors.ochre300,
    statePendingBg: Color(0x2AC9922E),
    success: AppColors.forest300,
    error: AppColors.rust300,
    paperNoise: Color(0x0AFFFFFF),
  );
}

/// Convenience accessor: `context.tokens.statePaid`
extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}