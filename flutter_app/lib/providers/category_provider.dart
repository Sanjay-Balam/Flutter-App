import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/category_api_service.dart';
import 'user_provider.dart';

// Category API Service provider
final categoryApiServiceProvider = Provider<CategoryApiService>((ref) {
  return CategoryApiService();
});

// Categories state notifier for efficient state management
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  CategoryApiService get _categoryApiService =>
      ref.read(categoryApiServiceProvider);

  @override
  Future<List<Category>> build() async {
    // Get current user ID
    final userId = ref.watch(requireUserIdProvider);

    // Fetch categories from API
    return await _categoryApiService.getCategoriesForUser(userId);
  }

  // Refresh categories
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(requireUserIdProvider);
      final categories = await _categoryApiService.getCategoriesForUser(userId);
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Add a new category
  Future<void> addCategory(Category category) async {
    try {
      final newCategory = await _categoryApiService.createCategory(category);

      // Update state optimistically
      state.whenData((currentCategories) {
        state = AsyncValue.data([...currentCategories, newCategory]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Update an existing category
  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final updatedCategory = await _categoryApiService.updateCategory(
        categoryId,
        updates,
      );

      // Update state optimistically
      state.whenData((currentCategories) {
        final updatedCategories = currentCategories.map((category) {
          return category.id == categoryId ? updatedCategory : category;
        }).toList();
        state = AsyncValue.data(updatedCategories);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoryApiService.deleteCategory(categoryId);

      // Update state optimistically
      state.whenData((currentCategories) {
        final updatedCategories = currentCategories
            .where((category) => category.id != categoryId)
            .toList();
        state = AsyncValue.data(updatedCategories);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Main categories provider (async)
final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
      return CategoriesNotifier();
    });

// Categories with count provider
final categoriesWithCountProvider = FutureProvider<List<CategoryWithCount>>((
  ref,
) async {
  final userId = ref.watch(requireUserIdProvider);
  final categoryApiService = ref.read(categoryApiServiceProvider);
  return await categoryApiService.getCategoriesWithCount(userId);
});

// Single category provider
final categoryProvider = Provider.family<AsyncValue<Category?>, String>((
  ref,
  categoryId,
) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.when(
    data: (categories) {
      try {
        final category = categories.firstWhere(
          (category) => category.id == categoryId,
        );
        return AsyncValue.data(category);
      } catch (e) {
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Active categories provider (filtered by isActive)
final activeCategoriesProvider = Provider<AsyncValue<List<Category>>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.when(
    data: (categories) => AsyncValue.data(
      categories.where((category) => category.isActive).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Total categories count
final totalCategoriesCountProvider = Provider<AsyncValue<int>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.when(
    data: (categories) => AsyncValue.data(categories.length),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Categories loading state
final isCategoriesLoadingProvider = Provider<bool>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.isLoading;
});

// Categories error state
final categoriesErrorProvider = Provider<String?>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.error?.toString();
});
