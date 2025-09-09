import 'package:json_annotation/json_annotation.dart';

part 'menu_item.g.dart';

enum ItemSize { small, large, regular }

@JsonSerializable()
class MenuItem {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String category; // Dynamic category name
  final Map<String, double> prices; // Flexible size -> price mapping
  final String? description;
  final bool isAvailable;
  final String? userId; // Backend userId field
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.prices,
    this.description,
    this.isAvailable = true,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // Handle the backend response format
    Map<String, dynamic> processedJson = Map<String, dynamic>.from(json);
    
    // Convert MongoDB _id to id - handle both string and object format
    if (processedJson.containsKey('_id')) {
      if (processedJson['_id'] is Map && processedJson['_id'].containsKey('\$oid')) {
        processedJson['_id'] = processedJson['_id']['\$oid'];
      }
      // If _id is already a string, leave it as is
    }
    
    // Convert userId ObjectId to string - handle both string and object format  
    if (processedJson.containsKey('userId')) {
      if (processedJson['userId'] is Map && processedJson['userId'].containsKey('\$oid')) {
        processedJson['userId'] = processedJson['userId']['\$oid'];
      }
      // If userId is already a string, leave it as is
    }
    
    // Convert date strings to DateTime - handle both string and object format
    if (processedJson.containsKey('createdAt') && processedJson['createdAt'] != null) {
      if (processedJson['createdAt'] is Map && processedJson['createdAt'].containsKey('\$date')) {
        processedJson['createdAt'] = processedJson['createdAt']['\$date'];
      }
      // If createdAt is already a string, leave it as is
    }
    
    if (processedJson.containsKey('updatedAt') && processedJson['updatedAt'] != null) {
      if (processedJson['updatedAt'] is Map && processedJson['updatedAt'].containsKey('\$date')) {
        processedJson['updatedAt'] = processedJson['updatedAt']['\$date'];
      }
      // If updatedAt is already a string, leave it as is
    }
    
    return _$MenuItemFromJson(processedJson);
  }
  
  Map<String, dynamic> toJson() => _$MenuItemToJson(this);

  // Helper method to get price by size
  double getPriceBySize(String size) {
    return prices[size] ?? prices.values.first;
  }

  // Helper method to get available sizes
  List<String> getAvailableSizes() {
    return prices.keys.toList();
  }

  // Helper method to check if item has multiple sizes
  bool hasMultipleSizes() {
    return prices.length > 1;
  }
}

// Utility class for category management
class CategoryUtils {
  static const Map<String, String> categoryIcons = {
    'Milk Cakes': '🥛',
    'Cheese Cakes': '🧀', 
    'Chocolate Brownie': '🍫',
    'Pizza': '🍕',
    'Burgers': '🍔',
    'Beverages': '🥤',
    'Desserts': '🍰',
    'Snacks': '🍿',
  };

  static String getCategoryIcon(String category) {
    return categoryIcons[category] ?? '🍽️';
  }

  static const Map<String, List<String>> categorySizePresets = {
    'Milk Cakes': ['Regular'],
    'Cheese Cakes': ['Small', 'Large'], 
    'Chocolate Brownie': ['Regular'],
    'Pizza': ['Small', 'Medium', 'Large'],
    'Burgers': ['Regular', 'Large'],
    'Beverages': ['Small', 'Medium', 'Large'],
  };

  static List<String> getSizePresets(String category) {
    return categorySizePresets[category] ?? ['Regular'];
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
