// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Afoosha Odaa';

  @override
  String get appTagline => 'Gathered under the Odaa tree';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionClose => 'Close';

  @override
  String get actionBack => 'Back';

  @override
  String get actionShare => 'Share';

  @override
  String get actionSave => 'Save';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingName(Object name) {
    return 'Akkam, $name';
  }

  @override
  String get homeStanding => 'You are standing in the shade.';

  @override
  String get homeYouOwe => 'You owe';

  @override
  String get homeMonthsPaid => 'Months paid';

  @override
  String homePayNow(Object amount) {
    return 'Pay now · $amount';
  }

  @override
  String get homeLatestNotice => 'Latest notice';

  @override
  String get homeNextMeeting => 'Next meeting';

  @override
  String get homeReadMore => 'Read more';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authPhoneHint => '09xx xxx xxx';

  @override
  String get authPinLabel => 'PIN';

  @override
  String get authLogin => 'Sign in';

  @override
  String get authLockedTitle => 'Account locked';

  @override
  String authLockedBody(Object minutes) {
    return 'Please try again in $minutes minutes.';
  }

  @override
  String get authChangePinTitle => 'Choose a new PIN';

  @override
  String get authChangePinBody =>
      'Your PIN was set by the committee. Pick your own 4 digits.';

  @override
  String get authPinWeak => 'That PIN is easy to guess. Try a different one.';

  @override
  String get authPinMismatch => 'The two PINs do not match.';

  @override
  String get navHome => 'Home';

  @override
  String get navMonths => 'Months';

  @override
  String get navPay => 'Pay';

  @override
  String get navMore => 'More';

  @override
  String get statePaid => 'Paid';

  @override
  String get statePartial => 'Partial';

  @override
  String get stateUnpaid => 'Unpaid';

  @override
  String get stateWaived => 'Waived';

  @override
  String get statePending => 'Pending';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'You appear to be offline.';

  @override
  String get errorRetry => 'Try again';

  @override
  String get monthsTitle => 'Your year';

  @override
  String get monthsSubtitle => 'Every leaf is a month.';

  @override
  String get monthsThisYear => 'This year';

  @override
  String get monthsPastYears => 'Past years';

  @override
  String get monthsReceipts => 'Receipts';

  @override
  String get payTitle => 'Pay';

  @override
  String get paySelectMonths => 'Which months?';

  @override
  String get paySummary => 'Summary';

  @override
  String get payTotal => 'Total';

  @override
  String get payOpen => 'Open payment page';

  @override
  String get paySuccessTitle => 'Payment received';

  @override
  String get paySuccessBody => 'Thank you. Your receipt is ready.';

  @override
  String get payFailedTitle => 'Payment did not go through';

  @override
  String get payPendingTitle => 'Waiting for confirmation';

  @override
  String get payPendingBody => 'We will let you know as soon as it clears.';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptNumber => 'Number';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptAmount => 'Amount';

  @override
  String get receiptPaidFor => 'Paid for';

  @override
  String get receiptShare => 'Share receipt';

  @override
  String get historyTitle => 'Payment history';

  @override
  String get historyEmpty => 'No payments yet.';

  @override
  String get aboutTitle => 'About Afoosha Odaa';

  @override
  String get aboutMission => 'Mission';

  @override
  String get aboutVision => 'Vision';

  @override
  String get aboutBylaws => 'Bylaws';

  @override
  String get aboutCommittee => 'Committee';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileChangePin => 'Change PIN';

  @override
  String get profileDevices => 'My devices';

  @override
  String get profileLogout => 'Log out';

  @override
  String profileVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get splashTagline => 'Gathered under the Odaa tree';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle => 'You can change this at any time.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageOromo => 'Afaan Oromoo';

  @override
  String get languageContinue => 'Continue';
}
