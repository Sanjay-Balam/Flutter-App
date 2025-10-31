import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../models/invoice.dart';

class InvoiceApiService {
  // Singleton pattern
  static final InvoiceApiService _instance = InvoiceApiService._internal();
  factory InvoiceApiService() => _instance;
  InvoiceApiService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Headers for API requests
  Map<String, String> get _headers => AppConfig.defaultHeaders;

  /// Generate invoice for a sale
  Future<Invoice> generateInvoice({
    required String saleId,
    required String userId,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/generate-invoice/$saleId',
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
          return Invoice.fromJson(responseData['data']);
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

  /// Get invoice data for a sale
  Future<Invoice?> getInvoiceData(String saleId) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/invoice/$saleId',
      );

      final response = await _client.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return Invoice.fromJson(responseData['data']);
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

  /// Get all invoices for a user
  Future<List<Invoice>> getUserInvoices({
    required String userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/invoices/$userId?page=$page&pageSize=$pageSize',
      );

      final response = await _client.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> invoicesJson = responseData['data'];
          return invoicesJson.map((json) => Invoice.fromJson(json)).toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch invoices: $e');
    }
  }

  /// Update business details
  Future<bool> updateBusinessDetails({
    required String userId,
    required BusinessDetails businessDetails,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/business-details/$userId',
      );

      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode(businessDetails.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update business details: $e');
    }
  }

  /// Update invoice settings
  Future<bool> updateInvoiceSettings({
    required String userId,
    required InvoiceSettings invoiceSettings,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/invoice-settings/$userId',
      );

      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode(invoiceSettings.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update invoice settings: $e');
    }
  }

  /// Generate PDF from invoice data
  Future<pw.Document> generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(invoice),
          pw.SizedBox(height: 20),
          _buildBusinessInfo(invoice.businessDetails),
          pw.SizedBox(height: 20),
          _buildInvoiceInfo(invoice),
          pw.SizedBox(height: 20),
          _buildItemsTable(invoice),
          pw.SizedBox(height: 20),
          _buildTotals(invoice),
          pw.Spacer(),
          _buildFooter(invoice),
        ],
      ),
    );

    return pdf;
  }

  /// Save PDF to device and return file path
  Future<String> saveInvoicePDF(Invoice invoice) async {
    try {
      final pdf = await generateInvoicePDF(invoice);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Invoice_${invoice.invoiceNumber}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  /// Share invoice PDF
  Future<void> shareInvoicePDF(Invoice invoice) async {
    try {
      final filePath = await saveInvoicePDF(invoice);
      final xFile = XFile(filePath);

      await Share.shareXFiles(
        [xFile],
        text:
            'Invoice ${invoice.invoiceNumber} - ${AppConfig.currencySymbol}${invoice.grandTotal.toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
        subject: 'Invoice ${invoice.invoiceNumber}',
      );
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  /// Print invoice PDF
  Future<void> printInvoicePDF(Invoice invoice) async {
    try {
      final pdf = await generateInvoicePDF(invoice);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${invoice.invoiceNumber}',
      );
    } catch (e) {
      throw Exception('Failed to print PDF: $e');
    }
  }

  // PDF Building Methods

  pw.Widget _buildHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.brown,
              ),
            ),
            pw.Text(
              invoice.invoiceNumber,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Date: ${_formatDate(invoice.generatedAt)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Time: ${_formatTime(invoice.generatedAt)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBusinessInfo(BusinessDetails businessDetails) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'From:',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (businessDetails.address != null) ...[
          pw.Text(businessDetails.address!.formattedAddress),
        ],
        if (businessDetails.contact?.phone != null) ...[
          pw.Text('Phone: ${businessDetails.contact!.phone}'),
        ],
        if (businessDetails.contact?.email != null) ...[
          pw.Text('Email: ${businessDetails.contact!.email}'),
        ],
        if (businessDetails.tax?.gstNumber != null) ...[
          pw.Text('GST: ${businessDetails.tax!.gstNumber}'),
        ],
      ],
    );
  }

  pw.Widget _buildInvoiceInfo(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Invoice Details',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Sale Date: ${_formatDate(invoice.saleRecord.timestamp)}'),
            pw.Text('Sale Time: ${_formatTime(invoice.saleRecord.timestamp)}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Payment Info',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Payment: Cash'),
            pw.Text('Status: Paid'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(Invoice invoice) {
    // Build table rows based on sale type
    final List<pw.TableRow> rows = [
      // Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          _buildTableCell('Item', isHeader: true),
          _buildTableCell('Size', isHeader: true),
          _buildTableCell('Qty', isHeader: true),
          _buildTableCell('Rate', isHeader: true),
          _buildTableCell('Amount', isHeader: true),
        ],
      ),
    ];

    // Add item rows
    if (invoice.saleRecord.isMultiItem && invoice.saleRecord.items != null) {
      // Multi-item sale: add a row for each item
      for (final item in invoice.saleRecord.items!) {
        rows.add(
          pw.TableRow(
            children: [
              _buildTableCell(item.itemName),
              _buildTableCell(item.size.name),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell(
                '${AppConfig.currencySymbol}${item.unitPrice.toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
              ),
              _buildTableCell(
                '${AppConfig.currencySymbol}${item.subtotal.toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
              ),
            ],
          ),
        );
      }
    } else {
      // Single-item sale
      rows.add(
        pw.TableRow(
          children: [
            _buildTableCell(invoice.saleRecord.itemName ?? 'Unknown'),
            _buildTableCell(invoice.saleRecord.size?.name ?? 'Unknown'),
            _buildTableCell((invoice.saleRecord.quantity ?? 0).toString()),
            _buildTableCell(
              '${AppConfig.currencySymbol}${(invoice.saleRecord.unitPrice ?? 0).toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
            ),
            _buildTableCell(
              '${AppConfig.currencySymbol}${invoice.saleRecord.totalAmount.toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: rows,
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildTotals(Invoice invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _buildTotalRow(
              'Subtotal:',
              '${AppConfig.currencySymbol}${invoice.totalAmount.toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
            ),
            if (invoice.invoiceSettings.includeTax) ...[
              _buildTotalRow(
                'Tax (${invoice.invoiceSettings.taxRate}%):',
                '${AppConfig.currencySymbol}${invoice.taxAmount.toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
              ),
            ],
            pw.Divider(color: PdfColors.grey),
            _buildTotalRow(
              'Total:',
              '${AppConfig.currencySymbol}${invoice.grandTotal.toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (invoice.saleRecord.notes?.isNotEmpty == true &&
            invoice.invoiceSettings.includeNotes) ...[
          pw.Text(
            'Notes:',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            invoice.saleRecord.notes!,
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 10),
        ],
        if (invoice.businessDetails.branding?.tagline != null) ...[
          pw.Center(
            child: pw.Text(
              invoice.businessDetails.branding!.tagline!,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        ],
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Dispose method for cleanup
  void dispose() {
    _client.close();
  }
}
