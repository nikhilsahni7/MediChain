import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class Hospital {
  final String id;
  final String? name;
  final String email;
  final String walletAddress;
  final double? latitude;
  final double? longitude;
  final int reputation;
  final String token;

  Hospital({
    required this.id,
    this.name,
    required this.email,
    required this.walletAddress,
    this.latitude,
    this.longitude,
    required this.reputation,
    required this.token,
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
      token: json['token'],
    );
  }
}

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Hospital> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final hospitalData = response['data'];
      final hospital = Hospital.fromJson(hospitalData);

      // Save user data to SharedPreferences
      await _saveUserData(
        hospital.id,
        hospital.name,
        hospital.email,
        hospital.walletAddress,
        hospital.token,
      );

      return hospital;
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear specific authentication-related keys
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('name');
      await prefs.remove('email');
      await prefs.remove('walletAddress');
      await prefs.setBool('isLoggedIn', false);

      // For complete cleanup, you might want to clear everything
      // but that could affect other app settings
      // await prefs.clear();

      debugPrint('Logout successful: All auth data cleared');
    } catch (e) {
      debugPrint('Logout error: $e');
      throw Exception('Logout failed: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token') != null;
    } catch (e) {
      debugPrint('isLoggedIn check error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final name = prefs.getString('name');
      final email = prefs.getString('email');
      final walletAddress = prefs.getString('walletAddress');
      final token = prefs.getString('token');

      if (userId != null &&
          email != null &&
          walletAddress != null &&
          token != null) {
        return {
          'id': userId,
          'name': name,
          'email': email,
          'walletAddress': walletAddress,
          'token': token,
        };
      }
      return null;
    } catch (e) {
      debugPrint('getCurrentUser error: $e');
      return null;
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      debugPrint('getToken error: $e');
      return null;
    }
  }

  Future<void> _saveUserData(
    String id,
    String? name,
    String email,
    String walletAddress,
    String token,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', id);
      if (name != null) await prefs.setString('name', name);
      await prefs.setString('email', email);
      await prefs.setString('walletAddress', walletAddress);
      await prefs.setString('token', token);
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      debugPrint('Error saving user data: $e');
      throw Exception('Failed to save user data: $e');
    }
  }
}
