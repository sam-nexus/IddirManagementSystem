import 'package:flutter/material.dart';
import 'package:odaa_mobile/l10n/app_localizations.dart';

/// Provides [AppLocalizations] for a specific locale while leaving every
/// other localization (Material, Cupertino, Widgets) alone.
///
/// This is the documented pattern for apps whose own language is not
/// supported by Flutter's built-in Material/Cupertino delegates — e.g.
/// Afaan Oromoo, which Flutter does not ship translations for.
class AppLocalizationsScope extends StatelessWidget {
  const AppLocalizationsScope({
    required this.locale,
    required this.child,
    super.key,
  });

  final Locale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Only override AppLocalizations. Material/Cupertino keep the English
    // versions they inherited from MaterialApp.
    return Localizations.override(
      context: context,
      locale: locale,
      delegates: const [AppLocalizations.delegate],
      child: child,
    );
  }
}