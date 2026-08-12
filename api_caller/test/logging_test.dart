import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkLogger Security & Redaction', () {
    late MockNetworkTransport mockTransport;
    final List<String> loggedMessages = <String>[];

    setUp(() {
      loggedMessages.clear();
      mockTransport = MockNetworkTransport();
    });

    test('Redacts sensitive headers and sensitive payload fields in DEBUG logs',
        () async {
      final NetworkLogger logger = NetworkLogger(
        level: LogLevel.debug,
        logPrinter: (String message, {LogLevel? level}) {
          loggedMessages.add(message);
        },
      );

      final NetworkClient client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        logger: logger,
      );

      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{'Set-Cookie': 'session=secret123'},
          data: <String, dynamic>{
            'token': 'super_secret_token_123',
            'username': 'johndoe'
          },
          request: NetworkRequest(method: 'POST', path: '/login', uri: Uri()),
        ),
      );

      await client.post<dynamic>(
        '/login',
        headers: <String, String>{
          'Authorization': 'Bearer my_access_token',
          'X-Api-Key': 'secret_api_key',
        },
        data: <String, dynamic>{
          'password': 'my_plain_password',
          'username': 'johndoe',
        },
      );

      final String fullLog = loggedMessages.join('\n');

      // Verify request masking
      expect(fullLog.contains('[REDACTED]'), isTrue);
      expect(fullLog.contains('Bearer my_access_token'), isFalse);
      expect(fullLog.contains('secret_api_key'), isFalse);
      expect(fullLog.contains('my_plain_password'), isFalse);
      expect(fullLog.contains('super_secret_token_123'), isFalse);
      expect(fullLog.contains('session=secret123'), isFalse);

      // Verify non-sensitive info is retained
      expect(fullLog.contains('johndoe'), isTrue);
      expect(fullLog.contains('POST'), isTrue);
    });

    test('LogLevel.none produces zero logs', () async {
      final NetworkLogger logger = NetworkLogger(
        level: LogLevel.none,
        logPrinter: (String message, {LogLevel? level}) {
          loggedMessages.add(message);
        },
      );

      final NetworkClient client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
        logger: logger,
      );

      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{},
          data: <String, dynamic>{'ok': true},
          request: NetworkRequest(method: 'GET', path: '/test', uri: Uri()),
        ),
      );

      await client.get<dynamic>('/test');

      expect(loggedMessages, isEmpty);
    });
  });
}
