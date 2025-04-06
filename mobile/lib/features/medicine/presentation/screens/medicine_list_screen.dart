import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medileger/core/services/auth_service.dart';
import 'package:medileger/features/medicine/data/models/medicine.dart';
import 'package:medileger/features/medicine/data/providers/medicine_providers.dart';
import 'package:medileger/features/medicine/presentation/screens/medicine_scan_screen.dart';

final authServiceProvider = Provider((ref) => AuthService());

final currentUserProvider = FutureProvider.autoDispose((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

final medicineSearchProvider = StateProvider<String>((ref) => '');
final medicineFilterProvider = StateProvider<String>((ref) => 'all');

extension MedicineExtension on Medicine {
  bool get isExpiringSoon {
    final now = DateTime.now();
    final diff = expiry.difference(now).inDays;
    return diff <= 30 && diff > 0;
  }

  bool get isExpired => expiry.isBefore(DateTime.now());

  bool get isLowStock => quantity <= 20;

  String get status {
    if (isExpired || quantity <= 10) return 'critical';
    if (isExpiringSoon || isLowStock) return 'warning';
    return 'good';
  }
}

class MedicineListScreen extends ConsumerStatefulWidget {
  const MedicineListScreen({super.key});

  @override
  ConsumerState<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends ConsumerState<MedicineListScreen> {
  String _searchQuery = '';
  final String _sortBy = 'name';
  final bool _ascending = true;
  int _selectedFilter = 0; // 0: All, 1: Low stock, 2: Expiring soon
  final bool _showFab = true;

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider);
    final userAsync = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Column(
          children: [
            // Header with wallet address
            userAsync.when(
              data: (userData) => userData != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      color: colorScheme.primaryContainer,
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData['name'] ?? 'Hospital',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${userData['walletAddress'].substring(0, 6)}...${userData['walletAddress'].substring(userData['walletAddress'].length - 4)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer
                                        .withOpacity(0.8),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Search and scan bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search medicines...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          hintStyle: TextStyle(
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (context) => const MedicineScanScreen(),
                          ),
                        )
                            .then((result) {
                          if (result != null) {
                            ref.invalidate(medicinesProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Medicines added to inventory!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.document_scanner_outlined,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == 0,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 0;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Low Stock'),
                    selected: _selectedFilter == 1,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 1;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Expiring Soon'),
                    selected: _selectedFilter == 2,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 2;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Priority'),
                    selected: _selectedFilter == 3,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 3;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Medicine inventory cards
            Expanded(
              child: medicinesAsync.when(
                data: (medicines) {
                  if (medicines.isEmpty) {
                    return const Center(
                      child: Text('No medicines found'),
                    );
                  }

                  // Filter medicines based on search query and selected filter
                  var filteredMedicines = medicines.where((medicine) {
                    final matchesSearch =
                        medicine.name.toLowerCase().contains(_searchQuery);

                    switch (_selectedFilter) {
                      case 1: // Low Stock
                        return matchesSearch && medicine.isLowStock;
                      case 2: // Expiring Soon
                        return matchesSearch && medicine.isExpiringSoon;
                      case 3: // Priority
                        return matchesSearch && medicine.priority;
                      default: // All
                        return matchesSearch;
                    }
                  }).toList();

                  // Sort medicines
                  filteredMedicines.sort((a, b) {
                    if (_sortBy == 'name') {
                      return _ascending
                          ? a.name.compareTo(b.name)
                          : b.name.compareTo(a.name);
                    } else if (_sortBy == 'quantity') {
                      return _ascending
                          ? a.quantity.compareTo(b.quantity)
                          : b.quantity.compareTo(a.quantity);
                    } else {
                      return _ascending
                          ? a.expiry.compareTo(b.expiry)
                          : b.expiry.compareTo(a.expiry);
                    }
                  });

                  // Add overview charts if no filters active
                  if (_selectedFilter == 0 && _searchQuery.isEmpty) {
                    return Column(
                      children: [
                        // Current Balance Card instead of charts
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildInventoryValueCard(context, medicines),
                        ),

                        // Medicine list
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredMedicines.length,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemBuilder: (context, index) {
                              final medicine = filteredMedicines[index];
                              return MedicineCard(medicine: medicine);
                            },
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Just show the filtered list without the value card
                    return ListView.builder(
                      itemCount: filteredMedicines.length,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final medicine = filteredMedicines[index];
                        return MedicineCard(medicine: medicine);
                      },
                    );
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading medicines: $error'),
                ),
              ),
            ),
          ],
        ),

        // FAB for adding new medicine
        Positioned(
          bottom: 16,
          right: 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showFab ? 1.0 : 0.0,
            child: FloatingActionButton(
              heroTag: 'medicine_list_fab',
              onPressed: () {
                // Navigate to add medicine screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MedicineScanScreen(),
                  ),
                );
              },
              tooltip: 'Add Medicine',
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}

class MedicineCard extends StatelessWidget {
  final Medicine medicine;

  const MedicineCard({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('MMM dd, yyyy');

    // Determine card style based on status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (medicine.status) {
      case 'critical':
        statusColor = Colors.red.shade700;
        statusText = medicine.isExpired ? 'Expired' : 'Critical';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusText = medicine.isExpiringSoon
            ? 'Expiring Soon'
            : medicine.isLowStock
                ? 'Low Stock'
                : 'Warning';
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = Colors.green;
        statusText = 'Good';
        statusIcon = Icons.check_circle_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: medicine.priority ? Colors.blue.shade300 : Colors.transparent,
          width: medicine.priority ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to medicine details screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      medicine.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (medicine.priority)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Priority',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Quantity indicator
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: medicine.isLowStock
                                  ? Colors.orange
                                  : colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              medicine.quantity.toString(),
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    medicine.isLowStock ? Colors.orange : null,
                              ),
                            ),
                            if (medicine.isLowStock)
                              Text(
                                ' (Low)',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expiry indicator
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expiry',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 18,
                              color: medicine.isExpired
                                  ? Colors.red
                                  : medicine.isExpiringSoon
                                      ? Colors.orange
                                      : colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(medicine.expiry),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: medicine.isExpired
                                    ? Colors.red
                                    : medicine.isExpiringSoon
                                        ? Colors.orange
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildInventoryValueCard(
    BuildContext context, List<Medicine> medicines) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  // Calculate total value (simplified for demo)
  final totalCount = medicines.length;
  final criticalCount = medicines.where((m) => m.status == 'critical').length;
  final warningCount = medicines.where((m) => m.status == 'warning').length;
  final goodCount = medicines.where((m) => m.status == 'good').length;

  // Fake total value calculation - would be based on actual prices in real app
  final totalValue = medicines.length * 1250;
  final formattedValue = NumberFormat("#,##0").format(totalValue);

  return Container(
    width: double.infinity,
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
                formattedValue,
                style: textTheme.displaySmall?.copyWith(
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
                totalCount.toString(),
                Icons.medication_outlined,
              ),
              const SizedBox(width: 8),
              _buildQuickStatCard(
                context,
                'Critical',
                criticalCount.toString(),
                Icons.warning_amber_outlined,
                isWarning: true,
              ),
              const SizedBox(width: 8),
              _buildQuickStatCard(
                context,
                'Low Stock',
                warningCount.toString(),
                Icons.inventory,
                isWarning: warningCount > 0,
              ),
            ],
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

class EnhancedMedicineListScreen extends ConsumerStatefulWidget {
  const EnhancedMedicineListScreen({super.key});

  @override
  ConsumerState<EnhancedMedicineListScreen> createState() =>
      _EnhancedMedicineListScreenState();
}

class _EnhancedMedicineListScreenState
    extends ConsumerState<EnhancedMedicineListScreen> {
  String _sortBy = 'name';
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicinesProvider);
    final searchQuery = ref.watch(medicineSearchProvider);
    final filterType = ref.watch(medicineFilterProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return medicinesAsync.when(
      data: (medicines) {
        if (medicines.isEmpty) {
          return _buildEmptyState(context);
        }

        // Filter medicines based on search query and selected filter
        var filteredMedicines = medicines.where((medicine) {
          final matchesSearch =
              medicine.name.toLowerCase().contains(searchQuery);

          switch (filterType) {
            case 'low_stock':
              return matchesSearch && medicine.isLowStock;
            case 'expiring':
              return matchesSearch && medicine.isExpiringSoon;
            case 'priority':
              return matchesSearch && medicine.priority;
            case 'critical':
              return matchesSearch && medicine.status == 'critical';
            case 'good':
              return matchesSearch && medicine.status == 'good';
            case 'recent':
              // Assume medicines added in the last 7 days are "recent"
              final weekAgo = DateTime.now().subtract(const Duration(days: 7));
              return matchesSearch && medicine.createdAt.isAfter(weekAgo);
            case 'regular':
              return matchesSearch && !medicine.priority;
            default: // 'all'
              return matchesSearch;
          }
        }).toList();

        // Sort medicines
        filteredMedicines.sort((a, b) {
          if (_sortBy == 'name') {
            return _ascending
                ? a.name.compareTo(b.name)
                : b.name.compareTo(a.name);
          } else if (_sortBy == 'quantity') {
            return _ascending
                ? a.quantity.compareTo(b.quantity)
                : b.quantity.compareTo(a.quantity);
          } else {
            return _ascending
                ? a.expiry.compareTo(b.expiry)
                : b.expiry.compareTo(a.expiry);
          }
        });

        // Create a ListView that includes both the compact summary card AND the medicine list
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // Compact inventory summary card - only show when no filter is active
            if (filterType == 'all' && searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildCompactSummaryCard(context, medicines),
              ),

            // Sort and view options with item count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${filteredMedicines.length} ${filteredMedicines.length == 1 ? 'medicine' : 'medicines'}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sort',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (_sortBy == value) {
                              // Toggle direction if same sort field is selected
                              _ascending = !_ascending;
                            } else {
                              _sortBy = value;
                              _ascending = true;
                            }
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'name',
                            child: Text('Name'),
                          ),
                          const PopupMenuItem(
                            value: 'quantity',
                            child: Text('Quantity'),
                          ),
                          const PopupMenuItem(
                            value: 'expiry',
                            child: Text('Expiry Date'),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                            _ascending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 18),
                        onPressed: () {
                          setState(() {
                            _ascending = !_ascending;
                          });
                        },
                        tooltip: _ascending ? 'Ascending' : 'Descending',
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Medicine list with improved spacing
            if (filteredMedicines.isEmpty)
              _buildNoResultsFound(context)
            else
              ...filteredMedicines.map((medicine) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: MedicineCard(medicine: medicine),
                  )),

            // Bottom padding for FAB
            const SizedBox(height: 80),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  // Empty state when no medicines are found
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Medicines in Inventory',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add medicines to your inventory',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MedicineScanScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Medicine'),
          ),
        ],
      ),
    );
  }

  // No results found state
  Widget _buildNoResultsFound(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Matching Medicines',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              // Reset all filters correctly
              ref.read(medicineSearchProvider.notifier).update((_) => '');
              ref.read(medicineFilterProvider.notifier).update((_) => 'all');
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  // Error state
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading medicines: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(medicinesProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Compact version of the inventory value card
  Widget _buildCompactSummaryCard(
      BuildContext context, List<Medicine> medicines) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Calculate stats
    final totalMedicines = medicines.length;
    final criticalCount = medicines.where((m) => m.status == 'critical').length;
    final expiringCount = medicines.where((m) => m.isExpiringSoon).length;
    final lowStockCount = medicines.where((m) => m.isLowStock).length;

    // Calculate total value (simplified for demo)
    final totalValue = medicines.length * 1250;
    final formattedValue = NumberFormat("#,##0").format(totalValue);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary.withOpacity(0.8),
          ],
          stops: const [0.3, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with value and live indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '\$',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedValue,
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'INVENTORY VALUE',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactStat(
                  context,
                  'Total',
                  totalMedicines.toString(),
                  Icons.medication_outlined,
                ),
                _buildCompactStat(
                  context,
                  'Critical',
                  criticalCount.toString(),
                  Icons.warning_amber_outlined,
                  isWarning: criticalCount > 0,
                ),
                _buildCompactStat(
                  context,
                  'Expiring',
                  expiringCount.toString(),
                  Icons.event_outlined,
                  isWarning: expiringCount > 0,
                ),
                _buildCompactStat(
                  context,
                  'Low Stock',
                  lowStockCount.toString(),
                  Icons.inventory_2_outlined,
                  isWarning: lowStockCount > 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for compact stat widgets
  Widget _buildCompactStat(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isWarning ? Colors.amber : Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }
}
