// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionInvoice _$TransactionInvoiceFromJson(Map<String, dynamic> json) =>
    TransactionInvoice(
      invoiceNumber: json['invoiceNumber'] as String,
      transaction: Transaction.fromJson(
        json['saleRecord'] as Map<String, dynamic>,
      ),
      businessDetails: json['businessDetails'] == null
          ? null
          : BusinessDetails.fromJson(
              json['businessDetails'] as Map<String, dynamic>,
            ),
      invoiceSettings: json['invoiceSettings'] == null
          ? null
          : InvoiceSettings.fromJson(
              json['invoiceSettings'] as Map<String, dynamic>,
            ),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$TransactionInvoiceToJson(TransactionInvoice instance) =>
    <String, dynamic>{
      'invoiceNumber': instance.invoiceNumber,
      'saleRecord': instance.transaction,
      'businessDetails': instance.businessDetails,
      'invoiceSettings': instance.invoiceSettings,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };
