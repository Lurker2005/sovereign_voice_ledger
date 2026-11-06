
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ProductApiService {
  // Get all products belonging to a shop.
  Future<Map<String, dynamic>> getProducts(int shopId) async {
    final url = Uri.parse('${ApiConfig.productUrl}/$shopId');

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'products': data['products'] ?? [],
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Unable to fetch products.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
      };
    }
  }

  // Add a new product.
  Future<Map<String, dynamic>> addProduct({
    required int shopId,
    required String productName,
    required String unit,
    required double unitPrice,
  }) async {
    final url = Uri.parse('${ApiConfig.productUrl}/add');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'shop_id': shopId,
              'product_name': productName.trim(),
              'unit': unit.trim(),
              'unit_price': unitPrice,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'product_id': data['product_id'],
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Unable to add product.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
      };
    }
  }

  // Update an existing product.
  Future<Map<String, dynamic>> updateProduct({
    required int shopId,
    required int productId,
    required String productName,
    required String unit,
    required double unitPrice,
  }) async {
    final url = Uri.parse('${ApiConfig.productUrl}/update');

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'shop_id': shopId,
              'product_id': productId,
              'product_name': productName.trim(),
              'unit': unit.trim(),
              'unit_price': unitPrice,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Unable to update product.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
      };
    }
  }

  // Deactivate a product without deleting its history.
  Future<Map<String, dynamic>> deactivateProduct({
    required int shopId,
    required int productId,
  }) async {
    final url = Uri.parse('${ApiConfig.productUrl}/deactivate');

    try {
      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'shop_id': shopId,
              'product_id': productId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Unable to deactivate product.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
      };
    }
  }
}
