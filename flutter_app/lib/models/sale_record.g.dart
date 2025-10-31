// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItem _$SaleItemFromJson(Map<String, dynamic> json) => SaleItem(
  menuItemId: json['menuItemId'] as String,
  itemName: json['itemName'] as String,
  categoryId: json['categoryId'] as String,
  categoryName: json['categoryName'] as String,
  size: $enumDecode(_$ItemSizeEnumMap, json['size']),
  unitPrice: (json['unitPrice'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  subtotal: (json['subtotal'] as num).toDouble(),
);

Map<String, dynamic> _$SaleItemToJson(SaleItem instance) => <String, dynamic>{
  'menuItemId': instance.menuItemId,
  'itemName': instance.itemName,
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
  'size': _$ItemSizeEnumMap[instance.size]!,
  'unitPrice': instance.unitPrice,
  'quantity': instance.quantity,
  'subtotal': instance.subtotal,
};

const _$ItemSizeEnumMap = {
  ItemSize.small: 'small',
  ItemSize.large: 'large',
  ItemSize.regular: 'regular',
};

SaleRecord _$SaleRecordFromJson(Map<String, dynamic> json) => SaleRecord(
  id: json['_id'] as String,
  menuItemId: json['menuItemId'] as String?,
  itemName: json['itemName'] as String?,
  categoryId: json['categoryId'] as String?,
  categoryName: json['categoryName'] as String?,
  category: $enumDecodeNullable(_$MenuCategoryEnumMap, json['category']),
  size: $enumDecodeNullable(_$ItemSizeEnumMap, json['size']),
  unitPrice: (json['unitPrice'] as num?)?.toDouble(),
  quantity: (json['quantity'] as num?)?.toInt(),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  saleType: json['saleType'] as String? ?? 'single',
  totalAmount: (json['totalAmount'] as num).toDouble(),
  taxAmount: (json['taxAmount'] as num?)?.toDouble(),
  grandTotal: (json['grandTotal'] as num).toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  notes: json['notes'] as String?,
  userId: json['userId'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  invoiceNumber: json['invoiceNumber'] as String?,
  invoiceGenerated: json['invoiceGenerated'] as bool?,
  invoiceGeneratedAt: json['invoiceGeneratedAt'] == null
      ? null
      : DateTime.parse(json['invoiceGeneratedAt'] as String),
  paymentMethod: json['paymentMethod'] as String?,
  paymentStatus: json['paymentStatus'] as String?,
);

Map<String, dynamic> _$SaleRecordToJson(SaleRecord instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'menuItemId': instance.menuItemId,
      'itemName': instance.itemName,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'category': _$MenuCategoryEnumMap[instance.category],
      'size': _$ItemSizeEnumMap[instance.size],
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'items': instance.items,
      'saleType': instance.saleType,
      'totalAmount': instance.totalAmount,
      'taxAmount': instance.taxAmount,
      'grandTotal': instance.grandTotal,
      'timestamp': instance.timestamp.toIso8601String(),
      'notes': instance.notes,
      'userId': instance.userId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'invoiceNumber': instance.invoiceNumber,
      'invoiceGenerated': instance.invoiceGenerated,
      'invoiceGeneratedAt': instance.invoiceGeneratedAt?.toIso8601String(),
      'paymentMethod': instance.paymentMethod,
      'paymentStatus': instance.paymentStatus,
    };

const _$MenuCategoryEnumMap = {
  MenuCategory.milkCakes: 'milkCakes',
  MenuCategory.cheeseCakes: 'cheeseCakes',
  MenuCategory.chocolateBrownie: 'chocolateBrownie',
};
