
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/product_api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductApiService _apiService = ProductApiService();

  List<Map<String, dynamic>> _products = [];

  bool _isLoading = true;
  String? _errorMessage;
  int? _shopId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shop_id');

      if (shopId == null) {
        throw Exception('Shop registration information not found.');
      }

      final result = await _apiService.getProducts(shopId);

      if (!mounted) return;

      if (result['success'] == true) {
        final List<dynamic> data = result['products'] as List<dynamic>;

        setState(() {
          _shopId = shopId;
          _products = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Unable to load products.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load products. Please try again.';
        _isLoading = false;
      });
    }
  }

  // Future<void> _showProductDialog({
  //   Map<String, dynamic>? product,
  // }) async {
  //   final isEditing = product != null;

  //   final nameController = TextEditingController(
  //     text: product?['product_name']?.toString() ?? '',
  //   );

  //   final unitController = TextEditingController(
  //     text: product?['unit']?.toString() ?? '',
  //   );

  //   final priceController = TextEditingController(
  //     text: product?['unit_price']?.toString() ?? '',
  //   );

  //   final formKey = GlobalKey<FormState>();

  //   final shouldSave = await showDialog<bool>(
  //     context: context,
  //     builder: (dialogContext) {
  //       return AlertDialog(
  //         title: Text(isEditing ? 'Edit Product' : 'Add Product'),
  //         content: SingleChildScrollView(
  //           child: Form(
  //             key: formKey,
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 TextFormField(
  //                   controller: nameController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Product Name',
  //                     hintText: 'Example: Rice',
  //                     border: OutlineInputBorder(),
  //                   ),
  //                   validator: (value) {
  //                     if (value == null || value.trim().isEmpty) {
  //                       return 'Enter product name';
  //                     }
  //                     return null;
  //                   },
  //                 ),
  //                 const SizedBox(height: 15),
  //                 TextFormField(
  //                   controller: unitController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Unit',
  //                     hintText: 'Example: kg, litre, piece',
  //                     border: OutlineInputBorder(),
  //                   ),
  //                   validator: (value) {
  //                     if (value == null || value.trim().isEmpty) {
  //                       return 'Enter product unit';
  //                     }
  //                     return null;
  //                   },
  //                 ),
  //                 const SizedBox(height: 15),
  //                 TextFormField(
  //                   controller: priceController,
  //                   keyboardType: const TextInputType.numberWithOptions(
  //                     decimal: true,
  //                   ),
  //                   decoration: const InputDecoration(
  //                     labelText: 'Price per unit',
  //                     prefixText: '₹ ',
  //                     border: OutlineInputBorder(),
  //                   ),
  //                   validator: (value) {
  //                     final price = double.tryParse(value ?? '');

  //                     if (price == null || price <= 0) {
  //                       return 'Enter a valid price greater than zero';
  //                     }

  //                     if (price > 9999999999999999) {
  //                       return 'Enter a smaller price';
  //                     }

  //                     final decimalPart = value!.split('.');
  //                     if (decimalPart.length > 1 &&
  //                         decimalPart[1].length > 2) {
  //                       return 'Maximum 2 decimal places allowed';
  //                     }

  //                     return null;
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(dialogContext, false);
  //             },
  //             child: const Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               if (formKey.currentState!.validate()) {
  //                 Navigator.pop(dialogContext, true);
  //               }
  //             },
  //             child: Text(isEditing ? 'Update' : 'Save'),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (shouldSave == true && _shopId != null) {
  //     final price = double.parse(priceController.text.trim());

  //     Map<String, dynamic> result;

  //     if (isEditing) {
  //       result = await _apiService.updateProduct(
  //         shopId: _shopId!,
  //         productId: (product['product_id'] as num).toInt(),
  //         productName: nameController.text,
  //         unit: unitController.text,
  //         unitPrice: price,
  //       );
  //     } else {
  //       result = await _apiService.addProduct(
  //         shopId: _shopId!,
  //         productName: nameController.text,
  //         unit: unitController.text,
  //         unitPrice: price,
  //       );
  //     }

  //     if (!mounted) return;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           result['success'] == true
  //               ? (result['message'] ??
  //                   (isEditing
  //                       ? 'Product updated successfully.'
  //                       : 'Product added successfully.'))
  //               : (result['message'] ?? 'Operation failed.'),
  //         ),
  //       ),
  //     );

  //     if (result['success'] == true) {
  //       await _loadProducts();
  //     }
  //   }

  //   nameController.dispose();
  //   unitController.dispose();
  //   priceController.dispose();
  // }
  
Future<void> _showProductDialog({
  Map<String, dynamic>? product,
}) async {
  final isEditing = product != null;

  final formData = await showDialog<ProductFormData>(
    context: context,
    builder: (dialogContext) {
      return ProductDialog(
        product: product,
      );
    },
  );

  // Cancel or dialog dismissal
  if (formData == null || !mounted || _shopId == null) {
    return;
  }

  final price = double.parse(formData.unitPrice);

  Map<String, dynamic> result;

  if (isEditing) {
    result = await _apiService.updateProduct(
      shopId: _shopId!,
      productId: (product['product_id'] as num).toInt(),
      productName: formData.productName,
      unit: formData.unit,
      unitPrice: price,
    );
  } else {
    result = await _apiService.addProduct(
      shopId: _shopId!,
      productName: formData.productName,
      unit: formData.unit,
      unitPrice: price,
    );
  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result['success'] == true
            ? (result['message'] ??
                (isEditing
                    ? 'Product updated successfully.'
                    : 'Product added successfully.'))
            : (result['message'] ?? 'Operation failed.'),
      ),
    ),
  );

  if (result['success'] == true) {
    await _loadProducts();
  }
}


  Future<void> _deactivateProduct(
    Map<String, dynamic> product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deactivate Product?'),
          content: Text(
            'Do you want to deactivate ${product['product_name']}? '
            'It will no longer appear in the active product list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _shopId == null) return;

    final result = await _apiService.deactivateProduct(
      shopId: _shopId!,
      productId: (product['product_id'] as num).toInt(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message'] ??
              (result['success'] == true
                  ? 'Product deactivated.'
                  : 'Unable to deactivate product.'),
        ),
      ),
    );

    if (result['success'] == true) {
      await _loadProducts();
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final price = double.tryParse(
          product['unit_price'].toString(),
        ) ??
        0;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8F5EC),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF16834A),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['product_name'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '₹${price.toStringAsFixed(2)} / ${product['unit']}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showProductDialog(product: product);
                } else if (value == 'deactivate') {
                  _deactivateProduct(product);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'deactivate',
                  child: Text('Deactivate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF7F9F7),
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh products',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shopId == null
            ? null
            : () => _showProductDialog(),
        backgroundColor: const Color(0xFF16834A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF16834A),
              ),
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
                          size: 50,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 65,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'No products yet',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Add your first product to start '
                              'managing your shop inventory.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          90,
                        ),
                        children: [
                          Text(
                            '${_products.length} active products',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._products.map(_buildProductCard),
                        ],
                      ),
                    ),
    );
  }
}

class ProductFormData {
  final String productName;
  final String unit;
  final String unitPrice;

  ProductFormData({
    required this.productName,
    required this.unit,
    required this.unitPrice,
  });
}

class ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductDialog({
    super.key,
    this.product,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.product?['product_name']?.toString() ?? '',
    );

    _unitController = TextEditingController(
      text: widget.product?['unit']?.toString() ?? '',
    );

    _priceController = TextEditingController(
      text: widget.product?['unit_price']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    // _nameController.dispose();
    // _unitController.dispose();
    // _priceController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    final price = double.tryParse(value ?? '');

    if (price == null || price <= 0) {
      return 'Enter a valid price greater than zero';
    }

    if (price > 9999999999999999) {
      return 'Enter a smaller price';
    }

    final parts = value!.split('.');

    if (parts.length > 1 && parts[1].length > 2) {
      return 'Maximum 2 decimal places allowed';
    }

    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      ProductFormData(
        productName: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        unitPrice: _priceController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'Example: Rice',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'Example: kg, litre, piece',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter product unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price per unit',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: _validatePrice,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}

