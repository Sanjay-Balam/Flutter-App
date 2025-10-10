import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/user_provider.dart';

class CategoryFormDialog extends ConsumerStatefulWidget {
  final Category? category; // null for create, Category for edit
  final String dialogTitle;

  const CategoryFormDialog({
    super.key,
    required this.dialogTitle,
    this.category,
  });

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();

  String _selectedColor = '#FF6B6B'; // Default color
  int _sortOrder = 0;
  bool _isActive = true;
  bool _isLoading = false;
  String _selectedEmojiCategory = 'Food & Bakery'; // Default emoji category

  // Predefined color options
  final List<String> _colorOptions = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#FFA07A', // Orange
    '#98D8C8', // Mint
    '#F7DC6F', // Yellow
    '#BB8FCE', // Purple
    '#85C1E2', // Light Blue
    '#F8B88B', // Peach
    '#AAB7B8', // Gray
  ];

  // Emoji suggestions organized by category
  final Map<String, List<String>> _emojiCategories = {
    'Food & Bakery': [
      '🍰',
      '🎂',
      '🧁',
      '🍪',
      '🍩',
      '🥐',
      '🍞',
      '🥖',
      '🥨',
      '🥯',
      '🥞',
      '🧇',
    ],
    'Meals & Dining': [
      '🍕',
      '🍔',
      '🌭',
      '🥪',
      '🌮',
      '🌯',
      '🥙',
      '🥗',
      '🍜',
      '🍝',
      '🍛',
      '🍲',
      '🥘',
      '🍱',
      '🍣',
      '🍤',
      '🍙',
      '🍚',
    ],
    'Beverages': ['☕', '🥛', '🍵', '🧃', '🥤', '🧋', '🍹', '🍸', '🧊', '🍷'],
    'Clothing & Fashion': [
      '👕',
      '👔',
      '👗',
      '👘',
      '👚',
      '👙',
      '🩱',
      '👖',
      '🧥',
      '🧤',
      '🧦',
      '👞',
      '👟',
      '🥾',
      '👠',
      '👡',
      '👢',
      '🎩',
      '👒',
      '🧢',
      '👑',
      '💍',
      '👜',
      '🎀',
    ],
    'Electronics': [
      '📱',
      '💻',
      '⌨️',
      '🖥️',
      '🖨️',
      '🖱️',
      '💾',
      '💿',
      '📀',
      '🎮',
      '🕹️',
      '📷',
      '📹',
      '🎥',
      '📞',
      '☎️',
      '📺',
      '📻',
      '🎧',
      '⌚',
      '🔋',
      '🔌',
    ],
    'Home & Furniture': [
      '🏠',
      '🛋️',
      '🪑',
      '🛏️',
      '🚪',
      '🪟',
      '🚿',
      '🛁',
      '🚽',
      '🧹',
      '🧺',
      '🧴',
      '🧻',
      '🕯️',
      '💡',
      '🔦',
      '🪔',
    ],
    'Sports & Fitness': [
      '⚽',
      '🏀',
      '🏈',
      '⚾',
      '🎾',
      '🏐',
      '🏉',
      '🎱',
      '🏓',
      '🏸',
      '🥊',
      '🥋',
      '⛳',
      '🏹',
      '🎣',
      '🤿',
      '🥇',
      '🥈',
      '🥉',
      '🏆',
      '🎯',
      '🛹',
      '🛼',
      '⛸️',
    ],
    'Beauty & Health': [
      '💄',
      '💅',
      '💋',
      '👄',
      '🦷',
      '👁️',
      '👃',
      '💆',
      '💇',
      '🧖',
      '💊',
      '💉',
      '🩺',
      '🩹',
      '🧴',
      '🧼',
      '🧽',
      '🧻',
    ],
    'Office & Stationery': [
      '📝',
      '📚',
      '📖',
      '📓',
      '📔',
      '📒',
      '📕',
      '📗',
      '📘',
      '📙',
      '📄',
      '📃',
      '📋',
      '📊',
      '📈',
      '📉',
      '🗂️',
      '📁',
      '📂',
      '🗃️',
      '✂️',
      '📌',
      '📍',
      '✏️',
      '✒️',
      '🖊️',
      '🖋️',
      '🖍️',
      '📏',
      '📐',
    ],
    'Tools & Hardware': [
      '🔧',
      '🔨',
      '⚒️',
      '🛠️',
      '⛏️',
      '🪛',
      '🔩',
      '⚙️',
      '🪚',
      '🔗',
      '⛓️',
      '🧰',
    ],
    'Vehicles & Transport': [
      '🚗',
      '🚕',
      '🚙',
      '🚌',
      '🚎',
      '🏎️',
      '🚓',
      '🚑',
      '🚒',
      '🚐',
      '🛻',
      '🚚',
      '🚛',
      '🚜',
      '🛵',
      '🏍️',
      '🚲',
      '🛴',
      '✈️',
      '🚁',
      '🚂',
      '🚆',
      '🚇',
      '🚊',
    ],
    'Gifts & Events': [
      '🎁',
      '🎈',
      '🎉',
      '🎊',
      '🎀',
      '🎂',
      '🎄',
      '🎃',
      '🎆',
      '🎇',
      '✨',
      '🎋',
      '🎍',
      '🎎',
      '🎏',
      '🎐',
      '🎑',
    ],
    'Nature & Plants': [
      '🌸',
      '🌺',
      '🌻',
      '🌷',
      '🌹',
      '🥀',
      '🌾',
      '🌿',
      '☘️',
      '🍀',
      '🍁',
      '🍂',
      '🍃',
      '🌱',
      '🌲',
      '🌳',
      '🌴',
      '🌵',
      '🌾',
      '🌿',
      '🎋',
      '🎍',
    ],
    'Animals & Pets': [
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐻',
      '🐼',
      '🐨',
      '🐯',
      '🦁',
      '🐮',
      '🐷',
      '🐸',
      '🐵',
      '🐔',
      '🐧',
      '🐦',
      '🐤',
      '🦆',
      '🦅',
      '🦉',
      '🦇',
      '🐺',
    ],
    'Books & Education': [
      '📚',
      '📖',
      '📕',
      '📗',
      '📘',
      '📙',
      '📓',
      '📔',
      '📒',
      '📝',
      '🎓',
      '🎒',
      '🖊️',
      '✏️',
      '📏',
      '📐',
      '🔬',
      '🔭',
      '🧪',
      '🧬',
    ],
    'Music & Entertainment': [
      '🎵',
      '🎶',
      '🎼',
      '🎹',
      '🎸',
      '🎺',
      '🎷',
      '🥁',
      '🎤',
      '🎧',
      '📻',
      '🎬',
      '🎭',
      '🎪',
      '🎨',
      '🖼️',
      '🎯',
      '🎲',
      '🎰',
      '🃏',
    ],
  };

  @override
  void initState() {
    super.initState();

    // If editing, populate form with existing data
    if (widget.category != null) {
      final category = widget.category!;
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
      _iconController.text = category.icon;
      _selectedColor = category.color;
      _sortOrder = category.sortOrder;
      _isActive = category.isActive;
    }
    // For new categories, leave icon empty - backend will apply default 📦 if not provided
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g., Birthday Cakes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Name must be less than 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Icon Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _iconController,
                    decoration: const InputDecoration(
                      labelText: 'Icon (Emoji) - Optional',
                      hintText: 'Choose an emoji or leave empty',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.emoji_emotions),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose an emoji:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Category dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedEmojiCategory,
                          underline: const SizedBox(),
                          isDense: true,
                          items: _emojiCategories.keys.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedEmojiCategory = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _emojiCategories[_selectedEmojiCategory]!.map(
                          (emoji) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _iconController.text = emoji;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _iconController.text == emoji
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: You can also type or paste any emoji in the field above',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Color Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color *',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colorOptions.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(color.substring(1), radix: 16) +
                                  0xFF000000,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description of the category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 16),

              // Sort Order
              TextFormField(
                initialValue: _sortOrder.toString(),
                decoration: const InputDecoration(
                  labelText: 'Sort Order',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sort),
                  helperText: 'Lower numbers appear first',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _sortOrder = int.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),

              // Active Switch
              SwitchListTile(
                title: const Text('Active'),
                subtitle: Text(
                  _isActive
                      ? 'Category is visible to users'
                      : 'Category is hidden',
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
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
              : Text(widget.category == null ? 'Create' : 'Update'),
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
      final userId = ref.read(requireUserIdProvider);

      // Create Category object
      final category = Category(
        id: widget.category?.id ?? '', // Will be generated by backend
        userId: userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        icon: _iconController.text.trim(), // Can be empty
        color: _selectedColor,
        isActive: _isActive,
        sortOrder: _sortOrder,
        createdAt: widget.category?.createdAt,
        updatedAt: widget.category?.updatedAt,
      );

      final categoryNotifier = ref.read(categoriesProvider.notifier);

      if (widget.category == null) {
        // Create new category
        await categoryNotifier.addCategory(category);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Category "${category.name}" created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing category
        await categoryNotifier.updateCategory(
          widget.category!.id,
          category.toJson(),
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Category "${category.name}" updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
