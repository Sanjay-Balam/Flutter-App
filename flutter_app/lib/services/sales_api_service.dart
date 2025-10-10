import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sale_record.dart';
import '../models/menu_item.dart';
import '../config/app_config.dart';

class SalesApiService {
  // Singleton pattern
  static final SalesApiService _instance = SalesApiService._internal();
  factory SalesApiService() => _instance;
  SalesApiService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Headers for API requests - using centralized config
  Map<String, String> get _headers => AppConfig.defaultHeaders;

  /// Create a new sale record (with stock validation and update)
  Future<SaleRecord> createSale({
    required MenuItem menuItem,
    required String categoryName, // Category name must be provided
    required ItemSize size,
    required int quantity,
    required String userId,
    String? notes,
  }) async {
    try {
      // Step 1: Validate stock if item is being tracked
      if (menuItem.isTrackingStock) {
        if (!menuItem.canSellQuantity(quantity)) {
          throw Exception(
            'Insufficient stock for ${menuItem.name}. Available: ${menuItem.currentStock}, Requested: $quantity',
          );
        }
      }

      // Step 2: Create the sale record
      final url = Uri.parse(AppConfig.createResourceEndpoint('SaleRecords'));

      final unitPrice = menuItem.getPriceBySize(size);
      final totalAmount = unitPrice * quantity;
      final timestamp = DateTime.now();

      final requestBody = {
        'menuItemId': menuItem.id,
        'userId': userId,
        'itemName': menuItem.name,
        'categoryId': menuItem.categoryId,
        'categoryName': categoryName,
        'size': size.name,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'totalAmount': totalAmount,
        'timestamp': timestamp.toIso8601String(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final sale = SaleRecord.fromJson(responseData['data']);

          // Step 3: Update stock if tracking is enabled
          if (menuItem.isTrackingStock) {
            await _updateStockAfterSale(
              menuItemId: menuItem.id,
              quantity: quantity,
              userId: userId,
              saleId: sale.id,
              itemName: menuItem.name,
            );
          }

          return sale;
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create sale: $e');
    }
  }

  /// Helper method to update stock after a successful sale
  Future<void> _updateStockAfterSale({
    required String menuItemId,
    required int quantity,
    required String userId,
    required String saleId,
    required String itemName,
  }) async {
    try {
      // Step 1: Get current menu item
      final getUrl = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/getresource/MenuItems/$menuItemId',
      );

      final getResponse = await _client.get(getUrl, headers: _headers);
      if (getResponse.statusCode != 200) {
        print('Warning: Failed to fetch menu item for stock update');
        return;
      }

      final menuItemData = jsonDecode(getResponse.body);
      if (menuItemData['success'] != true) {
        print('Warning: Failed to fetch menu item data');
        return;
      }

      final previousQuantity = menuItemData['data']['stockQuantity'] ?? 0;
      final newQuantity = previousQuantity - quantity;

      // Step 2: Update MenuItem stock using PATCH
      final patchUrl = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/updateresource/MenuItems/$menuItemId',
      );

      final patchResponse = await _client.patch(
        patchUrl,
        headers: _headers,
        body: jsonEncode({'stockQuantity': newQuantity}),
      );

      if (patchResponse.statusCode != 200) {
        print('Warning: Failed to update stock quantity');
        return;
      }

      // Step 3: Create StockHistory record
      final historyUrl = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/createresource/StockHistory',
      );

      final historyBody = {
        'menuItemId': menuItemId,
        'userId': userId,
        'movementType': 'SALE',
        'quantityChange': -quantity,
        'previousQuantity': previousQuantity,
        'newQuantity': newQuantity,
        'reason': 'Sale of $quantity unit(s)',
        'saleId': saleId,
      };

      await _client.post(
        historyUrl,
        headers: _headers,
        body: jsonEncode(historyBody),
      );
    } catch (e) {
      // Log but don't fail the sale
      print('Warning: Failed to update stock history: $e');
    }
  }

  /// Fetch all sales for a specific user
  Future<List<SaleRecord>> getSalesByUserId(String userId) async {
    try {
      final url = Uri.parse(AppConfig.searchResourceEndpoint('SaleRecords'));

      final requestBody = {
        'filter': {'userId': userId},
        'sort': {
          'timestamp': -1, // Latest first
        },
        'pageSize': 1000, // Get all sales (adjust as needed)
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> salesJson = responseData['data'];

          return salesJson.map((json) => SaleRecord.fromJson(json)).toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch sales: $e');
    }
  }

  /// Fetch sales by date range
  Future<List<SaleRecord>> getSalesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final url = Uri.parse(AppConfig.searchResourceEndpoint('SaleRecords'));

      final requestBody = {
        'filter': {
          'userId': userId,
          'timestamp': {
            '\$gte': startDate.toIso8601String(),
            '\$lte': endDate.toIso8601String(),
          },
        },
        'sort': {'timestamp': -1},
        'pageSize': 1000,
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> salesJson = responseData['data'];

          return salesJson.map((json) => SaleRecord.fromJson(json)).toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch sales by date range: $e');
    }
  }

  /// Fetch today's sales
  Future<List<SaleRecord>> getTodaysSales(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getSalesByDateRange(
      userId: userId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Fetch this week's sales
  Future<List<SaleRecord>> getThisWeekSales(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    return getSalesByDateRange(
      userId: userId,
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
  }

  /// Fetch this month's sales
  Future<List<SaleRecord>> getThisMonthSales(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return getSalesByDateRange(
      userId: userId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  /// Get sales by menu item ID
  Future<List<SaleRecord>> getSalesByMenuItemId({
    required String userId,
    required String menuItemId,
  }) async {
    try {
      final url = Uri.parse(AppConfig.searchResourceEndpoint('SaleRecords'));

      final requestBody = {
        'filter': {'userId': userId, 'menuItemId': menuItemId},
        'sort': {'timestamp': -1},
        'pageSize': 500,
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> salesJson = responseData['data'];

          return salesJson.map((json) => SaleRecord.fromJson(json)).toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch sales by menu item: $e');
    }
  }

  /// Delete a sale record
  Future<bool> deleteSale(String saleId) async {
    try {
      final url = Uri.parse(
        AppConfig.deleteResourceEndpoint('SaleRecords', saleId),
      );

      final response = await _client.delete(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete sale: $e');
    }
  }

  /// Dispose method for cleanup
  void dispose() {
    _client.close();
  }
}
