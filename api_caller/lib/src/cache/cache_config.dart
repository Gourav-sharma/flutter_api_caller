import 'cache_policy.dart';
import 'cache_storage.dart';

/// Configuration options for response caching behavior.
class CacheConfig {
  /// Default cache strategy policy.
  final CachePolicy policy;

  /// Default time-to-live duration for cached entries.
  final Duration ttl;

  /// Maximum number of items held in memory LRU cache.
  final int maxMemoryEntries;

  /// Persistent disk storage engine implementation.
  final CacheStorage? storage;

  const CacheConfig({
    this.policy = CachePolicy.networkOnly,
    this.ttl = const Duration(minutes: 5),
    this.maxMemoryEntries = 100,
    this.storage,
  });
}
