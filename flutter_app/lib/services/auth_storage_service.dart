import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';

/// Service for securely storing authentication data
class AuthStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  /// Save authentication data
  Future<bool> saveAuthData(String token, AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      return true;
    } catch (e) {
      print('Error saving auth data: $e');
      return false;
    }
  }

  /// Get stored token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  /// Get stored user
  Future<AuthUser?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson == null) return null;
      
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return AuthUser.fromJson(userData);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all authentication data
  Future<bool> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      return true;
    } catch (e) {
      print('Error clearing auth data: $e');
      return false;
    }
  }

  /// Update stored user data
  Future<bool> updateUser(AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }
}

