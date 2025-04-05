import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL for API calls
  static const String baseUrl =
      "https://medichain.nikhilsahni.me/api"; // For Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // For iOS simulator

  // HTTP headers
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('GET request error: $e');
      throw Exception('Failed to perform GET request: $e');
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('POST request error: $e');
      throw Exception('Failed to perform POST request: $e');
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('PUT request error: $e');
      throw Exception('Failed to perform PUT request: $e');
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('DELETE request error: $e');
      throw Exception('Failed to perform DELETE request: $e');
    }
  }

  // Process response
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      final errorBody =
          response.body.isNotEmpty ? json.decode(response.body) : null;
      final errorMessage = errorBody != null
          ? errorBody['message'] ?? 'Unknown error'
          : 'Unknown error';
      debugPrint('API Error: ${response.statusCode} - $errorMessage');
      throw Exception('API Error ${response.statusCode}: $errorMessage');
    }
  }
}
