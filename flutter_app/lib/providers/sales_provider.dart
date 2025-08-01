import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale_record.dart';
import '../models/menu_item.dart';
import '../services/sales_api_service.dart';
import 'user_provider.dart';

// Sales API Service provider
final salesApiServiceProvider = Provider<SalesApiService>((ref) {
  return SalesApiService();
});

// Sales state notifier for efficient state management
class SalesNotifier extends AsyncNotifier<List<SaleRecord>> {
  SalesApiService get _salesApiService => ref.read(salesApiServiceProvider);

  @override
  Future<List<SaleRecord>> build() async {
    // Get current user ID
    final userId = ref.watch(requireUserIdProvider);

    // Fetch sales from API
    return await _salesApiService.getSalesByUserId(userId);
  }

  // Refresh sales
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(requireUserIdProvider);
      final sales = await _salesApiService.getSalesByUserId(userId);
      state = AsyncValue.data(sales);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add a new sale
  Future<void> addSale({
    required MenuItem menuItem,
    required ItemSize size,
    required int quantity,
    String? notes,
  }) async {
    try {
      final userId = ref.read(requireUserIdProvider);

      final newSale = await _salesApiService.createSale(
        menuItem: menuItem,
        size: size,
        quantity: quantity,
        userId: userId,
        notes: notes,
      );

      // Update state optimistically
      state.whenData((currentSales) {
        state = AsyncValue.data([newSale, ...currentSales]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Remove a sale
  Future<void> removeSale(String saleId) async {
    try {
      await _salesApiService.deleteSale(saleId);

      // Update state optimistically
      state.whenData((currentSales) {
        final updatedSales = currentSales
            .where((sale) => sale.id != saleId)
            .toList();
        state = AsyncValue.data(updatedSales);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Main sales provider (async)
final salesProvider = AsyncNotifierProvider<SalesNotifier, List<SaleRecord>>(
  () {
    return SalesNotifier();
  },
);

// Legacy provider for backward compatibility
final salesRepositoryProvider = Provider<AsyncValue<List<SaleRecord>>>((ref) {
  return ref.watch(salesProvider);
});

// Derived providers (Atomic approach - each provider focuses on specific data)

// Today's sales
final todaysSalesProvider = Provider<AsyncValue<List<SaleRecord>>>((ref) {
  final salesAsync = ref.watch(salesProvider);
  return salesAsync.when(
    data: (sales) {
      final today = DateTime.now();
      final todaysSales = sales.where((sale) {
        return sale.timestamp.year == today.year &&
            sale.timestamp.month == today.month &&
            sale.timestamp.day == today.day;
      }).toList();
      return AsyncValue.data(todaysSales);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Today's revenue
final todaysRevenueProvider = Provider<double>((ref) {
  final todaysSalesAsync = ref.watch(todaysSalesProvider);
  return todaysSalesAsync.when(
    data: (todaysSales) =>
        todaysSales.fold(0.0, (sum, sale) => sum + sale.totalAmount),
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});

// This week's sales
final thisWeekSalesProvider = Provider<AsyncValue<List<SaleRecord>>>((ref) {
  final salesAsync = ref.watch(salesProvider);
  return salesAsync.when(
    data: (sales) {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final thisWeekSales = sales.where((sale) {
        return sale.timestamp.isAfter(
              weekStart.subtract(const Duration(days: 1)),
            ) &&
            sale.timestamp.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();
      return AsyncValue.data(thisWeekSales);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// This month's sales
final thisMonthSalesProvider = Provider<AsyncValue<List<SaleRecord>>>((ref) {
  final salesAsync = ref.watch(salesProvider);
  return salesAsync.when(
    data: (sales) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      final thisMonthSales = sales.where((sale) {
        return sale.timestamp.isAfter(
              monthStart.subtract(const Duration(days: 1)),
            ) &&
            sale.timestamp.isBefore(monthEnd.add(const Duration(days: 1)));
      }).toList();
      return AsyncValue.data(thisMonthSales);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// This year's sales
final thisYearSalesProvider = Provider<AsyncValue<List<SaleRecord>>>((ref) {
  final salesAsync = ref.watch(salesProvider);
  return salesAsync.when(
    data: (sales) {
      final now = DateTime.now();
      final yearStart = DateTime(now.year, 1, 1);
      final yearEnd = DateTime(now.year, 12, 31);
      final thisYearSales = sales.where((sale) {
        return sale.timestamp.isAfter(
              yearStart.subtract(const Duration(days: 1)),
            ) &&
            sale.timestamp.isBefore(yearEnd.add(const Duration(days: 1)));
      }).toList();
      return AsyncValue.data(thisYearSales);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Top selling items
final topSellingItemsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final salesAsync = ref.watch(salesProvider);
  return salesAsync.when(
    data: (sales) {
      final Map<String, int> itemCounts = {};
      for (final sale in sales) {
        itemCounts[sale.itemName] =
            (itemCounts[sale.itemName] ?? 0) + sale.quantity;
      }
      return AsyncValue.data(itemCounts);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Total revenue
final totalRevenueProvider = Provider<double>((ref) {
  final salesAsync = ref.watch(salesProvider);
  return salesAsync.when(
    data: (sales) => sales.fold(0.0, (sum, sale) => sum + sale.totalAmount),
    loading: () => 0.0,
    error: (error, stackTrace) => 0.0,
  );
});
