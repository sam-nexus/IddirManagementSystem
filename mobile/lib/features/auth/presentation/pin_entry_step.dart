import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/pin_pad.dart';

class PinEntryStep extends StatefulWidget {
  const PinEntryStep({
    required this.phoneDisplay,
    required this.onSubmit,
    required this.onBack,
    required this.isLoading,
    required this.errorText,
    this.controller,
    super.key,
  });

  final String phoneDisplay;
  final ValueChanged<String> onSubmit;
  final VoidCallback onBack;
  final bool isLoading;
  final String? errorText;
  final PinPadController? controller;

  @override
  State<PinEntryStep> createState() => _PinEntryStepState();
}

class _PinEntryStepState extends State<PinEntryStep> {
  final _padController = PinPadController();

  @override
  void dispose() {
    super.dispose();
  }

  void _onCompleted(String pin) {
    widget.onSubmit(pin);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    // When the parent changes the error text, clear the pad.
    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _padController.clear();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.authPinLabel,
          style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.phoneDisplay,
          style: AppTypography.body.copyWith(color: tokens.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (widget.errorText != null && widget.errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              widget.errorText!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS.copyWith(color: tokens.error),
            ),
          ),
        Center(
          child: PinPad(
            length: 4,
            controller: _padController,
            enabled: !widget.isLoading,
            onCompleted: _onCompleted,
          ),
        ),
        const Spacer(),
        Center(
          child: TextButton(
            onPressed: widget.isLoading ? null : widget.onBack,
            child: Text(
              l10n.actionBack,
              style: AppTypography.label.copyWith(color: tokens.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}