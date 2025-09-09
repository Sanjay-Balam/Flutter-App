// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleRecord _$SaleRecordFromJson(Map<String, dynamic> json) => SaleRecord(
  id: json['_id'] as String,
  menuItemId: json['menuItemId'] as String,
  itemName: json['itemName'] as String,
  category: json['category'] as String,
  size: json['size'] as String,
  unitPrice: (json['unitPrice'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  notes: json['notes'] as String?,
  userId: json['userId'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$SaleRecordToJson(SaleRecord instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'menuItemId': instance.menuItemId,
      'itemName': instance.itemName,
      'category': instance.category,
      'size': instance.size,
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'totalAmount': instance.totalAmount,
      'timestamp': instance.timestamp.toIso8601String(),
      'notes': instance.notes,
      'userId': instance.userId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$ItemSizeEnumMap = {
  ItemSize.small: 'small',
  ItemSize.large: 'large',
  ItemSize.regular: 'regular',
};