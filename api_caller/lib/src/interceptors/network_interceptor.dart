import 'dart:async';

import '../exceptions/network_exception.dart';
import '../request/network_request.dart';
import '../response/network_response.dart';
import 'interceptor_handler.dart';

/// Base class for all network interceptors in `flutter_api_caller`.
///
/// Subclasses can override [onRequest], [onResponse], or [onError] to inspect,
/// modify, short-circuit, or recover from network calls.
abstract class NetworkInterceptor {
  const NetworkInterceptor();

  /// Intercepts an outgoing request before transport execution.
  FutureOr<void> onRequest(
    NetworkRequest request,
    RequestInterceptorHandler handler,
  ) {
    handler.next(request);
  }

  /// Intercepts an incoming response after transport execution.
  FutureOr<void> onResponse(
    NetworkResponse<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  /// Intercepts an error thrown during request/response processing.
  FutureOr<void> onError(
    NetworkException error,
    ErrorInterceptorHandler handler,
  ) {
    handler.next(error);
  }
}
