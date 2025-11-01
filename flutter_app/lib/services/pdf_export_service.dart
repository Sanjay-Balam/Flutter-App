import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/sale_record.dart';

class PdfExportService {
  static Future<void> exportSalesReport({
    required List<SaleRecord> sales,
    required String reportTitle,
    required String dateRange,
    String? businessName,
  }) async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM dd, yyyy');

    // Calculate summary statistics
    final totalRevenue = sales.fold<double>(0, (sum, sale) => sum + sale.grandTotal);
    final totalItems = sales.fold<int>(0, (sum, sale) {
      if (sale.isMultiItem && sale.items != null) {
        return sum + sale.items!.fold<int>(0, (itemSum, item) => itemSum + item.quantity);
      } else {
        return sum + (sale.quantity ?? 0);
      }
    });
    final averageSale = sales.isNotEmpty ? totalRevenue / sales.length : 0.0;

    // Calculate top selling items
    final Map<String, int> itemCounts = {};
    for (final sale in sales) {
      if (sale.isMultiItem && sale.items != null) {
        for (final item in sale.items!) {
          itemCounts[item.itemName] = (itemCounts[item.itemName] ?? 0) + item.quantity;
        }
      } else {
        final itemName = sale.itemName ?? 'Unknown';
        final quantity = sale.quantity ?? 0;
        itemCounts[itemName] = (itemCounts[itemName] ?? 0) + quantity;
      }
    }
    final topItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate category revenue
    final Map<String, double> categoryRevenue = {};
    for (final sale in sales) {
      if (sale.isMultiItem && sale.items != null) {
        for (final item in sale.items!) {
          categoryRevenue[item.categoryName] =
              (categoryRevenue[item.categoryName] ?? 0) + item.subtotal;
        }
      } else {
        final categoryName = sale.categoryName ?? 'Uncategorized';
        categoryRevenue[categoryName] =
            (categoryRevenue[categoryName] ?? 0) + sale.totalAmount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (businessName != null)
                  pw.Text(
                    businessName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                pw.SizedBox(height: 8),
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  dateRange,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated on: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Summary Statistics
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Sales', '${sales.length}'),
                _buildSummaryItem('Total Revenue', currencyFormatter.format(totalRevenue)),
                _buildSummaryItem('Items Sold', '$totalItems'),
                _buildSummaryItem('Avg Sale', currencyFormatter.format(averageSale)),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Top Selling Items
          pw.Text(
            'Top Selling Items',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Item Name', isHeader: true),
                  _buildTableCell('Quantity Sold', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              // Data rows
              ...topItems.take(10).map((entry) => pw.TableRow(
                children: [
                  _buildTableCell(entry.key),
                  _buildTableCell('${entry.value}', align: pw.TextAlign.right),
                ],
              )),
            ],
          ),

          pw.SizedBox(height: 24),

          // Category Revenue
          pw.Text(
            'Revenue by Category',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Category', isHeader: true),
                  _buildTableCell('Revenue', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              // Data rows
              ...categoryRevenue.entries.map((entry) => pw.TableRow(
                children: [
                  _buildTableCell(entry.key),
                  _buildTableCell(currencyFormatter.format(entry.value), align: pw.TextAlign.right),
                ],
              )),
            ],
          ),

          pw.SizedBox(height: 24),

          // Detailed Sales List
          pw.Text(
            'Detailed Sales List',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Item(s)', isHeader: true),
                  _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                  _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              // Data rows
              ...sales.map((sale) {
                String itemDescription;
                int totalQty;
                
                if (sale.isMultiItem && sale.items != null) {
                  itemDescription = sale.items!.map((item) => item.itemName).join(', ');
                  totalQty = sale.items!.fold(0, (sum, item) => sum + item.quantity);
                } else {
                  itemDescription = sale.itemName ?? 'Unknown';
                  totalQty = sale.quantity ?? 0;
                }

                return pw.TableRow(
                  children: [
                    _buildTableCell(dateFormatter.format(sale.timestamp)),
                    _buildTableCell(itemDescription),
                    _buildTableCell('$totalQty', align: pw.TextAlign.center),
                    _buildTableCell(
                      currencyFormatter.format(sale.grandTotal),
                      align: pw.TextAlign.right,
                    ),
                  ],
                );
              }),
              // Total row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('TOTAL', isHeader: true),
                  _buildTableCell(''),
                  _buildTableCell('$totalItems', isHeader: true, align: pw.TextAlign.center),
                  _buildTableCell(
                    currencyFormatter.format(totalRevenue),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    // Show print dialog
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${reportTitle.replaceAll(' ', '_')}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}

