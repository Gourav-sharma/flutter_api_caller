import '../exceptions/network_exception.dart';

/// Exception thrown when an HTTP request operation is cancelled.
class CancellationException extends NetworkException {
  /// Optional human-readable reason for request cancellation.
  final String? reason;

  const CancellationException({
    required super.message,
    this.reason,
    super.request,
    super.underlyingError,
    super.stackTrace,
  });
}
