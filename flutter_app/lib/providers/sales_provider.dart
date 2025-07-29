import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/sale_record.dart';
import '../models/menu_item.dart';

const _uuid = Uuid();

// Sales Repository - manages all sales data
class SalesRepository {
  List<SaleRecord> _sales = [];

  List<SaleRecord> get allSales => List.unmodifiable(_sales);

  void addSale(SaleRecord sale) {
    _sales.add(sale);
  }

  void removeSale(String saleId) {
    _sales.removeWhere((sale) => sale.id == saleId);
  }

  List<SaleRecord> getSalesByDate(DateTime date) {
    return _sales.where((sale) {
      return sale.timestamp.year == date.year &&
          sale.timestamp.month == date.month &&
          sale.timestamp.day == date.day;
    }).toList();
  }

  List<SaleRecord> getSalesByDateRange(DateTime start, DateTime end) {
    return _sales.where((sale) {
      return sale.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          sale.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  double getTotalRevenue() {
    return _sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  double getTotalRevenueByDate(DateTime date) {
    return getSalesByDate(
      date,
    ).fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  double getTotalRevenueByDateRange(DateTime start, DateTime end) {
    return getSalesByDateRange(
      start,
      end,
    ).fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  Map<String, int> getItemSalesCount() {
    final Map<String, int> itemCounts = {};
    for (final sale in _sales) {
      itemCounts[sale.itemName] =
          (itemCounts[sale.itemName] ?? 0) + sale.quantity;
    }
    return itemCounts;
  }
}

// Main sales repository provider
final salesRepositoryProvider =
    StateNotifierProvider<SalesNotifier, SalesRepository>((ref) {
      return SalesNotifier();
    });

class SalesNotifier extends StateNotifier<SalesRepository> {
  SalesNotifier() : super(SalesRepository());

  // Add a new sale
  void addSale({
    required MenuItem menuItem,
    required ItemSize size,
    required int quantity,
    String? notes,
  }) {
    final sale = SaleRecord.fromMenuItem(
      id: _uuid.v4(),
      menuItem: menuItem,
      size: size,
      quantity: quantity,
      timestamp: DateTime.now(),
      notes: notes,
    );

    state.addSale(sale);
    // Trigger rebuild by creating new state
    state = SalesRepository().._sales = List.from(state.allSales);
  }

  // Remove a sale
  void removeSale(String saleId) {
    state.removeSale(saleId);
    state = SalesRepository().._sales = List.from(state.allSales);
  }
}

// Derived providers (Atomic approach - each provider focuses on specific data)

// Today's sales
final todaysSalesProvider = Provider<List<SaleRecord>>((ref) {
  final salesRepo = ref.watch(salesRepositoryProvider);
  final today = DateTime.now();
  return salesRepo.getSalesByDate(today);
});

// Today's revenue
final todaysRevenueProvider = Provider<double>((ref) {
  final todaysSales = ref.watch(todaysSalesProvider);
  return todaysSales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
});

// This week's sales
final thisWeekSalesProvider = Provider<List<SaleRecord>>((ref) {
  final salesRepo = ref.watch(salesRepositoryProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  return salesRepo.getSalesByDateRange(weekStart, weekEnd);
});

// This month's sales
final thisMonthSalesProvider = Provider<List<SaleRecord>>((ref) {
  final salesRepo = ref.watch(salesRepositoryProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);
  return salesRepo.getSalesByDateRange(monthStart, monthEnd);
});

// This year's sales
final thisYearSalesProvider = Provider<List<SaleRecord>>((ref) {
  final salesRepo = ref.watch(salesRepositoryProvider);
  final now = DateTime.now();
  final yearStart = DateTime(now.year, 1, 1);
  final yearEnd = DateTime(now.year, 12, 31);
  return salesRepo.getSalesByDateRange(yearStart, yearEnd);
});

// Top selling items
final topSellingItemsProvider = Provider<Map<String, int>>((ref) {
  final salesRepo = ref.watch(salesRepositoryProvider);
  return salesRepo.getItemSalesCount();
});

// Total revenue
final totalRevenueProvider = Provider<double>((ref) {
  final salesRepo = ref.watch(salesRepositoryProvider);
  return salesRepo.getTotalRevenue();
});
