import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/app_config.dart';

class UserApiService {
  // Singleton pattern
  static final UserApiService _instance = UserApiService._internal();
  factory UserApiService() => _instance;
  UserApiService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Headers for API requests - using centralized config
  Map<String, String> get _headers => AppConfig.defaultHeaders;

  /// Fetch user by ID
  Future<User> getUserById(String userId) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/searchresource/Users/$userId',
      );

      final response = await _client.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return User.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('User not found with ID: $userId');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Search for users (typically used for admin functions)
  Future<List<User>> searchUsers({
    Map<String, dynamic>? filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/searchresource/Users',
      );

      final requestBody = {
        if (filter != null) 'filter': filter,
        'sort': {'firstName': 1, 'lastName': 1},
        'pageSize': pageSize,
        'page': page,
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> usersJson = responseData['data'];
          return usersJson.map((json) => User.fromJson(json)).toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Update user profile
  Future<User> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final url = Uri.parse(
        '${AppConfig.baseUrl}/${AppConfig.database}/updateresource/Users/$userId',
      );

      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return User.fromJson(responseData['data']);
        } else {
          throw Exception(
            'API returned error: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Dispose method for cleanup
  void dispose() {
    _client.close();
  }
}
