import 'package:meta/meta.dart';

/// Helper utility for merging and normalizing HTTP headers.
@internal
class HeaderUtils {
  const HeaderUtils._();

  /// Merges [globalHeaders] and [requestHeaders].
  ///
  /// Matching header keys are case-insensitively overridden by [requestHeaders].
  static Map<String, String> mergeHeaders(
    Map<String, String>? globalHeaders,
    Map<String, String>? requestHeaders,
  ) {
    final Map<String, String> result = <String, String>{};

    if (globalHeaders != null) {
      for (final entry in globalHeaders.entries) {
        result[entry.key] = entry.value;
      }
    }

    if (requestHeaders != null) {
      for (final requestEntry in requestHeaders.entries) {
        // Remove existing header case-insensitively if found
        final String existingKey = result.keys.firstWhere(
          (k) => k.toLowerCase() == requestEntry.key.toLowerCase(),
          orElse: () => '',
        );

        if (existingKey.isNotEmpty) {
          result.remove(existingKey);
        }

        result[requestEntry.key] = requestEntry.value;
      }
    }

    return result;
  }

  /// Retrieves a header value by case-insensitive key search.
  static String? getHeaderValue(Map<String, String> headers, String targetKey) {
    final String lowerTarget = targetKey.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lowerTarget) {
        return entry.value;
      }
    }
    return null;
  }
}
