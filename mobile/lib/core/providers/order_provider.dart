import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medileger/core/services/order_service.dart';

// Provider for OrderService
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

// Provider for storing search results
final medicineSearchResultsProvider =
    StateProvider<List<MedicineSearchResult>>((ref) {
  return [];
});

// Provider for getting my orders
final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final orderService = ref.watch(orderServiceProvider);
  return await orderService.getMyOrders();
});

// Provider for selected medicine search result
final selectedMedicineResultProvider =
    StateProvider<MedicineSearchResult?>((ref) {
  return null;
});

// Provider for refreshing orders
final refreshOrdersProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // Invalidate the myOrdersProvider to refresh data
    ref.invalidate(myOrdersProvider);
  };
});
