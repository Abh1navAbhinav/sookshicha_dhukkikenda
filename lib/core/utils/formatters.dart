import 'package:intl/intl.dart';

/// Utility class for formatting values
class Formatters {
  Formatters._();

  // Currency Formatters
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static final NumberFormat _compactCurrencyFormat =
      NumberFormat.compactCurrency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      );

  // Number Formatters
  static final NumberFormat _numberFormat = NumberFormat('#,##,###', 'en_IN');
  static final NumberFormat _decimalFormat = NumberFormat(
    '#,##,###.##',
    'en_IN',
  );
  static final NumberFormat _percentFormat = NumberFormat.percentPattern();
  static final NumberFormat _compactFormat = NumberFormat.compact();

  /// Format as currency (e.g., ₹1,00,000.00)
  static String formatCurrency(num amount) => _currencyFormat.format(amount);

  /// Format as compact currency (e.g., ₹1L)
  static String formatCompactCurrency(num amount) =>
      _compactCurrencyFormat.format(amount);

  /// Format number with Indian number system (e.g., 1,00,000)
  static String formatNumber(num number) => _numberFormat.format(number);

  /// Format number with decimals (e.g., 1,00,000.50)
  static String formatDecimal(num number) => _decimalFormat.format(number);

  /// Format as percentage (e.g., 50%)
  static String formatPercent(double value) => _percentFormat.format(value);

  /// Format as compact number (e.g., 1K, 1M)
  static String formatCompact(num number) => _compactFormat.format(number);

  /// Format phone number (Indian format)
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '+91 ${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+${cleaned.substring(0, 2)} ${cleaned.substring(2, 7)} ${cleaned.substring(7)}';
    }
    return phone;
  }

  /// Mask phone number (e.g., +91 XXXXX 67890)
  static String maskPhoneNumber(String phone, {int visibleDigits = 5}) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < visibleDigits) return phone;

    final masked = 'X' * (cleaned.length - visibleDigits);
    final visible = cleaned.substring(cleaned.length - visibleDigits);
    return '$masked$visible';
  }

  /// Mask email (e.g., a***@example.com)
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) {
      return '${name[0]}***@$domain';
    }

    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Title case
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Format duration (e.g., 2h 30m)
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Format duration as timer (e.g., 02:30:00)
  static String formatDurationAsTimer(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Remove HTML tags
  static String stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Generate initials from name
  static String getInitials(String name, {int maxLength = 2}) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .take(maxLength)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
    return initials;
  }

  /// Format ordinal number (e.g., 1st, 2nd, 3rd)
  static String formatOrdinal(int number) {
    final suffixes = [
      'th',
      'st',
      'nd',
      'rd',
      'th',
      'th',
      'th',
      'th',
      'th',
      'th',
    ];
    final mod100 = number % 100;

    if (mod100 >= 11 && mod100 <= 13) {
      return '${number}th';
    }

    return '$number${suffixes[number % 10]}';
  }
}
