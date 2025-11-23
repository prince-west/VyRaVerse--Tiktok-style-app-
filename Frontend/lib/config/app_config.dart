/// App configuration with environment variable support
/// In production, these values should be set via build-time configuration
/// or environment variables
class AppConfig {
  // API Configuration
  // For production, set these via build-time configuration
  // Example: flutter build apk --dart-define=BASE_URL=https://api.yourdomain.com
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );
  
  static const String mediaUrl = String.fromEnvironment(
    'MEDIA_URL',
    defaultValue: 'http://localhost:8000/media',
  );

  // Request timeout in seconds
  static const int requestTimeoutSeconds = 30;

  // Retry configuration
  static const int maxRetries = 3;
  static const int retryDelaySeconds = 2;

  // Environment detection
  static bool get isProduction => baseUrl.contains('https://') && !baseUrl.contains('localhost');
  static bool get isDevelopment => !isProduction;
}

