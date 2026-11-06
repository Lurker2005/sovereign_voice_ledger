
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class CustomerApiService {
  // Fetch all customers belonging to a shop.
  Future<Map<String, dynamic>> getCustomers(int shopId) async {
    final url = Uri.parse('${ApiConfig.customerUrl}/$shopId');

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'customers': data['customers'] ?? [],
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Unable to fetch customers.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
      };
    }
  }

  // Fetch an individual customer's balance.
  Future<Map<String, dynamic>> getCustomerBalance({
    required int shopId,
    required int customerId,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.customerUrl}/$shopId/$customerId/balance',
    );

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'customer': data['customer'],
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Unable to fetch customer balance.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
      };
    }
  }

  // Find an existing customer or create a new one.
  Future<Map<String, dynamic>> resolveCustomer({
    required int shopId,
    required String customerName,
    String? phone,
    String? address,
  }) async {
    final url = Uri.parse('${ApiConfig.customerUrl}/resolve');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'shop_id': shopId,
              'customer_name': customerName.trim(),
              'phone': phone?.trim(),
              'address': address?.trim(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 ||
              response.statusCode == 201) &&
          data['success'] == true) {
        return {
          'success': true,
          ...data,
        };
      }

      return {
        'success': false,
        'requires_clarification':
            data['requires_clarification'] ?? false,
        'candidates': data['candidates'] ?? [],
        'message': data['error'] ?? 'Unable to resolve customer.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
      };
    }
  }
}
