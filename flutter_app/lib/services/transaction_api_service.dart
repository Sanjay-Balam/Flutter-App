import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/transaction.dart';
import '../models/transaction_invoice.dart';

class TransactionApiService {
  // Singleton pattern
  static final TransactionApiService _instance =
      TransactionApiService._internal();
  factory TransactionApiService() => _instance;
  TransactionApiService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Headers for API requests
  Map<String, String> get _headers => AppConfig.defaultHeaders;

  /// Create a new transaction
  Future<Transaction> createTransaction({
    required String userId,
    required List<TransactionItem> items,
    String? notes,
    double taxAmount = 0,
    String paymentMethod = 'cash',
    String paymentStatus = 'paid',
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/transactions',
      );

      final requestBody = {
        'userId': userId,
        'items': items
            .map(
              (item) => {
                'menuItemId': item.menuItemId,
                'itemName': item.itemName,
                'categoryId': item.categoryId,
                'categoryName': item.categoryName,
                'size': item.size.name,
                'unitPrice': item.unitPrice,
                'quantity': item.quantity,
                'subtotal': item.subtotal,
              },
            )
            .toList(),
        'taxAmount': taxAmount,
        'timestamp': DateTime.now().toIso8601String(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return Transaction.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Generate invoice for a transaction
  Future<TransactionInvoice> generateInvoice({
    required String transactionId,
    required String userId,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/transactions/$transactionId/generate-invoice',
      );

      final requestBody = {'userId': userId};

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return TransactionInvoice.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate invoice: $e');
    }
  }

  /// Get invoice data for a transaction
  Future<TransactionInvoice?> getInvoiceData(String transactionId) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/transactions/$transactionId/invoice',
      );

      final response = await _client.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return TransactionInvoice.fromJson(responseData['data']);
        }
      } else if (response.statusCode == 404) {
        return null; // Invoice not found
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get invoice data: $e');
    }
    return null;
  }

  /// Get all transactions for a user
  Future<List<Transaction>> getUserTransactions({
    required String userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/transactions/user/$userId?page=$page&pageSize=$pageSize',
      );

      final response = await _client.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> transactionsJson = responseData['data'];
          return transactionsJson
              .map((json) => Transaction.fromJson(json))
              .toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  /// Generate PDF for transaction invoice
  Future<File> generateTransactionInvoicePDF(TransactionInvoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    invoice.invoiceNumber,
                    style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Date: ${_formatDate(invoice.transaction.timestamp)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Time: ${_formatTime(invoice.transaction.timestamp)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 32),

          // Business Details
          if (invoice.businessDetails?.address != null ||
              invoice.businessDetails?.contact != null) ...[
            pw.Text(
              'From:',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (invoice.businessDetails?.address?.formattedAddress.isNotEmpty ==
                true)
              pw.Text(
                invoice.businessDetails!.address!.formattedAddress,
                style: const pw.TextStyle(fontSize: 12),
              ),
            if (invoice.businessDetails?.contact?.phone != null)
              pw.Text(
                'Phone: ${invoice.businessDetails!.contact!.phone}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            if (invoice.businessDetails?.contact?.email != null)
              pw.Text(
                'Email: ${invoice.businessDetails!.contact!.email}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            pw.SizedBox(height: 24),
          ],

          // Items Table
          pw.Text(
            'Items',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Item', isHeader: true),
                  _buildTableCell('Size', isHeader: true),
                  _buildTableCell('Qty', isHeader: true, alignRight: true),
                  _buildTableCell('Rate', isHeader: true, alignRight: true),
                  _buildTableCell('Amount', isHeader: true, alignRight: true),
                ],
              ),
              // Item rows
              ...invoice.transaction.items.map(
                (item) => pw.TableRow(
                  children: [
                    _buildTableCell(item.itemName),
                    _buildTableCell(item.size.name),
                    _buildTableCell('${item.quantity}', alignRight: true),
                    _buildTableCell(
                      '${AppConfig.currencySymbol}${item.unitPrice.toStringAsFixed(2)}',
                      alignRight: true,
                    ),
                    _buildTableCell(
                      '${AppConfig.currencySymbol}${item.subtotal.toStringAsFixed(2)}',
                      alignRight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildTotalRow('Subtotal:', invoice.totalAmount),
                  if (invoice.taxAmount > 0) ...[
                    pw.SizedBox(height: 4),
                    _buildTotalRow(
                      'Tax (${invoice.invoiceSettings?.taxRate ?? 0}%):',
                      invoice.taxAmount,
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.grey600),
                  pw.SizedBox(height: 8),
                  _buildTotalRow(
                    'Grand Total:',
                    invoice.grandTotal,
                    isBold: true,
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 32),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Items', '${invoice.totalItems}'),
                _buildSummaryItem('Unique Items', '${invoice.uniqueItems}'),
                _buildSummaryItem(
                  'Payment',
                  invoice.transaction.paymentMethod ?? 'Cash',
                ),
              ],
            ),
          ),

          // Notes
          if (invoice.transaction.notes?.isNotEmpty == true) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              'Notes:',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              invoice.transaction.notes!,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],

          pw.Spacer(),

          // Footer
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    // Save to temporary directory
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/invoice_${invoice.invoiceNumber.replaceAll('-', '_')}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Helper methods for PDF generation
  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Text(
          '${AppConfig.currencySymbol}${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Share invoice PDF
  Future<void> shareInvoice(TransactionInvoice invoice) async {
    try {
      final file = await generateTransactionInvoicePDF(invoice);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Invoice ${invoice.invoiceNumber}');
    } catch (e) {
      throw Exception('Failed to share invoice: $e');
    }
  }

  /// Print invoice
  Future<void> printInvoice(TransactionInvoice invoice) async {
    try {
      final file = await generateTransactionInvoicePDF(invoice);
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      throw Exception('Failed to print invoice: $e');
    }
  }

  /// Dispose method for cleanup
  void dispose() {
    _client.close();
  }
}
