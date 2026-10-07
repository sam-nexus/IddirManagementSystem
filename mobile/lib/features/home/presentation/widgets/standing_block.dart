import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

/// Two numbers side by side, no cards. A small hand-drawn divider between.
class StandingBlock extends StatelessWidget {
  const StandingBlock({
    required this.amountOwed,
    required this.currency,
    required this.monthsPaid,
    required this.monthsTotal,
    super.key,
  });

  final double amountOwed;
  final String currency;
  final int monthsPaid;
  final int monthsTotal;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    final owesColor =
        amountOwed > 0 ? tokens.stateUnpaid : tokens.statePaid;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeYouOwe,
                style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                Money.etb(amountOwed),
                style: AppTypography.moneyLarge.copyWith(color: owesColor),
              ),
            ],
          ),
        ),
        _CurvedDivider(color: tokens.divider),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeMonthsPaid,
                style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                '$monthsPaid of $monthsTotal',
                style: AppTypography.moneyLarge.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurvedDivider extends StatelessWidget {
  const _CurvedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: 14,
        height: 56,
        child: CustomPaint(painter: _CurvePainter(color)),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..quadraticBezierTo(
        size.width * 0.05, size.height / 2,
        size.width / 2, size.height,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) => old.color != color;
}