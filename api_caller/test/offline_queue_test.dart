import 'dart:async';

import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

class TestConnectivityService implements ConnectivityService {
  bool connected = true;
  final StreamController<bool> controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isConnected() async => connected;

  @override
  Stream<bool> get statusStream => controller.stream;

  void dispose() {
    controller.close();
  }
}

void main() {
  group('Offline Mutation Queue', () {
    late MemoryQueueStorage queueStorage;

    setUp(() {
      queueStorage = MemoryQueueStorage();
    });

    test(
        'Enqueues POST request while offline and drains queue when network connects',
        () async {
      final mockTransport = MockNetworkTransport();
      final connectivity = TestConnectivityService();
      connectivity.connected = false;

      final client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        connectivityService: connectivity,
        offlineQueueConfig: OfflineQueueConfig(storage: queueStorage),
      );

      final queuedResponse = await client.post<Map<String, dynamic>>(
        '/orders',
        data: <String, dynamic>{'orderId': '123'},
        offlinePolicy: OfflinePolicy.queue,
      );

      expect(queuedResponse.statusCode, 202);
      expect(queuedResponse.extra['is_offline_queued'], isTrue);
      expect(client.offlineQueueManager.pendingCount, 1);

      // Simulate connectivity restoration
      connectivity.connected = true;
      mockTransport.enqueueJsonResponse(<String, dynamic>{'status': 'created'});

      final drainResults = await client.offlineQueueManager.processQueue(
        (req) => client.request<dynamic>(
          req.path,
          method: req.method,
          body: req.body,
        ),
      );

      expect(drainResults.length, 1);
      expect(client.offlineQueueManager.pendingCount, 0);

      connectivity.dispose();
    });
  });
}
