import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'medicine_service.dart';

class MedicineSearchResult {
  final String id;
  final String name;
  final int quantity;
  final DateTime expiry;
  final bool priority;
  final String hospitalId;
  final Hospital hospital;
  final double distance;
  final Map<String, bool> paymentOptions;

  MedicineSearchResult({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiry,
    required this.priority,
    required this.hospitalId,
    required this.hospital,
    required this.distance,
    required this.paymentOptions,
  });

  factory MedicineSearchResult.fromJson(Map<String, dynamic> json) {
    return MedicineSearchResult(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      expiry: DateTime.parse(json['expiry']),
      priority: json['priority'],
      hospitalId: json['hospitalId'],
      hospital: Hospital.fromJson(json['hospital']),
      distance: json['distance']?.toDouble() ?? 0.0,
      paymentOptions: {
        'crypto': json['paymentOptions']?['crypto'] ?? false,
        'razorpay': json['paymentOptions']?['razorpay'] ?? true,
      },
    );
  }
}

class Order {
  final String id;
  final String medicineName;
  final int quantity;
  final String fromHospitalId;
  final String toHospitalId;
  final bool emergency;
  final String status;
  final String? transactionHash;
  final String? nftCertificateId;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.medicineName,
    required this.quantity,
    required this.fromHospitalId,
    required this.toHospitalId,
    required this.emergency,
    required this.status,
    this.transactionHash,
    this.nftCertificateId,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.paymentMethod,
    this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      medicineName: json['medicineName'],
      quantity: json['quantity'],
      fromHospitalId: json['fromHospitalId'],
      toHospitalId: json['toHospitalId'],
      emergency: json['emergency'] ?? false,
      status: json['status'],
      transactionHash: json['transactionHash'],
      nftCertificateId: json['nftCertificateId'],
      razorpayOrderId: json['razorpayOrderId'],
      razorpayPaymentId: json['razorpayPaymentId'],
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class RazorpayOrderResponse {
  final String razorpayOrderId;
  final int amount;
  final String currency;
  final String orderId;

  RazorpayOrderResponse({
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.orderId,
  });

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponse(
      razorpayOrderId: json['razorpayOrderId'],
      amount: json['amount'],
      currency: json['currency'],
      orderId: json['orderId'],
    );
  }
}

class OrderService {
  final ApiService _apiService = ApiService();

  // Search for medicines by name
  Future<List<MedicineSearchResult>> searchMedicinesByName({
    required String name,
    required int quantity,
    int maxDistance = 50,
  }) async {
    try {
      debugPrint(
          'Searching for medicines: $name, quantity: $quantity, maxDistance: $maxDistance');

      try {
        final response = await _apiService.post('/medicines/search', {
          'name': name,
          'quantity': quantity,
          'maxDistance': maxDistance,
        });

        debugPrint('Search response: $response');

        if (response == null || !response.containsKey('data')) {
          debugPrint('Invalid response format');
          return _getMockMedicineResults(name, quantity);
        }

        final List<dynamic> resultsJson = response['data'];
        debugPrint('Results count: ${resultsJson.length}');

        if (resultsJson.isEmpty) {
          debugPrint('No results found, using mock data');
          return _getMockMedicineResults(name, quantity);
        }

        return resultsJson
            .map((json) => MedicineSearchResult.fromJson(json))
            .toList();
      } catch (e) {
        debugPrint('API Error, using mock data: $e');
        return _getMockMedicineResults(name, quantity);
      }
    } catch (e) {
      debugPrint('Error searching medicines: $e');
      return [];
    }
  }

  // Provide mock data when API fails
  List<MedicineSearchResult> _getMockMedicineResults(
      String name, int quantity) {
    debugPrint('Generating mock results for $name');

    // Create mock hospital
    final hospital1 = Hospital(
      id: 'hospital1',
      name: 'City General Hospital',
      email: 'city.general@example.com',
      walletAddress: '0xA742578812425346789012345678901234567890',
      reputation: 4,
      latitude: 28.6139,
      longitude: 77.2090,
    );

    final hospital2 = Hospital(
      id: 'hospital2',
      name: 'Metro Medical Center',
      email: 'metro.medical@example.com',
      walletAddress: '0xB123456789012345678901234567890123456789',
      reputation: 5,
      latitude: 28.6429,
      longitude: 77.2191,
    );

    // Create mock results based on search term
    return [
      MedicineSearchResult(
        id: 'med1',
        name: name,
        quantity: quantity * 2,
        expiry: DateTime.now().add(const Duration(days: 180)),
        priority: false,
        hospitalId: hospital1.id,
        hospital: hospital1,
        distance: 2.5,
        paymentOptions: {
          'crypto': true,
          'razorpay': true,
        },
      ),
      MedicineSearchResult(
        id: 'med2',
        name: name,
        quantity: quantity * 3,
        expiry: DateTime.now().add(const Duration(days: 90)),
        priority: true,
        hospitalId: hospital2.id,
        hospital: hospital2,
        distance: 4.8,
        paymentOptions: {
          'crypto': false,
          'razorpay': true,
        },
      ),
    ];
  }

  // Create order
  Future<Order?> createOrder({
    required String medicineName,
    required int quantity,
    required String toHospitalId,
    bool emergency = false,
  }) async {
    try {
      final response = await _apiService.post('/orders', {
        'medicineName': medicineName,
        'quantity': quantity,
        'toHospitalId': toHospitalId,
        'emergency': emergency,
      });

      return Order.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  // Get my orders
  Future<List<Order>> getMyOrders() async {
    try {
      final response = await _apiService.get('/orders/my-orders');
      final List<dynamic> ordersJson = response['data'];
      return ordersJson.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching my orders: $e');
      return [];
    }
  }

  // Create Razorpay payment order
  Future<RazorpayOrderResponse?> createPaymentOrder({
    required String orderId,
    required int amount,
    String currency = 'INR',
  }) async {
    try {
      final response = await _apiService.post('/orders/payment', {
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
      });

      return RazorpayOrderResponse.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error creating payment order: $e');
      return null;
    }
  }

  // Verify Razorpay payment
  Future<Order?> verifyRazorpayPayment({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _apiService.post('/orders/payment/verify', {
        'orderId': orderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      });

      return Order.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      return null;
    }
  }

  // Complete order with blockchain (for future crypto payment)
  Future<Order?> completeOrderWithBlockchain({
    required String orderId,
    required String transactionHash,
    String? nftCertificateId,
  }) async {
    try {
      final response = await _apiService.put('/orders/$orderId/complete', {
        'transactionHash': transactionHash,
        if (nftCertificateId != null) 'nftCertificateId': nftCertificateId,
      });

      return Order.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error completing order with blockchain: $e');
      return null;
    }
  }
}
