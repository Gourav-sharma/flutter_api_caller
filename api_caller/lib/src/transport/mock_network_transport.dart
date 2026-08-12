import 'dart:async';

import '../exceptions/network_exception.dart';
import '../request/network_request.dart';
import '../response/network_response.dart';
import 'network_transport.dart';

/// Handler function signature for dynamic request mocking in tests.
typedef MockRequestHandler = FutureOr<NetworkResponse<dynamic>> Function(
  NetworkRequest request,
);

/// Mock implementation of [NetworkTransport] for unit testing without live network connections.
class MockNetworkTransport implements NetworkTransport {
  /// History of all requests processed by this mock transport instance.
  final List<NetworkRequest> history = <NetworkRequest>[];

  /// Queued mock responses to return sequentially.
  final List<NetworkResponse<dynamic>> _responseQueue =
      <NetworkResponse<dynamic>>[];

  /// Queued exceptions to throw sequentially.
  final List<NetworkException> _exceptionQueue = <NetworkException>[];

  /// Dynamic handler function for custom response logic.
  MockRequestHandler? mockHandler;

  /// Getter and setter alias for [mockHandler] for backward compatibility.
  MockRequestHandler? get handler => mockHandler;
  set handler(MockRequestHandler? value) => mockHandler = value;

  /// Artificial delay for simulating network latency.
  Duration? delay;

  MockNetworkTransport({
    this.mockHandler,
    this.delay,
  });

  /// Convenience getter returning the most recent [NetworkRequest] sent to this transport.
  NetworkRequest? get lastRequest => history.isNotEmpty ? history.last : null;

  /// Enqueues a response to be returned on subsequent request.
  void enqueueResponse(NetworkResponse<dynamic> response) {
    _responseQueue.add(response);
  }

  /// Enqueues a JSON data response with HTTP status code.
  void enqueueJsonResponse(
    dynamic data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    _responseQueue.add(
      NetworkResponse<dynamic>(
        statusCode: statusCode,
        data: data,
        headers:
            headers ?? <String, String>{'content-type': 'application/json'},
        request: NetworkRequest(
          method: 'GET',
          path: '/',
          uri: Uri.parse('http://localhost'),
        ),
      ),
    );
  }

  /// Enqueues an exception to be thrown on subsequent request.
  void enqueueException(NetworkException exception) {
    _exceptionQueue.add(exception);
  }

  /// Resets history and queued responses/exceptions.
  void reset() {
    history.clear();
    _responseQueue.clear();
    _exceptionQueue.clear();
    mockHandler = null;
  }

  @override
  Future<NetworkResponse<dynamic>> send(NetworkRequest request) async {
    history.add(request);

    if (delay != null) {
      await Future<void>.delayed(delay!);
    }

    if (_exceptionQueue.isNotEmpty) {
      throw _exceptionQueue.removeAt(0);
    }

    if (_responseQueue.isNotEmpty) {
      final NetworkResponse<dynamic> queued = _responseQueue.removeAt(0);
      return queued.copyWith(request: request);
    }

    if (mockHandler != null) {
      return await mockHandler!(request);
    }

    // Default mock response if nothing queued
    return NetworkResponse<dynamic>(
      statusCode: 200,
      statusMessage: 'OK',
      headers: <String, String>{'content-type': 'application/json'},
      data: <String, dynamic>{'message': 'Mock success'},
      request: request,
    );
  }

  @override
  void close() {}
}
