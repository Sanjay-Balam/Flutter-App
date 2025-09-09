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
  final _categoryController = TextEditingController();
  
  String _selectedCategory = '';
  bool _isAvailable = true;
  bool _isLoading = false;
  List<String> _selectedSizes = ['Regular'];
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void initState() {
    super.initState();

    // Initialize default sizes and controllers
    _initializePriceControllers();
    
    // If editing, populate form with existing data
    if (widget.menuItem != null) {
      final item = widget.menuItem!;
      _nameController.text = item.name;
      _descriptionController.text = item.description ?? '';
      _selectedCategory = item.category;
      _categoryController.text = item.category;
      _isAvailable = item.isAvailable;
      _selectedSizes = item.getAvailableSizes();
      
      // Reinitialize controllers for the item's sizes
      _initializePriceControllers();
      
      // Populate price fields
      for (final size in _selectedSizes) {
        final price = item.prices[size];
        if (price != null) {
          _priceControllers[size]!.text = price.toInt().toString();
        }
      }
    }
  }

  void _initializePriceControllers() {
    // Dispose existing controllers
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    _priceControllers.clear();
    
    // Create controllers for selected sizes
    for (final size in _selectedSizes) {
      _priceControllers[size] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingCategories = ref.watch(menuCategoriesProvider);

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

              // Category Input with Autocomplete
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _selectedCategory),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return existingCategories;
                  }
                  return existingCategories.where((category) =>
                      category.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _categoryController.text = category;
                    // Update sizes based on category presets
                    _selectedSizes = CategoryUtils.getSizePresets(category);
                    _initializePriceControllers();
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _categoryController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      hintText: 'e.g., Pizza, Burgers, Desserts',
                      border: const OutlineInputBorder(),
                      prefixIcon: Text(
                        CategoryUtils.getCategoryIcon(_selectedCategory.isEmpty ? 'Default' : _selectedCategory),
                        style: const TextStyle(fontSize: 20),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 40),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a category';
                      }
                      if (value.trim().length < 2) {
                        return 'Category must be at least 2 characters';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value.trim();
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Size Management Section
              Row(
                children: [
                  Text('Sizes & Prices *', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showSizeManagementDialog(),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Sizes'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Price Fields (dynamic based on selected sizes)
              ..._selectedSizes.map((size) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _priceControllers[size],
                  decoration: InputDecoration(
                    labelText: '$size Price (₹)',
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
                      return 'Please enter ${size.toLowerCase()} price';
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
              )).toList(),

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

  void _showSizeManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => _SizeManagementDialog(
        initialSizes: _selectedSizes,
        onSizesChanged: (newSizes) {
          setState(() {
            _selectedSizes = newSizes;
            _initializePriceControllers();
          });
        },
      ),
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

      // Build prices map from selected sizes
      final Map<String, double> prices = {};
      
      for (final size in _selectedSizes) {
        final controller = _priceControllers[size];
        if (controller != null) {
          final price = double.tryParse(controller.text) ?? 0;
          prices[size] = price;
        }
      }

      // Create MenuItem object
      final menuItem = MenuItem(
        id:
            widget.menuItem?.id ??
            '', // Will be generated by backend for new items
        name: _nameController.text.trim(),
        category: _selectedCategory.isEmpty ? _categoryController.text.trim() : _selectedCategory,
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

class _SizeManagementDialog extends StatefulWidget {
  final List<String> initialSizes;
  final Function(List<String>) onSizesChanged;

  const _SizeManagementDialog({
    required this.initialSizes,
    required this.onSizesChanged,
  });

  @override
  State<_SizeManagementDialog> createState() => _SizeManagementDialogState();
}

class _SizeManagementDialogState extends State<_SizeManagementDialog> {
  late List<String> _sizes;
  final _sizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sizes = List.from(widget.initialSizes);
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Sizes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add new size
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Add Size',
                    hintText: 'e.g., Small, Large, XL',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addSize(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addSize,
                icon: const Icon(Icons.add),
                tooltip: 'Add Size',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Current sizes
          const Text('Current Sizes:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_sizes.isEmpty)
            const Text('No sizes added yet', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              children: _sizes.map((size) => Chip(
                label: Text(size),
                deleteIcon: _sizes.length > 1 ? const Icon(Icons.close, size: 16) : null,
                onDeleted: _sizes.length > 1 ? () => _removeSize(size) : null,
              )).toList(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _sizes.isNotEmpty ? () {
            widget.onSizesChanged(_sizes);
            Navigator.of(context).pop();
          } : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  void _addSize() {
    final size = _sizeController.text.trim();
    if (size.isNotEmpty && !_sizes.contains(size)) {
      setState(() {
        _sizes.add(size);
        _sizeController.clear();
      });
    }
  }

  void _removeSize(String size) {
    if (_sizes.length > 1) {
      setState(() {
        _sizes.remove(size);
      });
    }
  }
}
