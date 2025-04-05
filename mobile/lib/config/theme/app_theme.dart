import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medileger/core/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- New Color Palette (Blue/Pink Theme) ---

// Light Theme Colors
const Color _lightBackground = Color(0xFFF0F0FF); // --background
const Color _lightSurface = Color(0xFFFFFFFF); // White for surfaces
const Color _lightPrimary = Color(0xFF020B88); // --primary
const Color _lightSecondary = Color(0xFFFD63CF); // --secondary
const Color _lightError = Color(0xFFD40248); // --accent (used as error)
const Color _lightOnPrimary = Color(0xFFFFFFFF); // White text on primary
const Color _lightOnSecondary = Color(0xFF000429); // --text on secondary
const Color _lightOnBackground = Color(0xFF000429); // --text
const Color _lightOnSurface = Color(0xFF000429); // --text on white surface
const Color _lightOnError = Color(0xFFFFFFFF); // White text on error

// Dark Theme Colors
const Color _darkBackground = Color(0xFF00000E); // --background
const Color _darkSurface = Color(0xFF101028); // Slightly lighter dark surface
const Color _darkPrimary = Color(0xFF7881FD); // --primary
const Color _darkSecondary = Color(0xFF9C026F); // --secondary
const Color _darkError = Color(0xFFFD2B72); // --accent (used as error)
const Color _darkOnPrimary = Color(0xFF000429); // Dark text on light primary
const Color _darkOnSecondary =
    Color(0xFFFFFFFF); // White text on dark secondary
const Color _darkOnBackground = Color(0xFFD5D9FF); // --text
const Color _darkOnSurface = Color(0xFFD5D9FF); // --text on dark surface
const Color _darkOnError = Color(0xFF00000E); // Dark text on light error

// --- AppTheme Class ---
class AppTheme {
  // Keep static border radius if needed elsewhere, or remove if only used internally
  static final BorderRadius _borderRadius = BorderRadius.circular(12);

  // Method to get theme data based on isDarkMode flag
  ThemeData getThemeData({required bool isDarkMode}) {
    final ColorScheme colorScheme = isDarkMode
        ? const ColorScheme.dark(
            primary: _darkPrimary,
            secondary: _darkSecondary,
            surface: _darkSurface,
            error: _darkError,
            onPrimary: _darkOnPrimary,
            onSecondary: _darkOnSecondary,
            onSurface: _darkOnSurface,
            onError: _darkOnError,
            brightness: Brightness.dark,
          )
        : const ColorScheme.light(
            primary: _lightPrimary,
            secondary: _lightSecondary,
            surface: _lightSurface,
            error: _lightError,
            onPrimary: _lightOnPrimary,
            onSecondary: _lightOnSecondary,
            onSurface: _lightOnSurface,
            onError: _lightOnError,
            brightness: Brightness.light,
          );

    // Define TextTheme using Nunito Sans
    final baseTextTheme = GoogleFonts.nunitoSansTextTheme(
      ThemeData(brightness: isDarkMode ? Brightness.dark : Brightness.light)
          .textTheme,
    );
    final textTheme = baseTextTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    // Generate ThemeData
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: isDarkMode ? 0.5 : 1.0,
        scrolledUnderElevation: 1.0,
        shadowColor: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: _borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          elevation: 2,
          shadowColor: colorScheme.primary.withOpacity(0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.primary.withOpacity(isDarkMode ? 0.6 : 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: _borderRadius),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(
            color: colorScheme.onSurface.withOpacity(isDarkMode ? 0.25 : 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _borderRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        floatingLabelStyle: TextStyle(color: colorScheme.primary),
        prefixIconColor: colorScheme.primary.withOpacity(0.8),
        suffixIconColor: colorScheme.onSurface.withOpacity(0.6),
      ),
      cardTheme: CardTheme(
        elevation: isDarkMode ? 1 : 2,
        shadowColor: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: _borderRadius,
          side: isDarkMode
              ? BorderSide(color: colorScheme.onSurface.withOpacity(0.2))
              : BorderSide.none,
        ),
        color: colorScheme.surface,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primary.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurface.withOpacity(0.6);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withOpacity(0.12),
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      splashColor: colorScheme.primary.withOpacity(0.1),
      highlightColor: colorScheme.primary.withOpacity(0.05),
    );
  }
}

// --- State Notifier and Providers ---

// Provider for the AppTheme instance
final appThemeProvider = Provider<AppTheme>((ref) {
  // This provider simply returns a new instance.
  // The actual determination of light/dark mode is done where the theme is consumed.
  return AppTheme();
});

// Notifier for managing theme mode persistence
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  static const _themeModeKey = 'themeMode';

  ThemeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final themeModeString = prefs.getString(_themeModeKey);
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (state != themeMode) {
      state = themeMode;
      String themeModeString;
      switch (themeMode) {
        case ThemeMode.light:
          themeModeString = 'light';
          break;
        case ThemeMode.dark:
          themeModeString = 'dark';
          break;
        case ThemeMode.system:
        default:
          themeModeString = 'system';
          break;
      }
      await _prefs.setString(_themeModeKey, themeModeString);
    }
  }
}

// Provider for the ThemeNotifier
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  // Depend on the SharedPreferences instance being ready
  final prefs = ref.watch(sharedPreferencesInstanceProvider).requireValue;
  return ThemeNotifier(prefs);
});
