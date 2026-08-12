import 'dart:async';

/// Abstract interface contract for managing authentication tokens.
abstract class TokenProvider {
  /// Retrieves the current active access token.
  Future<String?> getAccessToken();

  /// Requests a new access token using a refresh token or authentication flow.
  Future<String?> refreshToken();

  /// Clears stored access and refresh tokens upon authentication failure or logout.
  Future<void> clearTokens();
}
