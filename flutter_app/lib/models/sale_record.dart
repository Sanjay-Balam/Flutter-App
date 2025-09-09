import 'package:json_annotation/json_annotation.dart';
import 'menu_item.dart';

part 'sale_record.g.dart';

@JsonSerializable()
class SaleRecord {
  @JsonKey(name: '_id')
  final String id;
  final String menuItemId;
  final String itemName;
  final String category;
  final String size;
  final double unitPrice;
  final int quantity;
  final double totalAmount;
  final DateTime timestamp;
  final String? notes;
  final String? userId; // Backend userId field
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SaleRecord({
    required this.id,
    required this.menuItemId,
    required this.itemName,
    required this.category,
    required this.size,
    required this.unitPrice,
    required this.quantity,
    required this.totalAmount,
    required this.timestamp,
    this.notes,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    // Handle the backend response format
    Map<String, dynamic> processedJson = Map<String, dynamic>.from(json);

    // Convert MongoDB _id to id - handle both string and object format
    if (processedJson.containsKey('_id')) {
      if (processedJson['_id'] is Map && processedJson['_id'].containsKey('\$oid')) {
        processedJson['_id'] = processedJson['_id']['\$oid'];
      }
      // If _id is already a string, leave it as is
    }

    // Convert menuItemId ObjectId to string - handle both formats
    if (processedJson.containsKey('menuItemId')) {
      if (processedJson['menuItemId'] is Map && processedJson['menuItemId'].containsKey('\$oid')) {
        processedJson['menuItemId'] = processedJson['menuItemId']['\$oid'];
      }
      // If menuItemId is already a string, leave it as is
    }

    // Convert userId ObjectId to string - handle both formats  
    if (processedJson.containsKey('userId')) {
      if (processedJson['userId'] is Map && processedJson['userId'].containsKey('\$oid')) {
        processedJson['userId'] = processedJson['userId']['\$oid'];
      }
      // If userId is already a string, leave it as is
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

    return _$SaleRecordFromJson(processedJson);
  }

  Map<String, dynamic> toJson() => _$SaleRecordToJson(this);

  // Factory constructor to create a sale record from menu item for API submission
  factory SaleRecord.fromMenuItem({
    required String id,
    required MenuItem menuItem,
    required String size,
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
      category: menuItem.category,
      size: size,
      unitPrice: unitPrice,
      quantity: quantity,
      totalAmount: totalAmount,
      timestamp: timestamp,
      notes: notes,
      userId: userId,
    );
  }

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
