import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../data/menu_data.dart';

// Menu items provider - provides all menu items
final menuItemsProvider = Provider<List<MenuItem>>((ref) {
  return MenuData.menuItems;
});

// Menu items by category provider
final menuItemsByCategoryProvider =
    Provider.family<List<MenuItem>, MenuCategory>((ref, category) {
      final allItems = ref.watch(menuItemsProvider);
      return allItems.where((item) => item.category == category).toList();
    });

// All categories provider
final menuCategoriesProvider = Provider<List<MenuCategory>>((ref) {
  return MenuCategory.values;
});

// Single menu item provider
final menuItemProvider = Provider.family<MenuItem?, String>((ref, itemId) {
  final allItems = ref.watch(menuItemsProvider);
  try {
    return allItems.firstWhere((item) => item.id == itemId);
  } catch (e) {
    return null;
  }
});

// Available menu items (filtered by availability)
final availableMenuItemsProvider = Provider<List<MenuItem>>((ref) {
  final allItems = ref.watch(menuItemsProvider);
  return allItems.where((item) => item.isAvailable).toList();
});

// Menu items count by category
final menuItemsCountByCategoryProvider = Provider.family<int, MenuCategory>((
  ref,
  category,
) {
  final categoryItems = ref.watch(menuItemsByCategoryProvider(category));
  return categoryItems.length;
});
