import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import 'user_provider.dart';

// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Menu items state notifier for efficient state management
class MenuItemsNotifier extends AsyncNotifier<List<MenuItem>> {
  ApiService get _apiService => ref.read(apiServiceProvider);

  @override
  Future<List<MenuItem>> build() async {
    // Get current user ID
    final userId = ref.watch(requireUserIdProvider);

    // Fetch menu items from API
    return await _apiService.getMenuItemsByUserId(userId);
  }

  // Refresh menu items
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(requireUserIdProvider);
      final menuItems = await _apiService.getMenuItemsByUserId(userId);
      state = AsyncValue.data(menuItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add a new menu item
  Future<void> addMenuItem(MenuItem menuItem) async {
    try {
      final newItem = await _apiService.createMenuItem(menuItem);

      // Update state optimistically
      state.whenData((currentItems) {
        state = AsyncValue.data([...currentItems, newItem]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update an existing menu item
  Future<void> updateMenuItem(String itemId, MenuItem updatedItem) async {
    try {
      final updatedMenuItem = await _apiService.updateMenuItem(
        itemId,
        updatedItem,
      );

      // Update state optimistically
      state.whenData((currentItems) {
        final updatedItems = currentItems.map((item) {
          return item.id == itemId ? updatedMenuItem : item;
        }).toList();
        state = AsyncValue.data(updatedItems);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Delete a menu item
  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _apiService.deleteMenuItem(itemId);

      // Update state optimistically
      state.whenData((currentItems) {
        final updatedItems = currentItems
            .where((item) => item.id != itemId)
            .toList();
        state = AsyncValue.data(updatedItems);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Main menu items provider (async)
final menuItemsProvider =
    AsyncNotifierProvider<MenuItemsNotifier, List<MenuItem>>(() {
      return MenuItemsNotifier();
    });

// Menu items by category provider (computed from main provider)
final menuItemsByCategoryProvider =
    Provider.family<AsyncValue<List<MenuItem>>, MenuCategory>((ref, category) {
      final menuItemsAsync = ref.watch(menuItemsProvider);
      return menuItemsAsync.when(
        data: (items) => AsyncValue.data(
          items.where((item) => item.category == category).toList(),
        ),
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });

// Available menu items provider (filtered by availability)
final availableMenuItemsProvider = Provider<AsyncValue<List<MenuItem>>>((ref) {
  final menuItemsAsync = ref.watch(menuItemsProvider);
  return menuItemsAsync.when(
    data: (items) =>
        AsyncValue.data(items.where((item) => item.isAvailable).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Single menu item provider
final menuItemProvider = Provider.family<AsyncValue<MenuItem?>, String>((
  ref,
  itemId,
) {
  final menuItemsAsync = ref.watch(menuItemsProvider);
  return menuItemsAsync.when(
    data: (items) {
      try {
        final item = items.firstWhere((item) => item.id == itemId);
        return AsyncValue.data(item);
      } catch (e) {
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// All categories provider
final menuCategoriesProvider = Provider<List<MenuCategory>>((ref) {
  return MenuCategory.values;
});

// Menu items count by category
final menuItemsCountByCategoryProvider =
    Provider.family<AsyncValue<int>, MenuCategory>((ref, category) {
      final categoryItemsAsync = ref.watch(
        menuItemsByCategoryProvider(category),
      );
      return categoryItemsAsync.when(
        data: (items) => AsyncValue.data(items.length),
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });

// Total menu items count
final totalMenuItemsCountProvider = Provider<AsyncValue<int>>((ref) {
  final menuItemsAsync = ref.watch(menuItemsProvider);
  return menuItemsAsync.when(
    data: (items) => AsyncValue.data(items.length),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Menu items loading state
final isMenuItemsLoadingProvider = Provider<bool>((ref) {
  final menuItemsAsync = ref.watch(menuItemsProvider);
  return menuItemsAsync.isLoading;
});

// Menu items error state
final menuItemsErrorProvider = Provider<String?>((ref) {
  final menuItemsAsync = ref.watch(menuItemsProvider);
  return menuItemsAsync.error?.toString();
});
