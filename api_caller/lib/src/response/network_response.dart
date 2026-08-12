import '../request/network_request.dart';

/// Strongly-typed network response object.
class NetworkResponse<T> {
  /// The decoded response payload of type [T].
  final T? data;

  /// HTTP status code (e.g. 200, 201, 404).
  final int statusCode;

  /// Optional HTTP status message (e.g. "OK", "Not Found").
  final String? statusMessage;

  /// Response headers map.
  final Map<String, String> headers;

  /// The original [NetworkRequest] associated with this response.
  final NetworkRequest request;

  /// Optional response metadata.
  final Map<String, dynamic> extra;

  const NetworkResponse({
    required this.statusCode,
    required this.headers,
    required this.request,
    this.data,
    this.statusMessage,
    this.extra = const <String, dynamic>{},
  });

  /// Convenience getter to check if the HTTP status code indicates success (200..299).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Creates a copy of [NetworkResponse] with updated fields.
  NetworkResponse<R> copyWith<R>({
    R? data,
    int? statusCode,
    String? statusMessage,
    Map<String, String>? headers,
    NetworkRequest? request,
    Map<String, dynamic>? extra,
  }) {
    return NetworkResponse<R>(
      data: data ?? (this.data as R?),
      statusCode: statusCode ?? this.statusCode,
      statusMessage: statusMessage ?? this.statusMessage,
      headers: headers ?? Map<String, String>.from(this.headers),
      request: request ?? this.request,
      extra: extra ?? Map<String, dynamic>.from(this.extra),
    );
  }
}
