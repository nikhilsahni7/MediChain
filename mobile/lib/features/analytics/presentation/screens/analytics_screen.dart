import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medileger/features/analytics/data/providers/analytics_providers.dart';
import 'package:medileger/features/analytics/presentation/widgets/chart_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    // Watch all the providers
    final statsAsyncValue = ref.watch(medicineStatsProvider);
    final trendAsyncValue = ref.watch(medicineTrendProvider);
    final lowStockAsyncValue = ref.watch(lowStockMedicinesProvider);
    final expiringAsyncValue = ref.watch(expiringMedicinesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh all providers
        ref.invalidate(medicineStatsProvider);
        ref.invalidate(medicineTrendProvider);
        ref.invalidate(lowStockMedicinesProvider);
        ref.invalidate(expiringMedicinesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and refresh button
              _buildHeader(context, textTheme),
              const SizedBox(height: 20),

              // Stats summary cards in a grid
              statsAsyncValue.when(
                data: (stats) => _buildStatsGrid(context, stats, isTablet),
                loading: () => const _LoadingCard(height: 230),
                error: (error, stack) => _ErrorCard(
                  message: 'Failed to load statistics: $error',
                ),
              ),
              const SizedBox(height: 24),

              // Monthly trend chart
              _buildSectionHeader(
                  context, 'Monthly Trends', Icons.trending_up_outlined),
              const SizedBox(height: 12),
              trendAsyncValue.when(
                data: (trendData) => trendData['monthlyTrend'] != null
                    ? StockTrendLineChart(
                        trendData: List<Map<String, dynamic>>.from(
                          trendData['monthlyTrend'],
                        ),
                        lineColor: colorScheme.primary,
                        gradientColor: colorScheme.primaryContainer,
                      )
                    : const _ErrorCard(message: 'No trend data available'),
                loading: () => const _LoadingCard(height: 200),
                error: (error, stack) => _ErrorCard(
                  message: 'Failed to load trend data: $error',
                ),
              ),
              const SizedBox(height: 24),

              // Top categories pie chart
              _buildSectionHeader(context, 'Top Medicine Categories',
                  Icons.pie_chart_outline_outlined),
              const SizedBox(height: 12),
              trendAsyncValue.when(
                data: (trendData) => trendData['topCategories'] != null
                    ? Column(
                        children: [
                          CategoryPieChart(
                            categoryData: List<Map<String, dynamic>>.from(
                              trendData['topCategories'],
                            ),
                            colorList: const [
                              Colors.blue,
                              Colors.red,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryLegend(context, trendData),
                        ],
                      )
                    : const _ErrorCard(message: 'No category data available'),
                loading: () => const _LoadingCard(height: 240),
                error: (error, stack) => _ErrorCard(
                  message: 'Failed to load category data: $error',
                ),
              ),
              const SizedBox(height: 24),

              // Stock status bar chart
              _buildSectionHeader(
                  context, 'Stock Status', Icons.bar_chart_outlined),
              const SizedBox(height: 12),
              statsAsyncValue.when(
                data: (stats) => StockStatusBarChart(statsData: stats),
                loading: () => const _LoadingCard(height: 200),
                error: (error, stack) => _ErrorCard(
                  message: 'Failed to load stock status: $error',
                ),
              ),
              const SizedBox(height: 24),

              // Critical items list
              _buildSectionHeader(
                  context, 'Critical Items', Icons.warning_amber_outlined),
              const SizedBox(height: 12),
              _buildCriticalItemsSection(
                  context, ref, lowStockAsyncValue, expiringAsyncValue),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Dashboard',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitor your medicine inventory',
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            // Show date range picker for filtering data
            showDateRangePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  child: child!,
                );
              },
            );
          },
          icon: const Icon(Icons.date_range),
          tooltip: 'Filter by date range',
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, Map<String, dynamic> stats, bool isTablet) {
    final columns = isTablet ? 3 : 2;

    // Increase top margin for better spacing
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add a title for the stats section
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Inventory Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: isTablet ? 3.0 : 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            StatsCard(
              icon: Icons.all_inbox_outlined,
              title: 'Total Items',
              value: '${stats['totalItems']}',
              color: Colors.blue,
              trending: true,
              trendingUp: true,
            ),
            StatsCard(
              icon: Icons.assessment_outlined,
              title: 'Inventory Value',
              value: '\$${_formatNumber(stats['inventoryValue'])}',
              color: Colors.green,
              trending: true,
              trendingUp: true,
            ),
            StatsCard(
              icon: Icons.warning_amber_outlined,
              title: 'Low Stock',
              value: '${stats['lowStockCount']}',
              color: Colors.orange,
              subtitle: 'Need reorder',
            ),
            StatsCard(
              icon: Icons.access_time_outlined,
              title: 'Expiring Soon',
              value: '${stats['expiringCount']}',
              color: Colors.red,
              subtitle: 'Within 30d',
            ),
            StatsCard(
              icon: Icons.category_outlined,
              title: 'Categories',
              value: '${stats['uniqueCategories']}',
              color: Colors.purple,
            ),
            StatsCard(
              icon: Icons.priority_high_outlined,
              title: 'Priority',
              value: '${stats['priorityCount']}',
              color: Colors.deepPurple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryLegend(
      BuildContext context, Map<String, dynamic> trendData) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final List<Map<String, dynamic>> categories =
        List<Map<String, dynamic>>.from(
      trendData['topCategories'],
    );

    final colorList = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(
        categories.length,
        (index) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color:
                    index < colorList.length ? colorList[index] : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              categories[index]['name'],
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${categories[index]['count']})',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalItemsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> lowStockAsyncValue,
    AsyncValue<List<dynamic>> expiringAsyncValue,
  ) {
    return Column(
      children: [
        // Low stock items list
        lowStockAsyncValue.when(
          data: (lowStockItems) => lowStockItems.isNotEmpty
              ? _buildCriticalItemsList(
                  context,
                  'Low Stock Items',
                  lowStockItems,
                  Colors.orange,
                )
              : const SizedBox(),
          loading: () => const _LoadingCard(height: 100),
          error: (error, stack) => _ErrorCard(
            message: 'Failed to load low stock items: $error',
          ),
        ),
        const SizedBox(height: 16),

        // Expiring items list
        expiringAsyncValue.when(
          data: (expiringItems) => expiringItems.isNotEmpty
              ? _buildCriticalItemsList(
                  context,
                  'Expiring Items',
                  expiringItems,
                  Colors.red,
                )
              : const SizedBox(),
          loading: () => const _LoadingCard(height: 100),
          error: (error, stack) => _ErrorCard(
            message: 'Failed to load expiring items: $error',
          ),
        ),
      ],
    );
  }

  Widget _buildCriticalItemsList(
    BuildContext context,
    String title,
    List<dynamic> items,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  title.contains('Low')
                      ? Icons.inventory_2_outlined
                      : Icons.warning_amber_outlined,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} items',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length > 3 ? 3 : items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                title: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  title.contains('Low')
                      ? 'Qty: ${item.quantity}'
                      : 'Exp: ${_formatDate(item.expiry)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title.contains('Low') ? 'Reorder' : 'Expiring',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            },
          ),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    // Navigate to detailed view
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View All', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to format numbers with commas
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference <= 0) {
      return 'Expired';
    } else if (difference <= 1) {
      return 'Tomorrow';
    } else if (difference <= 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Loading widget for async data
class _LoadingCard extends StatelessWidget {
  final double height;

  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

// Error widget for async data
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
