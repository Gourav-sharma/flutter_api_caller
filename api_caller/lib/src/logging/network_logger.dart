import 'dart:convert';
import 'dart:developer' as developer;

import '../exceptions/network_exception.dart';
import '../interceptors/interceptor_handler.dart';
import '../interceptors/network_interceptor.dart';
import '../request/network_request.dart';
import '../response/network_response.dart';
import 'log_level.dart';

/// Function signature for custom log output handlers.
typedef LogPrinter = void Function(String message, {LogLevel level});

/// Configurable, security-focused logging interceptor for `flutter_api_caller`.
class NetworkLogger extends NetworkInterceptor {
  /// Active log severity level.
  final LogLevel level;

  /// Custom log printer callback. Defaults to [developer.log].
  final LogPrinter? logPrinter;

  /// Set of header names (case-insensitive) to redact from logs.
  final Set<String> sensitiveHeaders;

  /// Set of payload JSON field names (case-insensitive) to redact from logs.
  final Set<String> sensitiveFields;

  /// Default list of sensitive header keys redacted for security.
  static const Set<String> defaultSensitiveHeaders = <String>{
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'api-key',
    'apikey',
    'x-auth-token',
  };

  /// Default list of sensitive payload field keys redacted for security.
  static const Set<String> defaultSensitiveFields = <String>{
    'password',
    'pass',
    'secret',
    'access_token',
    'accesstoken',
    'refresh_token',
    'refreshtoken',
    'token',
    'auth_token',
    'private_key',
    'credit_card',
    'ssn',
  };

  NetworkLogger({
    this.level = LogLevel.info,
    this.logPrinter,
    Set<String>? sensitiveHeaders,
    Set<String>? sensitiveFields,
  })  : sensitiveHeaders = sensitiveHeaders != null
            ? (Set<String>.from(defaultSensitiveHeaders)
              ..addAll(sensitiveHeaders.map((e) => e.toLowerCase())))
            : defaultSensitiveHeaders,
        sensitiveFields = sensitiveFields != null
            ? (Set<String>.from(defaultSensitiveFields)
              ..addAll(sensitiveFields.map((e) => e.toLowerCase())))
            : defaultSensitiveFields;

  void _log(String message, LogLevel messageLevel) {
    if (level == LogLevel.none) return;
    if (messageLevel.index > level.index) return;

    if (logPrinter != null) {
      logPrinter!(message, level: messageLevel);
    } else {
      developer.log(
        message,
        name: 'flutter_api_caller',
        level: _getDeveloperLevel(messageLevel),
      );
    }
  }

  int _getDeveloperLevel(LogLevel messageLevel) {
    switch (messageLevel) {
      case LogLevel.error:
        return 1000;
      case LogLevel.warning:
        return 900;
      case LogLevel.info:
        return 800;
      case LogLevel.debug:
        return 500;
      case LogLevel.none:
        return 0;
    }
  }

  @override
  void onRequest(NetworkRequest request, RequestInterceptorHandler handler) {
    if (level == LogLevel.none) {
      handler.next(request);
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('--> ${request.method.toUpperCase()} ${request.uri}');

    if (level == LogLevel.debug) {
      if (request.headers.isNotEmpty) {
        buffer.writeln('Headers:');
        final Map<String, String> maskedHeaders = _maskHeaders(request.headers);
        maskedHeaders.forEach((key, value) {
          buffer.writeln('  $key: $value');
        });
      }

      if (request.queryParameters.isNotEmpty) {
        buffer.writeln('Query Parameters:');
        request.queryParameters.forEach((key, value) {
          buffer.writeln('  $key: $value');
        });
      }

      if (request.body != null) {
        buffer.writeln('Body:');
        buffer.writeln('  ${_maskBody(request.body)}');
      }

      if (request.multipart != null) {
        buffer.writeln('Multipart Fields: ${request.multipart!.fields.keys}');
        buffer.writeln(
          'Multipart Files: ${request.multipart!.files.map((f) => '${f.field} (${f.filename ?? "unnamed"})').toList()}',
        );
      }
    }

    _log(buffer.toString().trimRight(), LogLevel.info);
    handler.next(request);
  }

  @override
  void onResponse(
    NetworkResponse<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (level == LogLevel.none) {
      handler.next(response);
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      '<-- ${response.statusCode} ${response.request.method.toUpperCase()} ${response.request.uri}',
    );

    if (level == LogLevel.debug) {
      if (response.headers.isNotEmpty) {
        buffer.writeln('Headers:');
        final Map<String, String> maskedHeaders =
            _maskHeaders(response.headers);
        maskedHeaders.forEach((key, value) {
          buffer.writeln('  $key: $value');
        });
      }

      if (response.data != null) {
        buffer.writeln('Response Data:');
        buffer.writeln('  ${_maskBody(response.data)}');
      }
    }

    _log(buffer.toString().trimRight(), LogLevel.info);
    handler.next(response);
  }

  @override
  void onError(NetworkException error, ErrorInterceptorHandler handler) {
    if (level == LogLevel.none) {
      handler.next(error);
      return;
    }

    final StringBuffer buffer = StringBuffer();
    final Uri? uri = error.request?.uri;
    final String method = error.request?.method.toUpperCase() ?? '';

    buffer.writeln('<-- ERROR ${error.statusCode ?? ''} $method ${uri ?? ''}');
    buffer.writeln('Type: ${error.runtimeType}');
    buffer.writeln('Message: ${error.message}');

    if (error.responseData != null && level == LogLevel.debug) {
      buffer.writeln('Error Response Data:');
      buffer.writeln('  ${_maskBody(error.responseData)}');
    }

    _log(buffer.toString().trimRight(), LogLevel.error);
    handler.next(error);
  }

  Map<String, String> _maskHeaders(Map<String, String> headers) {
    final Map<String, String> masked = <String, String>{};
    headers.forEach((key, value) {
      if (sensitiveHeaders.contains(key.toLowerCase())) {
        masked[key] = '[REDACTED]';
      } else {
        masked[key] = value;
      }
    });
    return masked;
  }

  dynamic _maskBody(dynamic body) {
    if (body == null) return null;
    if (body is Map) {
      final Map<String, dynamic> maskedMap = <String, dynamic>{};
      body.forEach((key, value) {
        final String keyStr = key.toString();
        if (sensitiveFields.contains(keyStr.toLowerCase())) {
          maskedMap[keyStr] = '[REDACTED]';
        } else {
          maskedMap[keyStr] = _maskBody(value);
        }
      });
      return jsonEncode(maskedMap);
    } else if (body is List) {
      return jsonEncode(body.map(_maskBody).toList());
    } else {
      return body.toString();
    }
  }
}
