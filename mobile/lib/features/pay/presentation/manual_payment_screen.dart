import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/core/utils/money.dart';
import 'package:odaa_mobile/features/pay/domain/manual_payment_providers.dart';
import 'package:odaa_mobile/features/payments/domain/payment_providers.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/primary_button.dart';

class ManualPaymentScreen extends ConsumerStatefulWidget {
  const ManualPaymentScreen({super.key});

  @override
  ConsumerState<ManualPaymentScreen> createState() =>
      _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends ConsumerState<ManualPaymentScreen>
    with WidgetsBindingObserver {
  Uint8List? _fileBytes;
  String? _filename;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Android may have killed us while the gallery was open. Recover.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForLostData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForLostData();
    }
  }

  /// Handles the case where Android destroyed the MainActivity while the
  /// gallery was open. The OS passes the recovered image back to us here.
  Future<void> _checkForLostData() async {
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.isEmpty) return;

      if (response.file != null) {
        final bytes = await response.file!.readAsBytes();
        if (!mounted) return;
        setState(() {
          _fileBytes = bytes;
          _filename = response.file!.name;
          _error = null;
        });
      } else if (response.exception != null) {
        if (!mounted) return;
        setState(() =>
            _error = 'Could not recover the selected image. Please try again.',);
      }
    } catch (_) {
      // Nothing to recover — silent.
    }
  }

  Future<void> _pickFile() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (picked == null) return; // user cancelled — not an error

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _fileBytes = bytes;
        _filename = picked.name;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not open the gallery.');
    }
  }

  Future<void> _submit() async {
    final bytes = _fileBytes;
    final name = _filename;
    if (bytes == null || name == null) {
      setState(() => _error = 'Please attach a screenshot first.');
      return;
    }

    final plan = ref.read(paymentPlanProvider).valueOrNull;
    if (plan == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final id = await ref.read(manualPaymentRepositoryProvider).submit(
            fileBytes: bytes,
            filename: name,
            amount: plan.total,
          );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.manualSubmittedTitle),
          content: Text(context.l10n.manualSubmittedBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.l10n.actionClose),
            ),
          ],
        ),
      );

      if (!mounted) return;
      ref.invalidate(paymentPlanProvider);
      context.goNamed('home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final plan = ref.watch(paymentPlanProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.manualTitle),
      ),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.errorGeneric)),
        data: (p) => SingleChildScrollView(
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
                l10n.manualAmount,
                style: AppTypography.label.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: AppRadii.md,
                ),
                child: Text(
                  Money.etb(p.total),
                  style: AppTypography.moneyMedium.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                l10n.manualProof,
                style: AppTypography.label.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _FilePicker(
                picked: _filename,
                onTap: _pickFile,
                hint: l10n.manualPickFile,
                replaceLabel: l10n.manualReplaceFile,
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: AppTypography.bodyS.copyWith(color: tokens.error),
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: l10n.manualSubmit,
                onPressed: _fileBytes == null || _submitting ? null : _submit,
                isLoading: _submitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    required this.picked,
    required this.onTap,
    required this.hint,
    required this.replaceLabel,
  });

  final String? picked;
  final VoidCallback onTap;
  final String hint;
  final String replaceLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasFile = picked != null;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.md,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hasFile ? tokens.statePaidBg : tokens.surface,
          borderRadius: AppRadii.md,
          border: Border.all(
            color: hasFile ? tokens.statePaid : tokens.divider,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile
                  ? Icons.image_outlined
                  : Icons.add_photo_alternate_outlined,
              size: 22,
              color: hasFile ? tokens.statePaid : tokens.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile ? picked! : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: hasFile ? tokens.textPrimary : tokens.textMuted,
                    ),
                  ),
                  if (hasFile) ...[
                    const SizedBox(height: 2),
                    Text(
                      replaceLabel,
                      style: AppTypography.caption.copyWith(
                        color: tokens.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}