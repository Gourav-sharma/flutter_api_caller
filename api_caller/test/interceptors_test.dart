import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

class AuthHeaderInterceptor extends NetworkInterceptor {
  final String token;
  AuthHeaderInterceptor(this.token);

  @override
  void onRequest(NetworkRequest request, RequestInterceptorHandler handler) {
    final Map<String, String> updatedHeaders =
        Map<String, String>.from(request.headers);
    updatedHeaders['Authorization'] = 'Bearer $token';
    handler.next(request.copyWith(headers: updatedHeaders));
  }
}

class EarlyResolveInterceptor extends NetworkInterceptor {
  @override
  void onRequest(NetworkRequest request, RequestInterceptorHandler handler) {
    if (request.path == '/cached') {
      handler.resolve(
        NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{'x-cache': 'hit'},
          data: <String, dynamic>{'cached': true},
          request: request,
        ),
      );
      return;
    }
    handler.next(request);
  }
}

class ErrorRecoveryInterceptor extends NetworkInterceptor {
  @override
  void onError(NetworkException error, ErrorInterceptorHandler handler) {
    if (error.statusCode == 401) {
      // Recover from 401 by returning fallback cached response
      handler.resolve(
        NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{},
          data: <String, dynamic>{'recovered': true},
          request: error.request ??
              NetworkRequest(method: 'GET', path: '', uri: Uri()),
        ),
      );
      return;
    }
    handler.next(error);
  }
}

void main() {
  group('NetworkInterceptor Pipeline', () {
    late MockNetworkTransport mockTransport;

    setUp(() {
      mockTransport = MockNetworkTransport();
    });

    test('AuthHeaderInterceptor attaches bearer token to outgoing requests',
        () async {
      final NetworkClient client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        interceptors: <NetworkInterceptor>[
          AuthHeaderInterceptor('my_secret_token'),
        ],
      );

      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{},
          data: <String, dynamic>{'ok': true},
          request: NetworkRequest(method: 'GET', path: '/profile', uri: Uri()),
        ),
      );

      await client.get<dynamic>('/profile');

      final NetworkRequest request = mockTransport.history.single;
      expect(
          request.headers['Authorization'], equals('Bearer my_secret_token'));
    });

    test(
        'EarlyResolveInterceptor short-circuits request without calling transport',
        () async {
      final NetworkClient client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        interceptors: <NetworkInterceptor>[
          EarlyResolveInterceptor(),
        ],
      );

      final NetworkResponse<Map<String, dynamic>> response =
          await client.get<Map<String, dynamic>>('/cached');

      expect(response.statusCode, equals(200));
      expect(response.data?['cached'], isTrue);
      expect(mockTransport.history, isEmpty); // Transport never executed
    });

    test(
        'ErrorRecoveryInterceptor intercepts 401 and recovers with custom response',
        () async {
      final NetworkClient client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        interceptors: <NetworkInterceptor>[
          ErrorRecoveryInterceptor(),
        ],
      );

      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 401,
          headers: <String, String>{},
          data: <String, dynamic>{'error': 'unauthorized'},
          request:
              NetworkRequest(method: 'GET', path: '/protected', uri: Uri()),
        ),
      );

      final NetworkResponse<Map<String, dynamic>> response =
          await client.get<Map<String, dynamic>>('/protected');

      expect(response.statusCode, equals(200));
      expect(response.data?['recovered'], isTrue);
    });
  });
}
