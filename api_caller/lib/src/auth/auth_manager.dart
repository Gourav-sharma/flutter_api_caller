import 'dart:async';

import '../request/network_request.dart';
import 'auth_config.dart';
import 'auth_exception.dart';

/// Concurrency-safe manager handling token retrieval, header attachment,
/// and single-flight single-tenant token refresh when 401 Unauthorized occurs.
class AuthManager {
  final AuthConfig config;

  Completer<String?>? _refreshCompleter;

  AuthManager(this.config);

  /// Checks if [request] requires authentication credentials.
  bool shouldAuthenticate(NetworkRequest request) {
    if (config.requiresAuth != null) {
      return config.requiresAuth!(request);
    }
    return true;
  }

  /// Attaches authorization credentials header to [request] if active token exists.
  Future<NetworkRequest> attachCredentials(NetworkRequest request) async {
    if (!shouldAuthenticate(request)) return request;

    final String? token = await config.tokenProvider.getAccessToken();
    if (token == null || token.isEmpty) return request;

    final Map<String, String> updatedHeaders =
        Map<String, String>.from(request.headers);
    updatedHeaders[config.headerName] = '${config.tokenPrefix}$token';

    return request.copyWith(headers: updatedHeaders);
  }

  /// Concurrency-safe single-flight refresh operation.
  /// If 20 requests trigger a refresh concurrently, exactly ONE token refresh
  /// operation executes while all other 19 callers wait for the same result.
  Future<String?> refreshTokens(NetworkRequest request) async {
    if (_refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    final Completer<String?> completer = Completer<String?>();
    unawaited(completer.future.catchError((_, __) => null));
    _refreshCompleter = completer;

    try {
      final String? newToken = await config.tokenProvider.refreshToken();
      if (newToken == null || newToken.isEmpty) {
        if (config.clearTokensOnRefreshFailure) {
          await config.tokenProvider.clearTokens();
        }
        final AuthenticationException err = AuthenticationException(
          message: 'Token refresh returned null or empty token.',
          request: request,
        );
        completer.completeError(err);
        throw err;
      }
      completer.complete(newToken);
      return newToken;
    } catch (e, st) {
      if (config.clearTokensOnRefreshFailure) {
        await config.tokenProvider.clearTokens();
      }
      final AuthenticationException authErr = e is AuthenticationException
          ? e
          : AuthenticationException(
              message: 'Authentication token refresh failed: $e',
              request: request,
              underlyingError: e,
              stackTrace: st,
            );
      completer.completeError(authErr, st);
      throw authErr;
    } finally {
      _refreshCompleter = null;
    }
  }
}
