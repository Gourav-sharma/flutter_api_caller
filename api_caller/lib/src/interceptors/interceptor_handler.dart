import '../exceptions/network_exception.dart';
import '../request/network_request.dart';
import '../response/network_response.dart';

/// State outcome enum for interceptor handler processing.
enum InterceptorState {
  next,
  resolve,
  reject,
}

/// Base class for interceptor pipeline control flow handlers.
abstract class InterceptorHandler<T> {
  InterceptorState state = InterceptorState.next;
  dynamic resultData;

  /// Passes control to the next interceptor in the pipeline.
  void next(T data) {
    state = InterceptorState.next;
    resultData = data;
  }

  /// Resolves the request pipeline immediately with the provided [response].
  void resolve(NetworkResponse<dynamic> response) {
    state = InterceptorState.resolve;
    resultData = response;
  }

  /// Aborts the request pipeline immediately with the provided [error].
  void reject(NetworkException error) {
    state = InterceptorState.reject;
    resultData = error;
  }
}

/// Handler passed to [NetworkInterceptor.onRequest].
class RequestInterceptorHandler extends InterceptorHandler<NetworkRequest> {}

/// Handler passed to [NetworkInterceptor.onResponse].
class ResponseInterceptorHandler
    extends InterceptorHandler<NetworkResponse<dynamic>> {}

/// Handler passed to [NetworkInterceptor.onError].
class ErrorInterceptorHandler extends InterceptorHandler<NetworkException> {}
