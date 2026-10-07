import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/features/history/data/models/payment_record.dart';
import 'package:odaa_mobile/features/receipt/domain/receipt_providers.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/empty_view.dart';
import 'package:odaa_mobile/shared/widgets/error_view.dart';
import 'package:odaa_mobile/shared/widgets/receipt_slip.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({required this.paymentId, super.key});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final async = ref.watch(receiptProvider(paymentId));

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.receiptTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Deep-link fallback: if we arrived directly on this URL,
              // there's nothing to pop to.
              context.goNamed('history');
            }
          },
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorView(
          message: l10n.errorGeneric,
          onRetry: () => ref.invalidate(receiptProvider(paymentId)),
        ),
        data: (record) {
          if (record == null) {
            return EmptyView(
              title: l10n.receiptNotFound,
              icon: Icons.receipt_long_outlined,
            );
          }
          return _ReceiptBody(record: record);
        },
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.record});

  final PaymentRecord record;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final isOm = Localizations.localeOf(context).languageCode == 'om';

    final methodLabel = switch (record.method) {
      PaymentMethod.chapa => l10n.historyMethodChapa,
      PaymentMethod.cash => l10n.historyMethodCash,
      PaymentMethod.manual => l10n.historyMethodManual,
    };

    final periodsText =
        record.periodsCovered.map((iso) => _monthLabel(iso, isOm)).join(' · ');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          ReceiptSlip(
            receiptNumber: record.receiptNo ?? '—',
            children: [
              _Row(
                label: l10n.receiptDate,
                value: _formatDate(record.paidAt),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Row(label: l10n.receiptAmount, value: Money.etb(record.amount)),
              const SizedBox(height: AppSpacing.sm),
              _Row(label: l10n.receiptMethod, value: methodLabel),
              const SizedBox(height: AppSpacing.md),
              Divider(height: 1, color: tokens.divider),
              const SizedBox(height: AppSpacing.md),
              _Row(
                label: l10n.receiptPaidFor,
                value: periodsText,
                multiline: true,
              ),
              if (record.note != null) ...[
                const SizedBox(height: AppSpacing.md),
                _Row(
                  label: l10n.receiptNote,
                  value: record.note!,
                  multiline: true,
                ),
              ],
            ],
            footer: Center(
              child: Text(
                l10n.receiptThanks,
                style: AppTypography.bodyS.copyWith(
                  color: tokens.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _monthLabel(String iso, bool isOm) {
    final dt = DateTime.parse(iso);
    const namesEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const namesOm = [
      'Amajjii',
      'Guraandhala',
      'Bitooteessa',
      'Elbaa',
      'Caamsa',
      'Waxabajjii',
      'Adooleessa',
      'Hagayya',
      'Fuulbana',
      'Onkololeessa',
      'Sadaasa',
      'Muddee',
    ];
    final names = isOm ? namesOm : namesEn;
    return '${names[dt.month - 1]} ${dt.year}';
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: tokens.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMedium.copyWith(
              color: tokens.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
