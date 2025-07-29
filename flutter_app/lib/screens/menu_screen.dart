import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../providers/sales_provider.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/sell_dialog.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final categories = MenuCategory.values;
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(menuCategoriesProvider);
    final todaysRevenue = ref.watch(todaysRevenueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: categories.map((category) {
            return Tab(
              text: category.displayName,
              icon: Text(category.icon, style: const TextStyle(fontSize: 20)),
            );
          }).toList(),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Column(
        children: [
          // Today's Revenue Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Today\'s Revenue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(todaysRevenue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Menu Items Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories.map((category) {
                return _buildCategoryView(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryView(MenuCategory category) {
    final categoryItems = ref.watch(menuItemsByCategoryProvider(category));

    if (categoryItems.isEmpty) {
      return const Center(
        child: Text(
          'No items available in this category',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categoryItems.length,
      itemBuilder: (context, index) {
        final item = categoryItems[index];
        return MenuItemCard(
          menuItem: item,
          onSell: () => _showSellDialog(item),
        );
      },
    );
  }

  void _showSellDialog(MenuItem menuItem) {
    showDialog(
      context: context,
      builder: (context) => SellDialog(
        menuItem: menuItem,
        onSell: (size, quantity, notes) {
          ref
              .read(salesRepositoryProvider.notifier)
              .addSale(
                menuItem: menuItem,
                size: size,
                quantity: quantity,
                notes: notes,
              );

          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sold ${quantity}x ${menuItem.name} (${size.displayName})',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
