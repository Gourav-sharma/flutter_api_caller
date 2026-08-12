/// Defines handling policies when an HTTP request is made while device is offline.
enum ConnectivityPolicy {
  /// Immediately throw a [ConnectionException] if offline.
  failFast,

  /// Pause execution and await connectivity restoration stream before dispatching request.
  waitForConnection,

  /// Attempt to serve response from memory or disk cache if offline.
  useCache,

  /// Route mutating request to offline persistent queue for later execution.
  queueRequest,
}

/// Defines handling policies for mutating HTTP requests made while offline.
enum OfflinePolicy {
  /// Immediately fail mutating request if device is offline.
  fail,

  /// Enqueue mutating request to persistent queue when device is offline.
  queue,
}
