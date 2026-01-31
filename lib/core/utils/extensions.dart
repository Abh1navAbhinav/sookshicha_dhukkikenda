import 'package:flutter/material.dart';

/// String extensions
extension StringExtensions on String {
  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Title case
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Convert to slug
  String get toSlug {
    return toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Check if valid email
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  /// Check if valid phone
  bool get isValidPhone {
    final cleaned = replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned);
  }

  /// Check if valid URL
  bool get isValidUrl {
    return Uri.tryParse(this)?.hasAbsolutePath ?? false;
  }

  /// Parse to int safely
  int? toIntOrNull() => int.tryParse(this);

  /// Parse to double safely
  double? toDoubleOrNull() => double.tryParse(this);
}

/// Nullable String extensions
extension NullableStringExtensions on String? {
  /// Check if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;

  /// Return value or default
  String orDefault([String defaultValue = '']) => this ?? defaultValue;
}

/// Int extensions
extension IntExtensions on int {
  /// Duration in seconds
  Duration get seconds => Duration(seconds: this);

  /// Duration in milliseconds
  Duration get milliseconds => Duration(milliseconds: this);

  /// Duration in minutes
  Duration get minutes => Duration(minutes: this);

  /// Duration in hours
  Duration get hours => Duration(hours: this);

  /// Duration in days
  Duration get days => Duration(days: this);

  /// Convert to ordinal string
  String get ordinal {
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
    if (this % 100 >= 11 && this % 100 <= 13) {
      return '${this}th';
    }
    return '$this${suffixes[this % 10]}';
  }
}

/// Double extensions
extension DoubleExtensions on double {
  /// Round to specified decimal places
  double roundTo(int places) {
    final factor = 10.0 * places;
    return (this * factor).round() / factor;
  }

  /// Check if approximately equal
  bool approximatelyEqual(double other, {double epsilon = 0.0001}) {
    return (this - other).abs() < epsilon;
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Check if same day as another date
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if today
  bool get isToday => isSameDay(DateTime.now());

  /// Check if yesterday
  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  /// Check if tomorrow
  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Add business days
  DateTime addBusinessDays(int days) {
    var current = this;
    var remaining = days;
    while (remaining > 0) {
      current = current.add(const Duration(days: 1));
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        remaining--;
      }
    }
    return current;
  }
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Get first or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Get element at index or null
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Safe sublist
  List<T> safeSublist(int start, [int? end]) {
    final safeStart = start.clamp(0, length);
    final safeEnd = (end ?? length).clamp(safeStart, length);
    return sublist(safeStart, safeEnd);
  }
}

/// Map extensions
extension MapExtensions<K, V> on Map<K, V> {
  /// Get value or default
  V getOrDefault(K key, V defaultValue) => this[key] ?? defaultValue;

  /// Get value or null with type casting
  T? getAs<T>(K key) {
    final value = this[key];
    return value is T ? value : null;
  }
}

/// BuildContext extensions for easy access to theme, mediaQuery, etc.
extension BuildContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => mediaQuery.size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => mediaQuery.viewInsets.bottom > 0;

  /// Get padding
  EdgeInsets get padding => mediaQuery.padding;

  /// Get status bar height
  double get statusBarHeight => padding.top;

  /// Get bottom safe area
  double get bottomSafeArea => padding.bottom;

  /// Check if dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Check if small screen (phone)
  bool get isSmallScreen => screenWidth < 600;

  /// Check if medium screen (tablet)
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;

  /// Check if large screen (desktop)
  bool get isLargeScreen => screenWidth >= 1200;

  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Pop navigation
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Push named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);

  /// Push replacement named route
  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    Object? arguments,
  }) => Navigator.of(
    this,
  ).pushReplacementNamed<T, TO>(routeName, arguments: arguments);

  /// Pop until
  void popUntil(String routeName) =>
      Navigator.of(this).popUntil(ModalRoute.withName(routeName));
}
