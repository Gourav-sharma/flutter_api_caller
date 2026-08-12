import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

void main() {
  group('Request Deduplication Manager', () {
    late MockNetworkTransport mockTransport;
    late NetworkClient client;

    setUp(() {
      mockTransport = MockNetworkTransport();
      client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
      );
    });

    test(
        'Coalesces 50 simultaneous identical GET requests into 1 single network request',
        () async {
      int transportCallCount = 0;
      mockTransport.handler = (req) async {
        transportCallCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return NetworkResponse<dynamic>(
          statusCode: 200,
          data: <String, dynamic>{
            'items': <dynamic>[1, 2, 3]
          },
          headers: const <String, String>{},
          request: req,
        );
      };

      final futures = List.generate(
        50,
        (_) => client.get<Map<String, dynamic>>('/items'),
      );

      final responses = await Future.wait(futures);

      expect(responses.length, 50);
      expect(transportCallCount, 1);
      for (final res in responses) {
        expect(res.isSuccess, isTrue);
      }
    });
  });
}
