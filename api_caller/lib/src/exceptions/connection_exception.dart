import 'network_exception.dart';

/// Exception thrown when a network connection fails (e.g. SocketException, DNS failure, offline).
class ConnectionException extends NetworkException {
  const ConnectionException({
    required super.message,
    super.request,
    super.underlyingError,
    super.stackTrace,
  });
}
