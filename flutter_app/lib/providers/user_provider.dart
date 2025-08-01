import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

// Current user ID provider (atom-like state)
// Using the default userId from centralized configuration
final currentUserIdProvider = StateProvider<String?>((ref) {
  // Initialize with default user ID from config
  // In a real app, this would come from authentication
  return AppConfig.defaultUserId;
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
