import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale_record.dart';
import '../models/invoice.dart';
import '../services/invoice_api_service.dart';
import '../providers/user_provider.dart';
import '../config/app_config.dart';

class InvoiceDialog extends ConsumerStatefulWidget {
  final SaleRecord saleRecord;

  const InvoiceDialog({super.key, required this.saleRecord});

  @override
  ConsumerState<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends ConsumerState<InvoiceDialog> {
  final _invoiceApiService = InvoiceApiService();
  Invoice? _invoice;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingInvoice();
  }

  Future<void> _checkExistingInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final existingInvoice = await _invoiceApiService.getInvoiceData(
        widget.saleRecord.id,
      );
      setState(() {
        _invoice = existingInvoice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get userId from provider with proper error handling
      final userIdAsync = ref.read(currentUserIdProvider);
      if (userIdAsync == null) {
        throw Exception('User not loaded. Please wait and try again.');
      }

      final invoice = await _invoiceApiService.generateInvoice(
        saleId: widget.saleRecord.id,
        userId: userIdAsync,
      );

      setState(() {
        _invoice = invoice;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invoice ${invoice.invoiceNumber} generated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _shareInvoice() async {
    if (_invoice == null) return;

    try {
      setState(() => _isLoading = true);
      await _invoiceApiService.shareInvoicePDF(_invoice!);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share invoice: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printInvoice() async {
    if (_invoice == null) return;

    try {
      setState(() => _isLoading = true);
      await _invoiceApiService.printInvoicePDF(_invoice!);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to print invoice: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Invoice Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sale Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sale Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Item:', widget.saleRecord.itemName),
                    _buildDetailRow('Size:', widget.saleRecord.size.name),
                    _buildDetailRow(
                      'Quantity:',
                      widget.saleRecord.quantity.toString(),
                    ),
                    _buildDetailRow(
                      'Amount:',
                      '${AppConfig.currencySymbol}${widget.saleRecord.totalAmount.toStringAsFixed(AppConfig.currencyDecimalPlaces)}',
                    ),
                    _buildDetailRow(
                      'Date:',
                      '${widget.saleRecord.timestamp.day}/${widget.saleRecord.timestamp.month}/${widget.saleRecord.timestamp.year}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Loading/Error/Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              )
            else if (_invoice != null)
              // Invoice Generated
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Invoice Generated',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Invoice Number:',
                        _invoice!.invoiceNumber,
                      ),
                      _buildDetailRow(
                        'Generated:',
                        '${_invoice!.generatedAt.day}/${_invoice!.generatedAt.month}/${_invoice!.generatedAt.year}',
                      ),
                    ],
                  ),
                ),
              )
            else
              // No Invoice Yet
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('No invoice generated for this sale yet.'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                if (_invoice == null)
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final userId = ref.watch(currentUserIdProvider);
                        final canGenerate = !_isLoading && userId != null;

                        return ElevatedButton.icon(
                          onPressed: canGenerate ? _generateInvoice : null,
                          icon: const Icon(Icons.receipt_long),
                          label: Text(
                            userId == null
                                ? 'Loading User...'
                                : 'Generate Invoice',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        );
                      },
                    ),
                  )
                else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _shareInvoice,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _printInvoice,
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
