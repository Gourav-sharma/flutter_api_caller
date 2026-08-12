/// Strategies governing cache lookup and network fallback behavior.
enum CachePolicy {
  /// Always fetch from remote network; bypass cache entirely.
  networkOnly,

  /// Serve exclusively from local cache; fail if not cached.
  cacheOnly,

  /// Prefer cache if fresh; execute network request only on cache miss.
  cacheFirst,

  /// Prefer network; fall back to cache if network request fails.
  networkFirst,

  /// Immediately return cached response, then revalidate in background via network and update cache.
  staleWhileRevalidate,

  /// Use only in-memory LRU cache.
  memoryOnly,

  /// Use only persistent disk cache.
  diskOnly,

  /// Combine memory LRU cache and persistent disk cache.
  memoryAndDisk,
}
