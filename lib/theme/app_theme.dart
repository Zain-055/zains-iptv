import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF080808);
  static const Color surfaceColor = Color(0xFF141414);
  static const Color cardColor = Color(0xFF202020);
  static const Color focusedBorderColor = Color(0xFFFF6D00);
  static const Color primaryAccent = Color(0xFFFF6D00);
  static const Color favoriteGold = Color(0xFFFFC107);
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color errorRed = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: primaryAccent,
      secondary: favoriteGold,
      surface: surfaceColor,
      error: errorRed,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: Color(0xFF454554),
      outlineVariant: Color(0xFF343442),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: colorScheme,
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 16,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryAccent, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF343442),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryAccent,
        labelStyle: const TextStyle(color: textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryAccent
              : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryAccent.withValues(alpha: 0.35)
              : cardColor,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: TextStyle(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const lightTextPrimary = Color(0xFF111827);
    const lightTextSecondary = Color(0xFF5B6472);
    const lightSurface = Color(0xFFFFFFFF);
    const lightCard = Color(0xFFFFFFFF);
    const lightBackground = Color(0xFFF4F6FA);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryAccent,
        secondary: favoriteGold,
        surface: lightSurface,
        error: errorRed,
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        outline: Color(0xFFB7C0CC),
        outlineVariant: Color(0xFFE0E5EC),
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: lightTextSecondary,
          fontSize: 16,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F3F8),
        hintStyle: const TextStyle(color: lightTextSecondary),
        labelStyle: const TextStyle(color: lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryAccent, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E5EC),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE9EEF5),
        selectedColor: primaryAccent,
        labelStyle: const TextStyle(color: lightTextPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryAccent
              : lightTextSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryAccent.withValues(alpha: 0.2)
              : const Color(0xFFD8DEE8),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF263244),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

extension AppThemeContext on BuildContext {
  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get appSurface => Theme.of(this).colorScheme.surface;
  Color get appCard => Theme.of(this).cardTheme.color ?? appSurface;
  Color get appText => Theme.of(this).colorScheme.onSurface;
  Color get appTextSecondary => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get appBorder => Theme.of(this).colorScheme.outlineVariant;
}
