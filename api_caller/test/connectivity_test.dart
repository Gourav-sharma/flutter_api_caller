import 'dart:async';

import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

class MockConnectivityService implements ConnectivityService {
  bool connected = true;
  final StreamController<bool> controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isConnected() async => connected;

  @override
  Stream<bool> get statusStream => controller.stream;

  void setConnected(bool value) {
    connected = value;
    controller.add(value);
  }

  void dispose() {
    controller.close();
  }
}

void main() {
  group('Connectivity & Offline Policies', () {
    late MockConnectivityService connectivityService;
    late MockNetworkTransport mockTransport;

    setUp(() {
      connectivityService = MockConnectivityService();
      mockTransport = MockNetworkTransport();
    });

    tearDown(() {
      connectivityService.dispose();
    });

    test('failFast policy throws ConnectionException when offline', () async {
      connectivityService.connected = false;

      final client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        options: NetworkOptions(
          connectivityService: connectivityService,
          connectivityPolicy: ConnectivityPolicy.failFast,
        ),
      );

      expect(
        () => client.get<Map<String, dynamic>>('/users'),
        throwsA(isA<ConnectionException>()),
      );
    });

    test('waitForConnection blocks until network status becomes online',
        () async {
      connectivityService.connected = false;

      final client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        options: NetworkOptions(
          connectivityService: connectivityService,
        ),
      );

      mockTransport.enqueueJsonResponse(<String, dynamic>{'status': 'online'});

      final future = client.get<Map<String, dynamic>>(
        '/users',
        options: const RequestOptions(
          connectivityPolicy: ConnectivityPolicy.waitForConnection,
        ),
      );

      Timer(const Duration(milliseconds: 50), () {
        connectivityService.setConnected(true);
      });

      final response = await future;
      expect(response.isSuccess, isTrue);
      expect(response.data?['status'], 'online');
    });
  });
}
