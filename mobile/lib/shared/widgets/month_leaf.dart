import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

class MonthLeaf extends StatelessWidget {
  const MonthLeaf({
    required this.state,
    this.size = 28,
    this.isCurrentMonth = false,
    super.key,
  });

  final ContributionState state;
  final double size;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LeafPainter(
        state: state,
        isCurrentMonth: isCurrentMonth,
        tokens: context.tokens,
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  _LeafPainter({
    required this.state,
    required this.isCurrentMonth,
    required this.tokens,
  });

  final ContributionState state;
  final bool isCurrentMonth;
  final dynamic tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _leafPath(size);

    final fillColor = switch (state) {
      ContributionState.paid => tokens.statePaid as Color,
      ContributionState.unpaid => Colors.transparent,
      ContributionState.waived => Colors.transparent,
      ContributionState.pending => tokens.statePending as Color,
      ContributionState.suspended => Colors.transparent,
    };

    final strokeColor = switch (state) {
      ContributionState.paid => tokens.statePaid as Color,
      ContributionState.unpaid => tokens.stateUnpaid as Color,
      ContributionState.waived => tokens.stateWaived as Color,
      ContributionState.pending => tokens.statePending as Color,
      ContributionState.suspended => tokens.textMuted as Color,
    };

    if (fillColor != Colors.transparent) {
      canvas.drawPath(path, Paint()..color = fillColor);
    }

    if (state != ContributionState.paid) {
      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCurrentMonth ? 2.0 : 1.5,
      );
    }

    if (state == ContributionState.waived) {
      final p = Paint()
        ..color = strokeColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final inset = size.width * 0.32;
      canvas.drawLine(
        Offset(inset, inset),
        Offset(size.width - inset, size.height - inset),
        p,
      );
      canvas.drawLine(
        Offset(size.width - inset, inset),
        Offset(inset, size.height - inset),
        p,
      );
    }

    if (isCurrentMonth) {
      canvas.drawPath(
        path,
        Paint()
          ..color = (tokens.primaryAction as Color).withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }
  }

  Path _leafPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, h);
    path.cubicTo(w * 0.05, h * 0.75, w * 0.05, h * 0.25, w * 0.5, 0);
    path.cubicTo(w * 0.95, h * 0.25, w * 0.95, h * 0.75, w * 0.5, h);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _LeafPainter old) =>
      old.state != state ||
      old.isCurrentMonth != isCurrentMonth ||
      old.tokens != tokens;
}