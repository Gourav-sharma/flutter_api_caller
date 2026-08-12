import '../cancellation/cancel_token.dart';
import '../cache/cache_policy.dart';
import '../connectivity/connectivity_policy.dart';
import '../retry/retry_policy.dart';

/// Per-request configuration options overriding client default settings.
class RequestOptions {
  /// Request specific headers.
  final Map<String, String>? headers;

  /// Request specific query parameters.
  final Map<String, dynamic>? queryParameters;

  /// Connection timeout for this request.
  final Duration? connectTimeout;

  /// Send timeout for this request.
  final Duration? sendTimeout;

  /// Receive timeout for this request.
  final Duration? receiveTimeout;

  /// Custom metadata passed along with the request.
  final Map<String, dynamic>? extra;

  /// Cancellation token for this request.
  final CancelToken? cancelToken;

  /// Cache strategy policy override for this request.
  final CachePolicy? cachePolicy;

  /// Time-to-live duration override for response cache.
  final Duration? cacheTtl;

  /// Retry policy override for this request.
  final RetryPolicy? retryPolicy;

  /// Connectivity handling policy override for this request.
  final ConnectivityPolicy? connectivityPolicy;

  /// Offline policy override for mutating requests.
  final OfflinePolicy? offlinePolicy;

  /// Whether request deduplication is enabled for this request.
  final bool? deduplicate;

  const RequestOptions({
    this.headers,
    this.queryParameters,
    this.connectTimeout,
    this.sendTimeout,
    this.receiveTimeout,
    this.extra,
    this.cancelToken,
    this.cachePolicy,
    this.cacheTtl,
    this.retryPolicy,
    this.connectivityPolicy,
    this.offlinePolicy,
    this.deduplicate,
  });

  /// Creates a copy of [RequestOptions] with updated properties.
  RequestOptions copyWith({
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
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
    return RequestOptions(
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      extra: extra ?? this.extra,
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
