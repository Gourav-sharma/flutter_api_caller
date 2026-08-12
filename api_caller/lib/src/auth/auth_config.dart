import '../request/network_request.dart';
import 'token_provider.dart';

/// Predicate function deciding whether a request requires authentication headers.
typedef AuthHeaderFilter = bool Function(NetworkRequest request);

/// Configuration options for authentication and automatic token refresh behavior.
class AuthConfig {
  /// Custom token provider implementation provided by application layer.
  final TokenProvider tokenProvider;

  /// The header name used to attach authentication credentials (defaults to 'Authorization').
  final String headerName;

  /// Prefix prepended to access token value (defaults to 'Bearer ').
  final String tokenPrefix;

  /// Optional predicate to explicitly require or skip authentication for specific requests.
  final AuthHeaderFilter? requiresAuth;

  /// Whether stored tokens should be cleared if token refresh fails.
  final bool clearTokensOnRefreshFailure;

  /// Maximum consecutive refresh attempts permitted per 401 response (defaults to 1).
  final int maxRefreshAttempts;

  const AuthConfig({
    required this.tokenProvider,
    this.headerName = 'Authorization',
    this.tokenPrefix = 'Bearer ',
    this.requiresAuth,
    this.clearTokensOnRefreshFailure = true,
    this.maxRefreshAttempts = 1,
  });
}
