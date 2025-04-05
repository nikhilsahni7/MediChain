import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medileger/config/router/app_router.dart';
import 'package:medileger/config/theme/app_theme.dart';
import 'package:medileger/core/providers/shared_preferences_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Refactored Logout Logic (can be called from anywhere)
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('isLoggedIn', false);
      if (context.mounted) {
        // Use context safely
        context.go(AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final listTileTheme = Theme.of(context).listTileTheme;
    final cardTheme = Theme.of(context).cardTheme;

    // Helper for building section titles
    Widget buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(
            top: 24.0, bottom: 8.0, left: 16.0, right: 16.0),
        child: Text(
          title.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary, // Use primary color for section titles
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    return Scaffold(
      // AppBar is handled by HomeScreen's Scaffold
      body: ListView(
        // Remove default ListView padding, add our own via section title or Card margin
        padding: EdgeInsets.zero,
        children: [
          buildSectionTitle('Display Options'),
          Card(
            // Use theme card style
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Column(
              children: [
                // Use theme's RadioTheme and ListTileTheme
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  subtitle:
                      Text('Follow device setting', style: textTheme.bodySmall),
                  value: ThemeMode.system,
                  groupValue: currentThemeMode,
                  onChanged: (value) => ref
                      .read(themeNotifierProvider.notifier)
                      .setThemeMode(value ?? ThemeMode.system),
                  // activeColor: colorScheme.primary, // Handled by RadioTheme
                  contentPadding:
                      listTileTheme.contentPadding, // Use theme padding
                  shape: listTileTheme.shape, // Use theme shape
                ),
                // Add subtle divider
                Divider(
                    height: 1,
                    indent: listTileTheme.contentPadding?.horizontal ?? 32,
                    endIndent: listTileTheme.contentPadding?.horizontal ?? 32),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Mode'),
                  subtitle: Text('Always use light theme',
                      style: textTheme.bodySmall),
                  value: ThemeMode.light,
                  groupValue: currentThemeMode,
                  onChanged: (value) => ref
                      .read(themeNotifierProvider.notifier)
                      .setThemeMode(value ?? ThemeMode.light),
                  contentPadding: listTileTheme.contentPadding,
                  shape: listTileTheme.shape,
                ),
                Divider(
                    height: 1,
                    indent: listTileTheme.contentPadding?.horizontal ?? 32,
                    endIndent: listTileTheme.contentPadding?.horizontal ?? 32),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Mode'),
                  subtitle:
                      Text('Always use dark theme', style: textTheme.bodySmall),
                  value: ThemeMode.dark,
                  groupValue: currentThemeMode,
                  onChanged: (value) => ref
                      .read(themeNotifierProvider.notifier)
                      .setThemeMode(value ?? ThemeMode.dark),
                  contentPadding: listTileTheme.contentPadding,
                  shape: listTileTheme.shape,
                ),
              ],
            ),
          ),

          buildSectionTitle('Account'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: ListTile(
              leading: Icon(Icons.logout_outlined, color: colorScheme.error),
              title: Text('Logout',
                  style: TextStyle(
                      color: colorScheme.error, fontWeight: FontWeight.w600)),
              onTap: () => _logout(context, ref), // Call refactored logout
              contentPadding: listTileTheme.contentPadding,
              shape: listTileTheme.shape,
            ),
          ),

          // --- Add More Settings Sections Example ---
          // buildSectionTitle('Notifications'),
          // Card(
          //   margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          //   child: SwitchListTile(
          //     title: const Text('Push Notifications'),
          //     subtitle: Text('Receive updates and alerts', style: textTheme.bodySmall),
          //     value: true, // Replace with actual state provider
          //     onChanged: (bool value) {
          //       // TODO: Update notification preference
          //     },
          //     secondary: const Icon(Icons.notifications_active_outlined),
          //     activeColor: colorScheme.primary,
          //     contentPadding: listTileTheme.contentPadding,
          //     shape: listTileTheme.shape,
          //   ),
          // ),

          const SizedBox(height: 30), // Add some bottom space
        ],
      ),
    );
  }
}
