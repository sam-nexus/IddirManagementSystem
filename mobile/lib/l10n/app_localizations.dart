import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_om.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('om')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Afoosha Odaa'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Gathered under the Odaa tree'**
  String get appTagline;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Gathered under the Odaa tree'**
  String get splashTagline;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this at any time.'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageOromo.
  ///
  /// In en, this message translates to:
  /// **'Afaan Oromoo'**
  String get languageOromo;

  /// No description provided for @languageContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languageContinue;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingName.
  ///
  /// In en, this message translates to:
  /// **'Akkam, {name}'**
  String greetingName(String name);

  /// No description provided for @homeStanding.
  ///
  /// In en, this message translates to:
  /// **'You are standing in the shade.'**
  String get homeStanding;

  /// No description provided for @homeYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get homeYouOwe;

  /// No description provided for @homeMonthsPaid.
  ///
  /// In en, this message translates to:
  /// **'Months paid'**
  String get homeMonthsPaid;

  /// No description provided for @homePayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now · {amount}'**
  String homePayNow(String amount);

  /// No description provided for @homeLatestNotice.
  ///
  /// In en, this message translates to:
  /// **'Latest notice'**
  String get homeLatestNotice;

  /// No description provided for @homeNextMeeting.
  ///
  /// In en, this message translates to:
  /// **'Next meeting'**
  String get homeNextMeeting;

  /// No description provided for @homeReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get homeReadMore;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'09xx xxx xxx'**
  String get authPhoneHint;

  /// No description provided for @authPinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get authPinLabel;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLogin;

  /// No description provided for @authLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account locked'**
  String get authLockedTitle;

  /// No description provided for @authLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again in {minutes} minutes.'**
  String authLockedBody(String minutes);

  /// No description provided for @authChangePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new PIN'**
  String get authChangePinTitle;

  /// No description provided for @authChangePinBody.
  ///
  /// In en, this message translates to:
  /// **'Your PIN was set by the committee. Pick your own 4 digits.'**
  String get authChangePinBody;

  /// No description provided for @authPinWeak.
  ///
  /// In en, this message translates to:
  /// **'That PIN is easy to guess. Try a different one.'**
  String get authPinWeak;

  /// No description provided for @authPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two PINs do not match.'**
  String get authPinMismatch;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get navMonths;

  /// No description provided for @navPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get navPay;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @statePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statePaid;

  /// No description provided for @statePartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get statePartial;

  /// No description provided for @stateUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get stateUnpaid;

  /// No description provided for @stateWaived.
  ///
  /// In en, this message translates to:
  /// **'Waived'**
  String get stateWaived;

  /// No description provided for @statePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statePending;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline.'**
  String get errorNetwork;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get errorRetry;

  /// No description provided for @monthsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your year'**
  String get monthsTitle;

  /// No description provided for @monthsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every leaf is a month.'**
  String get monthsSubtitle;

  /// No description provided for @monthsThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get monthsThisYear;

  /// No description provided for @monthsPastYears.
  ///
  /// In en, this message translates to:
  /// **'Past years'**
  String get monthsPastYears;

  /// No description provided for @monthsReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get monthsReceipts;

  /// No description provided for @payTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get payTitle;

  /// No description provided for @paySelectMonths.
  ///
  /// In en, this message translates to:
  /// **'Which months?'**
  String get paySelectMonths;

  /// No description provided for @paySummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get paySummary;

  /// No description provided for @payTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get payTotal;

  /// No description provided for @payOpen.
  ///
  /// In en, this message translates to:
  /// **'Open payment page'**
  String get payOpen;

  /// No description provided for @paySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paySuccessTitle;

  /// No description provided for @paySuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your receipt is ready.'**
  String get paySuccessBody;

  /// No description provided for @payFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment did not go through'**
  String get payFailedTitle;

  /// No description provided for @payPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get payPendingTitle;

  /// No description provided for @payPendingBody.
  ///
  /// In en, this message translates to:
  /// **'We will let you know as soon as it clears.'**
  String get payPendingBody;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get receiptNumber;

  /// No description provided for @receiptDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get receiptDate;

  /// No description provided for @receiptAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get receiptAmount;

  /// No description provided for @receiptPaidFor.
  ///
  /// In en, this message translates to:
  /// **'Paid for'**
  String get receiptPaidFor;

  /// No description provided for @receiptShare.
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get receiptShare;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get historyEmpty;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Afoosha Odaa'**
  String get aboutTitle;

  /// No description provided for @aboutMission.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get aboutMission;

  /// No description provided for @aboutVision.
  ///
  /// In en, this message translates to:
  /// **'Vision'**
  String get aboutVision;

  /// No description provided for @aboutBylaws.
  ///
  /// In en, this message translates to:
  /// **'Bylaws'**
  String get aboutBylaws;

  /// No description provided for @aboutCommittee.
  ///
  /// In en, this message translates to:
  /// **'Committee'**
  String get aboutCommittee;

  /// No description provided for @stateSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get stateSuspended;

  /// No description provided for @stateComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get stateComingSoon;

  /// No description provided for @monthsPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get monthsPay;

  /// No description provided for @monthsSuspendedHint.
  ///
  /// In en, this message translates to:
  /// **'Please clear older months first.'**
  String get monthsSuspendedHint;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get profileChangePin;

  /// No description provided for @profileDevices.
  ///
  /// In en, this message translates to:
  /// **'My devices'**
  String get profileDevices;

  /// No description provided for @authConfirmPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get authConfirmPinLabel;

  /// No description provided for @authConfirmPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your new PIN again.'**
  String get authConfirmPinHint;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @paymentOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get paymentOpenNow;

  /// No description provided for @paymentWindowOpen.
  ///
  /// In en, this message translates to:
  /// **'Payment is open until the 2nd.'**
  String get paymentWindowOpen;

  /// No description provided for @paymentWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'Payment opens on {date}.'**
  String paymentWindowClosed(String date);

  /// No description provided for @paymentMustPayInOrder.
  ///
  /// In en, this message translates to:
  /// **'Please clear older months first.'**
  String get paymentMustPayInOrder;

  /// No description provided for @paymentOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest month first'**
  String get paymentOldestFirst;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String profileVersion(String version);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'om'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
