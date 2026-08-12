import 'dart:convert';
import 'dart:io';

import 'cache_storage.dart';

/// Cross-platform file-system disk storage engine for persistent cache entries.
class FileCacheStorage implements CacheStorage {
  final Directory directory;

  FileCacheStorage(this.directory);

  File _getFile(String key) {
    final String safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return File('${directory.path}/cache_$safeKey.json');
  }

  @override
  Future<void> write(String key, Map<String, dynamic> data) async {
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final File file = _getFile(key);
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {
      // Disk errors are non-fatal and ignored to protect networking stability
    }
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final File file = _getFile(key);
      if (!await file.exists()) return null;

      final String content = await file.readAsString();
      final dynamic decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      // On corruption or read error, cleanup corrupted file silently
      try {
        final File file = _getFile(key);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final File file = _getFile(key);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      if (await directory.exists()) {
        final List<FileSystemEntity> files = directory.listSync();
        for (final entity in files) {
          if (entity is File && entity.path.contains('cache_')) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }
}
