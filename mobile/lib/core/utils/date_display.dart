import 'package:ethio_greg_dual_calendar/ethio_greg_dual_calendar.dart';

/// Formats a Gregorian DateTime using the active calendar system.
class DateDisplay {
  static String primary(DateTime date) => AppDate.mediumDate(date);

  static String gregorian(DateTime date) {
    final saved = AppDate.calendar;
    AppDate.calendar = CalendarSystem.gregorian;
    final result = AppDate.mediumDate(date);
    AppDate.calendar = saved;
    return result;
  }

  static String ethiopian(DateTime date) {
    final saved = AppDate.calendar;
    AppDate.calendar = CalendarSystem.ethiopian;
    final result = AppDate.mediumDate(date);
    AppDate.calendar = saved;
    return result;
  }
}