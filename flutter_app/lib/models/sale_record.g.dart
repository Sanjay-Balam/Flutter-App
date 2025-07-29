// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleRecord _$SaleRecordFromJson(Map<String, dynamic> json) => SaleRecord(
  id: json['id'] as String,
  menuItemId: json['menuItemId'] as String,
  itemName: json['itemName'] as String,
  category: $enumDecode(_$MenuCategoryEnumMap, json['category']),
  size: $enumDecode(_$ItemSizeEnumMap, json['size']),
  unitPrice: (json['unitPrice'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$SaleRecordToJson(SaleRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'menuItemId': instance.menuItemId,
      'itemName': instance.itemName,
      'category': _$MenuCategoryEnumMap[instance.category]!,
      'size': _$ItemSizeEnumMap[instance.size]!,
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'totalAmount': instance.totalAmount,
      'timestamp': instance.timestamp.toIso8601String(),
      'notes': instance.notes,
    };

const _$MenuCategoryEnumMap = {
  MenuCategory.milkCakes: 'milkCakes',
  MenuCategory.cheeseCakes: 'cheeseCakes',
  MenuCategory.chocolateBrownie: 'chocolateBrownie',
};

const _$ItemSizeEnumMap = {
  ItemSize.small: 'small',
  ItemSize.large: 'large',
  ItemSize.regular: 'regular',
};
