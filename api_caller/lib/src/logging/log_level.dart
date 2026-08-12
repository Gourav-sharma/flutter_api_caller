/// Severity level for logging network activity.
enum LogLevel {
  /// Disable all logging.
  none,

  /// Log only error events.
  error,

  /// Log warnings and errors.
  warning,

  /// Log standard status information, requests, and responses.
  info,

  /// Verbose logging including full (redacted) headers and bodies.
  debug,
}
