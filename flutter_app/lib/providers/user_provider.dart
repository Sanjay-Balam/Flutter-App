import 'package:flutter_riverpod/flutter_riverpod.dart';

// Current user ID provider (atom-like state)
// Using the userId from your MenuItems data: 688722a1574e0612934de3a0
final currentUserIdProvider = StateProvider<String?>((ref) {
  // You can initialize this with your actual user ID
  // In a real app, this would come from authentication
  return '688722a1574e0612934de3a0';
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
