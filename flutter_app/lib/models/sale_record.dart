import 'package:json_annotation/json_annotation.dart';
import 'menu_item.dart';

part 'sale_record.g.dart';

// Sale Item for multi-item sales
@JsonSerializable()
class SaleItem {
  final String menuItemId;
  final String itemName;
  final String categoryId;
  final String categoryName;
  final ItemSize size;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const SaleItem({
    required this.menuItemId,
    required this.itemName,
    required this.categoryId,
    required this.categoryName,
    required this.size,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) =>
      _$SaleItemFromJson(json);
  Map<String, dynamic> toJson() => _$SaleItemToJson(this);
}

@JsonSerializable()
class SaleRecord {
  @JsonKey(name: '_id')
  final String id;

  // Single-item fields (for backward compatibility and quick sales)
  final String? menuItemId;
  final String? itemName;
  final String? categoryId; // Reference to Category._id (New Dynamic System)
  final String? categoryName; // Category name for faster querying
  final MenuCategory? category; // Legacy field for backwards compatibility
  final ItemSize? size;
  final double? unitPrice;
  final int? quantity;

  // Multi-item fields
  final List<SaleItem>? items;
  final String saleType; // 'single' or 'multi'

  // Shared fields
  final double totalAmount;
  final double? taxAmount;
  final double grandTotal;
  final DateTime timestamp;
  final String? notes;
  final String? userId; // Backend userId field
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Invoice fields
  final String? invoiceNumber;
  final bool? invoiceGenerated;
  final DateTime? invoiceGeneratedAt;

  // Payment fields
  final String? paymentMethod;
  final String? paymentStatus;

  const SaleRecord({
    required this.id,
    this.menuItemId,
    this.itemName,
    this.categoryId,
    this.categoryName,
    this.category,
    this.size,
    this.unitPrice,
    this.quantity,
    this.items,
    this.saleType = 'single',
    required this.totalAmount,
    this.taxAmount,
    required this.grandTotal,
    required this.timestamp,
    this.notes,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.invoiceNumber,
    this.invoiceGenerated,
    this.invoiceGeneratedAt,
    this.paymentMethod,
    this.paymentStatus,
  });

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    // Handle the backend response format
    Map<String, dynamic> processedJson = Map<String, dynamic>.from(json);

    // Convert MongoDB _id to id
    if (processedJson.containsKey('_id') && processedJson['_id'] is Map) {
      processedJson['_id'] = processedJson['_id']['\$oid'];
    }

    // Convert menuItemId ObjectId to string
    if (processedJson.containsKey('menuItemId') &&
        processedJson['menuItemId'] is Map) {
      processedJson['menuItemId'] = processedJson['menuItemId']['\$oid'];
    }

    // Convert categoryId ObjectId to string
    if (processedJson.containsKey('categoryId') &&
        processedJson['categoryId'] is Map) {
      processedJson['categoryId'] = processedJson['categoryId']['\$oid'];
    }

    // Convert userId ObjectId to string
    if (processedJson.containsKey('userId') && processedJson['userId'] is Map) {
      processedJson['userId'] = processedJson['userId']['\$oid'];
    }

    // Convert date strings to DateTime
    if (processedJson.containsKey('timestamp')) {
      if (processedJson['timestamp'] is Map &&
          processedJson['timestamp'].containsKey('\$date')) {
        processedJson['timestamp'] = processedJson['timestamp']['\$date'];
      }
    }

    if (processedJson.containsKey('createdAt')) {
      if (processedJson['createdAt'] is Map &&
          processedJson['createdAt'].containsKey('\$date')) {
        processedJson['createdAt'] = processedJson['createdAt']['\$date'];
      }
    }

    if (processedJson.containsKey('updatedAt')) {
      if (processedJson['updatedAt'] is Map &&
          processedJson['updatedAt'].containsKey('\$date')) {
        processedJson['updatedAt'] = processedJson['updatedAt']['\$date'];
      }
    }

    // Handle missing fields for backward compatibility
    // Set default taxAmount if missing
    if (!processedJson.containsKey('taxAmount') ||
        processedJson['taxAmount'] == null) {
      processedJson['taxAmount'] = 0.0;
    }

    // Calculate grandTotal if missing (for old records)
    if (!processedJson.containsKey('grandTotal') ||
        processedJson['grandTotal'] == null) {
      final totalAmount = processedJson['totalAmount'] ?? 0.0;
      final taxAmount = processedJson['taxAmount'] ?? 0.0;
      processedJson['grandTotal'] = totalAmount + taxAmount;
    }

    // Set default saleType if missing
    if (!processedJson.containsKey('saleType') ||
        processedJson['saleType'] == null) {
      // Determine saleType based on presence of items array
      if (processedJson.containsKey('items') &&
          processedJson['items'] is List &&
          (processedJson['items'] as List).isNotEmpty) {
        processedJson['saleType'] = 'multi';
      } else {
        processedJson['saleType'] = 'single';
      }
    }

    return _$SaleRecordFromJson(processedJson);
  }

  Map<String, dynamic> toJson() => _$SaleRecordToJson(this);

  // Factory constructor to create a single-item sale record from menu item for API submission
  factory SaleRecord.fromMenuItem({
    required String id,
    required MenuItem menuItem,
    required String categoryName, // Must be provided from Category object
    required ItemSize size,
    required int quantity,
    required DateTime timestamp,
    String? notes,
    String? userId,
  }) {
    final unitPrice = menuItem.getPriceBySize(size);
    final totalAmount = unitPrice * quantity;

    return SaleRecord(
      id: id,
      menuItemId: menuItem.id,
      itemName: menuItem.name,
      categoryId: menuItem.categoryId,
      categoryName: categoryName,
      size: size,
      unitPrice: unitPrice,
      quantity: quantity,
      saleType: 'single',
      totalAmount: totalAmount,
      grandTotal: totalAmount,
      timestamp: timestamp,
      notes: notes,
      userId: userId,
    );
  }

  // Factory constructor to create a multi-item sale record
  factory SaleRecord.fromItems({
    required String id,
    required List<SaleItem> items,
    required String userId,
    required DateTime timestamp,
    String? notes,
    double taxAmount = 0,
    String paymentMethod = 'cash',
    String paymentStatus = 'paid',
  }) {
    final totalAmount = items.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final grandTotal = totalAmount + taxAmount;

    return SaleRecord(
      id: id,
      items: items,
      saleType: 'multi',
      totalAmount: totalAmount,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      timestamp: timestamp,
      notes: notes,
      userId: userId,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
    );
  }

  // Helper to check if this is a multi-item sale
  bool get isMultiItem =>
      saleType == 'multi' && items != null && items!.isNotEmpty;

  // Helper to check if this is a single-item sale
  bool get isSingleItem => saleType == 'single' && menuItemId != null;

  // Helper methods for date filtering
  bool isToday() {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  bool isThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return timestamp.isAfter(weekStart.subtract(const Duration(days: 1)));
  }

  bool isThisMonth() {
    final now = DateTime.now();
    return timestamp.year == now.year && timestamp.month == now.month;
  }

  bool isThisYear() {
    final now = DateTime.now();
    return timestamp.year == now.year;
  }
}
