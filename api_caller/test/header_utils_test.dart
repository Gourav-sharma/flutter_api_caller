import 'package:flutter_api_caller/src/utils/header_utils.dart';
import 'package:test/test.dart';

void main() {
  group('HeaderUtils', () {
    test('merges global and request headers with request overriding global',
        () {
      final Map<String, String> globalHeaders = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer old_token',
      };

      final Map<String, String> requestHeaders = <String, String>{
        'authorization': 'Bearer new_token',
        'X-Custom': 'value',
      };

      final Map<String, String> merged = HeaderUtils.mergeHeaders(
        globalHeaders,
        requestHeaders,
      );

      expect(merged['Accept'], equals('application/json'));
      expect(merged['authorization'], equals('Bearer new_token'));
      expect(merged.containsKey('Authorization'), isFalse);
      expect(merged['X-Custom'], equals('value'));
    });

    test('getHeaderValue performs case-insensitive lookup', () {
      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json',
      };

      expect(HeaderUtils.getHeaderValue(headers, 'content-type'),
          equals('application/json'));
      expect(HeaderUtils.getHeaderValue(headers, 'CONTENT-TYPE'),
          equals('application/json'));
      expect(HeaderUtils.getHeaderValue(headers, 'Authorization'), isNull);
    });
  });
}
