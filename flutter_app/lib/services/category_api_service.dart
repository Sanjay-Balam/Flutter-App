import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../config/app_config.dart';

class CategoryApiService {
  // Singleton pattern
  static final CategoryApiService _instance = CategoryApiService._internal();
  factory CategoryApiService() => _instance;
  CategoryApiService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Headers for API requests - using centralized config
  Map<String, String> get _headers => AppConfig.defaultHeaders;

  /// Fetch all categories for a specific user using searchresource
  Future<List<Category>> getCategoriesForUser(String userId) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/searchresource/Categories',
      );

      final requestBody = {
        'filter': {'userId': userId, 'isActive': true},
        'sort': {'sortOrder': 1, 'name': 1},
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> categoriesJson = responseData['data'];
          return categoriesJson.map((json) => Category.fromJson(json)).toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Fetch categories with menu item counts using aggregation
  Future<List<CategoryWithCount>> getCategoriesWithCount(String userId) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/aggregatetable/Categories',
      );

      final aggregationPipeline = [
        {
          '\$match': {'userId': userId, 'isActive': true},
        },
        {
          '\$lookup': {
            'from': 'MenuItems',
            'localField': '_id',
            'foreignField': 'categoryId',
            'as': 'menuItems',
          },
        },
        {
          '\$addFields': {
            'menuItemsCount': {'\$size': '\$menuItems'},
          },
        },
        {
          '\$project': {
            'menuItems': 0, // Remove the array, we only need the count
          },
        },
        {
          '\$sort': {'sortOrder': 1, 'name': 1},
        },
      ];

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(aggregationPipeline),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> categoriesJson = responseData['data'];
          return categoriesJson
              .map((json) => CategoryWithCount.fromJson(json))
              .toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch categories with count: $e');
    }
  }

  /// Get a single category by ID
  Future<Category> getCategoryById(String categoryId) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/searchresource/Categories/$categoryId',
      );

      final response = await _client.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return Category.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('Category not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  /// Create a new category
  Future<Category> createCategory(Category category) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/createresource/Categories',
      );

      final requestBody = category.toJson();
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
          return Category.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update an existing category
  Future<Category> updateCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/updateresource/Categories/$categoryId',
      );

      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return Category.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/deleteresource/Categories/$categoryId',
      );

      final response = await _client.delete(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Dispose method for cleanup
  void dispose() {
    _client.close();
  }
}
