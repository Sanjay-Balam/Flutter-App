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

  /// Create a new sale record
  Future<SaleRecord> createSale({
    required MenuItem menuItem,
    required ItemSize size,
    required int quantity,
    required String userId,
    String? notes,
  }) async {
    try {
      final url = Uri.parse(AppConfig.createResourceEndpoint('SaleRecords'));

      final unitPrice = menuItem.getPriceBySize(size);
      final totalAmount = unitPrice * quantity;
      final timestamp = DateTime.now();

      final requestBody = {
        'menuItemId': menuItem.id,
        'userId': userId,
        'itemName': menuItem.name,
        'category': menuItem.category.name,
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
          return SaleRecord.fromJson(responseData['data']);
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
