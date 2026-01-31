import 'package:flutter/material.dart';

/// Calm Theme - Minimal, serene financial UI
///
/// Design Philosophy:
/// - Reduce visual noise to minimize cognitive load
/// - Use soft, muted colors that don't trigger anxiety
/// - Large typography for quick scanning
/// - Generous whitespace for breathing room
///
/// Color Strategy:
/// - Primary actions: Soft indigo (trustworthy, calm)
/// - Positive states: Muted sage green (growth without excitement)
/// - Negative states: Soft coral (warning without alarm)
/// - Neutral: Warm grays (friendlier than cold grays)
class CalmTheme {
  CalmTheme._();

  // ============== Color Palette ==============

  // Primary - Soft Indigo (trustworthy, professional, calm)
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color primaryMuted = Color(0xFFA5B4FC);

  // Success - Sage Green (positive without overstimulation)
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successMuted = Color(0xFF6EE7B7);

  // Warning - Amber (gentle attention)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Danger - Soft Coral (not alarming red)
  static const Color danger = Color(0xFFF87171);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color dangerMuted = Color(0xFFFCA5A5);

  // Neutrals - Warm Grays
  static const Color surface = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFF5F5F4);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7E5E4);
  static const Color divider = Color(0xFFF5F5F4);

  // Text Colors
  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFF78716C);
  static const Color textHint = Color(0xFFA8A29E);

  // ============== Typography ==============

  /// Large, calm typography system
  /// Generously sized for easy scanning
  static TextTheme get textTheme => const TextTheme(
    // Display - For the main number (Free Balance)
    displayLarge: TextStyle(
      fontSize: 56,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
      height: 1.1,
      color: textPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
      height: 1.2,
      color: textPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.2,
      color: textPrimary,
    ),

    // Headlines - For section titles
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.3,
      color: textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.3,
      color: textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.3,
      color: textPrimary,
    ),

    // Titles - For card headers
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.4,
      color: textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.4,
      color: textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
      color: textPrimary,
    ),

    // Body - For content
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
      color: textSecondary,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.5,
      color: textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.5,
      color: textMuted,
    ),

    // Labels - For small UI elements
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
      color: textSecondary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.4,
      color: textMuted,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.4,
      color: textMuted,
    ),
  );

  // ============== Spacing System ==============

  /// Consistent spacing for visual rhythm
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;
  static const double spacingXxxl = 64;

  /// Page padding - generous for breathing room
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 32,
  );

  /// Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(24);

  /// Section spacing
  static const double sectionSpacing = 32;

  // ============== Border Radius ==============

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 100;

  // ============== Shadows ==============

  /// Soft, subtle shadows for depth without heaviness
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];

  // ============== Theme Data ==============

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: primary,
        secondary: textSecondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: danger,
        onError: Colors.white,
        outline: border,
      ),

      // Scaffold
      scaffoldBackgroundColor: background,

      // Text
      textTheme: textTheme,

      // App Bar - Minimal, blends with background
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),

      // Cards - Soft, elevated
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textSecondary, size: 24),

      // Divider
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
      ),
    );
  }

  // ============== Helper Methods ==============

  /// Get color for balance based on value
  static Color getBalanceColor(double balance) {
    if (balance > 0) return success;
    if (balance < 0) return danger;
    return textPrimary;
  }

  /// Get background color for balance card
  static Color getBalanceBackgroundColor(double balance) {
    if (balance > 0) return successLight;
    if (balance < 0) return dangerLight;
    return surface;
  }

  /// Get text style for amount with color
  static TextStyle getAmountStyle(double amount, {bool large = false}) {
    final baseStyle = large ? textTheme.displayLarge : textTheme.headlineMedium;
    return baseStyle!.copyWith(color: getBalanceColor(amount));
  }
}
