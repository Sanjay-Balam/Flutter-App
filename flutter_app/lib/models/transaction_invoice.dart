import 'package:json_annotation/json_annotation.dart';
import 'transaction.dart';
import 'invoice.dart';

part 'transaction_invoice.g.dart';

@JsonSerializable()
class TransactionInvoice {
  final String invoiceNumber;

  @JsonKey(name: 'saleRecord')
  final Transaction transaction;

  final BusinessDetails? businessDetails;
  final InvoiceSettings? invoiceSettings;
  final DateTime generatedAt;

  const TransactionInvoice({
    required this.invoiceNumber,
    required this.transaction,
    this.businessDetails,
    this.invoiceSettings,
    required this.generatedAt,
  });

  factory TransactionInvoice.fromJson(Map<String, dynamic> json) =>
      _$TransactionInvoiceFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionInvoiceToJson(this);

  // Helper methods
  double get totalAmount => transaction.totalAmount;
  double get taxAmount => transaction.taxAmount;
  double get grandTotal => transaction.grandTotal;
  int get totalItems => transaction.totalItems;
  int get uniqueItems => transaction.uniqueItems;
}
