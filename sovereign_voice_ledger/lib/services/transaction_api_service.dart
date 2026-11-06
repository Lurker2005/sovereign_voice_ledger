
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class TransactionApiService {
  Future<Map<String, dynamic>> getTransactionHistory(int shopId) async {
    final url = Uri.parse('${ApiConfig.transactionUrl}/$shopId');

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 20));

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Invalid response from server.',
        };
      }

      if (response.statusCode == 200 && decoded['success'] == true) {
        final rawTransactions = decoded['transactions'];

        if (rawTransactions is! List) {
          return {
            'success': false,
            'message': 'Invalid transaction history data.',
          };
        }

        return {
          'success': true,
          'transactions': rawTransactions
              .whereType<Map>()
              .map((transaction) => Map<String, dynamic>.from(transaction))
              .toList(),
          'total_transactions': decoded['total_transactions'] ?? 0,
        };
      }

      return {
        'success': false,
        'message': decoded['error'] ?? 'Unable to fetch transaction history.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to the server.',
      };
    }
  }
}
