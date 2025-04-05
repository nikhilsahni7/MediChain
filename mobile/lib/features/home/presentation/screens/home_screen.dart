import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:medileger/core/services/auth_service.dart';
import 'package:medileger/features/maps/presentation/screens/hospital_map_screen.dart';
import 'package:medileger/features/medicine/presentation/screens/medicine_list_screen.dart';
import 'package:medileger/features/settings/presentation/screens/settings_screen.dart';

// TODO: Import actual feature screens when created
// import 'package:medileger/features/check_medicines/presentation/screens/check_medicines_screen.dart';
// import 'package:medileger/features/order_drugs/presentation/screens/order_drugs_screen.dart';
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
    'Inventory',
    'Orders',
    'Map',
    'Analytics',
    'Settings',
  ];

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Check if user is still logged in
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn && mounted) {
      // Navigate to login screen if not logged in
      // TODO: Implement redirect to login
    }
  }

  // Lazy loaded screens
  late final List<Widget> _widgetOptions = <Widget>[
    const MedicineListScreen(),
    const _PlaceholderScreenWidget(
        icon: Icons.shopping_cart_outlined, title: 'Order Medicines'),
    const HospitalMapScreen(),
    const _PlaceholderScreenWidget(
        icon: Icons.bar_chart_outlined, title: 'Analytics'),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: _buildBottomNav(context, isTablet),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Add new medicine action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add new medicine')),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForIndex(_selectedIndex),
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(_appBarTitles[_selectedIndex]),
        ],
      ),
      actions: [
        if (_selectedIndex == 0)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh inventory',
            onPressed: () {
              // Invalidate medicine provider to refresh data
              ref.invalidate(medicinesProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing inventory...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40 : 8,
            vertical: 8,
          ),
          child: GNav(
            gap: 8,
            activeColor: colorScheme.onPrimaryContainer,
            tabBackgroundColor: colorScheme.primaryContainer,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 8,
              vertical: 10,
            ),
            iconSize: isTablet ? 24 : 20,
            textStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 14 : 12,
              color: colorScheme.onPrimaryContainer,
            ),
            color: colorScheme.onSurfaceVariant,
            tabs: const [
              GButton(
                icon: Icons.inventory_2_outlined,
                text: 'Inventory',
              ),
              GButton(
                icon: Icons.shopping_cart_outlined,
                text: 'Order',
              ),
              GButton(
                icon: Icons.map_outlined,
                text: 'Map',
              ),
              GButton(
                icon: Icons.analytics_outlined,
                text: 'Analytics',
              ),
              GButton(
                icon: Icons.settings_outlined,
                text: 'Settings',
              ),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.inventory_2_outlined;
      case 1:
        return Icons.shopping_cart_outlined;
      case 2:
        return Icons.map_outlined;
      case 3:
        return Icons.analytics_outlined;
      case 4:
        return Icons.settings_outlined;
      default:
        return Icons.home_outlined;
    }
  }
}

// Enhanced placeholder screen with modern UI for hackathon
class _PlaceholderScreenWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PlaceholderScreenWidget({
    required this.icon,
    required this.title,
    this.message = '(UI Pending - Feature Implementation Next)',
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : 350,
              minHeight: screenSize.height * 0.7,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Always show the inventory value card for ALL tabs
                _buildInventoryValueCard(context, isTablet),
                SizedBox(height: isTablet ? 32 : 24),

                // Feature icon in a modern container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: isTablet ? 60 : 48,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 20),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: (isTablet
                          ? textTheme.headlineSmall
                          : textTheme.titleLarge)
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: (isTablet ? textTheme.bodyLarge : textTheme.bodyMedium)
                      ?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Add custom feature preview cards based on tab
                _buildFeaturePreviewCards(context, title),

                const SizedBox(height: 32),

                // Action button
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$title feature coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('Notify Me When Available'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New Inventory Value Card - shown on ALL tabs
  Widget _buildInventoryValueCard(BuildContext context, bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inventory Value',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '254,879',
                  style: (isTablet
                          ? textTheme.displaySmall
                          : textTheme.headlineLarge)
                      ?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Value of Medicine Stock',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '8.3%',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildQuickStatCard(
                  context,
                  'Items',
                  '1,254',
                  Icons.medication_outlined,
                ),
                const SizedBox(width: 8),
                _buildQuickStatCard(
                  context,
                  'Categories',
                  '38',
                  Icons.category_outlined,
                ),
                const SizedBox(width: 8),
                _buildQuickStatCard(
                  context,
                  'Expiring Soon',
                  '23',
                  Icons.warning_amber_outlined,
                  isWarning: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tab-specific feature preview cards
  Widget _buildFeaturePreviewCards(BuildContext context, String title) {
    // Different preview cards based on tab type
    if (title.contains('Order')) {
      return _buildOrderPreviewCards(context);
    } else if (title.contains('Map')) {
      return _buildMapPreviewCard(context);
    } else if (title.contains('Analytics')) {
      return _buildAnalyticsPreviewCards(context);
    } else {
      // Default empty container for other tabs
      return const SizedBox.shrink();
    }
  }

  // Order preview cards
  Widget _buildOrderPreviewCards(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Order',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildQuickOrderItem(
                      context, 'Paracetamol', Colors.blue.shade200),
                  const SizedBox(width: 8),
                  _buildQuickOrderItem(context, 'Insulin', Colors.red.shade200),
                  const SizedBox(width: 8),
                  _buildQuickOrderItem(
                      context, 'Antibiotics', Colors.green.shade200),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Map preview card
  Widget _buildMapPreviewCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.map_outlined,
              size: 80,
              color: colorScheme.primary.withOpacity(0.3),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Text(
                'Hospital Map',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Analytics preview cards
  Widget _buildAnalyticsPreviewCards(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'Critical Stock',
                '4 Items',
                Icons.error_outline,
                Colors.redAccent,
                'Order Now',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                'Expiring Soon',
                '23 Items',
                Icons.access_time,
                Colors.amberAccent.shade700,
                'View Items',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickOrderItem(BuildContext context, String name, Color color) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.add_shopping_cart,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isWarning ? Colors.amber : Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String actionText,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.surfaceContainerHighest,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                actionText,
                style: textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: color,
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
