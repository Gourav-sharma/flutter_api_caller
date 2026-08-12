import '../cancellation/cancel_token.dart';
import '../cache/cache_policy.dart';
import '../connectivity/connectivity_policy.dart';
import '../multipart/multipart_request.dart';
import '../retry/retry_policy.dart';

/// Represents an immutable HTTP request.
class NetworkRequest {
  /// The HTTP method (GET, POST, PUT, PATCH, DELETE, HEAD).
  final String method;

  /// The raw path or endpoint requested.
  final String path;

  /// The fully resolved target [Uri].
  final Uri uri;

  /// HTTP headers for this request.
  final Map<String, String> headers;

  /// Query parameters map.
  final Map<String, dynamic> queryParameters;

  /// Request body payload (JSON Map, List, String, etc.).
  final dynamic body;

  /// Optional multipart request data.
  final MultipartRequest? multipart;

  /// Connect timeout duration.
  final Duration connectTimeout;

  /// Send timeout duration.
  final Duration sendTimeout;

  /// Receive timeout duration.
  final Duration receiveTimeout;

  /// Custom request metadata map for interceptor context sharing.
  final Map<String, dynamic> extra;

  /// Cancellation token for this request.
  final CancelToken? cancelToken;

  /// Caching policy for this request.
  final CachePolicy? cachePolicy;

  /// Cache time-to-live duration.
  final Duration? cacheTtl;

  /// Retry policy override for this request.
  final RetryPolicy? retryPolicy;

  /// Connectivity policy override for this request.
  final ConnectivityPolicy? connectivityPolicy;

  /// Offline mutation policy override for this request.
  final OfflinePolicy? offlinePolicy;

  /// Whether request deduplication is enabled for this request.
  final bool? deduplicate;

  const NetworkRequest({
    required this.method,
    required this.path,
    required this.uri,
    this.headers = const <String, String>{},
    this.queryParameters = const <String, dynamic>{},
    this.body,
    this.multipart,
    this.connectTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.extra = const <String, dynamic>{},
    this.cancelToken,
    this.cachePolicy,
    this.cacheTtl,
    this.retryPolicy,
    this.connectivityPolicy,
    this.offlinePolicy,
    this.deduplicate,
  });

  /// Creates a modified copy of [NetworkRequest].
  NetworkRequest copyWith({
    String? method,
    String? path,
    Uri? uri,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    MultipartRequest? multipart,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? extra,
    CancelToken? cancelToken,
    CachePolicy? cachePolicy,
    Duration? cacheTtl,
    RetryPolicy? retryPolicy,
    ConnectivityPolicy? connectivityPolicy,
    OfflinePolicy? offlinePolicy,
    bool? deduplicate,
  }) {
    return NetworkRequest(
      method: method ?? this.method,
      path: path ?? this.path,
      uri: uri ?? this.uri,
      headers: headers ?? Map<String, String>.from(this.headers),
      queryParameters:
          queryParameters ?? Map<String, dynamic>.from(this.queryParameters),
      body: body ?? this.body,
      multipart: multipart ?? this.multipart,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      extra: extra ?? Map<String, dynamic>.from(this.extra),
      cancelToken: cancelToken ?? this.cancelToken,
      cachePolicy: cachePolicy ?? this.cachePolicy,
      cacheTtl: cacheTtl ?? this.cacheTtl,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      connectivityPolicy: connectivityPolicy ?? this.connectivityPolicy,
      offlinePolicy: offlinePolicy ?? this.offlinePolicy,
      deduplicate: deduplicate ?? this.deduplicate,
    );
  }
}
