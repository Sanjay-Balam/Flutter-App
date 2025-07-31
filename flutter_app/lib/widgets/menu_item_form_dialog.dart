import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../providers/user_provider.dart';

class MenuItemFormDialog extends ConsumerStatefulWidget {
  final MenuItem? menuItem; // null for create, MenuItem for edit
  final String dialogTitle;

  const MenuItemFormDialog({
    super.key,
    required this.dialogTitle,
    this.menuItem,
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

  MenuCategory _selectedCategory = MenuCategory.milkCakes;
  bool _isAvailable = true;
  bool _isLoading = false;

  // Price configuration based on category
  final Map<MenuCategory, List<ItemSize>> _categorySizes = {
    MenuCategory.milkCakes: [ItemSize.regular],
    MenuCategory.cheeseCakes: [ItemSize.small, ItemSize.large],
    MenuCategory.chocolateBrownie: [ItemSize.regular],
  };

  @override
  void initState() {
    super.initState();

    // If editing, populate form with existing data
    if (widget.menuItem != null) {
      final item = widget.menuItem!;
      _nameController.text = item.name;
      _descriptionController.text = item.description ?? '';
      _selectedCategory = item.category;
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
    final availableSizes =
        _categorySizes[_selectedCategory] ?? [ItemSize.regular];

    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: Form(
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

              // Category Dropdown
              DropdownButtonFormField<MenuCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: MenuCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(
                          category.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                      // Clear price fields when category changes
                      _smallPriceController.clear();
                      _largePriceController.clear();
                      _regularPriceController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Price Fields (dynamic based on category)
              Text('Prices *', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...availableSizes
                  .map(
                    (size) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _getPriceController(size),
                        decoration: InputDecoration(
                          labelText: '${size.displayName} Price (₹)',
                          hintText: 'Enter price in rupees',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter ${size.displayName.toLowerCase()} price';
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
                  )
                  .toList(),

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

  TextEditingController _getPriceController(ItemSize size) {
    switch (size) {
      case ItemSize.small:
        return _smallPriceController;
      case ItemSize.large:
        return _largePriceController;
      case ItemSize.regular:
        return _regularPriceController;
    }
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

      // Build prices map
      final availableSizes =
          _categorySizes[_selectedCategory] ?? [ItemSize.regular];
      final Map<ItemSize, double> prices = {};

      for (final size in availableSizes) {
        final controller = _getPriceController(size);
        final price = double.tryParse(controller.text) ?? 0;
        prices[size] = price;
      }

      // Create MenuItem object
      final menuItem = MenuItem(
        id:
            widget.menuItem?.id ??
            '', // Will be generated by backend for new items
        name: _nameController.text.trim(),
        category: _selectedCategory,
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
