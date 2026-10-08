import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/pay/data/models/payment_session.dart';
import 'package:odaa_mobile/features/pay/domain/pay_providers.dart';
import 'package:odaa_mobile/features/pay/presentation/widgets/pay_webview.dart';
import 'package:odaa_mobile/features/pay/presentation/widgets/plan_summary.dart';
import 'package:odaa_mobile/features/payments/domain/payment_providers.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/primary_button.dart';
import 'package:odaa_mobile/shared/widgets/secondary_button.dart';

class PayScreen extends ConsumerStatefulWidget {
  const PayScreen({this.period, super.key});

  /// Optional preselected period (YYYY-MM-DD) from the Months screen.
  final String? period;

  @override
  ConsumerState<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends ConsumerState<PayScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final planAsync = ref.watch(paymentPlanProvider);
    final session = ref.watch(paymentSessionProvider);

    // If the user is in the middle of a payment, show the webview step.
    if (session.status == PaymentSessionStatus.initializing ||
        session.status == PaymentSessionStatus.awaitingUser ||
        session.status == PaymentSessionStatus.verifying) {
      return _PayFlow(session: session);
    }

    return planAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => EmptyView(
        title: l10n.errorGeneric,
        body: l10n.errorRetry,
      ),
      data: (plan) {
        final hasPayment = plan.hasAnythingToPay;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.payTitle,
                style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                hasPayment ? l10n.paySummary : l10n.payNothingToPay,
                style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PlanSummary(plan: plan),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.payOpen,
                onPressed: hasPayment
                    ? () {
                        final periods = plan.payableRows
                            .map((r) =>
                                r.period.toIso8601String().split('T').first,)
                            .toList();
                        ref.read(paymentSessionProvider.notifier).init(
                              memberId: 'mock-member-id',
                              amount: plan.total,
                              periods: periods,
                            );
                      }
                    : null, // ← disabled when nothing to pay
              ),
              if (!hasPayment) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.payNothingToPayBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PayFlow extends ConsumerWidget {
  const _PayFlow({required this.session});

  final PaymentSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return switch (session.status) {
      PaymentSessionStatus.initializing =>
        const Center(child: CircularProgressIndicator()),
      PaymentSessionStatus.awaitingUser => PayWebView(
          url: session.checkoutUrl!,
          onClosed: () {
            if (session.txRef != null) {
              ref.read(paymentSessionProvider.notifier).verify(session.txRef!);
            }
          },
        ),
      PaymentSessionStatus.verifying => _VerifyingPanel(),
      PaymentSessionStatus.success => _SuccessPanel(session: session),
      PaymentSessionStatus.failed => _FailedPanel(
          message: session.errorMessage ?? l10n.payFailedTitle,
          onRetry: () {
            ref.read(paymentSessionProvider.notifier).reset();
          },
        ),
      PaymentSessionStatus.idle =>
        const Center(child: CircularProgressIndicator()),
    };
  }
}

class _VerifyingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(l10n.payPendingTitle, style: AppTypography.titleS),
            const SizedBox(height: 6),
            Text(
              l10n.payPendingBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessPanel extends ConsumerWidget {
  const _SuccessPanel({required this.session});

  final PaymentSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: tokens.statePaid,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.paySuccessTitle,
              style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.paySuccessBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (session.receiptNo != null)
              Text(
                session.receiptNo!,
                style: AppTypography.mono.copyWith(color: tokens.textMuted),
              ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: l10n.actionBack,
              onPressed: () {
                ref.read(paymentSessionProvider.notifier).reset();
                context.goNamed('home');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedPanel extends StatelessWidget {
  const _FailedPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: tokens.stateUnpaid),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.payFailedTitle,
              style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyS.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SecondaryButton(label: l10n.errorRetry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
