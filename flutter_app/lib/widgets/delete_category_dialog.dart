import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

class DeleteCategoryDialog extends ConsumerStatefulWidget {
  final Category category;

  const DeleteCategoryDialog({super.key, required this.category});

  @override
  ConsumerState<DeleteCategoryDialog> createState() =>
      _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends ConsumerState<DeleteCategoryDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Delete Category', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Text(
                  widget.category.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.category.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.category.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Are you sure you want to delete this category?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All menu items in this category will need to be reassigned.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }

  void _handleDelete() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await ref
          .read(categoriesProvider.notifier)
          .deleteCategory(widget.category.id);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Category "${widget.category.name}" deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
