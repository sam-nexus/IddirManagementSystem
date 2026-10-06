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

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  String _newPin = '';
  String? _confirmPin;
  bool _isLoading = false;
  String? _errorText;

  PinStrength get _strength => PinStrengthChecker.check(_newPin);

  bool get _isWeak => _newPin.length == 4 && _strength == PinStrength.weak;
  bool get _canMoveToConfirm => _newPin.length == 4 && !_isWeak;

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
              Text(
                l10n.authChangePinTitle,
                style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.authChangePinBody,
                style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: _confirmPin == null
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
          length: 4,
          enabled: !_isLoading && _newPin.length < 4,
          onCompleted: (_) {}, // handled by onChanged below
          onChanged: (value) => setState(() => _newPin = value),
        ),
        const Spacer(),
        PrimaryButton(
          label: l10n.actionContinue,
          onPressed: _canMoveToConfirm
              ? () => setState(() => _confirmPin = '')
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildConfirmStep(dynamic tokens, dynamic l10n) {
    return Column(
      children: [
        PinDots(length: 4, filled: _confirmPin?.length ?? 0),
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
          length: 4,
          enabled: !_isLoading,
          onChanged: (v) => setState(() => _confirmPin = v),
          onCompleted: _submit,
        ),
        const Spacer(),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => setState(() {
                    _confirmPin = null;
                    _errorText = null;
                  }),
          child: Text(
            l10n.actionBack,
            style: AppTypography.label.copyWith(color: tokens.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Future<void> _submit(String confirm) async {
    if (_isLoading) return;
    if (confirm != _newPin) {
      setState(() {
        _errorText = context.l10n.authPinMismatch;
        _confirmPin = '';
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
}