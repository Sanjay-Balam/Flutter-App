// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionItem _$TransactionItemFromJson(Map<String, dynamic> json) =>
    TransactionItem(
      menuItemId: json['menuItemId'] as String,
      itemName: json['itemName'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      size: $enumDecode(_$ItemSizeEnumMap, json['size']),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );

Map<String, dynamic> _$TransactionItemToJson(TransactionItem instance) =>
    <String, dynamic>{
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

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
  id: json['_id'] as String,
  userId: json['userId'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
  grandTotal: (json['grandTotal'] as num).toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  notes: json['notes'] as String?,
  invoiceNumber: json['invoiceNumber'] as String?,
  invoiceGenerated: json['invoiceGenerated'] as bool? ?? false,
  invoiceGeneratedAt: json['invoiceGeneratedAt'] == null
      ? null
      : DateTime.parse(json['invoiceGeneratedAt'] as String),
  paymentMethod: json['paymentMethod'] as String?,
  paymentStatus: json['paymentStatus'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'userId': instance.userId,
      'items': instance.items,
      'totalAmount': instance.totalAmount,
      'taxAmount': instance.taxAmount,
      'grandTotal': instance.grandTotal,
      'timestamp': instance.timestamp.toIso8601String(),
      'notes': instance.notes,
      'invoiceNumber': instance.invoiceNumber,
      'invoiceGenerated': instance.invoiceGenerated,
      'invoiceGeneratedAt': instance.invoiceGeneratedAt?.toIso8601String(),
      'paymentMethod': instance.paymentMethod,
      'paymentStatus': instance.paymentStatus,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
