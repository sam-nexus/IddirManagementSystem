import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/shared/widgets/month_leaf.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

/// The 12-leaf Odaa tree — the centerpiece of the Home screen.
class OdaaTree extends StatelessWidget {
  const OdaaTree({
    required this.months,
    this.currentMonthIndex,
    this.height = 220,
    super.key,
  });

  /// Exactly 12 entries: one per calendar month, in calendar order.
  final List<ContributionState> months;

  /// 0-based index of the current month (usually `DateTime.now().month - 1`).
  final int? currentMonthIndex;

  final double height;

  @override
  Widget build(BuildContext context) {
    assert(months.length == 12, 'OdaaTree requires exactly 12 months');
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrunkPainter(tokens: context.tokens),
        child: _LeavesLayer(
          months: months,
          currentMonthIndex: currentMonthIndex,
        ),
      ),
    );
  }
}

class _LeavesLayer extends StatelessWidget {
  const _LeavesLayer({
    required this.months,
    required this.currentMonthIndex,
  });

  final List<ContributionState> months;
  final int? currentMonthIndex;

  // Positioned along three gently curved branches.
  // x and y are fractions of the available width/height.
  static const _positions = <Offset>[
    // top branch
    Offset(0.32, 0.16),
    Offset(0.44, 0.10),
    Offset(0.56, 0.10),
    Offset(0.68, 0.16),
    // middle branch
    Offset(0.22, 0.40),
    Offset(0.38, 0.34),
    Offset(0.62, 0.34),
    Offset(0.78, 0.40),
    // lower branch
    Offset(0.28, 0.68),
    Offset(0.42, 0.60),
    Offset(0.58, 0.60),
    Offset(0.72, 0.68),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const leafSize = 30.0;

        return Stack(
          children: [
            for (var i = 0; i < 12; i++)
              Positioned(
                left: _positions[i].dx * w - leafSize / 2,
                top: _positions[i].dy * h - leafSize / 2,
                child: MonthLeaf(
                  state: months[i],
                  size: leafSize,
                  isCurrentMonth: currentMonthIndex == i,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TrunkPainter extends CustomPainter {
  _TrunkPainter({required this.tokens});

  final dynamic tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final trunkColor = (tokens.primary as Color).withValues(alpha: 0.9);

    // Trunk: a woven vertical shape, slightly wider at the base.
    final trunk = Path()
      ..moveTo(w * 0.47, h * 0.95)
      ..lineTo(w * 0.53, h * 0.95)
      ..quadraticBezierTo(w * 0.52, h * 0.55, w * 0.50, h * 0.30)
      ..quadraticBezierTo(w * 0.48, h * 0.55, w * 0.47, h * 0.95)
      ..close();
    canvas.drawPath(trunk, Paint()..color = trunkColor);

    // Three branches — soft curves that hold the leaves.
    final branch = Paint()
      ..color = trunkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final top = Path()
      ..moveTo(w * 0.50, h * 0.30)
      ..quadraticBezierTo(w * 0.30, h * 0.18, w * 0.14, h * 0.22);
    canvas.drawPath(top, branch);

    final topR = Path()
      ..moveTo(w * 0.50, h * 0.30)
      ..quadraticBezierTo(w * 0.70, h * 0.18, w * 0.86, h * 0.22);
    canvas.drawPath(topR, branch);

    final mid = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..quadraticBezierTo(w * 0.28, h * 0.42, w * 0.10, h * 0.50);
    canvas.drawPath(mid, branch);

    final midR = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..quadraticBezierTo(w * 0.72, h * 0.42, w * 0.90, h * 0.50);
    canvas.drawPath(midR, branch);

    final low = Path()
      ..moveTo(w * 0.50, h * 0.70)
      ..quadraticBezierTo(w * 0.30, h * 0.66, w * 0.15, h * 0.74);
    canvas.drawPath(low, branch);

    final lowR = Path()
      ..moveTo(w * 0.50, h * 0.70)
      ..quadraticBezierTo(w * 0.70, h * 0.66, w * 0.85, h * 0.74);
    canvas.drawPath(lowR, branch);
  }

  @override
  bool shouldRepaint(covariant _TrunkPainter old) => old.tokens != tokens;
}