import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../models/stock_history.dart';
import '../services/stock_api_service.dart';
import '../providers/user_provider.dart';
import '../providers/menu_provider.dart';

class StockManagementDialog extends ConsumerStatefulWidget {
  final MenuItem menuItem;

  const StockManagementDialog({super.key, required this.menuItem});

  @override
  ConsumerState<StockManagementDialog> createState() =>
      _StockManagementDialogState();
}

class _StockManagementDialogState extends ConsumerState<StockManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _stockApiService = StockApiService();

  StockMovementType _selectedMovementType = StockMovementType.restock;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _quantityChange {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    // For DAMAGE, SALE - quantity should be negative
    if (_selectedMovementType == StockMovementType.damage ||
        _selectedMovementType == StockMovementType.sale) {
      return -qty.abs();
    }
    // For RESTOCK, RETURN, INITIAL - quantity should be positive
    return qty.abs();
  }

  int get _newStockQuantity {
    return (widget.menuItem.stockQuantity ?? 0) + _quantityChange;
  }

  bool get _isValid {
    if (_quantityController.text.isEmpty) return false;
    final qty = int.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) return false;
    if (_newStockQuantity < 0) return false;
    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || !_isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(requireUserIdProvider);

      final result = await _stockApiService.updateStock(
        menuItemId: widget.menuItem.id,
        quantityChange: _quantityChange,
        movementType: _selectedMovementType,
        userId: userId,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          // Refresh menu items
          ref.invalidate(menuItemsProvider);

          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Stock updated successfully! New quantity: $_newStockQuantity',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['error'] ?? 'Failed to update stock'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.brown[700], size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Stock',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.menuItem.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Current Stock Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${widget.menuItem.stockQuantity ?? 0} units',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Movement Type Selection
                const Text(
                  'Movement Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<StockMovementType>(
                  value: _selectedMovementType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items:
                      [
                        StockMovementType.restock,
                        StockMovementType.adjustment,
                        StockMovementType.damage,
                        StockMovementType.returnItem,
                      ].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Text(
                                type.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(type.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMovementType = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Quantity Input
                const Text(
                  'Quantity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.numbers),
                    hintText: 'Enter quantity',
                    helperText:
                        _selectedMovementType == StockMovementType.damage ||
                            _selectedMovementType == StockMovementType.sale
                        ? 'Will be deducted from stock'
                        : 'Will be added to stock',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter quantity';
                    }
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'Quantity must be greater than 0';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {}); // Update preview
                  },
                ),

                const SizedBox(height: 16),

                // Reason Input
                const Text(
                  'Reason (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                    hintText: 'e.g., Weekly restock, Expired items, etc.',
                  ),
                ),

                const SizedBox(height: 20),

                // Preview New Stock
                if (_quantityController.text.isNotEmpty && _isValid) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _newStockQuantity <
                              (widget.menuItem.lowStockThreshold ?? 5)
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _newStockQuantity <
                                (widget.menuItem.lowStockThreshold ?? 5)
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.preview,
                          color:
                              _newStockQuantity <
                                  (widget.menuItem.lowStockThreshold ?? 5)
                              ? Colors.orange[700]
                              : Colors.green[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Stock Quantity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${widget.menuItem.stockQuantity ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    _quantityChange > 0
                                        ? Icons.arrow_forward
                                        : Icons.arrow_forward,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                  Text(
                                    '$_newStockQuantity units',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _quantityChange > 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${_quantityChange > 0 ? '+' : ''}$_quantityChange)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _quantityChange > 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Negative stock warning
                if (_quantityController.text.isNotEmpty &&
                    _newStockQuantity < 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cannot reduce stock below 0. Please enter a smaller quantity.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || !_isValid
                            ? null
                            : _handleSubmit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _isLoading ? 'Updating...' : 'Update Stock',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
