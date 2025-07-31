import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../providers/user_provider.dart';

/// Example widget demonstrating how to use the API-based menu providers
class MenuItemsListWidget extends ConsumerWidget {
  const MenuItemsListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the async menu items provider
    final menuItemsAsync = ref.watch(menuItemsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with refresh button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu Items',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      ref.read(menuItemsProvider.notifier).refresh(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // User ID display
            Text(
              'User ID: ${currentUserId ?? 'Not set'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Menu items content
            Expanded(
              child: menuItemsAsync.when(
                // Loading state
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Fetching menu items from API...'),
                    ],
                  ),
                ),

                // Error state
                error: (error, stackTrace) => Center(
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
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

                // Success state with data
                data: (menuItems) {
                  if (menuItems.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('No menu items found'),
                          Text(
                            'Add some menu items to get started',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group items by category for display
                  final groupedItems = <MenuCategory, List<MenuItem>>{};
                  for (final item in menuItems) {
                    groupedItems.putIfAbsent(item.category, () => []).add(item);
                  }

                  return ListView(
                    children: groupedItems.entries.map((entry) {
                      final category = entry.key;
                      final items = entry.value;

                      return ExpansionTile(
                        title: Text(
                          '${category.displayName} (${items.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        leading: Text(
                          category.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        initiallyExpanded: true,
                        children: items
                            .map((item) => _buildMenuItem(context, item))
                            .toList(),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return ListTile(
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.description != null)
            Text(
              item.description!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          const SizedBox(height: 4),
          // Display prices
          Wrap(
            spacing: 8,
            children: item.prices.entries.map((priceEntry) {
              return Chip(
                label: Text(
                  '${priceEntry.key.displayName}: ₹${priceEntry.value.toInt()}',
                  style: const TextStyle(fontSize: 12),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.isAvailable ? Icons.check_circle : Icons.cancel,
            color: item.isAvailable ? Colors.green : Colors.red,
          ),
          Text(
            item.isAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(
              fontSize: 10,
              color: item.isAvailable ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

/// Widget to demonstrate category-specific menu items
class CategoryMenuItemsWidget extends ConsumerWidget {
  final MenuCategory category;

  const CategoryMenuItemsWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryItemsAsync = ref.watch(menuItemsByCategoryProvider(category));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(category.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  category.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: categoryItemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Error: ${error.toString()}')),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No ${category.displayName.toLowerCase()} available',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: item.description != null
                            ? Text(item.description!)
                            : null,
                        trailing: Text('₹${item.prices.values.first.toInt()}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
