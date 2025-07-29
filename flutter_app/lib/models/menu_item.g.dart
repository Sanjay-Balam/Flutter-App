// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => MenuItem(
  id: json['id'] as String,
  name: json['name'] as String,
  category: $enumDecode(_$MenuCategoryEnumMap, json['category']),
  prices: (json['prices'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry($enumDecode(_$ItemSizeEnumMap, k), (e as num).toDouble()),
  ),
  description: json['description'] as String?,
  isAvailable: json['isAvailable'] as bool? ?? true,
);

Map<String, dynamic> _$MenuItemToJson(MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category': _$MenuCategoryEnumMap[instance.category]!,
  'prices': instance.prices.map((k, e) => MapEntry(_$ItemSizeEnumMap[k]!, e)),
  'description': instance.description,
  'isAvailable': instance.isAvailable,
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
