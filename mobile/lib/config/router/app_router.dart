import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medileger/core/providers/shared_preferences_provider.dart';
import 'package:medileger/features/auth/presentation/screens/login_screen.dart';
import 'package:medileger/features/home/presentation/screens/home_screen.dart';
import 'package:medileger/features/onboarding/presentation/screens/onboarding_screen.dart';

// Route names
class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/';
  // these routes will be added later
  static const checkMedicines = '/check-medicines';
  static const orderDrugs = '/order-drugs';
  static const maps = '/maps';
  static const stats = '/stats';
  static const settings = '/settings';
}

// Riverpod provider for the router
final goRouterProvider = Provider<GoRouter>((ref) {
  // Listen to providers needed for initial route decision
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  // Read the flags needed for initial routing
  final bool isLoggedIn = sharedPreferences.getBool('isLoggedIn') ?? false;
  // 'hasSeenOnboarding' is now mainly used internally by the onboarding screen
  // final bool hasSeenOnboarding = sharedPreferences.getBool('hasSeenOnboarding') ?? false;

  String getInitialLocation() {
    // Priority 1: If logged in, go straight home.
    if (isLoggedIn) {
      print("Router: User is logged in, navigating to Home.");
      return AppRoutes.home;
    }
    // Priority 2: If not logged in, always start with onboarding.
    else {
      print("Router: User is NOT logged in, navigating to Onboarding.");
      return AppRoutes.onboarding;
    }

    // --- Previous Logic (for reference) ---
    // if (!hasSeenOnboarding) {
    //   return AppRoutes.onboarding;
    // }
    // if (!isLoggedIn) {
    //   return AppRoutes.login;
    // }
    // return AppRoutes.home;
    // --- End Previous Logic ---
  }

  return GoRouter(
    initialLocation: getInitialLocation(),
    debugLogDiagnostics: true, // Log navigation events
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        // The onboarding screen itself will handle setting 'hasSeenOnboarding'
        // and navigating to login upon completion/skip.
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        // The login screen will handle setting 'isLoggedIn'
        // and navigating to home upon successful login.
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            const HomeScreen(), // Main app screen after login
        // TODO: Add sub-routes for features like check, order, maps, stats if needed
        // routes: [
        //   GoRoute(
        //     path: 'check', // e.g., /check
        //     builder: (context, state) => const CheckMedicinesScreen(),
        //   ),
        // ],
      ),
      // Add other top-level routes if needed
    ],
    // Redirect logic (optional, can handle auth state changes)
    // redirect: (context, state) {
    //   // Example: If user is not logged in and tries to access home, redirect to login
    //   final loggedIn = ref.read(authProvider).isLoggedIn; // Replace with your auth logic
    //   final loggingIn = state.matchedLocation == AppRoutes.login;
    //   final onboarding = state.matchedLocation == AppRoutes.onboarding;

    //   if (!hasSeenOnboarding && !onboarding) return AppRoutes.onboarding;
    //   if (hasSeenOnboarding && !loggedIn && !loggingIn) return AppRoutes.login;
    //   if (loggedIn && (loggingIn || onboarding)) return AppRoutes.home;

    //   return null; // No redirect needed
    // },
  );
});
