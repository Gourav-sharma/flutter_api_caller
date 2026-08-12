import '../request/network_request.dart';

/// Represents a queued mutating HTTP request waiting for network execution.
class OfflineQueueItem {
  final String id;
  final String method;
  final String path;
  final Uri uri;
  final Map<String, String> headers;
  final Map<String, dynamic> queryParameters;
  final dynamic body;
  final DateTime createdAt;
  final int retryCount;
  final int maxAttempts;
  final int priority;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;
  final String? lastError;

  OfflineQueueItem({
    required this.id,
    required this.method,
    required this.path,
    required this.uri,
    required this.createdAt,
    this.headers = const <String, String>{},
    this.queryParameters = const <String, dynamic>{},
    this.body,
    this.retryCount = 0,
    this.maxAttempts = 5,
    this.priority = 0,
    this.expiresAt,
    this.metadata = const <String, dynamic>{},
    this.lastError,
  });

  /// Returns true if this queue item has expired based on [expiresAt].
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Converts this queue item back into a [NetworkRequest].
  NetworkRequest toNetworkRequest() {
    return NetworkRequest(
      method: method,
      path: path,
      uri: uri,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      extra: metadata,
    );
  }

  /// Serializes item to JSON map for disk persistence.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'method': method,
      'path': path,
      'uri': uri.toString(),
      'headers': headers,
      'queryParameters': queryParameters,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'maxAttempts': maxAttempts,
      'priority': priority,
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
      'lastError': lastError,
    };
  }

  /// Deserializes item from JSON map.
  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: json['id'] as String,
      method: json['method'] as String,
      path: json['path'] as String,
      uri: Uri.parse(json['uri'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      headers: Map<String, String>.from(json['headers'] as Map),
      queryParameters:
          Map<String, dynamic>.from(json['queryParameters'] as Map),
      body: json['body'],
      retryCount: json['retryCount'] as int? ?? 0,
      maxAttempts: json['maxAttempts'] as int? ?? 5,
      priority: json['priority'] as int? ?? 0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : <String, dynamic>{},
      lastError: json['lastError'] as String?,
    );
  }

  OfflineQueueItem copyWith({
    int? retryCount,
    String? lastError,
  }) {
    return OfflineQueueItem(
      id: id,
      method: method,
      path: path,
      uri: uri,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      maxAttempts: maxAttempts,
      priority: priority,
      expiresAt: expiresAt,
      metadata: metadata,
      lastError: lastError ?? this.lastError,
    );
  }
}
