
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/transaction_api_service.dart';

const Color historyGreen = Color(0xFF16834A);
const Color historyBackground = Color(0xFFF7F9F7);
const Color historyText = Color(0xFF17251C);
const Color historySecondary = Color(0xFF78847B);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TransactionApiService _apiService = TransactionApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shop_id');

      if (shopId == null) {
        throw Exception('Shop registration not found.');
      }

      final result = await _apiService.getTransactionHistory(shopId);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _transactions =
              List<Map<String, dynamic>>.from(result['transactions']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Unable to load transaction history.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load transaction history.';
        _isLoading = false;
      });
    }
  }

  String _formatAmount(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return 'Date unavailable';

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;

    final hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
    final minute = localDate.minute.toString().padLeft(2, '0');
    final period = localDate.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }

  List<Map<String, dynamic>> _getItems(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _getPayments(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((payment) => Map<String, dynamic>.from(payment))
        .toList();
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['transaction_type']?.toString() ?? 'purchase';
    final isPurchase = type == 'purchase';

    final customerName =
        transaction['customer_name']?.toString() ?? 'Unknown customer';

    final amount = _formatAmount(transaction['total_amount']);
    final date = _formatDate(transaction['created_at']);

    final items = _getItems(transaction['items']);
    final payments = _getPayments(transaction['payments']);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPurchase
                      ? const Color(0xFFFFF0E8)
                      : const Color(0xFFE8F5EC),
                  child: Icon(
                    isPurchase
                        ? Icons.shopping_bag_outlined
                        : Icons.payments_outlined,
                    color: isPurchase ? Colors.deepOrange : historyGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: historyText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPurchase ? 'Purchase' : 'Repayment',
                        style: const TextStyle(
                          color: historySecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPurchase ? Colors.deepOrange : historyGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              'Transaction #${transaction['transaction_id'] ?? '-'}',
              style: const TextStyle(
                color: historySecondary,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 5),

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: historySecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  date,
                  style: const TextStyle(
                    color: historySecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            if (items.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Purchased items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: historyText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              ...items.map((item) {
                final name =
                    item['product_name']?.toString() ?? 'Product';
                final quantity = item['quantity']?.toString() ?? '0';
                final unit = item['unit']?.toString() ?? '';
                final subtotal = _formatAmount(item['subtotal']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$name • $quantity $unit',
                          style: const TextStyle(
                            fontSize: 12,
                            color: historySecondary,
                          ),
                        ),
                      ),
                      Text(
                        subtotal,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: historyText,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (payments.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Payments',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: historyText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              ...payments.map((payment) {
                final paymentAmount = _formatAmount(payment['amount']);
                final method =
                    payment['payment_method']?.toString() ?? 'Not specified';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          method,
                          style: const TextStyle(
                            fontSize: 12,
                            color: historySecondary,
                          ),
                        ),
                      ),
                      Text(
                        paymentAmount,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: historyGreen,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: historyBackground,
      appBar: AppBar(
        backgroundColor: historyBackground,
        title: const Text(
          'Transaction History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: historyText,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh history',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: historyGreen),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 45,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: historySecondary),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _loadHistory,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _transactions.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 65,
                            color: historySecondary,
                          ),
                          SizedBox(height: 18),
                          Center(
                            child: Text(
                              'No transactions yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: historyText,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Your purchases and repayments will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: historySecondary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            '${_transactions.length} transactions',
                            style: const TextStyle(
                              color: historySecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._transactions.map(_buildTransactionCard),
                        ],
                      ),
                    ),
    );
  }
}
