import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/menu_item.dart';

class SellDialog extends StatefulWidget {
  final MenuItem menuItem;
  final Function(ItemSize size, int quantity, String? notes) onSell;

  const SellDialog({super.key, required this.menuItem, required this.onSell});

  @override
  State<SellDialog> createState() => _SellDialogState();
}

class _SellDialogState extends State<SellDialog> {
  late ItemSize selectedSize;
  int quantity = 1;
  bool _isProcessingSale = false;
  final TextEditingController notesController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );
  final currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    selectedSize = widget.menuItem.getAvailableSizes().first;
  }

  @override
  void dispose() {
    notesController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  double get totalAmount {
    return widget.menuItem.getPriceBySize(selectedSize) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.menuItem.category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.menuItem.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sell Item',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

            // Size Selection
            if (widget.menuItem.hasMultipleSizes()) ...[
              const Text(
                'Size',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.menuItem.getAvailableSizes().map((size) {
                  final isSelected = selectedSize == size;
                  final price = widget.menuItem.getPriceBySize(size);

                  return FilterChip(
                    selected: isSelected,
                    label: Text(
                      '${size.displayName} - ${currencyFormatter.format(price)}',
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedSize = size;
                        });
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Single size - show price
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Price: ${currencyFormatter.format(widget.menuItem.getPriceBySize(selectedSize))}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Quantity Selection
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Decrease button
                IconButton(
                  onPressed: quantity > 1
                      ? () {
                          setState(() {
                            quantity--;
                            quantityController.text = quantity.toString();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Theme.of(context).primaryColor,
                ),
                // Quantity input
                Expanded(
                  child: TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      final newQuantity = int.tryParse(value) ?? 1;
                      setState(() {
                        quantity = newQuantity > 0 ? newQuantity : 1;
                      });
                    },
                  ),
                ),
                // Increase button
                IconButton(
                  onPressed: () {
                    setState(() {
                      quantity++;
                      quantityController.text = quantity.toString();
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Notes (Optional)
            const Text(
              'Notes (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add any notes about this sale...',
                contentPadding: EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 24),

            // Total and Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(totalAmount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessingSale ? null : _handleSell,
                          icon: _isProcessingSale
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
                              : const Icon(Icons.shopping_cart),
                          label: Text(
                            _isProcessingSale ? 'Processing...' : 'Sell',
                          ),
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
    );
  }

  void _handleSell() async {
    setState(() {
      _isProcessingSale = true;
    });

    try {
      await widget.onSell(
        selectedSize,
        quantity,
        notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      // Error is handled in the parent (menu_screen.dart)
      // Just reset the loading state
      if (mounted) {
        setState(() {
          _isProcessingSale = false;
        });
      }
    }
  }
}
