/// Defines backoff delay strategies for HTTP request retry logic.
enum RetryStrategy {
  /// Retries after a constant, fixed delay duration between attempts.
  fixed,

  /// Retries using exponential backoff delay calculation.
  exponentialBackoff,

  /// Retries using exponential backoff delay randomized with jitter to prevent thundering herd problems.
  exponentialBackoffJitter,

  /// Uses a custom delay calculation callback.
  custom,
}
