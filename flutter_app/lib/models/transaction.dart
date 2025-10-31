import 'package:json_annotation/json_annotation.dart';
import 'menu_item.dart';

part 'transaction.g.dart';

@JsonSerializable()
class TransactionItem {
  final String menuItemId;
  final String itemName;
  final String categoryId;
  final String categoryName;
  final ItemSize size;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const TransactionItem({
    required this.menuItemId,
    required this.itemName,
    required this.categoryId,
    required this.categoryName,
    required this.size,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      _$TransactionItemFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionItemToJson(this);

  // Helper to create from MenuItem
  factory TransactionItem.fromMenuItem({
    required MenuItem menuItem,
    required String categoryName,
    required ItemSize size,
    required int quantity,
  }) {
    final unitPrice = menuItem.getPriceBySize(size);
    final subtotal = unitPrice * quantity;

    return TransactionItem(
      menuItemId: menuItem.id,
      itemName: menuItem.name,
      categoryId: menuItem.categoryId,
      categoryName: categoryName,
      size: size,
      unitPrice: unitPrice,
      quantity: quantity,
      subtotal: subtotal,
    );
  }
}

@JsonSerializable()
class Transaction {
  @JsonKey(name: '_id')
  final String id;
  final String userId;
  final List<TransactionItem> items;
  final double totalAmount;

  @JsonKey(defaultValue: 0.0)
  final double taxAmount;

  final double grandTotal;
  final DateTime timestamp;
  final String? notes;

  // Invoice fields
  final String? invoiceNumber;

  @JsonKey(defaultValue: false)
  final bool invoiceGenerated;

  final DateTime? invoiceGeneratedAt;

  // Payment fields
  final String? paymentMethod;
  final String? paymentStatus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    this.taxAmount = 0.0,
    required this.grandTotal,
    required this.timestamp,
    this.notes,
    this.invoiceNumber,
    this.invoiceGenerated = false,
    this.invoiceGeneratedAt,
    this.paymentMethod,
    this.paymentStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Handle the backend response format
    Map<String, dynamic> processedJson = Map<String, dynamic>.from(json);

    // Convert MongoDB _id to id
    if (processedJson.containsKey('_id') && processedJson['_id'] is Map) {
      processedJson['_id'] = processedJson['_id']['\$oid'];
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

    if (processedJson.containsKey('invoiceGeneratedAt')) {
      if (processedJson['invoiceGeneratedAt'] is Map &&
          processedJson['invoiceGeneratedAt'].containsKey('\$date')) {
        processedJson['invoiceGeneratedAt'] =
            processedJson['invoiceGeneratedAt']['\$date'];
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

    return _$TransactionFromJson(processedJson);
  }

  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  // Helper methods
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  int get uniqueItems => items.length;

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
}
