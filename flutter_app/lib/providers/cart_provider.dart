import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item.dart';
import '../models/transaction.dart';

// Cart item class to track items in the cart
class CartItem {
  final MenuItem menuItem;
  final String categoryName;
  final ItemSize size;
  int quantity;

  CartItem({
    required this.menuItem,
    required this.categoryName,
    required this.size,
    this.quantity = 1,
  });

  double get unitPrice => menuItem.getPriceBySize(size);
  double get subtotal => unitPrice * quantity;

  // Unique identifier for cart item (menuItem + size combination)
  String get uniqueKey => '${menuItem.id}_${size.name}';

  CartItem copyWith({
    MenuItem? menuItem,
    String? categoryName,
    ItemSize? size,
    int? quantity,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      categoryName: categoryName ?? this.categoryName,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
    );
  }

  // Convert to TransactionItem for API
  TransactionItem toTransactionItem() {
    return TransactionItem.fromMenuItem(
      menuItem: menuItem,
      categoryName: categoryName,
      size: size,
      quantity: quantity,
    );
  }
}

// Cart state notifier
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // Add item to cart
  void addItem({
    required MenuItem menuItem,
    required String categoryName,
    required ItemSize size,
    int quantity = 1,
  }) {
    final uniqueKey = '${menuItem.id}_${size.name}';

    // Check if item already exists in cart
    final existingIndex = state.indexWhere(
      (item) => item.uniqueKey == uniqueKey,
    );

    if (existingIndex != -1) {
      // Update quantity if item exists
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + quantity)
          else
            state[i],
      ];
    } else {
      // Add new item
      state = [
        ...state,
        CartItem(
          menuItem: menuItem,
          categoryName: categoryName,
          size: size,
          quantity: quantity,
        ),
      ];
    }
  }

  // Update item quantity
  void updateQuantity(String uniqueKey, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(uniqueKey);
      return;
    }

    state = [
      for (final item in state)
        if (item.uniqueKey == uniqueKey)
          item.copyWith(quantity: newQuantity)
        else
          item,
    ];
  }

  // Remove item from cart
  void removeItem(String uniqueKey) {
    state = state.where((item) => item.uniqueKey != uniqueKey).toList();
  }

  // Clear entire cart
  void clearCart() {
    state = [];
  }

  // Get cart summary
  double getTotalAmount() {
    return state.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int getTotalItems() {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }

  int getUniqueItems() {
    return state.length;
  }

  // Convert cart to list of TransactionItems for API
  List<TransactionItem> toTransactionItems() {
    return state.map((item) => item.toTransactionItem()).toList();
  }
}

// Providers
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

// Computed providers
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.subtotal);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

final cartUniqueItemsProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.length;
});

final isCartEmptyProvider = Provider<bool>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.isEmpty;
});
