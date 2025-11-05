import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_user.dart';
import '../services/auth_api_service.dart';
import '../services/auth_storage_service.dart';

/// Authentication state
class AuthState {
  final AuthUser? user;
  final String? token;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    AuthUser? user,
    String? token,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  /// Create logged out state
  factory AuthState.loggedOut() {
    return const AuthState(
      user: null,
      token: null,
      isLoading: false,
      error: null,
      isAuthenticated: false,
    );
  }

  /// Create logged in state
  factory AuthState.loggedIn(AuthUser user, String token) {
    return AuthState(
      user: user,
      token: token,
      isLoading: false,
      error: null,
      isAuthenticated: true,
    );
  }
}

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _apiService;
  final AuthStorageService _storageService;

  AuthNotifier({
    required AuthApiService apiService,
    required AuthStorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(const AuthState(isLoading: true)) {
    // Check for existing auth on initialization
    _checkExistingAuth();
  }

  /// Check if user is already authenticated
  Future<void> _checkExistingAuth() async {
    try {
      final token = await _storageService.getToken();
      final user = await _storageService.getUser();

      if (token != null && user != null) {
        // Verify token is still valid
        final isValid = await _apiService.verifyToken(token);
        if (isValid) {
          state = AuthState.loggedIn(user, token);
          return;
        }
      }

      // No valid auth found
      state = AuthState.loggedOut();
    } catch (e) {
      print('Error checking existing auth: $e');
      state = AuthState.loggedOut();
    }
  }

  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final authResponse = await _apiService.login(
        email: email,
        password: password,
      );

      // Save auth data
      await _storageService.saveAuthData(authResponse.token, authResponse.user);

      state = AuthState.loggedIn(authResponse.user, authResponse.token);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? businessName,
    String role = 'owner',
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final authResponse = await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        businessName: businessName,
        role: role,
      );

      // Save auth data
      await _storageService.saveAuthData(authResponse.token, authResponse.user);

      state = AuthState.loggedIn(authResponse.user, authResponse.token);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _storageService.clearAuthData();
    state = AuthState.loggedOut();
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    try {
      if (state.token == null) return;

      final user = await _apiService.getProfile(state.token!);
      await _storageService.updateUser(user);
      
      state = state.copyWith(user: user);
    } catch (e) {
      print('Error refreshing profile: $e');
      // If token is invalid, logout
      if (e.toString().contains('Invalid or expired token')) {
        await logout();
      }
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider instances
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

final authStorageServiceProvider = Provider<AuthStorageService>((ref) {
  return AuthStorageService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    apiService: ref.watch(authApiServiceProvider),
    storageService: ref.watch(authStorageServiceProvider),
  );
});

/// Computed providers for easy access
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authProvider).user;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).token;
});

