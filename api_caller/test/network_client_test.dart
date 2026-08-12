import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkClient Core HTTP Operations', () {
    late MockNetworkTransport mockTransport;
    late NetworkClient client;

    setUp(() {
      mockTransport = MockNetworkTransport();
      client = NetworkClient(
        baseUrl: 'https://api.example.com',
        headers: <String, String>{
          'Accept': 'application/json',
          'X-Client-Version': '1.0.0',
        },
        transport: mockTransport,
      );
    });

    test('GET request resolves URL, headers, and query parameters', () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{'content-type': 'application/json'},
          data: <String, dynamic>{'id': 123, 'name': 'John Doe'},
          request: NetworkRequest(
            method: 'GET',
            path: '/users/123',
            uri: Uri.parse('https://api.example.com/users/123'),
          ),
        ),
      );

      final NetworkResponse<Map<String, dynamic>> response =
          await client.get<Map<String, dynamic>>(
        '/users/123',
        queryParameters: <String, dynamic>{'include_details': true},
        headers: <String, String>{'Authorization': 'Bearer test_token'},
      );

      expect(response.statusCode, equals(200));
      expect(response.data?['name'], equals('John Doe'));

      final NetworkRequest sentRequest = mockTransport.history.single;
      expect(sentRequest.method, equals('GET'));
      expect(sentRequest.uri.toString(),
          equals('https://api.example.com/users/123?include_details=true'));
      expect(sentRequest.headers['Authorization'], equals('Bearer test_token'));
      expect(sentRequest.headers['X-Client-Version'], equals('1.0.0'));
    });

    test('POST request sends JSON body and sets Content-Type automatically',
        () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 201,
          headers: <String, String>{'content-type': 'application/json'},
          data: <String, dynamic>{'id': 456, 'status': 'created'},
          request: NetworkRequest(
            method: 'POST',
            path: '/users',
            uri: Uri.parse('https://api.example.com/users'),
          ),
        ),
      );

      final Map<String, dynamic> bodyPayload = <String, dynamic>{
        'name': 'Alice',
        'email': 'alice@example.com',
      };

      final NetworkResponse<Map<String, dynamic>> response =
          await client.post<Map<String, dynamic>>(
        '/users',
        data: bodyPayload,
      );

      expect(response.statusCode, equals(201));
      expect(response.data?['id'], equals(456));

      final NetworkRequest sentRequest = mockTransport.history.single;
      expect(sentRequest.method, equals('POST'));
      expect(sentRequest.body, equals(bodyPayload));
      expect(sentRequest.headers['Content-Type'],
          equals('application/json; charset=utf-8'));
    });

    test('PUT, PATCH, DELETE, HEAD methods execute properly', () async {
      mockTransport.enqueueResponse(NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{},
          data: <String, dynamic>{},
          request: NetworkRequest(method: 'PUT', path: '/1', uri: Uri())));
      await client.put<dynamic>('/1', data: {'a': 1});
      expect(mockTransport.history.last.method, equals('PUT'));

      mockTransport.enqueueResponse(NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{},
          data: <String, dynamic>{},
          request: NetworkRequest(method: 'PATCH', path: '/1', uri: Uri())));
      await client.patch<dynamic>('/1', data: {'a': 2});
      expect(mockTransport.history.last.method, equals('PATCH'));

      mockTransport.enqueueResponse(NetworkResponse<dynamic>(
          statusCode: 204,
          headers: <String, String>{},
          data: null,
          request: NetworkRequest(method: 'DELETE', path: '/1', uri: Uri())));
      await client.delete<dynamic>('/1');
      expect(mockTransport.history.last.method, equals('DELETE'));

      mockTransport.enqueueResponse(NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{},
          data: null,
          request: NetworkRequest(method: 'HEAD', path: '/1', uri: Uri())));
      await client.head<dynamic>('/1');
      expect(mockTransport.history.last.method, equals('HEAD'));
    });
  });
}
