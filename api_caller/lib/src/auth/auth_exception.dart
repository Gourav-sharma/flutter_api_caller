import '../exceptions/network_exception.dart';

/// Exception thrown when authentication or token refresh operations fail.
class AuthenticationException extends NetworkException {
  const AuthenticationException({
    required super.message,
    super.statusCode = 401,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  });
}
