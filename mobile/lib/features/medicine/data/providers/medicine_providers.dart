import 'dart:convert';

import 'package:medileger/core/config/api_config.dart';
import 'package:medileger/core/services/auth_service.dart';
import 'package:medileger/features/medicine/data/models/medicine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Provider to store medicine scan results
final scanResultProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

// Provider to store fetched medicines
final medicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  try {
    final authService = AuthService();
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/medicines'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        return (data['data'] as List)
            .map((medicine) => Medicine.fromJson(medicine))
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load medicines: ${response.statusCode}');
    }
  } catch (e) {
    // For demo purposes, return mock data if API fails
    print('Error fetching medicines: $e');
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      Medicine(
        id: '1',
        name: 'Paracetamol',
        quantity: 100,
        expiry: DateTime.now().add(const Duration(days: 180)),
        priority: false,
        hospitalId: 'hospital1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Medicine(
        id: '2',
        name: 'Amoxicillin',
        quantity: 50,
        expiry: DateTime.now().add(const Duration(days: 90)),
        priority: true,
        hospitalId: 'hospital1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Medicine(
        id: '3',
        name: 'Insulin',
        quantity: 20,
        expiry: DateTime.now().add(const Duration(days: 30)),
        priority: true,
        hospitalId: 'hospital1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Medicine(
        id: '4',
        name: 'Loratadine',
        quantity: 10,
        expiry: DateTime.now().add(const Duration(days: 120)),
        priority: false,
        hospitalId: 'hospital1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
});
