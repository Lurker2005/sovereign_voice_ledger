
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ShopApiService {
  Future<Map<String, dynamic>> registerShop({
    required String shopName,
    required String ownerName,
    required String phone,
    String? email,
    String? address,
  }) async {
    final url = Uri.parse('${ApiConfig.shopUrl}/register');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'shop_name': shopName.trim(),
              'owner_name': ownerName.trim(),
              'phone': phone.trim(),
              'email': email?.trim().isEmpty == true
                  ? null
                  : email?.trim(),
              'address': address?.trim().isEmpty == true
                  ? null
                  : address?.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'shop_id': data['shop_id'],
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Shop registration failed.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server. Please try again.',
      };
    }
  }
}
