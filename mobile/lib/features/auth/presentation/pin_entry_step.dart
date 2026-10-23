import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/loading_overlay.dart';
import 'package:odaa_mobile/shared/widgets/pin_pad.dart';

class PinEntryStep extends StatefulWidget {
  const PinEntryStep({
    required this.phoneDisplay,
    required this.onSubmit,
    required this.onBack,
    required this.isLoading,
    required this.errorText,
    this.onUseAnotherNumber,
    this.controller,
    super.key,
  });

  final String phoneDisplay;
  final ValueChanged<String> onSubmit;
  final VoidCallback onBack;
  final bool isLoading;
  final String? errorText;
  final VoidCallback? onUseAnotherNumber;
  final PinPadController? controller;

  @override
  State<PinEntryStep> createState() => _PinEntryStepState();
}

class _PinEntryStepState extends State<PinEntryStep> {
  final _padController = PinPadController();

  @override
  void didUpdateWidget(covariant PinEntryStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear the pad whenever a new error arrives so the user can retry.
    if (widget.errorText != null &&
        widget.errorText!.isNotEmpty &&
        widget.errorText != oldWidget.errorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _padController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return LoadingOverlay(
      isLoading: widget.isLoading,
      message: l10n.authSigningIn,
      child: Column(
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
              onCompleted: widget.onSubmit,
            ),
          ),
          const Spacer(),
          if (widget.onUseAnotherNumber != null)
            Center(
              child: TextButton(
                onPressed:
                    widget.isLoading ? null : widget.onUseAnotherNumber,
                child: Text(
                  l10n.authUseAnotherNumber,
                  style: AppTypography.label.copyWith(color: tokens.primary),
                ),
              ),
            )
          else
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
      ),
    );
  }
}