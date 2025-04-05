import 'package:flutter/foundation.dart';

import 'api_service.dart';

class Medicine {
  final String id;
  final String name;
  final int quantity;
  final DateTime expiry;
  final bool priority;
  final String hospitalId;
  final Hospital? hospital;

  Medicine({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiry,
    required this.priority,
    required this.hospitalId,
    this.hospital,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      expiry: DateTime.parse(json['expiry']),
      priority: json['priority'],
      hospitalId: json['hospitalId'],
      hospital:
          json['hospital'] != null ? Hospital.fromJson(json['hospital']) : null,
    );
  }

  // Check if medicine is expiring soon (within 30 days)
  bool get isExpiringSoon {
    final now = DateTime.now();
    final difference = expiry.difference(now).inDays;
    return difference <= 30 && difference >= 0;
  }

  // Check if medicine is expired
  bool get isExpired {
    return expiry.isBefore(DateTime.now());
  }

  // Check if medicine is low in stock (less than 20)
  bool get isLowStock {
    return quantity < 20;
  }

  // Get status color (red for expired/critical, yellow for warning, green for good)
  String get status {
    if (isExpired || quantity <= 10) {
      return 'critical';
    } else if (isExpiringSoon || isLowStock) {
      return 'warning';
    } else {
      return 'good';
    }
  }
}

class Hospital {
  final String id;
  final String? name;
  final String email;
  final String walletAddress;
  final double? latitude;
  final double? longitude;
  final int reputation;

  Hospital({
    required this.id,
    this.name,
    required this.email,
    required this.walletAddress,
    this.latitude,
    this.longitude,
    required this.reputation,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      walletAddress: json['walletAddress'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      reputation: json['reputation'] ?? 0,
    );
  }
}

class MedicineService {
  final ApiService _apiService = ApiService();

  // Get all medicines
  Future<List<Medicine>> getAllMedicines() async {
    try {
      final response = await _apiService.get('/medicines');
      final List<dynamic> medicinesJson = response['data'];
      return medicinesJson.map((json) => Medicine.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all medicines: $e');
      return [];
    }
  }

  // Get medicines by hospital
  Future<List<Medicine>> getMedicinesByHospital(String hospitalId) async {
    try {
      final response = await _apiService.get('/medicines/hospital/$hospitalId');
      final List<dynamic> medicinesJson = response['data'];
      return medicinesJson.map((json) => Medicine.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching hospital medicines: $e');
      return [];
    }
  }

  // Get low stock medicines for current hospital
  Future<List<Medicine>> getLowStockMedicines(int threshold) async {
    try {
      final response = await _apiService.get('/medicines/low-stock/$threshold');
      final List<dynamic> medicinesJson = response['data'];
      return medicinesJson.map((json) => Medicine.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching low stock medicines: $e');
      return [];
    }
  }

  // Get expiring soon medicines for current hospital
  Future<List<Medicine>> getExpiringSoonMedicines(int days) async {
    try {
      final response = await _apiService.get('/medicines/expiring-soon/$days');
      final List<dynamic> medicinesJson = response['data'];
      return medicinesJson.map((json) => Medicine.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching expiring soon medicines: $e');
      return [];
    }
  }

  // Create medicine
  Future<Medicine?> createMedicine({
    required String name,
    required int quantity,
    required DateTime expiry,
    required bool priority,
  }) async {
    try {
      final response = await _apiService.post('/medicines', {
        'name': name,
        'quantity': quantity,
        'expiry': expiry.toIso8601String(),
        'priority': priority,
      });
      return Medicine.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error creating medicine: $e');
      return null;
    }
  }

  // Update medicine
  Future<Medicine?> updateMedicine({
    required String id,
    String? name,
    int? quantity,
    DateTime? expiry,
    bool? priority,
  }) async {
    try {
      final data = {
        if (name != null) 'name': name,
        if (quantity != null) 'quantity': quantity,
        if (expiry != null) 'expiry': expiry.toIso8601String(),
        if (priority != null) 'priority': priority,
      };

      final response = await _apiService.put('/medicines/$id', data);
      return Medicine.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error updating medicine: $e');
      return null;
    }
  }

  // Delete medicine
  Future<bool> deleteMedicine(String id) async {
    try {
      await _apiService.delete('/medicines/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      return false;
    }
  }
}
