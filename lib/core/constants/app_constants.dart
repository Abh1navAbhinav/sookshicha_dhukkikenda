/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Sookshicha Dhukkikenda';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.example.com';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Configuration
  static const Duration cacheTimeout = Duration(hours: 1);
  static const String cacheBoxName = 'app_cache';

  // Hive Box Names
  static const String userBoxName = 'user_box';
  static const String settingsBoxName = 'settings_box';

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Debounce Duration
  static const Duration debounceDuration = Duration(milliseconds: 300);

  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String settingsCollection = 'settings';
}

/// Storage Keys for SharedPreferences/Hive
class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String isLoggedIn = 'is_logged_in';
  static const String isFirstLaunch = 'is_first_launch';
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String lastSync = 'last_sync';
}

/// Route Names
class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
}
