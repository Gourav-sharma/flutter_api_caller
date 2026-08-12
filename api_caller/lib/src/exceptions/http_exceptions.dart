import '../request/network_request.dart';
import 'network_exception.dart';

/// Base class for HTTP status code exceptions returned by remote server.
abstract class HttpException extends NetworkException {
  const HttpException({
    required super.message,
    required int super.statusCode,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  });

  /// Factory helper that maps HTTP status codes to specific typed exceptions.
  factory HttpException.fromStatusCode({
    required int statusCode,
    required String message,
    required NetworkRequest request,
    dynamic responseData,
    Object? underlyingError,
    StackTrace? stackTrace,
  }) {
    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: message,
          responseData: responseData,
          request: request,
          underlyingError: underlyingError,
          stackTrace: stackTrace,
        );
      case 401:
        return UnauthorizedException(
          message: message,
          responseData: responseData,
          request: request,
          underlyingError: underlyingError,
          stackTrace: stackTrace,
        );
      case 403:
        return ForbiddenException(
          message: message,
          responseData: responseData,
          request: request,
          underlyingError: underlyingError,
          stackTrace: stackTrace,
        );
      case 404:
        return NotFoundException(
          message: message,
          responseData: responseData,
          request: request,
          underlyingError: underlyingError,
          stackTrace: stackTrace,
        );
      case 409:
        return ConflictException(
          message: message,
          responseData: responseData,
          request: request,
          underlyingError: underlyingError,
          stackTrace: stackTrace,
        );
      case 422:
        return ValidationException(
          message: message,
          responseData: responseData,
          request: request,
          underlyingError: underlyingError,
          stackTrace: stackTrace,
        );
      default:
        if (statusCode >= 500 && statusCode < 600) {
          return ServerException(
            message: message,
            statusCode: statusCode,
            responseData: responseData,
            request: request,
            underlyingError: underlyingError,
            stackTrace: stackTrace,
          );
        }
        return UnknownHttpException(
          message: message,
          statusCode: statusCode,
          responseData: responseData,
          request: request,
          underlyingError: underlyingError,
          stackTrace: stackTrace,
        );
    }
  }
}

/// HTTP exception for unclassified HTTP status codes.
class UnknownHttpException extends HttpException {
  const UnknownHttpException({
    required super.message,
    required super.statusCode,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  });
}

/// HTTP 400 Bad Request Exception.
class BadRequestException extends HttpException {
  const BadRequestException({
    required super.message,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  }) : super(statusCode: 400);
}

/// HTTP 401 Unauthorized Exception.
class UnauthorizedException extends HttpException {
  const UnauthorizedException({
    required super.message,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  }) : super(statusCode: 401);
}

/// HTTP 403 Forbidden Exception.
class ForbiddenException extends HttpException {
  const ForbiddenException({
    required super.message,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  }) : super(statusCode: 403);
}

/// HTTP 404 Not Found Exception.
class NotFoundException extends HttpException {
  const NotFoundException({
    required super.message,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  }) : super(statusCode: 404);
}

/// HTTP 409 Conflict Exception.
class ConflictException extends HttpException {
  const ConflictException({
    required super.message,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  }) : super(statusCode: 409);
}

/// HTTP 422 Unprocessable Entity / Validation Exception.
class ValidationException extends HttpException {
  const ValidationException({
    required super.message,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  }) : super(statusCode: 422);
}

/// HTTP 5xx Server Exception.
class ServerException extends HttpException {
  const ServerException({
    required super.message,
    required super.statusCode,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  });
}

/// Exception for unknown, unexpected, or unclassified network errors.
class UnknownNetworkException extends NetworkException {
  const UnknownNetworkException({
    required super.message,
    super.statusCode,
    super.responseData,
    super.request,
    super.underlyingError,
    super.stackTrace,
  });
}
