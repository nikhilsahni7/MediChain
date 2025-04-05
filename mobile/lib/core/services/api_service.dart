import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL for API calls
  static const String baseUrl = "https://medichain.nikhilsahni.me/api";

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
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('GET request to: $url');

      final response = await http.get(url, headers: headers);

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
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('POST request to: $url');
      debugPrint('POST data: ${json.encode(data)}');

      final response = await http.post(
        url,
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
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('PUT request to: $url');

      final response = await http.put(
        url,
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
      final url = Uri.parse('$baseUrl$endpoint');
      debugPrint('DELETE request to: $url');

      final response = await http.delete(
        url,
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
    debugPrint('Response status code: ${response.statusCode}');
    debugPrint('Response headers: ${response.headers}');

    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;

        final responseBody = response.body;
        debugPrint(
            'Response body preview: ${responseBody.length > 100 ? '${responseBody.substring(0, 100)}...' : responseBody}');

        return json.decode(responseBody);
      } else {
        final responseBody = response.body;
        debugPrint(
            'Error response: ${responseBody.length > 200 ? '${responseBody.substring(0, 200)}...' : responseBody}');

        Map<String, dynamic>? errorBody;
        try {
          if (responseBody.isNotEmpty) {
            errorBody = json.decode(responseBody);
          }
        } catch (e) {
          debugPrint('Error parsing error response: $e');
        }

        final errorMessage = errorBody != null
            ? errorBody['message'] ?? 'Unknown error'
            : 'Unknown error';

        debugPrint('API Error: ${response.statusCode} - $errorMessage');
        throw Exception('API Error ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      debugPrint('Error processing response: $e');
      throw Exception('Error processing response: $e');
    }
  }
}
