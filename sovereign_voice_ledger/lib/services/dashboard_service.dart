
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class DashboardService {
  Future<Map<String, dynamic>> fetchDashboard() async {
    // Get the registered shop ID.
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shop_id');

    if (shopId == null || shopId <= 0) {
      throw Exception('Shop ID not found. Please register your shop.');
    }

    // Prepare the dashboard API URL.
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/dashboard/$shopId',
    );

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid dashboard response.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          decoded['message'] ?? 'Failed to load dashboard.',
        );
      }

      if (decoded['success'] != true ||
          decoded['data'] is! Map<String, dynamic>) {
        throw Exception(
          decoded['message'] ?? 'Unable to load dashboard data.',
        );
      }

      return decoded['data'] as Map<String, dynamic>;
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Unable to connect to the server: $error');
    }
  }
}
