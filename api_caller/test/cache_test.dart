import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

void main() {
  group('Memory & Disk Cache Engine', () {
    late MockNetworkTransport mockTransport;
    late MemoryStorageEngine storageEngine;
    late NetworkClient client;

    setUp(() {
      mockTransport = MockNetworkTransport();
      storageEngine = MemoryStorageEngine();
      client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        cacheConfig: CacheConfig(
          policy: CachePolicy.cacheFirst,
          ttl: const Duration(minutes: 5),
          storage: storageEngine,
        ),
      );
    });

    test(
        'Serves response from cache on second identical GET request without network transport roundtrip',
        () async {
      int transportCalls = 0;
      mockTransport.handler = (req) async {
        transportCalls++;
        return NetworkResponse<dynamic>(
          statusCode: 200,
          data: <String, dynamic>{
            'users': <dynamic>['Alice', 'Bob']
          },
          headers: const <String, String>{},
          request: req,
        );
      };

      final res1 = await client.get<Map<String, dynamic>>('/users');
      expect(res1.isSuccess, isTrue);
      expect(transportCalls, 1);

      final res2 = await client.get<Map<String, dynamic>>('/users');
      expect(res2.isSuccess, isTrue);
      expect(transportCalls, 1); // Transport was NOT called again
      expect(res2.extra['is_cache_hit'], isTrue);
    });

    test(
        'staleWhileRevalidate serves stale cache immediately and updates cache in background',
        () async {
      int transportCalls = 0;
      mockTransport.handler = (req) async {
        transportCalls++;
        return NetworkResponse<dynamic>(
          statusCode: 200,
          data: <String, dynamic>{'version': transportCalls},
          headers: const <String, String>{},
          request: req,
        );
      };

      // 1. Initial request populates cache
      await client.get<Map<String, dynamic>>('/config',
          cachePolicy: CachePolicy.cacheFirst);
      expect(transportCalls, 1);

      // 2. Request with staleWhileRevalidate returns v1 immediately
      final resStale = await client.get<Map<String, dynamic>>(
        '/config',
        cachePolicy: CachePolicy.staleWhileRevalidate,
      );

      expect(resStale.data?['version'], 1);
      expect(resStale.extra['is_cache_hit'], isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(transportCalls, 2); // Background fetch executed
    });
  });
}
