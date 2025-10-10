import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/stock_history.dart';
import '../models/menu_item.dart';

class StockApiService {
  static final StockApiService _instance = StockApiService._internal();
  factory StockApiService() => _instance;
  StockApiService._internal();

  final _client = http.Client();
  final Map<String, String> _headers = {'Content-Type': 'application/json'};

  // Update stock for a menu item using standard PATCH and POST
  Future<Map<String, dynamic>> updateStock({
    required String menuItemId,
    required int quantityChange,
    required StockMovementType movementType,
    required String userId,
    String? reason,
    String? performedBy,
    String? saleId,
  }) async {
    try {
      // Step 1: Get current menu item to calculate new stock
      final getUrl = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/getresource/MenuItems/$menuItemId',
      );

      final getResponse = await _client.get(getUrl, headers: _headers);

      if (getResponse.statusCode != 200) {
        return {
          'success': false,
          'error': 'Failed to fetch menu item: ${getResponse.statusCode}',
        };
      }

      final menuItemData = jsonDecode(getResponse.body);
      if (menuItemData['success'] != true) {
        return menuItemData;
      }

      final previousQuantity = menuItemData['data']['stockQuantity'] ?? 0;
      final newQuantity = previousQuantity + quantityChange;

      // Validate new quantity
      if (newQuantity < 0) {
        return {
          'success': false,
          'error':
              'Insufficient stock. Available: $previousQuantity, Requested: ${quantityChange.abs()}',
        };
      }

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
        return {
          'success': false,
          'error': 'Failed to update stock: ${patchResponse.statusCode}',
        };
      }

      // Step 3: Create StockHistory record using POST
      final historyUrl = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/createresource/StockHistory',
      );

      final historyBody = {
        'menuItemId': menuItemId,
        'userId': userId,
        'movementType': movementType.name.toUpperCase(),
        'quantityChange': quantityChange,
        'previousQuantity': previousQuantity,
        'newQuantity': newQuantity,
        if (reason != null) 'reason': reason,
        if (performedBy != null) 'performedBy': performedBy,
        if (saleId != null) 'saleId': saleId,
      };

      final historyResponse = await _client.post(
        historyUrl,
        headers: _headers,
        body: jsonEncode(historyBody),
      );

      if (historyResponse.statusCode != 200) {
        return {
          'success': false,
          'error':
              'Stock updated but failed to record history: ${historyResponse.statusCode}',
        };
      }

      return {
        'success': true,
        'data': {
          'previousQuantity': previousQuantity,
          'newQuantity': newQuantity,
          'menuItem': jsonDecode(patchResponse.body)['data'],
          'stockHistory': jsonDecode(historyResponse.body)['data'],
        },
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Get stock history for a menu item using generic searchresource
  Future<List<StockHistory>> getStockHistory({
    required String menuItemId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/searchresource/StockHistory?page=$page&pageSize=$pageSize',
      );

      final requestBody = {
        'filter': {'menuItemId': menuItemId},
        'sort': {'createdAt': -1},
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List historyList = data['data'] ?? [];
          return historyList
              .map((json) => StockHistory.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching stock history: $e');
      return [];
    }
  }

  // Get low stock items for a user using generic searchresource
  Future<List<MenuItem>> getLowStockItems({required String userId}) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/searchresource/MenuItems',
      );

      final requestBody = {
        'filter': {'userId': userId, 'trackStock': true},
        'sort': {'stockQuantity': 1},
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List itemsList = data['data'] ?? [];
          // Filter in frontend where stockQuantity <= lowStockThreshold
          return itemsList
              .map((json) => MenuItem.fromJson(json))
              .where(
                (item) =>
                    item.isTrackingStock &&
                    item.currentStock <= (item.lowStockThreshold ?? 5),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching low stock items: $e');
      return [];
    }
  }

  // Restock item (convenience method)
  Future<Map<String, dynamic>> restockItem({
    required String menuItemId,
    required int quantity,
    required String userId,
    String? reason,
  }) {
    return updateStock(
      menuItemId: menuItemId,
      quantityChange: quantity,
      movementType: StockMovementType.restock,
      userId: userId,
      reason: reason ?? 'Restocked $quantity units',
    );
  }

  // Adjust stock (convenience method)
  Future<Map<String, dynamic>> adjustStock({
    required String menuItemId,
    required int quantityChange,
    required String userId,
    String? reason,
  }) {
    return updateStock(
      menuItemId: menuItemId,
      quantityChange: quantityChange,
      movementType: StockMovementType.adjustment,
      userId: userId,
      reason: reason ?? 'Manual adjustment',
    );
  }

  // Mark items as damaged/expired
  Future<Map<String, dynamic>> markDamaged({
    required String menuItemId,
    required int quantity,
    required String userId,
    String? reason,
  }) {
    return updateStock(
      menuItemId: menuItemId,
      quantityChange: -quantity,
      movementType: StockMovementType.damage,
      userId: userId,
      reason: reason ?? 'Damaged/expired items',
    );
  }

  // Return items to stock
  Future<Map<String, dynamic>> returnItems({
    required String menuItemId,
    required int quantity,
    required String userId,
    String? saleId,
    String? reason,
  }) {
    return updateStock(
      menuItemId: menuItemId,
      quantityChange: quantity,
      movementType: StockMovementType.returnItem,
      userId: userId,
      saleId: saleId,
      reason: reason ?? 'Customer return',
    );
  }
}
