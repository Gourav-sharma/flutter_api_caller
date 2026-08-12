import 'dart:collection';

import 'cache_entry.dart';

/// Concurrency-safe in-memory Least Recently Used (LRU) cache with maximum capacity.
class MemoryCache {
  final int maxEntries;
  final LinkedHashMap<String, CacheEntry> _cache =
      LinkedHashMap<String, CacheEntry>();

  MemoryCache({this.maxEntries = 100});

  /// Retrieves entry by key, updating LRU access order.
  CacheEntry? get(String key) {
    final entry = _cache.remove(key);
    if (entry == null) return null;

    if (entry.isExpired) {
      return null;
    }

    // Re-insert at end to mark as recently used
    _cache[key] = entry;
    return entry;
  }

  /// Stores entry in memory cache, evicting oldest entry if capacity is exceeded.
  void set(String key, CacheEntry entry) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxEntries && _cache.isNotEmpty) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = entry;
  }

  /// Removes specified key from memory cache.
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clears all entries from memory cache.
  void clear() {
    _cache.clear();
  }

  /// Returns current entry count.
  int get length => _cache.length;
}
