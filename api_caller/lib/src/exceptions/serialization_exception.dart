import 'network_exception.dart';

/// Exception thrown when JSON encoding or decoding fails.
class SerializationException extends NetworkException {
  const SerializationException({
    required super.message,
    super.statusCode,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  });
}
