import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/menu_item.dart';
import '../models/transaction.dart';
import '../providers/menu_provider.dart';
import '../providers/category_provider.dart';
import '../providers/user_provider.dart';
import '../providers/sales_provider.dart';
import '../services/transaction_api_service.dart';
import '../widgets/transaction_invoice_dialog.dart';
import '../config/app_config.dart';

// Billing item class - represents items selected for billing
class BillingItem {
  final MenuItem menuItem;
  final String categoryName;
  final ItemSize size;
  int quantity;

  BillingItem({
    required this.menuItem,
    required this.categoryName,
    required this.size,
    this.quantity = 1,
  });

  double get unitPrice => menuItem.getPriceBySize(size);
  double get subtotal => unitPrice * quantity;
  String get uniqueKey => '${menuItem.id}_${size.name}';

  BillingItem copyWith({int? quantity}) {
    return BillingItem(
      menuItem: menuItem,
      categoryName: categoryName,
      size: size,
      quantity: quantity ?? this.quantity,
    );
  }

  TransactionItem toTransactionItem() {
    return TransactionItem.fromMenuItem(
      menuItem: menuItem,
      categoryName: categoryName,
      size: size,
      quantity: quantity,
    );
  }
}

// Billing state provider
class BillingNotifier extends StateNotifier<List<BillingItem>> {
  BillingNotifier() : super([]);

  void addItem(BillingItem item) {
    // Check if item already exists
    final existingIndex = state.indexWhere(
      (i) => i.uniqueKey == item.uniqueKey,
    );

    if (existingIndex != -1) {
      // Update quantity
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + item.quantity)
          else
            state[i],
      ];
    } else {
      // Add new item
      state = [...state, item];
    }
  }

  void updateQuantity(String uniqueKey, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(uniqueKey);
      return;
    }

    state = [
      for (final item in state)
        if (item.uniqueKey == uniqueKey)
          item.copyWith(quantity: newQuantity)
        else
          item,
    ];
  }

  void removeItem(String uniqueKey) {
    state = state.where((item) => item.uniqueKey != uniqueKey).toList();
  }

  void clearBilling() {
    state = [];
  }

  double getTotalAmount() {
    return state.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int getTotalItems() {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

final billingProvider =
    StateNotifierProvider<BillingNotifier, List<BillingItem>>(
      (ref) => BillingNotifier(),
    );

final billingTotalProvider = Provider<double>((ref) {
  final billing = ref.watch(billingProvider);
  return billing.fold(0.0, (sum, item) => sum + item.subtotal);
});

final billingItemCountProvider = Provider<int>((ref) {
  final billing = ref.watch(billingProvider);
  return billing.fold(0, (sum, item) => sum + item.quantity);
});

// Main Billing Screen
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
  );
  bool _isProcessing = false;
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check user authentication state
    final userAsync = ref.watch(currentUserProvider);
    final billingItems = ref.watch(billingProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800; // Mobile if screen width < 800px

    // Handle user loading/error states
    return userAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Billing'), centerTitle: true),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading user data...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Billing'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (user) =>
          _buildAuthenticatedContent(context, isMobile, billingItems),
    );
  }

  Widget _buildAuthenticatedContent(
    BuildContext context,
    bool isMobile,
    List<BillingItem> billingItems,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        centerTitle: true,
        actions: [
          // Show bill summary badge on mobile
          if (isMobile && billingItems.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.receipt_long),
                  onPressed: () => _showMobileBillSheet(),
                  tooltip: 'View Bill',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${billingItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          if (!isMobile && billingItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDialog(),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      // Floating action button for mobile
      floatingActionButton: isMobile && billingItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showMobileBillSheet(),
              icon: const Icon(Icons.receipt_long),
              label: Text('Bill (${billingItems.length})'),
            )
          : null,
    );
  }

  // Desktop/Tablet Layout (Split Screen)
  Widget _buildDesktopLayout() {
    final billingItems = ref.watch(billingProvider);
    final totalAmount = ref.watch(billingTotalProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Row(
      children: [
        // Left Side - Menu Items Selection
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Category Tabs
              categoriesAsync.when(
                data: (categories) => Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCategoryChip(
                          'All',
                          null,
                          '🏪',
                          _selectedCategoryId == null,
                        );
                      }
                      final category = categories[index - 1];
                      return _buildCategoryChip(
                        category.name,
                        category.id,
                        category.icon,
                        _selectedCategoryId == category.id,
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Menu Items Grid
              Expanded(child: _buildMenuItemsGrid()),
            ],
          ),
        ),

        // Right Side - Billing Summary
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Bill Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Current Bill',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Billing Items List
              Expanded(
                child: billingItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No items added',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select items from the menu',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: billingItems.length,
                        itemBuilder: (context, index) {
                          return _buildBillingItemCard(billingItems[index]);
                        },
                      ),
              ),

              // Notes Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Add notes (optional)',
                    prefixIcon: const Icon(Icons.note, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 1,
                ),
              ),

              // Total and Checkout Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total (${billingItems.length} items)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(totalAmount),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: billingItems.isEmpty || _isProcessing
                                ? null
                                : _quickSell,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.flash_on),
                            label: const Text(
                              'Quick Sell',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: billingItems.isEmpty || _isProcessing
                                ? null
                                : _generateBill,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.receipt_long),
                            label: const Text(
                              'Generate Bill',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
      ],
    );
  }

  // Mobile Layout (Full Screen Menu)
  Widget _buildMobileLayout() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      children: [
        // Category Tabs
        categoriesAsync.when(
          data: (categories) => Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(
                    'All',
                    null,
                    '🏪',
                    _selectedCategoryId == null,
                  );
                }
                final category = categories[index - 1];
                return _buildCategoryChip(
                  category.name,
                  category.id,
                  category.icon,
                  _selectedCategoryId == category.id,
                );
              },
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Menu Items Grid (2 columns for mobile)
        Expanded(child: _buildMobileMenuGrid()),
      ],
    );
  }

  Widget _buildMobileMenuGrid() {
    final menuItemsAsync = _selectedCategoryId == null
        ? ref.watch(menuItemsProvider)
        : ref.watch(menuItemsByCategoryIdProvider(_selectedCategoryId!));

    return menuItemsAsync.when(
      data: (menuItems) {
        final filteredItems = menuItems.where((item) {
          if (_searchQuery.isEmpty) return true;
          return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              'No items found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns for mobile
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            return _buildMenuItemCard(filteredItems[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  // Mobile Bill Sheet (Bottom Sheet)
  void _showMobileBillSheet() {
    final billingItems = ref.read(billingProvider);
    final totalAmount = ref.read(billingTotalProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Bill Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Current Bill',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      _showClearDialog();
                    },
                  ),
                ],
              ),
            ),

            // Billing Items List
            Expanded(
              child: billingItems.isEmpty
                  ? const Center(child: Text('No items added'))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: billingItems.length,
                      itemBuilder: (context, index) {
                        return _buildBillingItemCard(billingItems[index]);
                      },
                    ),
            ),

            // Notes Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Add notes (optional)',
                  prefixIcon: const Icon(Icons.note, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: 1,
              ),
            ),

            // Total and Generate Bill
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total (${billingItems.length} items)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(totalAmount),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: billingItems.isEmpty || _isProcessing
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    _quickSell();
                                  },
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.flash_on),
                            label: const Text(
                              'Quick Sell',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: billingItems.isEmpty || _isProcessing
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    _generateBill();
                                  },
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.receipt_long),
                            label: const Text(
                              'Generate Bill',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String name,
    String? categoryId,
    String icon,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon.isNotEmpty) ...[
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
            ],
            Text(name),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = selected ? categoryId : null;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildMenuItemsGrid() {
    final menuItemsAsync = _selectedCategoryId == null
        ? ref.watch(menuItemsProvider)
        : ref.watch(menuItemsByCategoryIdProvider(_selectedCategoryId!));

    return menuItemsAsync.when(
      data: (menuItems) {
        // Filter by search query
        final filteredItems = menuItems.where((item) {
          if (_searchQuery.isEmpty) return true;
          return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              'No items found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            return _buildMenuItemCard(filteredItems[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final categoriesAsync = ref.read(categoriesProvider);
    final categoryName = categoriesAsync.when(
      data: (categories) {
        final category = categories.firstWhere(
          (cat) => cat.id == item.categoryId,
          orElse: () => categories.first,
        );
        return category.name;
      },
      loading: () => 'Unknown',
      error: (_, __) => 'Unknown',
    );

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showSizeSelector(item, categoryName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item icon
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fastfood,
                  size: 36,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 8),
              // Item name
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Price range
              Text(
                item.getAvailableSizes().length > 1
                    ? '${currencyFormatter.format(item.prices[ItemSize.small] ?? 0)} - ${currencyFormatter.format(item.prices[ItemSize.large] ?? 0)}'
                    : currencyFormatter.format(
                        item.getPriceBySize(item.getAvailableSizes().first),
                      ),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSizeSelector(MenuItem item, String categoryName) {
    final availableSizes = item.getAvailableSizes();

    if (availableSizes.length == 1) {
      // Only one size, add directly with quantity 1
      _addItemToBilling(item, categoryName, availableSizes.first, 1);
      return;
    }

    // Multiple sizes, show selector
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        categoryName,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Select Size',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...availableSizes.map((size) {
              final price = item.getPriceBySize(size);
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    size == ItemSize.small
                        ? Icons.local_cafe
                        : size == ItemSize.regular
                        ? Icons.coffee
                        : Icons.local_drink,
                    color: Colors.brown[700],
                  ),
                ),
                title: Text(
                  size.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  currencyFormatter.format(price),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addItemToBilling(item, categoryName, size, 1);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _addItemToBilling(
    MenuItem item,
    String categoryName,
    ItemSize size,
    int quantity,
  ) {
    ref
        .read(billingProvider.notifier)
        .addItem(
          BillingItem(
            menuItem: item,
            categoryName: categoryName,
            size: size,
            quantity: quantity,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Added ${item.name} (${size.displayName})'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildBillingItemCard(BillingItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuItem.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.brown[200]!),
                    ),
                    child: Text(
                      item.size.displayName,
                      style: TextStyle(fontSize: 10, color: Colors.brown[700]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currencyFormatter.format(item.unitPrice)} × ${item.quantity}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(item.subtotal),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, size: 20),
                      onPressed: () {
                        ref
                            .read(billingProvider.notifier)
                            .updateQuantity(item.uniqueKey, item.quantity - 1);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      color: Colors.red,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 20),
                      onPressed: () {
                        ref
                            .read(billingProvider.notifier)
                            .updateQuantity(item.uniqueKey, item.quantity + 1);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Items?'),
        content: const Text(
          'Are you sure you want to remove all items from the billing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(billingProvider.notifier).clearBilling();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateBill() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final billingItems = ref.read(billingProvider);
      final transactionItems = billingItems
          .map((item) => item.toTransactionItem())
          .toList();
      final notes = _notesController.text.trim();

      // Create transaction
      final transactionService = TransactionApiService();
      final transaction = await transactionService.createTransaction(
        userId: userId,
        items: transactionItems,
        notes: notes.isEmpty ? null : notes,
        paymentMethod: 'cash',
        paymentStatus: 'paid',
      );

      // Generate invoice
      final invoice = await transactionService.generateInvoice(
        transactionId: transaction.id,
        userId: userId,
      );

      // Clear billing
      ref.read(billingProvider.notifier).clearBilling();
      _notesController.clear();

      // Refresh sales provider to show new sale in Sales page
      ref.invalidate(salesProvider);

      setState(() => _isProcessing = false);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Bill Generated! Invoice: ${invoice.invoiceNumber}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Show invoice dialog
        showDialog(
          context: context,
          builder: (context) => TransactionInvoiceDialog(invoice: invoice),
        );
      }
    } catch (error) {
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to generate bill: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _quickSell() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final billingItems = ref.read(billingProvider);
      final transactionItems = billingItems
          .map((item) => item.toTransactionItem())
          .toList();
      final notes = _notesController.text.trim();

      // Calculate total
      final totalAmount = billingItems.fold<double>(
        0,
        (sum, item) => sum + (item.unitPrice * item.quantity),
      );

      // Create transaction without invoice
      final transactionService = TransactionApiService();
      await transactionService.createTransaction(
        userId: userId,
        items: transactionItems,
        notes: notes.isEmpty ? null : notes,
        paymentMethod: 'cash',
        paymentStatus: 'paid',
      );

      // Clear billing
      ref.read(billingProvider.notifier).clearBilling();
      _notesController.clear();

      // Refresh sales provider to show new sale in Sales page
      ref.invalidate(salesProvider);

      setState(() => _isProcessing = false);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Sale Completed! Total: ${AppConfig.currencySymbol}${totalAmount.toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to complete sale: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
