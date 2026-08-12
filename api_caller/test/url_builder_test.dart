import 'package:flutter_api_caller/src/utils/url_builder.dart';
import 'package:test/test.dart';

void main() {
  group('UrlBuilder', () {
    test('resolves simple path with baseUrl', () {
      final Uri uri = UrlBuilder.buildUri(
        baseUrl: 'https://api.example.com',
        path: '/users',
      );
      expect(uri.toString(), equals('https://api.example.com/users'));
    });

    test('handles trailing slash on baseUrl and leading slash on path', () {
      final Uri uri = UrlBuilder.buildUri(
        baseUrl: 'https://api.example.com/v1/',
        path: '/users',
      );
      expect(uri.toString(), equals('https://api.example.com/v1/users'));
    });

    test('handles missing slash on baseUrl and path', () {
      final Uri uri = UrlBuilder.buildUri(
        baseUrl: 'https://api.example.com/v1',
        path: 'users',
      );
      expect(uri.toString(), equals('https://api.example.com/v1/users'));
    });

    test('overrides baseUrl with absolute URL path', () {
      final Uri uri = UrlBuilder.buildUri(
        baseUrl: 'https://api.example.com',
        path: 'https://custom.service.org/data',
      );
      expect(uri.toString(), equals('https://custom.service.org/data'));
    });

    test('encodes query parameters correctly', () {
      final Uri uri = UrlBuilder.buildUri(
        baseUrl: 'https://api.example.com',
        path: '/users',
        queryParameters: <String, dynamic>{
          'page': 1,
          'search': 'john doe',
          'active': true,
          'nullable': null,
          'tags': <String>['flutter', 'dart'],
        },
      );

      expect(uri.queryParameters['page'], equals('1'));
      expect(uri.queryParameters['search'], equals('john doe'));
      expect(uri.queryParameters['active'], equals('true'));
      expect(uri.queryParameters.containsKey('nullable'), isFalse);
      expect(
          uri.queryParametersAll['tags'], equals(<String>['flutter', 'dart']));
    });
  });
}
