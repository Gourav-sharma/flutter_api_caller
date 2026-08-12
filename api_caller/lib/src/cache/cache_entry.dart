import '../request/network_request.dart';
import '../response/network_response.dart';

/// Persistable cache wrapper container for network responses with TTL metadata.
class CacheEntry {
  final String key;
  final int statusCode;
  final String? statusMessage;
  final Map<String, String> headers;
  final dynamic data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.key,
    required this.statusCode,
    required this.headers,
    required this.data,
    required this.createdAt,
    required this.ttl,
    this.statusMessage,
  });

  /// Returns true if this cache entry has exceeded its time-to-live.
  bool get isExpired => DateTime.now().difference(createdAt) > ttl;

  /// Restores a strongly typed [NetworkResponse] from this cache entry.
  NetworkResponse<dynamic> toResponse(NetworkRequest request) {
    final Map<String, dynamic> extraMap =
        Map<String, dynamic>.from(request.extra);
    extraMap['is_cache_hit'] = true;

    return NetworkResponse<dynamic>(
      statusCode: statusCode,
      statusMessage: statusMessage,
      headers: headers,
      data: data,
      request: request,
      extra: extraMap,
    );
  }

  /// Serializes cache entry to JSON map for persistent disk storage.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'headers': headers,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'ttlMs': ttl.inMilliseconds,
    };
  }

  /// Deserializes cache entry from JSON map.
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'] as String,
      statusCode: json['statusCode'] as int,
      statusMessage: json['statusMessage'] as String?,
      headers: Map<String, String>.from(json['headers'] as Map),
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt'] as String),
      ttl: Duration(milliseconds: json['ttlMs'] as int),
    );
  }
}
