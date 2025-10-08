import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../providers/category_provider.dart';
import '../providers/sales_provider.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/sell_dialog.dart';
import '../widgets/menu_item_form_dialog.dart';
import '../widgets/category_form_dialog.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _selectedCategoryId;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final todaysRevenue = ref.watch(todaysRevenueProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider);
    final isLoading = ref.watch(isMenuItemsLoadingProvider);
    final error = ref.watch(menuItemsErrorProvider);

    return categoriesAsync.when(
      data: (categories) {
        // Filter categories based on search query
        final filteredCategories = categories.where((category) {
          if (_searchQuery.isEmpty) return true;
          return category.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Menu'),
            centerTitle: true,
            actions: [
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: isLoading
                    ? null
                    : () {
                        ref.read(menuItemsProvider.notifier).refresh();
                        ref.read(categoriesProvider.notifier).refresh();
                      },
              ),
            ],
          ),
          body: Column(
            children: [
              // Today's Revenue Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

              // Category Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Category Grid/List
              if (_selectedCategoryId == null)
                Expanded(
                  child: filteredCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No categories found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = category.id;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      category.icon,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        category.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                )
              // Loading indicator
              else if (isLoading && !menuItemsAsync.hasValue)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading menu items...'),
                      ],
                    ),
                  ),
                )
              // Error state
              else if (error != null && !menuItemsAsync.hasValue)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load menu items',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(menuItemsProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              // Selected Category Header with Back Button
              else if (_selectedCategoryId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        },
                        tooltip: 'Back to categories',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categories
                            .firstWhere(
                              (cat) => cat.id == _selectedCategoryId,
                              orElse: () => categories.first,
                            )
                            .icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          categories
                              .firstWhere(
                                (cat) => cat.id == _selectedCategoryId,
                                orElse: () => categories.first,
                              )
                              .name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _buildCategoryView(
                        categories.firstWhere(
                          (cat) => cat.id == _selectedCategoryId,
                          orElse: () => categories.first,
                        ),
                      ),
                      // Loading overlay when refreshing
                      if (isLoading && menuItemsAsync.hasValue)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            child: const LinearProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else
                const Expanded(
                  child: Center(child: Text('No category selected')),
                ),
            ],
          ),
          floatingActionButton: _selectedCategoryId != null
              ? FloatingActionButton.extended(
                  onPressed: () => _showCreateDialog(_selectedCategoryId),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  tooltip: 'Add new menu item',
                )
              : FloatingActionButton.extended(
                  onPressed: _showCreateCategoryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New Category'),
                  tooltip: 'Create new category',
                  backgroundColor: Colors.green,
                ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Menu'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Menu'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to load categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(categoriesProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryView(category) {
    final categoryItemsAsync = ref.watch(
      menuItemsByCategoryIdProvider(category.id),
    );

    return categoryItemsAsync.when(
      data: (categoryItems) {
        if (categoryItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(category.icon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No items in ${category.name}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(category.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Item'),
                ),
              ],
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading ${category.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(menuItemsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSellDialog(MenuItem menuItem) {
    showDialog(
      context: context,
      builder: (context) => SellDialog(
        menuItem: menuItem,
        onSell: (size, quantity, notes) async {
          try {
            // Find the category name from categories provider
            final categoriesAsync = ref.read(categoriesProvider);
            final categoryName = categoriesAsync.when(
              data: (categories) {
                final category = categories.firstWhere(
                  (cat) => cat.id == menuItem.categoryId,
                  orElse: () => categories.first,
                );
                return category.name;
              },
              loading: () => 'Unknown',
              error: (_, __) => 'Unknown',
            );

            await ref
                .read(salesProvider.notifier)
                .addSale(
                  menuItem: menuItem,
                  categoryName: categoryName,
                  size: size,
                  quantity: quantity,
                  notes: notes,
                );

            // Show success snackbar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Sold ${quantity}x ${menuItem.name} (${size.displayName}) - ₹${(menuItem.getPriceBySize(size) * quantity).toInt()}',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (error) {
            // Show error snackbar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Failed to record sale: ${error.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showCreateDialog(String? initialCategoryId) {
    showDialog(
      context: context,
      builder: (context) => MenuItemFormDialog(
        dialogTitle: 'Create New Menu Item',
        initialCategoryId: initialCategoryId,
      ),
    );
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          const CategoryFormDialog(dialogTitle: 'Create New Category'),
    );
  }
}
