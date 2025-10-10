import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/menu_item.dart';
import '../screens/stock_history_screen.dart';
import 'menu_item_form_dialog.dart';
import 'delete_menu_item_dialog.dart';
import 'stock_management_dialog.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback onSell;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MenuItemCard({
    super.key,
    required this.menuItem,
    required this.onSell,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menuItem.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (menuItem.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          menuItem.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Stock indicator
                      if (menuItem.isTrackingStock) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              menuItem.isOutOfStock
                                  ? Icons.remove_circle
                                  : menuItem.isLowStock
                                  ? Icons.warning_amber
                                  : Icons.check_circle,
                              size: 16,
                              color: menuItem.isOutOfStock
                                  ? Colors.red
                                  : menuItem.isLowStock
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              menuItem.isOutOfStock
                                  ? 'Out of Stock'
                                  : menuItem.isLowStock
                                  ? 'Low Stock (${menuItem.currentStock})'
                                  : 'Stock: ${menuItem.currentStock}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: menuItem.isOutOfStock
                                    ? Colors.red
                                    : menuItem.isLowStock
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Menu button
                Row(
                  children: [
                    // More menu button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'More options',
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditDialog(context);
                            break;
                          case 'stock':
                            _showStockManagementDialog(context);
                            break;
                          case 'history':
                            _navigateToStockHistory(context);
                            break;
                          case 'delete':
                            _showDeleteDialog(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit, color: Colors.blue),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'stock',
                          child: ListTile(
                            leading: Icon(
                              Icons.inventory_2,
                              color: Colors.orange,
                            ),
                            title: Text('Manage Stock'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: ListTile(
                            leading: Icon(Icons.history, color: Colors.purple),
                            title: Text('Stock History'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pricing and Sell Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price Display
                Expanded(child: _buildPriceDisplay(currencyFormatter)),
                const SizedBox(width: 16),
                // Sell Button
                ElevatedButton.icon(
                  onPressed: menuItem.isAvailable && menuItem.hasStock
                      ? onSell
                      : null,
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: Text(menuItem.isOutOfStock ? 'Out of Stock' : 'Sell'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Availability Status
            if (!menuItem.isAvailable) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.red.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Out of Stock',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplay(NumberFormat currencyFormatter) {
    if (menuItem.hasMultipleSizes()) {
      // Multiple sizes - show all prices
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prices:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          ...menuItem.prices.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.key.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormatter.format(entry.value),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    } else {
      // Single price
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormatter.format(menuItem.prices.values.first),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      );
    }
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          MenuItemFormDialog(dialogTitle: 'Edit Menu Item', menuItem: menuItem),
    );
  }

  void _showStockManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StockManagementDialog(menuItem: menuItem),
    );
  }

  void _navigateToStockHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StockHistoryScreen(menuItem: menuItem),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DeleteMenuItemDialog(menuItem: menuItem),
    );
  }
}
