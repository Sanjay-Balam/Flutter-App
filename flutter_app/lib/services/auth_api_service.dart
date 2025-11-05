import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/auth_user.dart';

/// API Service for authentication operations
class AuthApiService {
  /// Register a new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? businessName,
    String role = 'owner',
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/auth/register');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          if (phone != null) 'phone': phone,
          if (businessName != null) 'businessName': businessName,
          'role': role,
        }),
      ).timeout(Duration(seconds: AppConfig.apiTimeoutSeconds));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true && data['data'] != null) {
          return AuthResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Registration failed');
        }
      } else if (response.statusCode == 409) {
        throw Exception('Email already exists');
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/auth/login');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: AppConfig.apiTimeoutSeconds));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true && data['data'] != null) {
          return AuthResponse.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else if (response.statusCode == 403) {
        throw Exception('Account is deactivated');
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Get current user profile
  Future<AuthUser> getProfile(String token) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/auth/me');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: AppConfig.apiTimeoutSeconds));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true && data['data'] != null) {
          return AuthUser.fromJson(data['data']['user']);
        } else {
          throw Exception(data['message'] ?? 'Failed to get profile');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Invalid or expired token');
      } else {
        throw Exception(data['message'] ?? 'Failed to get profile');
      }
    } catch (e) {
      print('Get profile error: $e');
      rethrow;
    }
  }

  /// Verify token
  Future<bool> verifyToken(String token) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/auth/verify');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'token': token}),
      ).timeout(Duration(seconds: AppConfig.apiTimeoutSeconds));

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('Token verification error: $e');
      return false;
    }
  }
}

