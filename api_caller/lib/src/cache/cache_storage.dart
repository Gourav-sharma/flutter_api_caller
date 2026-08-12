/// Interface abstract contract for persistent disk storage engines.
abstract class CacheStorage {
  /// Writes key-value map entry to persistent storage.
  Future<void> write(String key, Map<String, dynamic> data);

  /// Reads key-value map entry from persistent storage.
  Future<Map<String, dynamic>?> read(String key);

  /// Deletes specified key from persistent storage.
  Future<void> delete(String key);

  /// Clears all entries from persistent storage.
  Future<void> clear();
}

/// In-memory implementation of [CacheStorage] for testing or lightweight persistence.
class MemoryStorageEngine implements CacheStorage {
  final Map<String, Map<String, dynamic>> _storage =
      <String, Map<String, dynamic>>{};

  @override
  Future<void> write(String key, Map<String, dynamic> data) async {
    _storage[key] = Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final entry = _storage[key];
    if (entry == null) return null;
    return Map<String, dynamic>.from(entry);
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}
