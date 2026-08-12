import '../exceptions/network_exception.dart';
import '../request/network_request.dart';
import 'retry_strategy.dart';

/// Predicate signature determining if a failed request should be retried.
typedef RetryPredicate = bool Function(
  NetworkRequest request,
  NetworkException error,
  int attempt,
);

/// Custom delay calculation function signature.
typedef CustomRetryDelay = Duration Function(int attempt);

/// Configuration policy governing retry behavior for transient network failures.
class RetryPolicy {
  /// Maximum number of retry attempts allowed before throwing error (defaults to 3).
  final int maxRetries;

  /// Backoff strategy to use between retry attempts.
  final RetryStrategy strategy;

  /// Initial delay before first retry attempt (defaults to 500ms).
  final Duration initialDelay;

  /// Maximum cap for exponential backoff delay (defaults to 10s).
  final Duration maxDelay;

  /// HTTP status codes deemed retryable transient failures.
  final Set<int> retryableStatusCodes;

  /// Safe HTTP methods eligible for automatic retry (defaults to GET, HEAD, PUT, DELETE).
  final List<String> retryableMethods;

  /// Optional custom predicate to explicitly override retry evaluation logic.
  final RetryPredicate? retryIf;

  /// Optional custom delay provider when strategy is [RetryStrategy.custom].
  final CustomRetryDelay? customDelay;

  const RetryPolicy({
    this.maxRetries = 3,
    this.strategy = RetryStrategy.exponentialBackoffJitter,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.retryableStatusCodes = const <int>{408, 429, 500, 502, 503, 504},
    this.retryableMethods = const <String>['GET', 'HEAD', 'PUT', 'DELETE'],
    this.retryIf,
    this.customDelay,
  });

  /// Default disabled policy.
  static const RetryPolicy noRetry = RetryPolicy(maxRetries: 0);
}
