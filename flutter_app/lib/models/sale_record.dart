import 'package:json_annotation/json_annotation.dart';
import 'menu_item.dart';

part 'sale_record.g.dart';

@JsonSerializable()
class SaleRecord {
  final String id;
  final String menuItemId;
  final String itemName;
  final MenuCategory category;
  final ItemSize size;
  final double unitPrice;
  final int quantity;
  final double totalAmount;
  final DateTime timestamp;
  final String? notes;

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
  });

  factory SaleRecord.fromJson(Map<String, dynamic> json) =>
      _$SaleRecordFromJson(json);
  Map<String, dynamic> toJson() => _$SaleRecordToJson(this);

  // Factory constructor to create a sale record from menu item
  factory SaleRecord.fromMenuItem({
    required String id,
    required MenuItem menuItem,
    required ItemSize size,
    required int quantity,
    required DateTime timestamp,
    String? notes,
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
