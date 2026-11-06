
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/customer_api_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerApiService _customerApi = CustomerApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _customers = [];

  bool _isLoading = true;
  String? _errorMessage;
  int? _shopId;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shop_id');

      if (shopId == null || shopId <= 0) {
        throw Exception('Shop registration not found.');
      }

      final result = await _customerApi.getCustomers(shopId);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _shopId = shopId;
          _customers = List<dynamic>.from(result['customers']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Unable to load customers.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load customers. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return _customers;

    return _customers.where((customer) {
      final name =
          (customer['customer_name'] ?? '').toString().toLowerCase();

      final phone =
          (customer['phone'] ?? '').toString().toLowerCase();

      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  double get _totalOutstanding {
    double total = 0;

    for (final customer in _customers) {
      final balance =
          double.tryParse(customer['current_balance'].toString()) ?? 0;

      if (balance > 0) {
        total += balance;
      }
    }

    return total;
  }

  String _formatBalance(dynamic value) {
    final balance = double.tryParse(value.toString()) ?? 0;
    return '₹${balance.toStringAsFixed(2)}';
  }

  Color _balanceColor(double balance) {
    if (balance > 0) return Colors.red.shade700;
    if (balance < 0) return Colors.green.shade700;
    return Colors.grey.shade700;
  }

  String _balanceLabel(double balance) {
    if (balance > 0) return 'Due';
    if (balance < 0) return 'Advance';
    return 'Settled';
  }

  Future<void> _showCustomerBalance(dynamic customer) async {
    final customerId = customer['customer_id'];

    final result = await _customerApi.getCustomerBalance(
      shopId: _shopId!,
      customerId: customerId,
    );

    if (!mounted) return;

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Unable to fetch customer balance.',
          ),
        ),
      );
      return;
    }

    final details = result['customer'];
    final balance =
        double.tryParse(details['current_balance'].toString()) ?? 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(details['customer_name'] ?? 'Customer Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer ID: ${details['customer_id']}'),
              const SizedBox(height: 12),
              Text('Account ID: ${details['account_id']}'),
              const SizedBox(height: 16),
              const Text('Current Balance'),
              const SizedBox(height: 4),
              Text(
                _formatBalance(details['current_balance']),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _balanceColor(balance),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _balanceLabel(balance),
                style: TextStyle(
                  color: _balanceColor(balance),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerCard(dynamic customer) {
    final name = customer['customer_name'] ?? 'Unknown';
    final phone = customer['phone'] ?? 'No phone number';

    final balance =
        double.tryParse(customer['current_balance'].toString()) ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F5E9),
          child: Text(
            name.toString().isNotEmpty
                ? name.toString()[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name.toString(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(phone.toString()),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatBalance(customer['current_balance']),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _balanceColor(balance),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _balanceLabel(balance),
              style: TextStyle(
                fontSize: 12,
                color: _balanceColor(balance),
              ),
            ),
          ],
        ),
        onTap: () => _showCustomerBalance(customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _filteredCustomers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            onPressed: _loadCustomers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadCustomers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCustomers,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Customers',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${_customers.length}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Total Outstanding'),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_totalOutstanding.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search customers...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Customer List (${filteredCustomers.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (filteredCustomers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 55,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _customers.isEmpty
                                    ? 'No customers yet'
                                    : 'No matching customers found',
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredCustomers.map(_buildCustomerCard),
                    ],
                  ),
                ),
    );
  }
}
