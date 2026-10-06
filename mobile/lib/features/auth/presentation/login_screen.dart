import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/features/auth/data/models/auth_models.dart';
import 'package:odaa_mobile/features/auth/domain/auth_providers.dart';
import 'package:odaa_mobile/features/auth/presentation/phone_entry_step.dart';
import 'package:odaa_mobile/features/auth/presentation/pin_entry_step.dart';
import 'package:odaa_mobile/features/auth/presentation/widgets/back_step_button.dart';
import 'package:odaa_mobile/features/auth/presentation/widgets/locked_banner.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

enum _Step { phone, pin }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();

  _Step _step = _Step.phone;
  bool _isLoading = false;
  String? _errorText;
  AuthError _lastError = AuthError.none;
  DateTime? _lockedUntil;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinueFromPhone() {
    setState(() {
      _step = _Step.pin;
      _errorText = null;
      _lastError = AuthError.none;
    });
  }

  void _onBackToPhone() {
    setState(() {
      _step = _Step.phone;
      _errorText = null;
      _lastError = AuthError.none;
    });
  }

  Future<void> _submitPin(String pin) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
      _lastError = AuthError.none;
    });

    final repo = ref.read(authRepositoryProvider);
    final deviceId = await ref.read(secureStoreProvider).readDeviceId() ??
        'unknown-device';

    final result = await repo.login(
      phone: _phoneController.text.trim(),
      pin: pin,
      deviceId: deviceId,
    );

    if (!mounted) return;

    switch (result) {
      case AuthOk(session: final s):
        await ref.read(sessionProvider.notifier).signIn(
              accessToken: s.accessToken,
              refreshToken: s.refreshToken,
            );
        if (!mounted) return;
        if (s.mustChangePin) {
          context.goNamed('changePin');
        } else {
          context.goNamed('home');
        }

      case AuthErr(failure: final f):
        setState(() {
          _isLoading = false;
          _lastError = f.error;
          _lockedUntil = f.lockedUntil;
          _errorText = _messageFor(f, context);
        });
    }
  }

  String? _messageFor(AuthFailure f, BuildContext context) {
    final l10n = context.l10n;
    switch (f.error) {
      case AuthError.wrongCredentials:
        return 'That PIN is not right. Please try again.';
      case AuthError.unknownPhone:
        return 'We do not recognize that number.';
      case AuthError.accountSuspended:
        return 'This account is suspended. Please contact the committee.';
      case AuthError.network:
        return l10n.errorNetwork;
      case AuthError.accountLocked:
      case AuthError.server:
      case AuthError.unknown:
      case AuthError.none:
        return null; // handled elsewhere
    }
  }

  @override
  Widget build(BuildContext context) {
    // final tokens = context.tokens;
    final l10n = context.l10n;
    final isLocked = _lastError == AuthError.accountLocked;

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
              // Back arrow appears only on the PIN step
              SizedBox(
                height: 44,
                child: _step == _Step.pin
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: BackStepButton(onTap: _onBackToPhone),
                      )
                    : null,
              ),

              if (isLocked && _lockedUntil != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: LockedBanner(
                    title: l10n.authLockedTitle,
                    body: l10n.authLockedBody(_remainingMinutes()),
                  ),
                ),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _step == _Step.phone
                      ? PhoneEntryStep(
                          key: const ValueKey('phone'),
                          controller: _phoneController,
                          errorText: _errorText,
                          isLoading: _isLoading,
                          onContinue: _onContinueFromPhone,
                        )
                      : PinEntryStep(
                          key: const ValueKey('pin'),
                          phoneDisplay: _phoneController.text.trim(),
                          isLoading: _isLoading,
                          errorText: _errorText,
                          onSubmit: _submitPin,
                          onBack: _onBackToPhone,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _remainingMinutes() {
    final u = _lockedUntil;
    if (u == null) return '15';
    final diff = u.difference(DateTime.now()).inMinutes;
    return diff <= 0 ? '0' : diff.toString();
  }
}