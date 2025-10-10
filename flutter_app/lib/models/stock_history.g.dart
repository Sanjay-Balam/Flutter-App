// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockHistory _$StockHistoryFromJson(Map<String, dynamic> json) => StockHistory(
  id: json['_id'] as String,
  menuItemId: json['menuItemId'] as String,
  userId: json['userId'] as String,
  movementType: $enumDecode(_$StockMovementTypeEnumMap, json['movementType']),
  quantityChange: (json['quantityChange'] as num).toInt(),
  previousQuantity: (json['previousQuantity'] as num).toInt(),
  newQuantity: (json['newQuantity'] as num).toInt(),
  reason: json['reason'] as String?,
  saleId: json['saleId'] as String?,
  performedBy: json['performedBy'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$StockHistoryToJson(StockHistory instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'menuItemId': instance.menuItemId,
      'userId': instance.userId,
      'movementType': _$StockMovementTypeEnumMap[instance.movementType]!,
      'quantityChange': instance.quantityChange,
      'previousQuantity': instance.previousQuantity,
      'newQuantity': instance.newQuantity,
      'reason': instance.reason,
      'saleId': instance.saleId,
      'performedBy': instance.performedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$StockMovementTypeEnumMap = {
  StockMovementType.initial: 'INITIAL',
  StockMovementType.restock: 'RESTOCK',
  StockMovementType.sale: 'SALE',
  StockMovementType.adjustment: 'ADJUSTMENT',
  StockMovementType.returnItem: 'RETURN',
  StockMovementType.damage: 'DAMAGE',
  StockMovementType.transfer: 'TRANSFER',
};
