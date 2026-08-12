import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../exceptions/connection_exception.dart';
import '../exceptions/network_exception.dart';
import '../exceptions/serialization_exception.dart';
import '../exceptions/timeout_exception.dart';
import '../request/network_request.dart';
import '../response/network_response.dart';
import 'network_transport.dart';

/// Production network transport implementation powered by `package:http`.
class HttpNetworkTransport implements NetworkTransport {
  final http.Client _client;

  /// Creates an instance of [HttpNetworkTransport].
  HttpNetworkTransport({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<NetworkResponse<dynamic>> send(NetworkRequest request) async {
    try {
      if (request.multipart != null) {
        return await _sendMultipart(request);
      } else {
        return await _sendStandard(request);
      }
    } on TimeoutException catch (e, st) {
      throw NetworkTimeoutException(
        message: 'Request timed out for URI: ${request.uri}',
        timeoutType: TimeoutType.receive,
        timeoutDuration: request.receiveTimeout,
        request: request,
        underlyingError: e,
        stackTrace: st,
      );
    } on SocketException catch (e, st) {
      throw ConnectionException(
        message: 'Failed to connect to host: ${request.uri.host}',
        request: request,
        underlyingError: e,
        stackTrace: st,
      );
    } on http.ClientException catch (e, st) {
      throw ConnectionException(
        message: 'HTTP client error: ${e.message}',
        request: request,
        underlyingError: e,
        stackTrace: st,
      );
    } on NetworkException {
      rethrow;
    } catch (e, st) {
      throw ConnectionException(
        message: 'Transport error occurred: $e',
        request: request,
        underlyingError: e,
        stackTrace: st,
      );
    }
  }

  Future<NetworkResponse<dynamic>> _sendStandard(NetworkRequest request) async {
    final http.Request httpRequest = http.Request(
      request.method,
      request.uri,
    );

    httpRequest.headers.addAll(request.headers);

    if (request.body != null) {
      if (request.body is String) {
        httpRequest.body = request.body as String;
      } else if (request.body is List<int>) {
        httpRequest.bodyBytes = request.body as List<int>;
      } else {
        try {
          httpRequest.body = jsonEncode(request.body);
        } catch (e, st) {
          throw SerializationException(
            message: 'Failed to JSON encode request body: $e',
            request: request,
            underlyingError: e,
            stackTrace: st,
          );
        }
      }
    }

    final http.StreamedResponse streamedResponse =
        await _client.send(httpRequest).timeout(request.receiveTimeout);

    final http.Response httpResponse =
        await http.Response.fromStream(streamedResponse);

    return _buildResponse(request, httpResponse);
  }

  Future<NetworkResponse<dynamic>> _sendMultipart(
      NetworkRequest request) async {
    final http.MultipartRequest multiRequest = http.MultipartRequest(
      request.method,
      request.uri,
    );

    multiRequest.headers.addAll(request.headers);
    if (request.multipart != null) {
      multiRequest.fields.addAll(request.multipart!.fields);

      for (final file in request.multipart!.files) {
        if (file.bytes != null) {
          multiRequest.files.add(
            http.MultipartFile.fromBytes(
              file.field,
              file.bytes!,
              filename: file.filename,
            ),
          );
        } else if (file.path != null) {
          multiRequest.files.add(
            await http.MultipartFile.fromPath(
              file.field,
              file.path!,
              filename: file.filename,
            ),
          );
        }
      }
    }

    final http.StreamedResponse streamedResponse =
        await _client.send(multiRequest).timeout(request.receiveTimeout);

    final http.Response httpResponse =
        await http.Response.fromStream(streamedResponse);

    return _buildResponse(request, httpResponse);
  }

  NetworkResponse<dynamic> _buildResponse(
    NetworkRequest request,
    http.Response response,
  ) {
    dynamic parsedBody;
    final String bodyString = response.body;

    if (bodyString.isNotEmpty) {
      final String? contentType = response.headers['content-type'];
      final bool isJson = contentType != null &&
          contentType.toLowerCase().contains('application/json');

      if (isJson) {
        try {
          parsedBody = jsonDecode(bodyString);
        } catch (_) {
          // If content-type claims JSON but parse fails, keep raw string for error response analysis
          parsedBody = bodyString;
        }
      } else {
        try {
          parsedBody = jsonDecode(bodyString);
        } catch (_) {
          parsedBody = bodyString;
        }
      }
    }

    return NetworkResponse<dynamic>(
      statusCode: response.statusCode,
      statusMessage: response.reasonPhrase,
      headers: response.headers,
      data: parsedBody,
      request: request,
    );
  }

  @override
  void close() {
    _client.close();
  }
}
