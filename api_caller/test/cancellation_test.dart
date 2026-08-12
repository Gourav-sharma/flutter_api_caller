import 'dart:async';

import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

void main() {
  group('Request Cancellation & CancelToken', () {
    late MockNetworkTransport mockTransport;
    late NetworkClient client;

    setUp(() {
      mockTransport = MockNetworkTransport();
      client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
      );
    });

    test('Throws CancellationException when cancelled before or during request',
        () async {
      final cancelToken = CancelToken();

      mockTransport.handler = (req) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return NetworkResponse<dynamic>(
          statusCode: 200,
          data: <String, dynamic>{'status': 'ok'},
          headers: const <String, String>{},
          request: req,
        );
      };

      final future =
          client.get<Map<String, dynamic>>('/slow', cancelToken: cancelToken);

      Timer(const Duration(milliseconds: 50), () {
        cancelToken.cancel('User navigated away');
      });

      expect(
        () => future,
        throwsA(isA<CancellationException>().having(
          (e) => e.reason,
          'reason',
          'User navigated away',
        )),
      );
    });
  });
}
