import 'network_exception.dart';

/// Enum specifying which stage of request execution timed out.
enum TimeoutType {
  connect,
  send,
  receive,
}

/// Exception thrown when a network request times out (connect, send, or receive).
class NetworkTimeoutException extends NetworkException {
  /// The stage of the request where timeout occurred.
  final TimeoutType timeoutType;

  /// The duration limit that was exceeded.
  final Duration timeoutDuration;

  const NetworkTimeoutException({
    required super.message,
    required this.timeoutType,
    required this.timeoutDuration,
    super.request,
    super.underlyingError,
    super.stackTrace,
  });

  @override
  String toString() {
    return 'NetworkTimeoutException (${timeoutType.name}): $message (limit: ${timeoutDuration.inMilliseconds}ms)';
  }
}

/// Alias for [NetworkTimeoutException] for convenience.
typedef TimeoutException = NetworkTimeoutException;
