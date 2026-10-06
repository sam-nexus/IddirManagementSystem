import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/primary_button.dart';
import 'package:odaa_mobile/shared/widgets/text_input.dart';

class PhoneEntryStep extends StatelessWidget {
  const PhoneEntryStep({
    required this.controller,
    required this.errorText,
    required this.isLoading,
    required this.onContinue,
    super.key,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool isLoading;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final canContinue = controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.authLogin,
          style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.authPhoneHint,
          style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextInput(
          label: l10n.authPhoneLabel,
          hint: l10n.authPhoneHint,
          controller: controller,
          errorText: errorText,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
            LengthLimitingTextInputFormatter(15),
          ],
          prefixIcon: Icons.phone_outlined,
          onChanged: (_) => (context as Element).markNeedsBuild(),
          onSubmitted: (_) {
            if (canContinue) onContinue();
          },
        ),
        const Spacer(),
        PrimaryButton(
          label: l10n.actionContinue,
          onPressed: canContinue ? onContinue : null,
          isLoading: isLoading,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}