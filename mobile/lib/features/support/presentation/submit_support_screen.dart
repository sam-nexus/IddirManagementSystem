import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_radii.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/dependents/domain/dependents_providers.dart';
import 'package:odaa_mobile/features/support/data/models/support_request.dart';
import 'package:odaa_mobile/features/support/domain/support_providers.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/primary_button.dart';
import 'package:odaa_mobile/shared/widgets/text_input.dart';

class SubmitSupportScreen extends ConsumerStatefulWidget {
  const SubmitSupportScreen({super.key});

  @override
  ConsumerState<SubmitSupportScreen> createState() =>
      _SubmitSupportScreenState();
}

class _SubmitSupportScreenState extends ConsumerState<SubmitSupportScreen> {
  SupportType _type = SupportType.death;
  String? _dependentId;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.length < 3) {
      setState(() => _error = 'Please describe the situation.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final amountText = _amountController.text.trim();
      final amount =
          amountText.isEmpty ? null : double.tryParse(amountText);

      final created = await ref.read(supportRepositoryProvider).submit(
            type: _type,
            description: description,
            amountRequested: amount,
            dependentId: _dependentId,
          );

      ref.invalidate(supportRequestsProvider);

      if (!mounted) return;
      context.pushReplacementNamed(
        'supportDetail',
        pathParameters: {'id': created.id},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final dependentsAsync = ref.watch(dependentsProvider);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.supportSubmit),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.lg,
          AppSpacing.screenEdge,
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector
            Text(
              l10n.supportType,
              style: AppTypography.label.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SupportType.values.map((t) {
                final selected = t == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? tokens.primaryAction : tokens.surface,
                      borderRadius: AppRadii.md,
                    ),
                    child: Text(
                      _typeLabel(t, l10n),
                      style: AppTypography.label.copyWith(
                        color: selected
                            ? tokens.textOnPrimary
                            : tokens.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Dependent picker (optional)
            dependentsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (deps) {
                if (deps.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.supportFor,
                      style: AppTypography.label.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String?>(
                      initialValue: _dependentId,
                      decoration: const InputDecoration(),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.supportForMe),
                        ),
                        ...deps.map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text('${d.fullName} (${d.relationship})'),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _dependentId = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
            ),

            TextInput(
              label: l10n.supportAmountRequested,
              controller: _amountController,
              hint: '0.00',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            TextInput(
              label: l10n.supportDescription,
              controller: _descriptionController,
              hint: l10n.supportDescriptionHint,
              maxLines: 5,
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
              label: l10n.supportSubmit,
              onPressed: _submitting ? null : _submit,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(SupportType t, dynamic l10n) {
    switch (t) {
      case SupportType.death:
        return l10n.supportTypeDeath;
      case SupportType.illness:
        return l10n.supportTypeIllness;
      case SupportType.emergency:
        return l10n.supportTypeEmergency;
      case SupportType.other:
        return l10n.supportTypeOther;
    }
  }
}