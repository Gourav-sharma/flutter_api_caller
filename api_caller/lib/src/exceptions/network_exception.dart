import '../request/network_request.dart';

/// Base class for all network exceptions thrown by `flutter_api_caller`.
abstract class NetworkException implements Exception {
  /// Description of the error.
  final String message;

  /// Associated HTTP status code if available.
  final int? statusCode;

  /// Raw or parsed response payload returned by server if available.
  final dynamic responseData;

  /// The [NetworkRequest] that produced this error.
  final NetworkRequest? request;

  /// The underlying root error object (e.g. SocketException).
  final Object? underlyingError;

  /// Stack trace for debugging.
  final StackTrace? stackTrace;

  const NetworkException({
    required this.message,
    this.statusCode,
    this.responseData,
    this.request,
    this.underlyingError,
    this.stackTrace,
  });

  @override
  String toString() {
    final String statusStr =
        statusCode != null ? ' (Status Code: $statusCode)' : '';
    return '$runtimeType: $message$statusStr';
  }
}
