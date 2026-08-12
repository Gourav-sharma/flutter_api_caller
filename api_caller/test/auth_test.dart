import 'dart:async';

import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

class MockTokenProvider implements TokenProvider {
  String? accessToken = 'initial_access_token';
  String? refreshTokenValue = 'initial_refresh_token';
  int refreshCallCount = 0;
  bool shouldFailRefresh = false;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> refreshToken() async {
    refreshCallCount++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldFailRefresh) {
      throw const AuthenticationException(message: 'Refresh token expired');
    }
    accessToken = 'refreshed_access_token_$refreshCallCount';
    return accessToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshTokenValue = null;
  }
}

void main() {
  group('Authentication & Single-Flight Token Refresh', () {
    late MockTokenProvider tokenProvider;
    late MockNetworkTransport mockTransport;
    late NetworkClient client;

    setUp(() {
      tokenProvider = MockTokenProvider();
      mockTransport = MockNetworkTransport();
      client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        auth: AuthConfig(tokenProvider: tokenProvider),
      );
    });

    test('Attaches Authorization header to outgoing requests', () async {
      mockTransport.enqueueJsonResponse(<String, dynamic>{'status': 'ok'});

      final response = await client.get<Map<String, dynamic>>('/user');

      expect(response.isSuccess, isTrue);
      expect(mockTransport.lastRequest?.headers['Authorization'],
          'Bearer initial_access_token');
    });

    test(
        'Single-Flight Lock: 100 concurrent 401 responses trigger EXACTLY ONE token refresh',
        () async {
      mockTransport.handler = (NetworkRequest req) async {
        final String? authHeader = req.headers['Authorization'];
        if (authHeader == 'Bearer initial_access_token') {
          return NetworkResponse<dynamic>(
            statusCode: 401,
            statusMessage: 'Unauthorized',
            headers: const <String, String>{},
            request: req,
          );
        }
        return NetworkResponse<dynamic>(
          statusCode: 200,
          data: <String, dynamic>{
            'status': 'authenticated',
            'token': authHeader,
          },
          headers: const <String, String>{},
          request: req,
        );
      };

      final List<Future<NetworkResponse<Map<String, dynamic>>>> futures =
          <Future<NetworkResponse<Map<String, dynamic>>>>[];

      for (int i = 0; i < 100; i++) {
        futures.add(client.get<Map<String, dynamic>>('/profile'));
      }

      final List<NetworkResponse<Map<String, dynamic>>> responses =
          await Future.wait(futures);

      expect(responses.length, 100);
      for (final resp in responses) {
        expect(resp.isSuccess, isTrue);
        expect(resp.data?['token'], 'Bearer refreshed_access_token_1');
      }

      // Crucial verification: refresh was executed EXACTLY ONCE
      expect(tokenProvider.refreshCallCount, 1);
    });

    test('Refresh failure clears tokens and throws AuthenticationException',
        () async {
      tokenProvider.shouldFailRefresh = true;
      mockTransport.enqueueJsonResponse(
          <String, dynamic>{'error': 'Unauthorized'},
          statusCode: 401);

      await expectLater(
        client.get<Map<String, dynamic>>('/protected'),
        throwsA(isA<AuthenticationException>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(tokenProvider.accessToken, isNull);
      expect(tokenProvider.refreshTokenValue, isNull);
    });
  });
}
