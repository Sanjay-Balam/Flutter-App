/// Centralized configuration for the Flutter app
/// This file contains all app-wide constants and settings
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // ==========================================================================
  // API Configuration
  // ==========================================================================

  /// Base URL for the backend API
  /// Switch between local and deployed backend
  static const String baseUrl = 'https://flutter-app-1o90.onrender.com';
  // Local development: 'http://localhost:3000'

  /// Database name used in API endpoints
  static const String database = 'DemoDB';

  /// API timeout duration in seconds
  static const int apiTimeoutSeconds = 30;

  /// Maximum retry attempts for failed API calls
  static const int maxRetryAttempts = 3;

  // ==========================================================================
  // User Configuration
  // ==========================================================================

  /// Default user ID for demo purposes
  /// TODO: Replace with actual authentication system
  static const String defaultUserId = '688722a1574e0612934de3a0';

  // ==========================================================================
  // Pagination Configuration
  // ==========================================================================

  /// Default page size for API requests
  static const int defaultPageSize = 100;

  /// Maximum page size allowed
  static const int maxPageSize = 1000;

  // ==========================================================================
  // UI Configuration
  // ==========================================================================

  /// Default currency symbol
  static const String currencySymbol = '₹';

  /// Number of decimal places for currency display
  static const int currencyDecimalPlaces = 0;

  /// Default animation duration in milliseconds
  static const int defaultAnimationDuration = 300;

  // ==========================================================================
  // Environment-specific Configuration
  // ==========================================================================

  /// Current environment (development, staging, production)
  static const AppEnvironment environment = AppEnvironment.development;

  /// Enable debug mode (shows debug information)
  static bool get isDebugMode => environment == AppEnvironment.development;

  /// Enable logging
  static bool get isLoggingEnabled => environment != AppEnvironment.production;

  // ==========================================================================
  // Computed Properties
  // ==========================================================================

  /// Full API base URL with database
  static String get apiBaseUrl => '$baseUrl/$database';

  /// Menu Items endpoint base
  static String get menuItemsEndpoint => '$apiBaseUrl/searchresource/MenuItems';

  /// Sale Records endpoint base
  static String get saleRecordsEndpoint =>
      '$apiBaseUrl/searchresource/SaleRecords';

  /// Create resource endpoint template
  static String createResourceEndpoint(String tableName) =>
      '$baseUrl/$database/createresource/$tableName';

  /// Update resource endpoint template
  static String updateResourceEndpoint(String tableName, String id) =>
      '$baseUrl/$database/updateresource/$tableName/$id';

  /// Delete resource endpoint template
  static String deleteResourceEndpoint(String tableName, String id) =>
      '$baseUrl/$database/deleteresource/$tableName/$id';

  /// Search resource endpoint template
  static String searchResourceEndpoint(String tableName) =>
      '$baseUrl/$database/searchresource/$tableName';

  // ==========================================================================
  // HTTP Headers
  // ==========================================================================

  /// Default HTTP headers for API requests
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'BusinessSalesApp/1.0.0',
  };

  // ==========================================================================
  // Feature Flags
  // ==========================================================================

  /// Enable offline mode support
  static const bool enableOfflineMode = false;

  /// Enable analytics tracking
  static const bool enableAnalytics = true;

  /// Enable crash reporting
  static const bool enableCrashReporting =
      environment != AppEnvironment.development;

  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = true;

  // ==========================================================================
  // Business Logic Configuration
  // ==========================================================================

  /// Minimum quantity for sale items
  static const int minSaleQuantity = 1;

  /// Maximum quantity for sale items
  static const int maxSaleQuantity = 999;

  /// Maximum length for item names
  static const int maxItemNameLength = 100;

  /// Maximum length for sale notes
  static const int maxSaleNotesLength = 500;

  // ==========================================================================
  // Validation Methods
  // ==========================================================================

  /// Validate if the current configuration is valid
  static bool isConfigValid() {
    return baseUrl.isNotEmpty &&
        database.isNotEmpty &&
        defaultUserId.isNotEmpty;
  }

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'baseUrl': baseUrl,
      'database': database,
      'environment': environment.name,
      'isDebugMode': isDebugMode,
      'isLoggingEnabled': isLoggingEnabled,
      'defaultUserId': defaultUserId,
    };
  }
}

/// Available application environments
enum AppEnvironment {
  development,
  staging,
  production;

  /// Get human-readable name
  String get displayName {
    switch (this) {
      case AppEnvironment.development:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }
}

/// Environment-specific configurations
class EnvironmentConfig {
  static const Map<AppEnvironment, Map<String, dynamic>> _configs = {
    AppEnvironment.development: {
      'baseUrl': 'http://localhost:3000',
      'database': 'DemoDB',
      'enableLogging': true,
      'enableDebugMode': true,
    },
    AppEnvironment.staging: {
      'baseUrl': 'https://business-sales-backend-staging.onrender.com',
      'database': 'DemoDB',
      'enableLogging': true,
      'enableDebugMode': false,
    },
    AppEnvironment.production: {
      'baseUrl': 'https://business-sales-backend.onrender.com',
      'database': 'DemoDB',
      'enableLogging': false,
      'enableDebugMode': false,
    },
  };

  /// Get configuration for specific environment
  static Map<String, dynamic>? getConfig(AppEnvironment env) {
    return _configs[env];
  }
}
