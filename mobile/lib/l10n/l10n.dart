import 'package:flutter/widgets.dart';
import 'package:odaa_mobile/l10n/app_localizations.dart';

export 'package:odaa_mobile/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}