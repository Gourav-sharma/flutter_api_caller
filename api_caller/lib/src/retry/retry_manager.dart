import 'dart:math';

import '../exceptions/connection_exception.dart';
import '../exceptions/http_exceptions.dart';
import '../exceptions/network_exception.dart';
import '../exceptions/timeout_exception.dart';
import '../request/network_request.dart';
import 'retry_policy.dart';
import 'retry_strategy.dart';

/// Manager evaluating and executing retry loops according to [RetryPolicy].
class RetryManager {
  final RetryPolicy policy;
  final Random _random = Random();

  RetryManager([this.policy = const RetryPolicy()]);

  /// Evaluates whether [attempt] can be retried for [request] and [error].
  bool shouldRetry(
    NetworkRequest request,
    NetworkException error,
    int attempt,
  ) {
    if (attempt > policy.maxRetries) return false;

    if (policy.retryIf != null) {
      return policy.retryIf!(request, error, attempt);
    }

    final String method = request.method.toUpperCase();
    if (!policy.retryableMethods.map((m) => m.toUpperCase()).contains(method)) {
      return false;
    }

    return isTransientError(error);
  }

  /// Determines if [error] is a transient error eligible for retry.
  bool isTransientError(NetworkException error) {
    if (error is ConnectionException || error is TimeoutException) {
      return true;
    }

    if (error is HttpException) {
      if (error.statusCode != null &&
          policy.retryableStatusCodes.contains(error.statusCode!)) {
        return true;
      }
    }

    return false;
  }

  /// Calculates delay duration before executing attempt #[attempt].
  Duration calculateDelay(int attempt) {
    if (policy.strategy == RetryStrategy.custom && policy.customDelay != null) {
      return policy.customDelay!(attempt);
    }

    if (policy.strategy == RetryStrategy.fixed) {
      return policy.initialDelay;
    }

    // Exponential backoff calculation: initialDelay * 2^(attempt - 1)
    final double exponent = pow(2, attempt - 1).toDouble();
    final int delayMs = (policy.initialDelay.inMilliseconds * exponent).toInt();
    final int cappedDelayMs = min(delayMs, policy.maxDelay.inMilliseconds);

    if (policy.strategy == RetryStrategy.exponentialBackoffJitter) {
      // Apply jitter: 50% to 100% of calculated backoff delay
      final double jitterFactor = 0.5 + (_random.nextDouble() * 0.5);
      return Duration(milliseconds: (cappedDelayMs * jitterFactor).toInt());
    }

    return Duration(milliseconds: cappedDelayMs);
  }
}
