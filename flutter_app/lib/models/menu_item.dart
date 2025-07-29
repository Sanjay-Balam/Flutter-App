import 'package:json_annotation/json_annotation.dart';

part 'menu_item.g.dart';

enum MenuCategory { milkCakes, cheeseCakes, chocolateBrownie }

enum ItemSize { small, large, regular }

@JsonSerializable()
class MenuItem {
  final String id;
  final String name;
  final MenuCategory category;
  final Map<ItemSize, double> prices; // Size -> Price mapping
  final String? description;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.prices,
    this.description,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);
  Map<String, dynamic> toJson() => _$MenuItemToJson(this);

  // Helper method to get price by size
  double getPriceBySize(ItemSize size) {
    return prices[size] ?? prices.values.first;
  }

  // Helper method to get available sizes
  List<ItemSize> getAvailableSizes() {
    return prices.keys.toList();
  }

  // Helper method to check if item has multiple sizes
  bool hasMultipleSizes() {
    return prices.length > 1;
  }
}

// Extension to convert enum to display string
extension MenuCategoryExtension on MenuCategory {
  String get displayName {
    switch (this) {
      case MenuCategory.milkCakes:
        return 'Milk Cakes';
      case MenuCategory.cheeseCakes:
        return 'Cheese Cakes';
      case MenuCategory.chocolateBrownie:
        return 'Chocolate Brownie';
    }
  }

  String get icon {
    switch (this) {
      case MenuCategory.milkCakes:
        return '🥛';
      case MenuCategory.cheeseCakes:
        return '🧀';
      case MenuCategory.chocolateBrownie:
        return '🍫';
    }
  }
}

extension ItemSizeExtension on ItemSize {
  String get displayName {
    switch (this) {
      case ItemSize.small:
        return 'Small';
      case ItemSize.large:
        return 'Large';
      case ItemSize.regular:
        return 'Regular';
    }
  }
}
