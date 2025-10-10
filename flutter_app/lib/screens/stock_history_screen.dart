import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_history.dart';
import '../models/menu_item.dart';
import '../services/stock_api_service.dart';

class StockHistoryScreen extends StatefulWidget {
  final MenuItem menuItem;

  const StockHistoryScreen({super.key, required this.menuItem});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final _stockApiService = StockApiService();
  List<StockHistory> _stockHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStockHistory();
  }

  Future<void> _loadStockHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _stockApiService.getStockHistory(
        menuItemId: widget.menuItem.id,
      );

      setState(() {
        _stockHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock History'),
            Text(widget.menuItem.name, style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStockHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStockHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_stockHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No stock movements yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Current Stock Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.blue.shade50,
          child: Column(
            children: [
              const Text(
                'Current Stock',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.menuItem.stockQuantity ?? 0} units',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // History List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _stockHistory.length,
            itemBuilder: (context, index) {
              final history = _stockHistory[index];
              return _buildHistoryCard(history, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(StockHistory history, int index) {
    final dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');
    final isIncrease = history.quantityChange > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movement Type Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getMovementColor(history.movementType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  history.movementType.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Movement Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movement Type
                  Text(
                    history.movementType.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Date/Time
                  Text(
                    history.createdAt != null
                        ? dateFormatter.format(history.createdAt!)
                        : 'Unknown date',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),

                  if (history.reason != null && history.reason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        history.reason!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Quantity Change and New Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quantity Change
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isIncrease
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isIncrease
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    '${isIncrease ? '+' : ''}${history.quantityChange}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isIncrease ? Colors.green : Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Stock Level
                Text(
                  '${history.previousQuantity} → ${history.newQuantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                // New Total
                Text(
                  '${history.newQuantity} units',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMovementColor(StockMovementType type) {
    switch (type) {
      case StockMovementType.restock:
      case StockMovementType.returnItem:
      case StockMovementType.initial:
        return Colors.green;
      case StockMovementType.sale:
        return Colors.blue;
      case StockMovementType.damage:
        return Colors.red;
      case StockMovementType.adjustment:
      case StockMovementType.transfer:
        return Colors.orange;
    }
  }
}
