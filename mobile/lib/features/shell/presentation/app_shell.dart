import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/features/shell/presentation/widgets/canopy_bar.dart';
import 'package:odaa_mobile/features/shell/presentation/widgets/canopy_subbar.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

/// The two-row "canopy" navigation shell that wraps the four main sections.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.section,
    required this.child,
    super.key,
  });

  final CanopySection section;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Persist the currently selected sub-section per top-level section.
  String _monthsSegment = 'this_year';
  String _moreSegment = 'about';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: tokens.background,
      body: Column(
        children: [
          // Top padding for the system status bar
          SizedBox(height: MediaQuery.of(context).padding.top),

          // The contextual sub-bar — only for Months and More

          if (widget.section == CanopySection.months)
            CanopySubbar(
              segments: [
                CanopySegment(label: l10n.monthsThisYear, value: 'this_year'),
                CanopySegment(label: l10n.monthsPastYears, value: 'past_years'),
                CanopySegment(label: l10n.monthsReceipts, value: 'receipts'),
              ],
              selected: _monthsSegment,
              onSelected: (v) {
                setState(() => _monthsSegment = v);
                if (v == 'receipts') {
                  context.goNamed('history');
                } else {
                  context.goNamed('months');
                }
              },
            ),

          if (widget.section == CanopySection.more)
            CanopySubbar(
              segments: [
                CanopySegment(label: l10n.aboutTitle, value: 'about'),
                CanopySegment(label: l10n.profileTitle, value: 'profile'),
              ],
              selected: _moreSegment,
              onSelected: (v) => setState(() => _moreSegment = v),
            ),

          // The actual screen
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: CanopyBar(
        selected: widget.section,
        onSelect: (s) {
          switch (s) {
            case CanopySection.home:
              context.goNamed('home');
            case CanopySection.months:
              context.goNamed('months');
            case CanopySection.pay:
              context.goNamed('pay');
            case CanopySection.more:
              context.goNamed('more');
          }
        },
      ),
    );
  }
}
