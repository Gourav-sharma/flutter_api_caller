import 'dart:typed_data';

import 'package:flutter_api_caller/flutter_api_caller.dart';
import 'package:test/test.dart';

void main() {
  group('Multipart Handling', () {
    late MockNetworkTransport mockTransport;
    late NetworkClient client;

    setUp(() {
      mockTransport = MockNetworkTransport();
      client = NetworkClient(
        baseUrl: 'https://api.example.com',
        transport: mockTransport,
      );
    });

    test('Multipart request passes fields and files to transport', () async {
      mockTransport.enqueueResponse(
        NetworkResponse<dynamic>(
          statusCode: 200,
          headers: <String, String>{'content-type': 'application/json'},
          data: <String, dynamic>{'uploaded': true},
          request: NetworkRequest(method: 'POST', path: '/upload', uri: Uri()),
        ),
      );

      final Uint8List dummyBytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);

      final MultipartRequest multipart = MultipartRequest(
        fields: <String, String>{
          'title': 'Avatar Image',
        },
        files: <MultipartFile>[
          MultipartFile.fromBytes(
            dummyBytes,
            field: 'file',
            filename: 'avatar.png',
            contentType: 'image/png',
          ),
        ],
      );

      final NetworkResponse<Map<String, dynamic>> response =
          await client.post<Map<String, dynamic>>(
        '/upload',
        multipart: multipart,
      );

      expect(response.statusCode, equals(200));
      expect(response.data?['uploaded'], isTrue);

      final NetworkRequest sent = mockTransport.history.single;
      expect(sent.multipart, isNotNull);
      expect(sent.multipart!.fields['title'], equals('Avatar Image'));
      expect(sent.multipart!.files.single.filename, equals('avatar.png'));
      expect(sent.headers['Content-Type'], equals('multipart/form-data'));
    });
  });
}
