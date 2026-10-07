import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/theme/app_spacing.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/core/theme/app_typography.dart';
import 'package:odaa_mobile/features/profile/domain/profile_providers.dart';
import 'package:odaa_mobile/features/profile/presentation/widgets/profile_row.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final versionAsync = ref.watch(appVersionProvider);

    final currentLanguage = lang?.languageCode == 'om'
        ? l10n.languageOromo
        : l10n.languageEnglish;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.lg,
            AppSpacing.screenEdge,
            AppSpacing.lg,
          ),
          child: Text(
            l10n.profileTitle,
            style: AppTypography.titleL.copyWith(color: tokens.textPrimary),
          ),
        ),
        Divider(height: 1, color: tokens.divider),

        // Language
        ProfileRow(
          icon: Icons.language,
          label: l10n.profileLanguage,
          trailing: currentLanguage,
          onTap: () => _showLanguageSheet(context, ref),
        ),

        // Change PIN
        ProfileRow(
          icon: Icons.lock_outline,
          label: l10n.profileChangePin,
          onTap: () => context.pushNamed('changePin'),
        ),

        // Devices
        ProfileRow(
          icon: Icons.devices_outlined,
          label: l10n.profileDevices,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('My devices — coming soon')),
            );
          },
        ),

        const SizedBox(height: AppSpacing.lg),
        Divider(height: 1, color: tokens.divider),

        // Log out
        ProfileRow(
          icon: Icons.logout,
          label: l10n.profileLogout,
          isDestructive: true,
          onTap: () => _confirmLogout(context, ref),
        ),

        // Version
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdge,
            AppSpacing.xxxl,
            AppSpacing.screenEdge,
            AppSpacing.lg,
          ),
          child: versionAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (v) => Text(
              l10n.profileVersion(v),
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: tokens.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) async {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final current = ref.read(languageProvider)?.languageCode ?? 'en';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                title: Text(
                  l10n.languageEnglish,
                  style: AppTypography.body.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                trailing: current == 'en'
                    ? Icon(Icons.check, color: tokens.primaryAction)
                    : null,
                onTap: () async {
                  await ref.read(languageProvider.notifier).setLanguage('en');
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                title: Text(
                  l10n.languageOromo,
                  style: AppTypography.body.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
                trailing: current == 'om'
                    ? Icon(Icons.check, color: tokens.primaryAction)
                    : null,
                onTap: () async {
                  await ref.read(languageProvider.notifier).setLanguage('om');
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileLogout),
        content: Text(l10n.profileLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.profileLogout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(sessionProvider.notifier).signOut();
      if (context.mounted) context.goNamed('login');
    }
  }
}