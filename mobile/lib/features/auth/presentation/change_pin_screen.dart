import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/auth/data/models/auth_models.dart';
import 'package:odaa_mobile/features/auth/data/pin_strength.dart';
import 'package:odaa_mobile/features/auth/domain/auth_providers.dart';
import 'package:odaa_mobile/features/auth/presentation/widgets/pin_strength_bar.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/pin_dots.dart';
import 'package:odaa_mobile/shared/widgets/pin_pad.dart';
import 'package:odaa_mobile/shared/widgets/primary_button.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

/// Two-step flow, one step visible at a time.
enum _Step { newPin, confirmPin }

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  _Step _step = _Step.newPin;

  String _newPin = '';
  String _confirmPin = '';

  bool _isLoading = false;
  String? _errorText;
  int _attempt = 0;

  PinStrength get _strength => PinStrengthChecker.check(_newPin);
  bool get _isWeak => _newPin.length == 4 && _strength == PinStrength.weak;
  bool get _canMoveToConfirm => _newPin.length == 4 && !_isWeak;

  void _goToConfirm() {
    setState(() {
      _step = _Step.confirmPin;
      _confirmPin = '';
      _errorText = null;
    });
  }

  void _goBackToNewPin() {
    setState(() {
      _step = _Step.newPin;
      _newPin = '';
      _confirmPin = '';
      _errorText = null;
      _attempt++;
    });
  }

  Future<void> _submit(String confirm) async {
    if (_isLoading) return;

    if (confirm != _newPin) {
      setState(() {
        _errorText = context.l10n.authPinMismatch;
        _confirmPin = '';
        _attempt++;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final session = ref.read(sessionProvider);
    final token = switch (session) {
      SessionSignedIn(:final token) => token,
      _ => '',
    };

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.changePin(
      accessToken: token,
      currentPin: '1234', // mock expects the temporary PIN
      newPin: _newPin,
    );

    if (!mounted) return;

    switch (result) {
      case AuthOk():
        context.goNamed('home');
      case AuthErr(:final failure):
        setState(() {
          _isLoading = false;
          _errorText = _messageFor(failure);
        });
    }
  }

  String _messageFor(AuthFailure f) {
    switch (f.error) {
      case AuthError.wrongCredentials:
        return 'Your session has expired. Please sign in again.';
      case AuthError.network:
        return context.l10n.errorNetwork;
      default:
        return context.l10n.errorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdge,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // ---------- Header ----------
              Text(
                _step == _Step.newPin
                    ? l10n.authChangePinTitle
                    : l10n.authConfirmPinLabel,
                style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _step == _Step.newPin
                    ? l10n.authChangePinBody
                    : l10n.authConfirmPinHint,
                style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ---------- Step content ----------
              Expanded(
                child: _step == _Step.newPin
                    ? _buildNewPinStep(tokens, l10n)
                    : _buildConfirmStep(tokens, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewPinStep(dynamic tokens, dynamic l10n) {
   const int attempt = 0;
    return Column(
      children: [
        PinDots(length: 4, filled: _newPin.length),
        const SizedBox(height: AppSpacing.lg),
        if (_newPin.length == 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: PinStrengthBar(
              strength: _strength,
              message: PinStrengthChecker.message(
                _strength,
                Localizations.localeOf(context).languageCode,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xxl),
        PinPad(
          key: ValueKey('new-$attempt'),
          length: 4,
          showDots: false,
          enabled: !_isLoading,
          onChanged: (value) => setState(() => _newPin = value),
          onCompleted: (_) {
            // New-PIN step doesn't auto-advance — the Continue button does.
          },
        ),
        const Spacer(),
        PrimaryButton(
          label: l10n.actionContinue,
          onPressed: _canMoveToConfirm ? _goToConfirm : null,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildConfirmStep(dynamic tokens, dynamic l10n) {
    return Column(
      children: [
        PinDots(length: 4, filled: _confirmPin.length),
        const SizedBox(height: AppSpacing.lg),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              _errorText!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS.copyWith(color: tokens.error),
            ),
          ),
        const SizedBox(height: AppSpacing.xxl),
        PinPad(
          key: ValueKey('confirm-$_attempt'),
          length: 4,
          showDots: false,
          enabled: !_isLoading,
          onChanged: (v) => setState(() => _confirmPin = v),
          onCompleted: _submit,
        ),
        const Spacer(),
        TextButton(
          onPressed: _isLoading ? null : _goBackToNewPin,
          child: Text(
            l10n.actionBack,
            style: AppTypography.label.copyWith(color: tokens.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
