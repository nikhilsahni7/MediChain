import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medileger/core/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Enhanced Color Palette with Better Contrast ---

// Light Theme Colors
const Color _lightBackground =
    Color(0xFFF7F9FF); // Slightly blue-tinted white for better readability
const Color _lightSurface = Color(0xFFFFFFFF); // Pure white for surfaces
const Color _lightPrimary =
    Color(0xFF0C2694); // Deeper blue for better contrast
const Color _lightSecondary =
    Color(0xFFF252C5); // Brighter pink for better visibility
const Color _lightError = Color(0xFFD40248); // Vibrant red for errors
const Color _lightOnPrimary = Color(0xFFFFFFFF); // White text on primary
const Color _lightOnSecondary = Color(0xFF000429); // Dark text on secondary
const Color _lightOnBackground = Color(0xFF000429); // Dark text on background
const Color _lightOnSurface = Color(0xFF000429); // Dark text on white surface
const Color _lightOnError = Color(0xFFFFFFFF); // White text on error

// Dark Theme Colors
const Color _darkBackground =
    Color(0xFF06071A); // Slightly blue dark background for better context
const Color _darkSurface =
    Color(0xFF121336); // Elevated dark surface for better depth
const Color _darkPrimary = Color(0xFF6E78FF); // Brighter blue for dark mode
const Color _darkSecondary = Color(0xFFE252AD); // Brighter pink for dark mode
const Color _darkError =
    Color(0xFFFF3B7B); // Vibrant pink-red for errors in dark mode
const Color _darkOnPrimary = Color(0xFF000429); // Dark text on light primary
const Color _darkOnSecondary =
    Color(0xFFFFFFFF); // White text on dark secondary
const Color _darkOnBackground =
    Color(0xFFE6EAFF); // Light blue-white text on dark background
const Color _darkOnSurface =
    Color(0xFFE6EAFF); // Light blue-white text on dark surface
const Color _darkOnError = Color(0xFF000429); // Dark text on light error

// --- AppTheme Class ---
class AppTheme {
  // Keep static border radius if needed elsewhere, or remove if only used internally
  static final BorderRadius _borderRadius = BorderRadius.circular(12);

  // Method to get theme data based on isDarkMode flag
  ThemeData getThemeData({required bool isDarkMode}) {
    // Enhanced color scheme with better Material 3 properties
    final ColorScheme colorScheme = isDarkMode
        ? ColorScheme.dark(
            primary: _darkPrimary,
            onPrimary: _darkOnPrimary,
            primaryContainer: _darkPrimary.withOpacity(0.2),
            onPrimaryContainer: _darkPrimary.withOpacity(0.9),
            secondary: _darkSecondary,
            onSecondary: _darkOnSecondary,
            secondaryContainer: _darkSecondary.withOpacity(0.2),
            onSecondaryContainer: _darkSecondary.withOpacity(0.9),
            tertiary: _darkSecondary.withBlue(80),
            surface: _darkSurface,
            onSurface: _darkOnSurface,
            surfaceContainerHighest: _darkSurface.withOpacity(0.25),
            surfaceContainer: _darkSurface.withOpacity(0.6),
            error: _darkError,
            onError: _darkOnError,
            outline: _darkOnBackground.withOpacity(0.3),
            outlineVariant: _darkOnBackground.withOpacity(0.15),
            shadow: Colors.black,
          )
        : ColorScheme.light(
            primary: _lightPrimary,
            onPrimary: _lightOnPrimary,
            primaryContainer: _lightPrimary.withOpacity(0.12),
            onPrimaryContainer: _lightPrimary,
            secondary: _lightSecondary,
            onSecondary: _lightOnSecondary,
            secondaryContainer: _lightSecondary.withOpacity(0.15),
            onSecondaryContainer: _lightSecondary.withRed(200),
            tertiary: _lightSecondary.withBlue(100),
            surface: _lightSurface,
            onSurface: _lightOnSurface,
            surfaceContainerHighest: _lightSurface.withOpacity(0.96),
            surfaceContainer: _lightSurface.withOpacity(0.85),
            error: _lightError,
            onError: _lightOnError,
            outline: _lightOnBackground.withOpacity(0.25),
            outlineVariant: _lightOnBackground.withOpacity(0.1),
            shadow: Colors.black,
          );

    // Define TextTheme using Nunito Sans with improved readability and contrast
    final baseTextTheme = GoogleFonts.nunitoSansTextTheme(
      ThemeData(brightness: isDarkMode ? Brightness.dark : Brightness.light)
          .textTheme,
    );
    final textTheme = baseTextTheme
        .copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          displayMedium: baseTextTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          displaySmall: baseTextTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
          ),
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
          ),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
          titleSmall: baseTextTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.15,
            height: 1.5,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
            height: 1.5,
          ),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
            height: 1.4,
          ),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          labelMedium: baseTextTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          labelSmall: baseTextTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    // Generate enhanced ThemeData
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: isDarkMode ? 0.5 : 1.0,
        scrolledUnderElevation: 1.0,
        shadowColor: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
        elevation: 3,
        enableFeedback: true,
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
            color: colorScheme.primary.withOpacity(isDarkMode ? 0.7 : 0.5),
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
      // Enhanced input styles for better visibility
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDarkMode ? colorScheme.surfaceContainer : colorScheme.surface,
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
            color: colorScheme.outline,
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
      // Enhanced card theme for better elevation and contrast
      cardTheme: CardTheme(
        elevation: isDarkMode ? 3 : 2,
        shadowColor: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: _borderRadius,
          side: isDarkMode
              ? BorderSide(color: colorScheme.outline)
              : BorderSide.none,
        ),
        color: colorScheme.surface,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        clipBehavior: Clip.antiAlias,
      ),
      // Enhanced list tile for better interaction feedback
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        dense: false,
        minLeadingWidth: 24,
        minVerticalPadding: 12,
      ),
      // Enhanced radio buttons
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurface.withOpacity(0.6);
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      // Enhanced dividers
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),
      // Enhanced bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.7),
        elevation: 6,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      // Enhanced chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
            width: 1,
          ),
        ),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
        elevation: 0,
        showCheckmark: true,
        checkmarkColor: colorScheme.primary,
      ),
      splashColor: colorScheme.primary.withOpacity(0.1),
      highlightColor: colorScheme.primary.withOpacity(0.05),
      disabledColor: colorScheme.onSurface.withOpacity(0.38),
      visualDensity: VisualDensity.standard,
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
