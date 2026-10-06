import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/theme/app_theme.dart';
import 'package:odaa_mobile/shared/widgets/growth_ring.dart';
import 'package:odaa_mobile/shared/widgets/odaa_tree.dart';
import 'package:odaa_mobile/shared/widgets/receipt_slip.dart';
import 'package:odaa_mobile/shared/widgets/status_chip.dart';

void main() {
  runApp(const ProviderScope(child: OdaaApp()));
}

class OdaaApp extends StatelessWidget {
  const OdaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afoosha Odaa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('om'),
      ],
      home: const _DesignSystemPreview(),
    );
  }
}

class _DesignSystemPreview extends StatelessWidget {
  const _DesignSystemPreview();

  @override
  Widget build(BuildContext context) {
    const months = <ContributionState>[
      ContributionState.paid,
      ContributionState.paid,
      ContributionState.partial,
      ContributionState.paid,
      ContributionState.paid,
      ContributionState.unpaid,
      ContributionState.paid,
      ContributionState.paid,
      ContributionState.waived,
      ContributionState.paid,
      ContributionState.paid,
      ContributionState.pending,
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Afoosha Odaa',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              const OdaaTree(months: months, currentMonthIndex: 11),
              const SizedBox(height: 16),
              const GrowthRing(months: months),
              const SizedBox(height: 32),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatusChip(state: ContributionState.paid, label: 'Paid'),
                  StatusChip(state: ContributionState.partial, label: 'Partial'),
                  StatusChip(state: ContributionState.unpaid, label: 'Unpaid'),
                  StatusChip(state: ContributionState.waived, label: 'Waived'),
                ],
              ),
              const SizedBox(height: 32),
              const ReceiptSlip(
                receiptNumber: 'RCT-2026-004812',
                children: [
                  Text(
                    'ETB 1,200.00',
                    style: TextStyle(fontFamily: 'Fraunces', fontSize: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}