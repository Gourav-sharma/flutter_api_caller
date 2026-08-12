import 'dart:convert';

import '../request/network_request.dart';
import '../response/network_response.dart';
import 'cache_config.dart';
import 'cache_entry.dart';
import 'cache_policy.dart';
import 'cache_storage.dart';
import 'memory_cache.dart';

/// Central coordinator for generating cache keys, evaluating cache policies,
/// reading/writing memory and disk caches, and background stale-while-revalidate execution.
class CacheManager {
  final CacheConfig config;
  final MemoryCache memoryCache;
  final CacheStorage diskStorage;

  CacheManager({
    CacheConfig? config,
  })  : config = config ?? const CacheConfig(),
        memoryCache = MemoryCache(
          maxEntries: config?.maxMemoryEntries ?? 100,
        ),
        diskStorage = config?.storage ?? MemoryStorageEngine();

  /// Generates deterministic unique cache key from [request] parameters.
  String generateKey(NetworkRequest request) {
    final Map<String, String> sortedHeaders =
        Map<String, String>.from(request.headers);
    sortedHeaders.remove('Authorization');
    sortedHeaders.remove('authorization');

    final Map<String, dynamic> keyData = <String, dynamic>{
      'method': request.method.toUpperCase(),
      'uri': request.uri.toString(),
      'headers': sortedHeaders,
      'body': request.body,
    };

    return jsonEncode(keyData);
  }

  /// Determines if HTTP request method is cache-safe (defaults to GET and HEAD).
  bool isCacheableMethod(String method) {
    final String m = method.toUpperCase();
    return m == 'GET' || m == 'HEAD';
  }

  /// Retrieves valid cached response for [request] using [policy].
  Future<NetworkResponse<dynamic>?> getResponse(
    NetworkRequest request, {
    CachePolicy? policy,
  }) async {
    final CachePolicy effectivePolicy = policy ?? config.policy;
    if (effectivePolicy == CachePolicy.networkOnly ||
        !isCacheableMethod(request.method)) {
      return null;
    }

    final String key = generateKey(request);

    // 1. Try Memory Cache
    if (effectivePolicy != CachePolicy.diskOnly) {
      final CacheEntry? memEntry = memoryCache.get(key);
      if (memEntry != null && !memEntry.isExpired) {
        return memEntry.toResponse(request);
      }
    }

    // 2. Try Disk Cache
    if (effectivePolicy != CachePolicy.memoryOnly) {
      try {
        final Map<String, dynamic>? diskData = await diskStorage.read(key);
        if (diskData != null) {
          final CacheEntry diskEntry = CacheEntry.fromJson(diskData);
          if (!diskEntry.isExpired) {
            memoryCache.set(key, diskEntry);
            return diskEntry.toResponse(request);
          } else {
            await diskStorage.delete(key);
          }
        }
      } catch (_) {
        // Disk cache failures must never crash networking
      }
    }

    return null;
  }

  /// Saves [response] to memory and/or disk cache according to [policy].
  Future<void> saveResponse(
    NetworkRequest request,
    NetworkResponse<dynamic> response, {
    CachePolicy? policy,
    Duration? ttl,
  }) async {
    final CachePolicy effectivePolicy = policy ?? config.policy;
    if (effectivePolicy == CachePolicy.networkOnly ||
        !isCacheableMethod(request.method) ||
        !response.isSuccess) {
      return;
    }

    final String key = generateKey(request);
    final Duration effectiveTtl = ttl ?? config.ttl;

    final CacheEntry entry = CacheEntry(
      key: key,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      headers: response.headers,
      data: response.data,
      createdAt: DateTime.now(),
      ttl: effectiveTtl,
    );

    if (effectivePolicy != CachePolicy.diskOnly) {
      memoryCache.set(key, entry);
    }

    if (effectivePolicy != CachePolicy.memoryOnly) {
      try {
        await diskStorage.write(key, entry.toJson());
      } catch (_) {
        // Ignore disk write errors
      }
    }
  }

  /// Invalidates cache entry for [request].
  Future<void> invalidate(NetworkRequest request) async {
    final String key = generateKey(request);
    memoryCache.remove(key);
    try {
      await diskStorage.delete(key);
    } catch (_) {}
  }

  /// Clears memory and disk caches completely.
  Future<void> clear() async {
    memoryCache.clear();
    try {
      await diskStorage.clear();
    } catch (_) {}
  }
}
