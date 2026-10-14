import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaa_mobile/core/providers/app_providers.dart';

/// Which calendar system the UI uses to render dates.
///
/// This is a display-layer choice only. All `DateTime` values in the app
/// remain Gregorian — only the formatting changes.
class CalendarSystemNotifier extends StateNotifier<CalendarSystem> {
  CalendarSystemNotifier(this._prefs)
      : super(_parse(_prefs.readCalendarSystem())) {
    // Keep the library's global in sync from the first frame.
    AppDate.calendar = state;
  }

  final dynamic _prefs;

  static CalendarSystem _parse(String raw) {
    return raw == 'ethiopian'
        ? CalendarSystem.ethiopian
        : CalendarSystem.gregorian;
  }

  static String _serialize(CalendarSystem mode) {
    return mode == CalendarSystem.ethiopian ? 'ethiopian' : 'gregorian';
  }

  Future<void> setSystem(CalendarSystem mode) async {
    state = mode;
    AppDate.calendar = mode;
    await _prefs.writeCalendarSystem(_serialize(mode));
  }
}

final calendarSystemProvider =
    StateNotifierProvider<CalendarSystemNotifier, CalendarSystem>((ref) {
  return CalendarSystemNotifier(ref.watch(prefsStoreProvider));
});