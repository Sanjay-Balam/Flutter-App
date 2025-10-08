import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../models/category.dart';
import '../providers/menu_provider.dart';
import '../providers/category_provider.dart';
import '../providers/user_provider.dart';

class MenuItemFormDialog extends ConsumerStatefulWidget {
  final MenuItem? menuItem; // null for create, MenuItem for edit
  final String dialogTitle;
  final String? initialCategoryId; // For pre-selecting category when creating

  const MenuItemFormDialog({
    super.key,
    required this.dialogTitle,
    this.menuItem,
    this.initialCategoryId,
  });

  @override
  ConsumerState<MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends ConsumerState<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _smallPriceController = TextEditingController();
  final _largePriceController = TextEditingController();
  final _regularPriceController = TextEditingController();

  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If editing, populate form with existing data
    if (widget.menuItem != null) {
      final item = widget.menuItem!;
      _nameController.text = item.name;
      _descriptionController.text = item.description ?? '';
      _selectedCategoryId = item.categoryId;
      _isAvailable = item.isAvailable;

      // Populate price fields based on category
      final prices = item.prices;
      if (prices.containsKey(ItemSize.small)) {
        _smallPriceController.text = prices[ItemSize.small]!.toInt().toString();
      }
      if (prices.containsKey(ItemSize.large)) {
        _largePriceController.text = prices[ItemSize.large]!.toInt().toString();
      }
      if (prices.containsKey(ItemSize.regular)) {
        _regularPriceController.text = prices[ItemSize.regular]!
            .toInt()
            .toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _smallPriceController.dispose();
    _largePriceController.dispose();
    _regularPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    // Set initial category if provided and not already set
    if (_selectedCategoryId == null && widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
    }

    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: categoriesAsync.when(
        data: (categories) {
          // Set first category as default if none selected
          if (_selectedCategoryId == null && categories.isNotEmpty) {
            _selectedCategoryId = categories.first.id;
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      hintText: 'e.g., Chocolate Brownie',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter item name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown (Dynamic)
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Row(
                          children: [
                            Text(
                              category.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Price Fields (all sizes available)
                  Text(
                    'Prices *',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),

                  // Regular Price (always shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _regularPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Regular Price (₹) *',
                        hintText: 'Enter price in rupees',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter regular price';
                        }
                        final price = int.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                        if (price > 10000) {
                          return 'Price must be less than ₹10,000';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Small Price (optional)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _smallPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Small Price (₹) - Optional',
                        hintText: 'Leave empty if not applicable',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),

                  // Large Price (optional)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _largePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Large Price (₹) - Optional',
                        hintText: 'Leave empty if not applicable',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Brief description of the item',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),

                  // Availability Switch
                  SwitchListTile(
                    title: const Text('Available for Sale'),
                    subtitle: Text(
                      _isAvailable
                          ? 'Customers can order this item'
                          : 'Item is temporarily unavailable',
                    ),
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox(
          width: 400,
          height: 400,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => SizedBox(
          width: 400,
          height: 200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to load categories'),
                const SizedBox(height: 8),
                Text(error.toString(), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.menuItem == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (_selectedCategoryId == null) {
        throw Exception('Please select a category');
      }

      // Build prices map
      final Map<ItemSize, double> prices = {};

      // Always include regular price (required)
      final regularPrice = double.tryParse(_regularPriceController.text);
      if (regularPrice != null && regularPrice > 0) {
        prices[ItemSize.regular] = regularPrice;
      }

      // Add small price if provided
      final smallPrice = double.tryParse(_smallPriceController.text);
      if (smallPrice != null && smallPrice > 0) {
        prices[ItemSize.small] = smallPrice;
      }

      // Add large price if provided
      final largePrice = double.tryParse(_largePriceController.text);
      if (largePrice != null && largePrice > 0) {
        prices[ItemSize.large] = largePrice;
      }

      // Create MenuItem object
      final menuItem = MenuItem(
        id:
            widget.menuItem?.id ??
            '', // Will be generated by backend for new items
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId!,
        prices: prices,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isAvailable: _isAvailable,
        userId: userId,
        createdAt: widget.menuItem?.createdAt,
        updatedAt: widget.menuItem?.updatedAt,
      );

      final menuNotifier = ref.read(menuItemsProvider.notifier);

      if (widget.menuItem == null) {
        // Create new menu item
        await menuNotifier.addMenuItem(menuItem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Created "${menuItem.name}" successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing menu item
        await menuNotifier.updateMenuItem(widget.menuItem!.id, menuItem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Updated "${menuItem.name}" successfully!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
