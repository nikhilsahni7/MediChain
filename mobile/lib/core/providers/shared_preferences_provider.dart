import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider that asynchronously creates the SharedPreferences instance
final sharedPreferencesInstanceProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Provider that provides the SharedPreferences instance once it's ready
// Throws an error if accessed before SharedPreferences is initialized
// Use this provider in other providers/widgets that need synchronous access
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return ref.watch(sharedPreferencesInstanceProvider).when(
        data: (prefs) => prefs,
        loading: () => throw Exception('SharedPreferences not yet initialized'),
        error: (err, stack) =>
            throw Exception('Failed to initialize SharedPreferences: $err'),
      );
});

// Example of a provider that depends on SharedPreferences
// final onboardingCompletedProvider = StateProvider<bool>((ref) {
//   final prefs = ref.watch(sharedPreferencesProvider);
//   return prefs.getBool('hasSeenOnboarding') ?? false;
// });
