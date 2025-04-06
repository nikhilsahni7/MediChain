import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medileger/config/router/app_router.dart';
import 'package:medileger/config/theme/app_theme.dart';
import 'package:medileger/core/providers/shared_preferences_provider.dart';

class medilegerApp extends ConsumerWidget {
  const medilegerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the FutureProvider for SharedPreferences initialization
    final sharedPreferencesAsyncValue =
        ref.watch(sharedPreferencesInstanceProvider);

    // Build the UI based on the state of SharedPreferences initialization
    return sharedPreferencesAsyncValue.when(
      data: (prefs) {
        // Watch theme dependencies AFTER prefs are ready
        final themeMode = ref.watch(themeNotifierProvider);
        final appTheme =
            ref.watch(appThemeProvider); // Get the AppTheme instance
        final goRouter = ref.watch(goRouterProvider);

        // Determine if dark mode is active
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final isDarkMode = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                platformBrightness == Brightness.dark);

        return MaterialApp.router(
          title: 'medileger',
          debugShowCheckedModeBanner: false,
          // Get theme data based on isDarkMode
          theme: appTheme.getThemeData(isDarkMode: false),
          darkTheme: appTheme.getThemeData(isDarkMode: true),
          themeMode: themeMode, // Let MaterialApp handle switching
          routerConfig: goRouter,
        );
      },
      loading: () {
        // Use a themed loading screen if possible, or a simple one
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, stackTrace) {
        print("Error initializing SharedPreferences: $error\n$stackTrace");
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Failed to initialize app. Please restart.\nError: $error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
