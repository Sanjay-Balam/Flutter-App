import '../models/menu_item.dart';

class MenuData {
  static const List<MenuItem> menuItems = [
    // Milk Cakes - All 99/-
    MenuItem(
      id: 'milk_malai',
      name: 'Milk Malai',
      category: MenuCategory.milkCakes,
      prices: {ItemSize.regular: 99.0},
      description: 'Creamy milk-based cake with malai flavor',
    ),
    MenuItem(
      id: 'oreo_milk',
      name: 'Oreo',
      category: MenuCategory.milkCakes,
      prices: {ItemSize.regular: 99.0},
      description: 'Milk cake with Oreo cookie flavor',
    ),
    MenuItem(
      id: 'biscoff_milk',
      name: 'Biscoff',
      category: MenuCategory.milkCakes,
      prices: {ItemSize.regular: 99.0},
      description: 'Milk cake with Biscoff cookie flavor',
    ),
    MenuItem(
      id: 'dairy_milk',
      name: 'Dairy Milk',
      category: MenuCategory.milkCakes,
      prices: {ItemSize.regular: 99.0},
      description: 'Chocolate milk cake with Dairy Milk flavor',
    ),
    MenuItem(
      id: 'ras_malai',
      name: 'Ras Malai',
      category: MenuCategory.milkCakes,
      prices: {ItemSize.regular: 99.0},
      description: 'Traditional Ras Malai flavored milk cake',
    ),

    // Cheese Cakes - Small 79/-, Large 139/-
    MenuItem(
      id: 'lotus_biscoff_cheese',
      name: 'Lotus Biscoff',
      category: MenuCategory.cheeseCakes,
      prices: {ItemSize.small: 79.0, ItemSize.large: 139.0},
      description: 'Rich cheesecake with Lotus Biscoff flavor',
    ),
    MenuItem(
      id: 'oreo_cheese',
      name: 'Oreo',
      category: MenuCategory.cheeseCakes,
      prices: {ItemSize.small: 79.0, ItemSize.large: 139.0},
      description: 'Cheesecake with crushed Oreo cookies',
    ),
    MenuItem(
      id: 'blueberry_cheese',
      name: 'Blueberry',
      category: MenuCategory.cheeseCakes,
      prices: {ItemSize.small: 79.0, ItemSize.large: 139.0},
      description: 'Fresh blueberry cheesecake',
    ),

    // Chocolate Brownie - 149/-
    MenuItem(
      id: 'chocolate_brownie',
      name: 'Chocolate Brownie',
      category: MenuCategory.chocolateBrownie,
      prices: {ItemSize.regular: 149.0},
      description:
          'Rich and fudgy chocolate goodness topped with a scoop of vanilla ice cream. The perfect dessert for chocolate lovers.',
    ),
  ];

  // Helper methods to get items by category
  static List<MenuItem> getItemsByCategory(MenuCategory category) {
    return menuItems.where((item) => item.category == category).toList();
  }

  static List<MenuCategory> getAllCategories() {
    return MenuCategory.values;
  }

  static MenuItem? getItemById(String id) {
    try {
      return menuItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
