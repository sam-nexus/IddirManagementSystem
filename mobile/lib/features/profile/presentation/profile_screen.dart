import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';
import 'package:odaa_mobile/core/providers/calendar_provider.dart';
import 'package:odaa_mobile/core/providers/theme_provider.dart';
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
    final themeMode = ref.watch(themeModeProvider);
    final versionAsync = ref.watch(appVersionProvider);
    final calendarSystem = ref.watch(calendarSystemProvider);
    final currentCalendarLabel = calendarSystem == CalendarSystem.ethiopian
        ? l10n.calendarEthiopian
        : l10n.calendarGregorian;

    final currentLanguage =
        lang?.languageCode == 'om' ? l10n.languageOromo : l10n.languageEnglish;

    final currentThemeLabel = switch (themeMode) {
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
      ThemeMode.system => l10n.themeSystem,
    };

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.profileTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          // Language
          ProfileRow(
            icon: Icons.language,
            label: l10n.profileLanguage,
            trailing: currentLanguage,
            onTap: () => _showLanguageSheet(context, ref),
          ),

          // Appearance
          ProfileRow(
            icon: Icons.brightness_6_outlined,
            label: l10n.profileAppearance,
            trailing: currentThemeLabel,
            onTap: () => _showThemeSheet(context, ref),
          ),

          // Calendar
          ProfileRow(
            icon: Icons.calendar_month_outlined,
            label: l10n.profileCalendar,
            trailing: currentCalendarLabel, // ← replace with the calendar label
            onTap: () => _showCalendarSheet(context, ref),
          ),

          // Change PIN
          ProfileRow(
            icon: Icons.lock_outline,
            label: l10n.profileChangePin,
            onTap: () => context.pushNamed('changePin'),
          ),

          // Dependents
          ProfileRow(
            icon: Icons.people_outline,
            label: l10n.dependentsTitle,
            onTap: () => context.pushNamed('dependents'),
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
      ),
    );
  }


    Future<void> _showCalendarSheet(BuildContext context, WidgetRef ref) async {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final current = ref.read(calendarSystemProvider);

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
              _SheetHandle(tokens: tokens),
              _SheetOption(
                label: l10n.calendarGregorian,
                selected: current == CalendarSystem.gregorian,
                onTap: () async {
                  await ref.read(calendarSystemProvider.notifier)
                      .setSystem(CalendarSystem.gregorian);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              _SheetOption(
                label: l10n.calendarEthiopian,
                selected: current == CalendarSystem.ethiopian,
                onTap: () async {
                  await ref.read(calendarSystemProvider.notifier)
                      .setSystem(CalendarSystem.ethiopian);
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

  // ---------------------------------------------------------------------------
  // Language sheet
  // ---------------------------------------------------------------------------
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
              _SheetHandle(tokens: tokens),
              _SheetOption(
                label: l10n.languageEnglish,
                selected: current == 'en',
                onTap: () async {
                  await ref.read(languageProvider.notifier).setLanguage('en');
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              _SheetOption(
                label: l10n.languageOromo,
                selected: current == 'om',
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

  // ---------------------------------------------------------------------------
  // Theme sheet
  // ---------------------------------------------------------------------------
  Future<void> _showThemeSheet(BuildContext context, WidgetRef ref) async {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final current = ref.read(themeModeProvider);

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
              _SheetHandle(tokens: tokens),
              _SheetOption(
                label: l10n.themeSystem,
                selected: current == ThemeMode.system,
                onTap: () async {
                  await ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.system);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              _SheetOption(
                label: l10n.themeLight,
                selected: current == ThemeMode.light,
                onTap: () async {
                  await ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.light);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              _SheetOption(
                label: l10n.themeDark,
                selected: current == ThemeMode.dark,
                onTap: () async {
                  await ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.dark);
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
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.tokens});

  final dynamic tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: tokens.divider as Color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListTile(
      title: Text(
        label,
        style: AppTypography.body.copyWith(color: tokens.textPrimary),
      ),
      trailing:
          selected ? Icon(Icons.check, color: tokens.primaryAction) : null,
      onTap: onTap,
    );
  }
}
