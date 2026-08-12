import '../auth/auth_config.dart';
import '../cache/cache_config.dart';
import '../connectivity/connectivity_policy.dart';
import '../connectivity/connectivity_service.dart';
import '../interceptors/network_interceptor.dart';
import '../logging/network_logger.dart';
import '../offline_queue/offline_queue_config.dart';
import '../retry/retry_policy.dart';
import '../transport/network_transport.dart';

/// Central configuration settings for initializing a [NetworkClient].
class NetworkOptions {
  /// Base host URL (e.g. `https://api.example.com`).
  final String? baseUrl;

  /// Default headers sent with all requests.
  final Map<String, String>? headers;

  /// Default query parameters appended to all request URIs.
  final Map<String, dynamic>? queryParameters;

  /// Connection timeout limit.
  final Duration connectTimeout;

  /// Send timeout limit.
  final Duration sendTimeout;

  /// Receive timeout limit.
  final Duration receiveTimeout;

  /// List of interceptors executed in order.
  final List<NetworkInterceptor> interceptors;

  /// Logging configuration or instance.
  final NetworkLogger? logger;

  /// Underlying network transport engine.
  final NetworkTransport? transport;

  /// Authentication and token refresh configuration.
  final AuthConfig? auth;

  /// Default retry policy configuration for transient errors.
  final RetryPolicy? retryPolicy;

  /// Service for monitoring network connectivity status.
  final ConnectivityService? connectivityService;

  /// Default connectivity policy for offline request handling.
  final ConnectivityPolicy? connectivityPolicy;

  /// Caching configuration for memory and disk response caches.
  final CacheConfig? cacheConfig;

  /// Offline mutation request queue configuration.
  final OfflineQueueConfig? offlineQueueConfig;

  /// Whether request deduplication is enabled by default.
  final bool enableDeduplication;

  const NetworkOptions({
    this.baseUrl,
    this.headers,
    this.queryParameters,
    this.connectTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.interceptors = const <NetworkInterceptor>[],
    this.logger,
    this.transport,
    this.auth,
    this.retryPolicy,
    this.connectivityService,
    this.connectivityPolicy,
    this.cacheConfig,
    this.offlineQueueConfig,
    this.enableDeduplication = true,
  });

  /// Creates a copy of [NetworkOptions] with updated settings.
  NetworkOptions copyWith({
    String? baseUrl,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    List<NetworkInterceptor>? interceptors,
    NetworkLogger? logger,
    NetworkTransport? transport,
    AuthConfig? auth,
    RetryPolicy? retryPolicy,
    ConnectivityService? connectivityService,
    ConnectivityPolicy? connectivityPolicy,
    CacheConfig? cacheConfig,
    OfflineQueueConfig? offlineQueueConfig,
    bool? enableDeduplication,
  }) {
    return NetworkOptions(
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      interceptors: interceptors ?? this.interceptors,
      logger: logger ?? this.logger,
      transport: transport ?? this.transport,
      auth: auth ?? this.auth,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      connectivityService: connectivityService ?? this.connectivityService,
      connectivityPolicy: connectivityPolicy ?? this.connectivityPolicy,
      cacheConfig: cacheConfig ?? this.cacheConfig,
      offlineQueueConfig: offlineQueueConfig ?? this.offlineQueueConfig,
      enableDeduplication: enableDeduplication ?? this.enableDeduplication,
    );
  }
}
