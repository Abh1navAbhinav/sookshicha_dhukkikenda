import 'package:intl/intl.dart';

/// Utility class for date/time operations
class AppDateUtils {
  AppDateUtils._();

  // Date Formatters
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM');
  static final DateFormat _fullDateFormat = DateFormat('EEEE, MMMM d, yyyy');
  static final DateFormat _isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  /// Format date to dd/MM/yyyy
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Format time to HH:mm
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Format date and time to dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Format to Month Year (e.g., January 2024)
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Format to Day Month (e.g., 15 Jan)
  static String formatDayMonth(DateTime date) => _dayMonthFormat.format(date);

  /// Format to full date (e.g., Monday, January 15, 2024)
  static String formatFullDate(DateTime date) => _fullDateFormat.format(date);

  /// Format to ISO 8601 format for API calls
  static String formatIso(DateTime date) => _isoFormat.format(date.toUtc());

  /// Format to API date format (yyyy-MM-dd)
  static String formatApiDate(DateTime date) => _apiDateFormat.format(date);

  /// Parse ISO 8601 date string
  static DateTime? parseIso(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  /// Parse date string with specific format
  static DateTime? parseDate(
    String? dateString, {
    String format = 'dd/MM/yyyy',
  }) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateFormat(format).parse(dateString);
    } catch (_) {
      return null;
    }
  }

  /// Get relative time string (e.g., "2 hours ago", "Yesterday")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) =>
      isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) =>
      isSameDay(date, DateTime.now().add(const Duration(days: 1)));

  /// Get start of day
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Get end of day
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysToSubtract)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Get end of month
  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  /// Get age from birth date
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
