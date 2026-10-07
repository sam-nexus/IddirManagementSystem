import 'package:flutter/material.dart';
import 'package:odaa_mobile/core/theme/app_theme_extension.dart';
import 'package:odaa_mobile/features/shell/presentation/widgets/canopy_item.dart';
import 'package:odaa_mobile/l10n/l10n.dart';

enum CanopySection { home, months, pay, more }

class CanopyBar extends StatelessWidget {
  const CanopyBar({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final CanopySection selected;
  final ValueChanged<CanopySection> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(
          top: BorderSide(color: tokens.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            CanopyItem(
              icon: Icons.cottage_outlined,
              label: l10n.navHome,
              selected: selected == CanopySection.home,
              onTap: () => onSelect(CanopySection.home),
            ),
            CanopyItem(
              icon: Icons.calendar_month_outlined,
              label: l10n.navMonths,
              selected: selected == CanopySection.months,
              onTap: () => onSelect(CanopySection.months),
            ),
            CanopyItem(
              icon: Icons.payments_outlined,
              label: l10n.navPay,
              selected: selected == CanopySection.pay,
              onTap: () => onSelect(CanopySection.pay),
            ),
            CanopyItem(
              icon: Icons.more_horiz,
              label: l10n.navMore,
              selected: selected == CanopySection.more,
              onTap: () => onSelect(CanopySection.more),
            ),
          ],
        ),
      ),
    );
  }
}