/// Date and time text used across the app.
class Formatters {
  static const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

  /// "8:42 AM"
  static String clock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "8:42 AM · OCT 19, 2026" (Emergency Alert header)
  static String alertStamp(DateTime t) => '${clock(t)} · ${_months[t.month - 1]} ${t.day}, ${t.year}';
}
