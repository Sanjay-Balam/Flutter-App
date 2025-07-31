import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  static const String database = 'DemoDB';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Fetch all menu items for a specific user
  Future<List<MenuItem>> getMenuItemsByUserId(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/$database/searchresource/MenuItems');

      // Create search body to filter by userId
      final requestBody = {
        'filter': {
          'userId': userId,
          'isAvailable': true, // Only fetch available items
        },
        'sort': {'category': 1, 'name': 1},
        'pageSize': 100, // Get all items (adjust as needed)
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> menuItemsJson = responseData['data'];

          return menuItemsJson.map((json) => MenuItem.fromJson(json)).toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch menu items: $e');
    }
  }

  /// Fetch menu items by category and userId
  Future<List<MenuItem>> getMenuItemsByCategory(
    String userId,
    MenuCategory category,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/$database/searchresource/MenuItems');

      final requestBody = {
        'filter': {
          'userId': userId,
          'category': category.name,
          'isAvailable': true,
        },
        'sort': {'name': 1},
        'pageSize': 50,
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> menuItemsJson = responseData['data'];

          return menuItemsJson.map((json) => MenuItem.fromJson(json)).toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch menu items by category: $e');
    }
  }

  /// Get a single menu item by ID
  Future<MenuItem?> getMenuItemById(String itemId) async {
    try {
      final url = Uri.parse('$baseUrl/$database/getresource/MenuItems/$itemId');

      final response = await _client.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return MenuItem.fromJson(responseData['data']);
        }
      } else if (response.statusCode == 404) {
        return null; // Item not found
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch menu item: $e');
    }
    return null;
  }

  /// Create a new menu item
  Future<MenuItem> createMenuItem(MenuItem menuItem) async {
    try {
      final url = Uri.parse('$baseUrl/$database/createresource/MenuItems');

      final requestBody = menuItem.toJson();
      // Remove id field for creation as backend generates _id
      requestBody.remove('_id');

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return MenuItem.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create menu item: $e');
    }
  }

  /// Update an existing menu item
  Future<MenuItem> updateMenuItem(String itemId, MenuItem menuItem) async {
    try {
      final url = Uri.parse(
        '$baseUrl/$database/updateresource/MenuItems/$itemId',
      );

      final requestBody = menuItem.toJson();
      // Remove fields that shouldn't be updated
      requestBody.remove('_id');
      requestBody.remove('createdAt');
      requestBody.remove('updatedAt');

      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return MenuItem.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update menu item: $e');
    }
  }

  /// Delete a menu item
  Future<bool> deleteMenuItem(String itemId) async {
    try {
      final url = Uri.parse(
        '$baseUrl/$database/deleteresource/MenuItems/$itemId',
      );

      final response = await _client.delete(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete menu item: $e');
    }
  }

  /// Dispose method for cleanup
  void dispose() {
    _client.close();
  }
}
