import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

void main() {
  group('Retry Policy & Backoff Delay Logic', () {
    late MockNetworkTransport mockTransport;

    setUp(() {
      mockTransport = MockNetworkTransport();
    });

    test('Retries transient 500 error up to maxRetries limit', () async {
      int attempts = 0;
      mockTransport.handler = (req) async {
        attempts++;
        if (attempts < 3) {
          return NetworkResponse<dynamic>(
            statusCode: 500,
            statusMessage: 'Server Error',
            headers: const <String, String>{},
            request: req,
          );
        }
        return NetworkResponse<dynamic>(
          statusCode: 200,
          data: <String, dynamic>{'success': true},
          headers: const <String, String>{},
          request: req,
        );
      };

      final client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        retryPolicy: const RetryPolicy(
          maxRetries: 3,
          strategy: RetryStrategy.fixed,
          initialDelay: Duration(milliseconds: 10),
        ),
      );

      final response = await client.get<Map<String, dynamic>>('/data');

      expect(response.isSuccess, isTrue);
      expect(attempts, 3);
      expect(response.extra['retry_count'], 2);
    });

    test('Does not retry non-transient 400 Bad Request error', () async {
      int attempts = 0;
      mockTransport.handler = (req) async {
        attempts++;
        return NetworkResponse<dynamic>(
          statusCode: 400,
          statusMessage: 'Bad Request',
          headers: const <String, String>{},
          request: req,
        );
      };

      final client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        retryPolicy: const RetryPolicy(maxRetries: 3),
      );

      expect(
        () => client.get<Map<String, dynamic>>('/bad'),
        throwsA(isA<BadRequestException>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(attempts, 1);
    });

    test('Protects POST requests from auto-retry by default', () async {
      int attempts = 0;
      mockTransport.handler = (req) async {
        attempts++;
        return NetworkResponse<dynamic>(
          statusCode: 503,
          statusMessage: 'Service Unavailable',
          headers: const <String, String>{},
          request: req,
        );
      };

      final client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        retryPolicy: const RetryPolicy(
          maxRetries: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
      );

      expect(
        () => client.post<Map<String, dynamic>>('/order',
            data: <String, dynamic>{'item': '1'}),
        throwsA(isA<ServerException>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(attempts, 1);
    });
  });
}
