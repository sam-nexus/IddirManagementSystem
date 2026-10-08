// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oromo (`om`).
class AppLocalizationsOm extends AppLocalizations {
  AppLocalizationsOm([String locale = 'om']) : super(locale);

  @override
  String get appName => 'Afoosha Odaa';

  @override
  String get appTagline => 'Muka Odaa jalatti walitti qabamne';

  @override
  String get splashTagline => 'Muka Odaa jalatti walitti qabamne';

  @override
  String get languageTitle => 'Afaan kee filadhu';

  @override
  String get languageSubtitle =>
      'Yeroo barbaaddetti kamittuu jijjiiruu ni dandeessa.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageOromo => 'Afaan Oromoo';

  @override
  String get languageContinue => 'Itti fufi';

  @override
  String get actionContinue => 'Itti fufi';

  @override
  String get actionCancel => 'Dhiisi';

  @override
  String get actionRetry => 'Irra deebi\'ii yaali';

  @override
  String get actionClose => 'Cufi';

  @override
  String get actionBack => 'Duubatti deebi\'i';

  @override
  String get actionShare => 'Qoodi';

  @override
  String get actionSave => 'Olkaa\'i';

  @override
  String get greetingMorning => 'Akkam bulte';

  @override
  String get greetingAfternoon => 'Akkam ooltee';

  @override
  String get greetingEvening => 'Galgala gaarii';

  @override
  String greetingName(String name) {
    return 'Akkam jirta, $name';
  }

  @override
  String get homeStanding => 'Gaaddisa jalatti dhaabbatta.';

  @override
  String get homeYouOwe => 'Kaffaluu qabda';

  @override
  String get homeMonthsPaid => 'Ji\'oota kaffalaman';

  @override
  String homePayNow(String amount) {
    return 'Amma kaffali · $amount';
  }

  @override
  String get homeLatestNotice => 'Beeksisa haaraa';

  @override
  String get homeNextMeeting => 'Walga\'ii itti aanu';

  @override
  String get homeReadMore => 'Dabalataan dubbisi';

  @override
  String get authPhoneLabel => 'Lakkoofsa bilbilaa';

  @override
  String get authPhoneHint => '09xx xxx xxx';

  @override
  String get authPinLabel => 'PIN';

  @override
  String get authLogin => 'Seeni';

  @override
  String get authLockedTitle => 'Herregni kee cufameera';

  @override
  String authLockedBody(String minutes) {
    return 'Maaloo daqiiqaa $minutes booda irra deebi\'ii yaali.';
  }

  @override
  String get authChangePinTitle => 'PIN haaraa filadhu';

  @override
  String get authChangePinBody =>
      'PIN kee koreen kaa\'eera. Lakkoofsa afur kan ofii kee filadhu.';

  @override
  String get authPinWeak => 'PIN kun salphaatti tilmaamama. Kan biraa filadhu.';

  @override
  String get authPinMismatch => 'PIN lamaan wal hin fakkaatan.';

  @override
  String get navHome => 'Mana';

  @override
  String get navMonths => 'Ji\'oota';

  @override
  String get navPay => 'Kaffali';

  @override
  String get navMore => 'Dabalata';

  @override
  String get statePaid => 'Kaffalame';

  @override
  String get statePartial => 'Kutaan kaffalame';

  @override
  String get stateUnpaid => 'Hin kaffalamne';

  @override
  String get stateWaived => 'Dhiifame';

  @override
  String get statePending => 'Eegaa jira';

  @override
  String get errorGeneric =>
      'Rakkoon tokko uumameera. Maaloo irra deebi\'ii yaali.';

  @override
  String get errorNetwork => 'Interneetiin hin jiru fakkaata.';

  @override
  String get errorRetry => 'Irra deebi\'ii yaali';

  @override
  String get monthsTitle => 'Gumaacha kee';

  @override
  String get monthsSubtitle => 'Ji\'oota kee gaaddisa Odaa jalatti';

  @override
  String get monthsThisYear => 'Bara kana';

  @override
  String get monthsPastYears => 'Baroota darban';

  @override
  String get monthsReceipts => 'Nagahee';

  @override
  String get payTitle => 'Kaffali';

  @override
  String get paySelectMonths => 'Ji\'oota kam?';

  @override
  String get paySummary => 'Cuunfaa';

  @override
  String get payTotal => 'Waliigala';

  @override
  String get payOpen => 'Fuula kaffaltii bani';

  @override
  String get paySuccessTitle => 'Kaffaltiin fudhatameera';

  @override
  String get paySuccessBody => 'Galatoomi. Nagaheen kee qophiidha.';

  @override
  String get payFailedTitle => 'Kaffaltiin hin milkoofne';

  @override
  String get payPendingTitle => 'Mirkaneessa eegaa jira';

  @override
  String get payPendingBody => 'Yeroo mirkanaa\'u sitti himna.';

  @override
  String get receiptTitle => 'Nagahee';

  @override
  String get receiptNumber => 'Lakkoofsa';

  @override
  String get receiptDate => 'Guyyaa';

  @override
  String get receiptAmount => 'Hanga maallaqaa';

  @override
  String get receiptPaidFor => 'Kan kaffalameef';

  @override
  String get receiptShare => 'Nagahee qoodi';

  @override
  String get historyTitle => 'Seenaa kaffaltii';

  @override
  String get historyEmpty => 'Amma ammaatti kaffaltiin hin jiru.';

  @override
  String get aboutTitle => 'Waa\'ee Afoosha Odaa';

  @override
  String get aboutMission => 'Ergama';

  @override
  String get aboutVision => 'Mul\'ata';

  @override
  String get aboutBylaws => 'Seera dhaabbataa';

  @override
  String get aboutCommittee => 'Koree';

  @override
  String get pastYearsEmpty => 'Asitti amma homaa hin jiru';

  @override
  String get pastYearsEmptyBody =>
      'Seenaan Afoosha kee bara kee jalqabaa booda asitti mul\'ata.';

  @override
  String get monthsNothingThisYear => 'Bara kana amma homaa hin jiru';

  @override
  String get monthsNothingThisYearBody =>
      'Bara kanaaf galmeen gumaacha kee hin jiru.';

  @override
  String get aboutShort => 'Waa\'ee';

  @override
  String get profileShort => 'Profaayilii';

  @override
  String get roleChairperson => 'Dura Taa\'aa';

  @override
  String get roleSecretary => 'Barreessaa';

  @override
  String get roleTreasurer => 'Qabaa Maallaqaa';

  @override
  String get roleAuditor => 'Qorataa Herregaa';

  @override
  String get profileLogoutConfirm => 'Dhuguma ba\'uu barbaaddaa?';

  @override
  String get historyMethodChapa => 'Chapa';

  @override
  String get historyMethodCash => 'Maallaqa harkaa';

  @override
  String get historyMethodManual => 'Dabarsa harkaa';

  @override
  String get historyEmptyBody => 'Yeroo kaffaltii raawwattu asitti mul\'ata.';

  @override
  String get receiptMethod => 'Mala';

  @override
  String get receiptNote => 'Yaadannoo';

  @override
  String get receiptThanks => 'Gumaacha keetiif galatoomi.';

  @override
  String get receiptNotFound => 'Nagaheen hin argamne';

  @override
  String get payDues => 'Gumaacha';

  @override
  String get payPenalties => 'Adabbii';

  @override
  String get payNothingToPay => 'Hundi kaffalameera';

  @override
  String get payNothingToPayBody => 'Amma kaffaltiin hin jiru.';

  @override
  String get stateSuspended => 'Dhaabame';

  @override
  String get stateComingSoon => 'Dhiyootti dhufa';

  @override
  String get monthsPay => 'Kaffali';

  @override
  String get monthsSuspendedHint => 'Maaloo ji\'oota duraanii dura kaffali.';

  @override
  String get profileTitle => 'Profaayilii';

  @override
  String get profileLanguage => 'Afaan';

  @override
  String get profileChangePin => 'PIN jijjiiri';

  @override
  String get profileDevices => 'Meeshaalee koo';

  @override
  String get authConfirmPinLabel => 'PIN mirkaneessi';

  @override
  String get authConfirmPinHint => 'PIN haaraa kee irra deebi\'ii galchi.';

  @override
  String get profileLogout => 'Ba\'i';

  @override
  String get paymentOpenNow => 'Amma banaadha';

  @override
  String get paymentWindowOpen =>
      'Kaffaltiin hanga guyyaa 2ffaatti banaa jira.';

  @override
  String paymentWindowClosed(String date) {
    return 'Kaffaltiin guyyaa $date irraa eegalee banama.';
  }

  @override
  String get paymentMustPayInOrder => 'Maaloo ji\'oota duraanii dura kaffali.';

  @override
  String get paymentOldestFirst => 'Ji\'a durii dursa';

  @override
  String get errorSessionExpired =>
      'Yeroon seensa keetii dhumeera. Maaloo irra deebi\'ii seeni.';

  @override
  String profileVersion(String version) {
    return 'Versiyoonii $version';
  }
}
