import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/splash/presentation/widgets/language_card.dart';
import 'package:odaa_mobile/l10n/l10n.dart';
import 'package:odaa_mobile/shared/widgets/primary_button.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(languageProvider)?.languageCode;
  }

  Future<void> _continue() async {
    final code = _selected;
    if (code == null) return;
    await ref.read(languageProvider.notifier).setLanguage(code);
    if (!mounted) return;
    context.goNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final canContinue = _selected != null;

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
                l10n.languageTitle,
                style: AppTypography.titleL.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.languageSubtitle,
                style: AppTypography.body.copyWith(
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              LanguageCard(
                title: l10n.languageEnglish,
                subtitle: 'English',
                selected: _selected == 'en',
                onTap: () => setState(() => _selected = 'en'),
              ),
              const SizedBox(height: AppSpacing.md),
              LanguageCard(
                title: l10n.languageOromo,
                subtitle: 'Afaan Oromoo',
                selected: _selected == 'om',
                onTap: () => setState(() => _selected = 'om'),
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.languageContinue,
                onPressed: canContinue ? _continue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}