import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage_service.dart';
import '../config/app_config.dart';

/// HTTP Client service with automatic auth token injection
class HttpClientService {
  final AuthStorageService _authStorage = AuthStorageService();

  /// Get headers with optional auth token
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = Map<String, String>.from(AppConfig.defaultHeaders);
    
    if (includeAuth) {
      final token = await _authStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  /// GET request with auth
  Future<http.Response> get(
    String url, {
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    return http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(
      timeout ?? Duration(seconds: AppConfig.apiTimeoutSeconds),
    );
  }

  /// POST request with auth
  Future<http.Response> post(
    String url, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    return http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(
      timeout ?? Duration(seconds: AppConfig.apiTimeoutSeconds),
    );
  }

  /// PUT request with auth
  Future<http.Response> put(
    String url, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    return http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(
      timeout ?? Duration(seconds: AppConfig.apiTimeoutSeconds),
    );
  }

  /// DELETE request with auth
  Future<http.Response> delete(
    String url, {
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    return http.delete(
      Uri.parse(url),
      headers: headers,
    ).timeout(
      timeout ?? Duration(seconds: AppConfig.apiTimeoutSeconds),
    );
  }

  /// PATCH request with auth
  Future<http.Response> patch(
    String url, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
    Duration? timeout,
  }) async {
    final headers = await getHeaders(includeAuth: includeAuth);
    return http.patch(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(
      timeout ?? Duration(seconds: AppConfig.apiTimeoutSeconds),
    );
  }
}

