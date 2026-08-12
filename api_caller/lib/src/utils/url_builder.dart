import 'package:meta/meta.dart';

/// Helper utility for building and resolving absolute [Uri]s with query parameters.
@internal
class UrlBuilder {
  const UrlBuilder._();

  /// Builds a final resolved [Uri] using [baseUrl], [path], and [queryParameters].
  ///
  /// Safe against duplicate slashes, handles absolute path overrides, and standardizes
  /// query parameter serialization.
  static Uri buildUri({
    required String path,
    String? baseUrl,
    Map<String, dynamic>? queryParameters,
  }) {
    final String resolvedPath = _resolvePath(baseUrl: baseUrl, path: path);
    final Uri baseUri = Uri.parse(resolvedPath);

    if (queryParameters == null || queryParameters.isEmpty) {
      return baseUri;
    }

    final Map<String, dynamic> existingParams = Map<String, dynamic>.from(
      baseUri.queryParametersAll,
    );

    final Map<String, List<String>> normalizedParams = <String, List<String>>{};

    // Add existing query parameters from baseUri
    existingParams.forEach((String key, dynamic value) {
      if (value is List) {
        normalizedParams[key] = value.map((e) => e.toString()).toList();
      } else if (value != null) {
        normalizedParams[key] = <String>[value.toString()];
      }
    });

    // Merge new query parameters
    queryParameters.forEach((String key, dynamic value) {
      if (value == null) return;

      if (value is Iterable) {
        final List<String> stringList =
            value.where((e) => e != null).map((e) => e.toString()).toList();
        if (stringList.isNotEmpty) {
          normalizedParams[key] = stringList;
        }
      } else {
        normalizedParams[key] = <String>[value.toString()];
      }
    });

    return baseUri.replace(
        queryParameters: _flattenQueryParameters(normalizedParams));
  }

  /// Flattens parameter lists into string values for Uri query replace.
  static Map<String, dynamic> _flattenQueryParameters(
    Map<String, List<String>> params,
  ) {
    final Map<String, dynamic> result = <String, dynamic>{};
    params.forEach((String key, List<String> values) {
      if (values.length == 1) {
        result[key] = values.first;
      } else {
        result[key] = values;
      }
    });
    return result;
  }

  /// Resolves the URL string combining [baseUrl] and [path].
  static String _resolvePath({
    required String path,
    String? baseUrl,
  }) {
    final String trimmedPath = path.trim();

    // Check if path is already an absolute URL
    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      return trimmedPath;
    }

    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return trimmedPath;
    }

    final String trimmedBase = baseUrl.trim();

    final bool baseHasTrailingSlash = trimmedBase.endsWith('/');
    final bool pathHasLeadingSlash = trimmedPath.startsWith('/');

    if (baseHasTrailingSlash && pathHasLeadingSlash) {
      return '${trimmedBase.substring(0, trimmedBase.length - 1)}$trimmedPath';
    } else if (!baseHasTrailingSlash && !pathHasLeadingSlash) {
      return '$trimmedBase/$trimmedPath';
    } else {
      return '$trimmedBase$trimmedPath';
    }
  }
}
