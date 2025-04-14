import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:medileger/core/services/auth_service.dart';
import 'package:medileger/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:medileger/features/maps/presentation/screens/hospital_map_screen.dart';
import 'package:medileger/features/medicine/data/providers/medicine_providers.dart';
import 'package:medileger/features/medicine/presentation/screens/medicine_list_screen.dart';
import 'package:medileger/features/medicine/presentation/screens/medicine_scan_screen.dart';
import 'package:medileger/features/notifications/data/providers/notification_providers.dart';
import 'package:medileger/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:medileger/features/notifications/presentation/widgets/alert_banner.dart';
import 'package:medileger/features/order_drugs/presentation/screens/order_drugs_screen.dart';
import 'package:medileger/features/settings/presentation/screens/settings_screen.dart';

// TODO: Import actual feature screens when created
// import 'package:medileger/features/check_medicines/presentation/screens/check_medicines_screen.dart';
// import 'package:medileger/features/stats/presentation/screens/stats_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

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

    // Add scroll listener
    _scrollController.addListener(() {
      setState(() {
        _showScrollToTop = _scrollController.offset > 200;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    _buildEnhancedInventoryScreen(),
    const OrderDrugsScreen(),
    const HospitalMapScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      // Reset scroll position when changing tabs
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: colorScheme.surface,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForIndex(_selectedIndex),
              size: 24,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _appBarTitles[_selectedIndex],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        if (_selectedIndex == 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh inventory',
              onPressed: () {
                // Invalidate medicine provider to refresh data
                ref.invalidate(medicinesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Refreshing inventory...'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        Consumer(
          builder: (context, ref, child) {
            final unreadCount = ref.watch(unreadNotificationsCountProvider);
            return Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () {
                      // Navigate to notifications screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.error.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40 : 8,
            vertical: 12,
          ),
          child: GNav(
            gap: 8,
            activeColor: colorScheme.onPrimaryContainer,
            tabBackgroundColor: colorScheme.primaryContainer,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 12,
              vertical: 12,
            ),
            iconSize: isTablet ? 24 : 22,
            textStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 14 : 12,
              color: colorScheme.onPrimaryContainer,
            ),
            color: colorScheme.onSurfaceVariant,
            rippleColor: colorScheme.primaryContainer.withOpacity(0.3),
            hoverColor: colorScheme.primaryContainer.withOpacity(0.2),
            curve: Curves.easeOutCubic,
            duration: const Duration(milliseconds: 300),
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

  Widget? _buildFloatingActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_selectedIndex == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showScrollToTop)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FloatingActionButton.small(
                heroTag: 'scroll_to_top',
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                },
                tooltip: 'Scroll to top',
                elevation: 4,
                backgroundColor: colorScheme.surfaceContainerHigh,
                foregroundColor: colorScheme.primary,
                child: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          FloatingActionButton.extended(
            heroTag: 'home_fab',
            onPressed: () {
              // Open Medicine Scan Screen
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => const MedicineScanScreen(),
                ),
              )
                  .then((result) {
                // If medicines were added, refresh the medicine list
                if (result != null) {
                  // Invalidate medicine provider to refresh data
                  ref.invalidate(medicinesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.greenAccent[100],
                          ),
                          const SizedBox(width: 12),
                          const Text('Medicines added to inventory!'),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              });
            },
            tooltip: 'Scan Medicine',
            elevation: 4,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text(
              'Scan Medicine',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ],
      );
    }
    return null;
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.inventory_2_rounded;
      case 1:
        return Icons.shopping_cart_rounded;
      case 2:
        return Icons.map_rounded;
      case 3:
        return Icons.analytics_rounded;
      case 4:
        return Icons.settings_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  Widget _buildEnhancedInventoryScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Alert banner
        SliverToBoxAdapter(
          child: Consumer(
            builder: (context, ref, child) {
              final recentAlerts = ref.watch(recentAlertsProvider);
              return recentAlerts.isNotEmpty
                  ? const AlertsBanner()
                  : const SizedBox(height: 4);
            },
          ),
        ),

        // Search bar with improved visual design
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withBlue(colorScheme.primary.blue + 15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search medicines...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    onChanged: (value) {
                      // Forward the search query to MedicineListScreen
                      ref
                          .read(medicineSearchProvider.notifier)
                          .update((_) => value.toLowerCase());
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Show filter dialog
                      },
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      splashColor: Colors.white.withOpacity(0.1),
                      highlightColor: Colors.white.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.filter_list_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Filter chips with improved visual design
        SliverToBoxAdapter(
          child: SizedBox(
            height: 56,
            child: Consumer(
              builder: (context, ref, child) {
                final selectedFilter = ref.watch(medicineFilterProvider);

                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(
                        'All', Icons.all_inclusive, selectedFilter == 'all'),
                    _buildFilterChip('Low Stock', Icons.inventory_2_outlined,
                        selectedFilter == 'low_stock'),
                    _buildFilterChip(
                        'Expiring Soon',
                        Icons.warning_amber_rounded,
                        selectedFilter == 'expiring'),
                    _buildFilterChip('Priority', Icons.priority_high_rounded,
                        selectedFilter == 'priority'),
                    _buildFilterChip(
                        'Recently Added',
                        Icons.new_releases_rounded,
                        selectedFilter == 'recent'),
                    _buildFilterChip('Categories', Icons.category_rounded,
                        selectedFilter == 'categories'),
                  ],
                );
              },
            ),
          ),
        ),

        // Add spacing between filter chips and medicine list
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),

        // Remainder of the screen filled with medicine list
        const SliverFillRemaining(
          hasScrollBody: true,
          child: EnhancedMedicineListScreen(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool selected) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        selected: selected,
        onSelected: (value) {
          // Update the filter provider based on selection
          if (value) {
            switch (label) {
              case 'All':
                ref.read(medicineFilterProvider.notifier).update((_) => 'all');
                break;
              case 'Low Stock':
                ref
                    .read(medicineFilterProvider.notifier)
                    .update((_) => 'low_stock');
                break;
              case 'Expiring Soon':
                ref
                    .read(medicineFilterProvider.notifier)
                    .update((_) => 'expiring');
                break;
              case 'Priority':
                ref
                    .read(medicineFilterProvider.notifier)
                    .update((_) => 'priority');
                break;
              case 'Recently Added':
                ref
                    .read(medicineFilterProvider.notifier)
                    .update((_) => 'recent');
                break;
              case 'Categories':
                ref
                    .read(medicineFilterProvider.notifier)
                    .update((_) => 'categories');
                break;
            }
          }
        },
        backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        elevation: selected ? 2 : 0,
        pressElevation: 4,
        shadowColor: selected ? colorScheme.shadow : Colors.transparent,
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withOpacity(0.7),
                        colorScheme.primaryContainer.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: isTablet ? 64 : 52,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: isTablet ? 28 : 24),

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
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),

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

                const SizedBox(height: 36),

                // Add custom feature preview cards based on tab
                _buildFeaturePreviewCards(context, title),

                const SizedBox(height: 36),

                // Action button
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title feature coming soon!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Notify Me When Available'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
            colorScheme.primary.withBlue(colorScheme.primary.blue + 20),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
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
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
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
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Value of Medicine Stock',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Container(
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
