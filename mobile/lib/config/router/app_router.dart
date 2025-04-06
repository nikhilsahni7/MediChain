import 'package:medileger/core/services/auth_service.dart';
import 'package:medileger/features/auth/presentation/screens/login_screen.dart';
import 'package:medileger/features/home/presentation/screens/home_screen.dart';
import 'package:medileger/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Authentication state provider (rebuilds when auth state changes)
final authStateProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(authServiceProvider).isLoggedIn();
});

// Riverpod provider for the router
final goRouterProvider = Provider<GoRouter>((ref) {
  // Create a key to allow reloading the router state
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  // This is used to trigger router rebuilds on auth state changes
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login, // Default starting point
    debugLogDiagnostics: true, // Log navigation events

    // Use redirect for dynamic routing based on auth state
    redirect: (context, state) {
      // If auth state is loading, don't redirect yet
      if (authState.isLoading) return null;

      // Check if user is logged in (handles errors as not logged in)
      final bool isLoggedIn = authState.valueOrNull ?? false;

      // Get current path
      final currentPath = state.matchedLocation;

      // Onboarding has the highest priority - if on onboarding, stay there
      if (currentPath == AppRoutes.onboarding) return null;

      // If logged in and trying to access login or onboarding, redirect to home
      if (isLoggedIn &&
          (currentPath == AppRoutes.login ||
              currentPath == AppRoutes.onboarding)) {
        return AppRoutes.home;
      }

      // If not logged in and trying to access protected routes, redirect to login
      if (!isLoggedIn && currentPath != AppRoutes.login) {
        return AppRoutes.login;
      }

      // No need to redirect
      return null;
    },

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
  );
});
