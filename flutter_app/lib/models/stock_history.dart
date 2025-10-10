import 'package:json_annotation/json_annotation.dart';

part 'stock_history.g.dart';

enum StockMovementType {
  @JsonValue('INITIAL')
  initial,
  @JsonValue('RESTOCK')
  restock,
  @JsonValue('SALE')
  sale,
  @JsonValue('ADJUSTMENT')
  adjustment,
  @JsonValue('RETURN')
  returnItem,
  @JsonValue('DAMAGE')
  damage,
  @JsonValue('TRANSFER')
  transfer,
}

@JsonSerializable()
class StockHistory {
  @JsonKey(name: '_id')
  final String id;
  final String menuItemId;
  final String userId;
  final StockMovementType movementType;
  final int quantityChange;
  final int previousQuantity;
  final int newQuantity;
  final String? reason;
  final String? saleId;
  final String? performedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockHistory({
    required this.id,
    required this.menuItemId,
    required this.userId,
    required this.movementType,
    required this.quantityChange,
    required this.previousQuantity,
    required this.newQuantity,
    this.reason,
    this.saleId,
    this.performedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory StockHistory.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB ObjectId conversions
    Map<String, dynamic> processedJson = Map<String, dynamic>.from(json);

    // Convert _id
    if (processedJson.containsKey('_id') && processedJson['_id'] is Map) {
      processedJson['_id'] = processedJson['_id']['\$oid'];
    }

    // Convert menuItemId
    if (processedJson.containsKey('menuItemId') &&
        processedJson['menuItemId'] is Map) {
      processedJson['menuItemId'] = processedJson['menuItemId']['\$oid'];
    }

    // Convert userId
    if (processedJson.containsKey('userId') && processedJson['userId'] is Map) {
      processedJson['userId'] = processedJson['userId']['\$oid'];
    }

    // Convert saleId
    if (processedJson.containsKey('saleId') && processedJson['saleId'] is Map) {
      processedJson['saleId'] = processedJson['saleId']['\$oid'];
    }

    // Convert performedBy
    if (processedJson.containsKey('performedBy') &&
        processedJson['performedBy'] is Map) {
      processedJson['performedBy'] = processedJson['performedBy']['\$oid'];
    }

    // Convert dates
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

    return _$StockHistoryFromJson(processedJson);
  }

  Map<String, dynamic> toJson() => _$StockHistoryToJson(this);
}

// Extension for display strings
extension StockMovementTypeExtension on StockMovementType {
  String get displayName {
    switch (this) {
      case StockMovementType.initial:
        return 'Initial Stock';
      case StockMovementType.restock:
        return 'Restocked';
      case StockMovementType.sale:
        return 'Sale';
      case StockMovementType.adjustment:
        return 'Adjustment';
      case StockMovementType.returnItem:
        return 'Return';
      case StockMovementType.damage:
        return 'Damage/Expired';
      case StockMovementType.transfer:
        return 'Transfer';
    }
  }

  String get icon {
    switch (this) {
      case StockMovementType.initial:
        return '📦';
      case StockMovementType.restock:
        return '📥';
      case StockMovementType.sale:
        return '💰';
      case StockMovementType.adjustment:
        return '⚙️';
      case StockMovementType.returnItem:
        return '↩️';
      case StockMovementType.damage:
        return '❌';
      case StockMovementType.transfer:
        return '🔄';
    }
  }
}
