import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:medileger/features/settings/presentation/screens/settings_screen.dart';

// TODO: Import actual feature screens when created
// import 'package:medileger/features/check_medicines/presentation/screens/check_medicines_screen.dart';
// import 'package:medileger/features/order_drugs/presentation/screens/order_drugs_screen.dart';
// import 'package:medileger/features/maps/presentation/screens/maps_screen.dart';
// import 'package:medileger/features/stats/presentation/screens/stats_screen.dart';
// import 'package:medileger/features/settings/presentation/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const List<String> _appBarTitles = [
    'Check Availability',
    'Place Order',
    'Hospital Map',
    'Inventory Stats',
    'Settings',
  ];

  // Revert to using the local _PlaceholderScreenWidget
  static final List<Widget> _widgetOptions = <Widget>[
    const _PlaceholderScreenWidget(
        icon: Icons.search_outlined, title: 'Check Availability'),
    const _PlaceholderScreenWidget(
        icon: Icons.shopping_cart_outlined, title: 'Order Drugs'),
    const _PlaceholderScreenWidget(
        icon: Icons.map_outlined, title: 'Hospital Map'),
    const _PlaceholderScreenWidget(
        icon: Icons.bar_chart_outlined,
        title: 'Inventory Stats'), // Changed icon
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logout logic is now in SettingsScreen

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Let the theme handle the background color
      // backgroundColor: colorScheme.background, // Already handled by theme
      appBar: AppBar(
        // Use theme's AppBar settings
        title: Text(_appBarTitles[_selectedIndex]),
        // actions: [ // Example Action
        //   IconButton(icon: Icon(Icons.notifications_none), onPressed: () {}),
        // ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bottomNavTheme.backgroundColor, // Use theme background
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.1),
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          // Ensure GNav respects safe areas
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: GNav(
              backgroundColor:
                  Colors.transparent, // Container handles background
              color: bottomNavTheme.unselectedItemColor, // Use theme color
              activeColor: bottomNavTheme.selectedItemColor, // Use theme color
              tabBackgroundColor: colorScheme.primary
                  .withOpacity(0.08), // Subtle background for active tab
              gap: 8,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              iconSize: 24,
              tabs: const [
                GButton(icon: Icons.search_outlined, text: 'Check'),
                GButton(icon: Icons.shopping_cart_outlined, text: 'Order'),
                GButton(icon: Icons.map_outlined, text: 'Map'),
                GButton(
                    icon: Icons.bar_chart_outlined,
                    text: 'Stats'), // Changed icon
                GButton(icon: Icons.settings_outlined, text: 'Settings'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}

// Keep the local placeholder widget definition here
class _PlaceholderScreenWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PlaceholderScreenWidget({
    // super.key, // Key is often optional for private widgets
    required this.icon,
    required this.title,
    this.message = '(UI Pending - Feature Implementation Next)',
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 60, // Slightly smaller icon
              color: colorScheme.primary
                  .withOpacity(0.6), // Use primary color with opacity
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
