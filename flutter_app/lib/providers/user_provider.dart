import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/user_api_service.dart';
import '../config/app_config.dart';

// User API Service provider
final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService();
});

// Current user data provider (fetches from API)
class CurrentUserNotifier extends AsyncNotifier<User> {
  UserApiService get _userApiService => ref.read(userApiServiceProvider);

  @override
  Future<User> build() async {
    // Fetch user from API using the default user ID from config
    return await _userApiService.getUserById(AppConfig.defaultUserId);
  }

  // Refresh user data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final user = await _userApiService.getUserById(AppConfig.defaultUserId);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update user data
  Future<void> updateUser(Map<String, dynamic> updates) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) throw Exception('No user loaded');

      final updatedUser = await _userApiService.updateUser(
        currentUser.id,
        updates,
      );

      state = AsyncValue.data(updatedUser);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Main current user provider (async)
final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, User>(
  () {
    return CurrentUserNotifier();
  },
);

// User ID provider (derived from current user)
final currentUserIdProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user.id,
    loading: () => null,
    error: (_, __) => null,
  );
});

// User authentication state provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return userId != null;
});

// Helper provider to get current user ID (throws if not authenticated)
final requireUserIdProvider = Provider<String>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  return userId;
});

// Helper provider to get current user (throws if not authenticated)
final requireUserProvider = Provider<User>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user,
    loading: () => throw Exception('User loading...'),
    error: (error, _) => throw Exception('Failed to load user: $error'),
  );
});
