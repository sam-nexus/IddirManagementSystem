import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

/// The top of Home. Not a header bar — a line of greeting, in Figtree
/// for the small part and Fraunces for the warm part.
class GreetingLine extends StatelessWidget {
  const GreetingLine({required this.firstName, super.key});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final hour = DateTime.now().hour;

    final greeting = hour < 12
        ? l10n.greetingMorning
        : hour < 18
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          firstName,
          style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.homeStanding,
          style: AppTypography.body.copyWith(color: tokens.textSecondary),
        ),
      ],
    );
  }
}