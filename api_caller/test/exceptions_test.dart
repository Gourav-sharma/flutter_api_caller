import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

void main() {
  group('Typed Exceptions Hierarchy', () {
    late MockNetworkTransport mockTransport;
    late NetworkClient client;

    setUp(() {
      mockTransport = MockNetworkTransport();
      client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        retryPolicy: RetryPolicy.noRetry,
      );
    });

    test('HTTP 400 throws BadRequestException', () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 400,
          headers: const <String, String>{},
          data: <String, dynamic>{'error': 'invalid format'},
          request: NetworkRequest(method: 'GET', path: '/users', uri: Uri()),
        ),
      );

      expect(
        () => client.get<dynamic>('/users'),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('HTTP 401 throws UnauthorizedException', () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 401,
          headers: const <String, String>{},
          data: <String, dynamic>{'error': 'unauthorized'},
          request: NetworkRequest(method: 'GET', path: '/users', uri: Uri()),
        ),
      );

      expect(
        () => client.get<dynamic>('/users'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('HTTP 403 throws ForbiddenException', () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 403,
          headers: const <String, String>{},
          data: <String, dynamic>{'error': 'forbidden'},
          request: NetworkRequest(method: 'GET', path: '/users', uri: Uri()),
        ),
      );

      expect(
        () => client.get<dynamic>('/users'),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('HTTP 404 throws NotFoundException', () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 404,
          headers: const <String, String>{},
          data: <String, dynamic>{'error': 'not found'},
          request:
              NetworkRequest(method: 'GET', path: '/users/999', uri: Uri()),
        ),
      );

      expect(
        () => client.get<dynamic>('/users/999'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('HTTP 409 throws ConflictException', () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 409,
          headers: const <String, String>{},
          data: <String, dynamic>{'error': 'duplicate record'},
          request: NetworkRequest(method: 'POST', path: '/users', uri: Uri()),
        ),
      );

      expect(
        () => client
            .post<dynamic>('/users', data: {'email': 'existing@example.com'}),
        throwsA(isA<ConflictException>()),
      );
    });

    test('HTTP 422 throws ValidationException', () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 422,
          headers: const <String, String>{},
          data: <String, dynamic>{'field': 'email invalid'},
          request: NetworkRequest(method: 'POST', path: '/users', uri: Uri()),
        ),
      );

      expect(
        () => client.post<dynamic>('/users', data: {'email': 'bad'}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('HTTP 500 throws ServerException', () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 500,
          headers: const <String, String>{},
          data: <String, dynamic>{'error': 'internal server error'},
          request: NetworkRequest(method: 'GET', path: '/users', uri: Uri()),
        ),
      );

      expect(
        () => client.get<dynamic>('/users'),
        throwsA(isA<ServerException>()),
      );
    });

    test('Transport exception throws ConnectionException', () async {
      mockTransport.enqueueException(
        const ConnectionException(message: 'No Internet Connection'),
      );

      expect(
        () => client.get<dynamic>('/users'),
        throwsA(isA<ConnectionException>()),
      );
    });

    test('Timeout exception throws NetworkTimeoutException', () async {
      mockTransport.enqueueException(
        const NetworkTimeoutException(
          message: 'Connection timed out',
          timeoutType: TimeoutType.connect,
          timeoutDuration: Duration(seconds: 5),
        ),
      );

      expect(
        () => client.get<dynamic>('/users'),
        throwsA(isA<NetworkTimeoutException>()),
      );
    });
  });
}
