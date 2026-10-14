import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around SharedPreferences for non-sensitive local state.
class PrefsStore {
  PrefsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kLanguage = 'app_language';
  static const _kOnboarded = 'onboarded';
  static const _kRememberedPhone = 'remembered_phone';
  static const _kThemeMode = 'theme_mode';
  static const _kCalendarSystem = 'calendar_system';

  static Future<PrefsStore> open() async {
    return PrefsStore(await SharedPreferences.getInstance());
  }

  // ---------- Language ----------
  String? readLanguage() => _prefs.getString(_kLanguage);
  Future<void> writeLanguage(String value) =>
      _prefs.setString(_kLanguage, value);

  // ---------- Onboarding ----------
  bool get hasOnboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> markOnboarded() => _prefs.setBool(_kOnboarded, true);

  // ---------- Remembered phone ----------
  String? readPhone() => _prefs.getString(_kRememberedPhone);
  Future<void> writePhone(String phone) =>
      _prefs.setString(_kRememberedPhone, phone);
  Future<void> clearPhone() => _prefs.remove(_kRememberedPhone);

  // ---------- Theme mode ----------
  /// Stored as 'system' | 'light' | 'dark'. Defaults to 'system'.
  String readThemeMode() => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> writeThemeMode(String value) =>
      _prefs.setString(_kThemeMode, value);

  // ---------- Calendar system ----------
  String readCalendarSystem() =>
      _prefs.getString(_kCalendarSystem) ?? 'ethiopian';
  Future<void> writeCalendarSystem(String value) =>
      _prefs.setString(_kCalendarSystem, value);
}