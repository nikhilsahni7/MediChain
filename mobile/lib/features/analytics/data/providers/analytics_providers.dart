import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medileger/core/services/api_service.dart';
import 'package:medileger/features/medicine/data/models/medicine.dart';

// Provider for medicine statistics data
final medicineStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final apiService = ApiService();
    final response = await apiService.get('/medicines');

    if (response != null &&
        response['status'] == 'success' &&
        response['data'] != null) {
      final List<Medicine> medicines = (response['data'] as List)
          .map((medicine) => Medicine.fromJson(medicine))
          .toList();

      // Calculate various statistics
      final stats = _calculateMedicineStats(medicines);
      return stats;
    }
    return _getMockStats(); // Fallback to mock data if no response
  } catch (e) {
    print('Error fetching medicine stats: $e');
    // Return mock data for demo purposes
    return _getMockStats();
  }
});

// Provider for low stock medicines
final lowStockMedicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  try {
    final apiService = ApiService();
    final response = await apiService.get('/medicines/low-stock/20');

    if (response != null &&
        response['status'] == 'success' &&
        response['data'] != null) {
      return (response['data'] as List)
          .map((medicine) => Medicine.fromJson(medicine))
          .toList();
    }
    return []; // Empty list if no data
  } catch (e) {
    print('Error fetching low stock medicines: $e');
    return []; // Empty list on error
  }
});

// Provider for expiring medicines
final expiringMedicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  try {
    final apiService = ApiService();
    final response = await apiService.get('/medicines/expiring-soon/30');

    if (response != null &&
        response['status'] == 'success' &&
        response['data'] != null) {
      return (response['data'] as List)
          .map((medicine) => Medicine.fromJson(medicine))
          .toList();
    }
    return []; // Empty list if no data
  } catch (e) {
    print('Error fetching expiring medicines: $e');
    return []; // Empty list on error
  }
});

// Provider for medicine trend data (for charts)
final medicineTrendProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final apiService = ApiService();
    // This would ideally be a dedicated API endpoint for trend data
    final response = await apiService.get('/medicines');

    if (response != null &&
        response['status'] == 'success' &&
        response['data'] != null) {
      final List<Medicine> medicines = (response['data'] as List)
          .map((medicine) => Medicine.fromJson(medicine))
          .toList();

      // Generate trend data from medicines
      return _generateTrendData(medicines);
    }
    return _getMockTrendData(); // Fallback to mock data
  } catch (e) {
    print('Error fetching medicine trends: $e');
    return _getMockTrendData(); // Return mock data for demo
  }
});

// Helper function to calculate medicine statistics
Map<String, dynamic> _calculateMedicineStats(List<Medicine> medicines) {
  if (medicines.isEmpty) {
    return _getMockStats();
  }

  // Total medicine count
  final totalItems = medicines.length;

  // Total inventory quantity
  final totalQuantity =
      medicines.fold(0, (sum, medicine) => sum + medicine.quantity);

  // Count of low stock items (less than 20 units)
  final lowStockCount = medicines.where((m) => m.quantity < 20).length;

  // Count of items expiring within 30 days
  final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
  final expiringCount =
      medicines.where((m) => m.expiry.isBefore(thirtyDaysFromNow)).length;

  // Priority medicines count
  final priorityCount = medicines.where((m) => m.priority).length;

  // Calculate inventory value (assuming average cost of $10 per unit for demo)
  final inventoryValue = totalQuantity * 10;

  // Count unique categories (using medicine names for demo)
  final uniqueNames = medicines.map((m) => m.name).toSet().length;

  return {
    'totalItems': totalItems,
    'totalQuantity': totalQuantity,
    'lowStockCount': lowStockCount,
    'expiringCount': expiringCount,
    'priorityCount': priorityCount,
    'inventoryValue': inventoryValue,
    'uniqueCategories': uniqueNames,
  };
}

// Helper function to generate trend data for charts
Map<String, dynamic> _generateTrendData(List<Medicine> medicines) {
  if (medicines.isEmpty) {
    return _getMockTrendData();
  }

  // Sort medicines by creation date for trend analysis
  medicines.sort((a, b) => a.createdAt.compareTo(b.createdAt));

  // Generate monthly data points (last 6 months)
  final now = DateTime.now();
  final monthlyData = <Map<String, dynamic>>[];

  for (int i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final monthName = _getMonthName(month.month);

    // Count items added this month
    final itemsThisMonth = medicines
        .where((m) =>
            m.createdAt.year == month.year && m.createdAt.month == month.month)
        .length;

    // Add data point
    monthlyData.add({
      'month': monthName,
      'items': itemsThisMonth,
    });
  }

  // Calculate top categories (using medicine names for demo)
  final categoryCount = <String, int>{};
  for (final medicine in medicines) {
    categoryCount[medicine.name] = (categoryCount[medicine.name] ?? 0) + 1;
  }

  // Sort and get top 5 categories
  final sortedCategories = categoryCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final topCategories = sortedCategories
      .take(5)
      .map((entry) => {
            'name': entry.key,
            'count': entry.value,
          })
      .toList();

  return {
    'monthlyTrend': monthlyData,
    'topCategories': topCategories,
  };
}

// Helper function to get month name
String _getMonthName(int month) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return monthNames[month - 1];
}

// Mock statistics data for demo purposes
Map<String, dynamic> _getMockStats() {
  return {
    'totalItems': 1254,
    'totalQuantity': 24879,
    'lowStockCount': 23,
    'expiringCount': 18,
    'priorityCount': 42,
    'inventoryValue': 254879,
    'uniqueCategories': 38,
  };
}

// Mock trend data for demo purposes
Map<String, dynamic> _getMockTrendData() {
  return {
    'monthlyTrend': [
      {'month': 'Jan', 'items': 75},
      {'month': 'Feb', 'items': 120},
      {'month': 'Mar', 'items': 90},
      {'month': 'Apr', 'items': 180},
      {'month': 'May', 'items': 140},
      {'month': 'Jun', 'items': 210},
    ],
    'topCategories': [
      {'name': 'Antibiotics', 'count': 32},
      {'name': 'Painkillers', 'count': 28},
      {'name': 'Vitamins', 'count': 25},
      {'name': 'Antivirals', 'count': 18},
      {'name': 'Insulin', 'count': 15},
    ],
  };
}
