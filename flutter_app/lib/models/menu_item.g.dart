// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => MenuItem(
  id: json['_id'] as String,
  name: json['name'] as String,
  categoryId: json['categoryId'] as String,
  category: $enumDecodeNullable(_$MenuCategoryEnumMap, json['category']),
  prices: (json['prices'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry($enumDecode(_$ItemSizeEnumMap, k), (e as num).toDouble()),
  ),
  description: json['description'] as String?,
  isAvailable: json['isAvailable'] as bool? ?? true,
  userId: json['userId'] as String?,
  stockQuantity: (json['stockQuantity'] as num?)?.toInt(),
  lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt(),
  trackStock: json['trackStock'] as bool?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$MenuItemToJson(MenuItem instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'categoryId': instance.categoryId,
  'category': _$MenuCategoryEnumMap[instance.category],
  'prices': instance.prices.map((k, e) => MapEntry(_$ItemSizeEnumMap[k]!, e)),
  'description': instance.description,
  'isAvailable': instance.isAvailable,
  'userId': instance.userId,
  'stockQuantity': instance.stockQuantity,
  'lowStockThreshold': instance.lowStockThreshold,
  'trackStock': instance.trackStock,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
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
