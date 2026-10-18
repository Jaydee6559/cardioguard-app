/// Date and time text used across the app.
class Formatters {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// "8:42 AM"
  static String clock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$hour:${_two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "8:42 AM · OCT 19, 2026" (Emergency Alert header)
  static String alertStamp(DateTime t) =>
      '${clock(t)} · ${_months[t.month - 1].toUpperCase()} ${t.day}, ${t.year}';

  /// "Oct 19, 2026"
  static String date(DateTime t) => '${_months[t.month - 1]} ${t.day}, ${t.year}';

  /// "Oct 13"
  static String shortDate(DateTime t) => '${_months[t.month - 1]} ${t.day}';

  /// "Sep 14 · 14:22" (event list)
  static String eventStamp(DateTime t) => '${shortDate(t)} · ${_two(t.hour)}:${_two(t.minute)}';

  /// "14:00" (chart axis, x = hour of day)
  static String hour(double h) => '${_two(h.round())}:00';

  /// Weekday name for a date, e.g. "Mon".
  static String weekday(DateTime t) => weekdays[t.weekday - 1];
}
